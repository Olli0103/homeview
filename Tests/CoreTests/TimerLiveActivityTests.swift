import XCTest
@testable import HomeViewCore

@MainActor private final class ActivityBackendProbe:TimerActivityBackend {
 var supported=true
 var applied:[TimerActivityState?]=[]
 var starts=0,ends=0,active=false,throwNext=false
 var hold=false
 var continuation:CheckedContinuation<Void,Never>?
 func apply(_ state:TimerActivityState?,mayStart:@escaping @MainActor ()->Bool) async throws -> TimerActivityDelivery {
  if hold {hold=false;await withCheckedContinuation {continuation=$0}}
  if throwNext {throwNext=false;throw CocoaError(.fileWriteUnknown)}
  applied.append(state)
  if state==nil {ends+=1;active=false;return .ended}
  if !active {guard mayStart() else {return .waitingForExplicitStart};starts+=1;active=true}
  return .active
 }
}
final class TimerLiveActivityTests:XCTestCase {
 let now=Date(timeIntervalSince1970:1_800_000_000)
 func state(_ seconds:Double=60)->TimerActivityState {
  TimerActivityState.project([.init(deadline:now.addingTimeInterval(seconds),pausedRemaining:0)],at:now)!
 }
 func testProjectionUsesNextDeadlineAndCountsPausedWithoutPersonalPayload() throws {
  let value=TimerActivityState.project([.init(deadline:now.addingTimeInterval(120),pausedRemaining:900),.init(deadline:now.addingTimeInterval(60),pausedRemaining:100),.init(deadline:nil,pausedRemaining:4.2),.init(deadline:now,pausedRemaining:99)],at:now)!
  XCTAssertEqual(value.runningCount,2);XCTAssertEqual(value.pausedCount,1)
  XCTAssertEqual(value.deadline,now.addingTimeInterval(60));XCTAssertEqual(value.pausedSeconds,5)
  let object=try JSONSerialization.jsonObject(with:JSONEncoder().encode(value)) as! [String:Any]
  XCTAssertEqual(Set(object.keys),Set(["runningCount","pausedCount","deadline","pausedSeconds"]))
  XCTAssertEqual(try JSONDecoder().decode(TimerActivityState.self,from:JSONEncoder().encode(value)),value)
 }
 func testProjectionBoundsMalformedExpiredAndEmptyInputs() {
  XCTAssertNil(TimerActivityState.project([],at:now))
  XCTAssertNil(TimerActivityState.project([.init(deadline:now.addingTimeInterval(-1),pausedRemaining:5),.init(deadline:nil,pausedRemaining:.nan),.init(deadline:nil,pausedRemaining:-1),.init(deadline:nil,pausedRemaining:86401),.init(deadline:now.addingTimeInterval(86401),pausedRemaining:0)],at:now))
  XCTAssertNil(TimerActivityState.project([],at:Date(timeIntervalSince1970:.nan)))
  let value=TimerActivityState.project(Array(repeating:.init(deadline:nil,pausedRemaining:10),count:13),at:now)!
  XCTAssertEqual(value.pausedCount,12);XCTAssertNil(value.deadline)
 }
 @MainActor func settle(_ s:TimerLiveActivitySession) async throws {
  for _ in 0..<1000 where s.busy {await Task.yield()}
  XCTAssertFalse(s.busy)
 }
 @MainActor private func entered(_ p:ActivityBackendProbe) async {
  for _ in 0..<1000 where p.continuation==nil {await Task.yield()}
  XCTAssertNotNil(p.continuation)
 }
 @MainActor func testExplicitForegroundStartAndPauseResumeEndAreSerialized() async throws {
  let p=ActivityBackendProbe()
  let session=TimerLiveActivitySession(backend:p)
  session.synchronize(state(),enabled:true,foreground:true);try await settle(session)
  XCTAssertEqual(p.starts,0)
  session.synchronize(state(),enabled:true,foreground:true,requestStart:true);try await settle(session)
  XCTAssertEqual(p.starts,1)
  let paused=TimerActivityState.project([.init(deadline:nil,pausedRemaining:30)],at:now)
  session.synchronize(paused,enabled:true,foreground:true);try await settle(session)
  XCTAssertEqual(p.applied.last!,paused);XCTAssertEqual(p.starts,1)
  session.synchronize(state(30),enabled:true,foreground:true);try await settle(session)
  session.synchronize(nil,enabled:true,foreground:true);try await settle(session)
  XCTAssertFalse(p.active);XCTAssertEqual(p.ends,1)
 }
 @MainActor func testDisabledOrBackgroundNeverStartsAndRepeatedPulseDoesNotWrite() async throws {
  let p=ActivityBackendProbe(),s=TimerLiveActivitySession(backend:p)
  s.synchronize(state(),enabled:false,foreground:true,requestStart:true);try await settle(s)
  XCTAssertEqual(p.starts,0);XCTAssertNil(p.applied.last!)
  s.synchronize(state(),enabled:true,foreground:false,requestStart:true);try await settle(s)
  XCTAssertEqual(p.starts,0)
  let count=p.applied.count
  for _ in 0..<30 {s.synchronize(state(),enabled:true,foreground:false)}
  try await settle(s);XCTAssertEqual(p.applied.count,count)
 }
 @MainActor func testLateStartCannotCrossRevocationAndOldResultCannotReplaceStatus() async throws {
  let p=ActivityBackendProbe(),s=TimerLiveActivitySession(backend:p);p.hold=true
  s.synchronize(state(),enabled:true,foreground:true,requestStart:true);await entered(p)
  s.synchronize(state(),enabled:false,foreground:true)
  p.continuation?.resume();p.continuation=nil;try await settle(s)
  XCTAssertEqual(p.starts,0);XCTAssertFalse(p.active);XCTAssertEqual(s.status,TimerActivityDelivery.ended.message)
 }
 @MainActor func testLateStartCannotCrossBackgroundOrRestartWithoutAnotherExplicitAction() async throws {
  let p=ActivityBackendProbe(),s=TimerLiveActivitySession(backend:p);p.hold=true
  s.synchronize(state(),enabled:true,foreground:true,requestStart:true);await entered(p)
  s.synchronize(state(),enabled:true,foreground:false)
  p.continuation?.resume();p.continuation=nil;try await settle(s)
  XCTAssertEqual(p.starts,0)
  s.synchronize(state(),enabled:true,foreground:true);try await settle(s);XCTAssertEqual(p.starts,0)
 }
 @MainActor func testInFlightUpdateConvergesToLatestStateThenEndsOnlyOwnActivity() async throws {
  let p=ActivityBackendProbe(),s=TimerLiveActivitySession(backend:p)
  s.synchronize(state(),enabled:true,foreground:true,requestStart:true);try await settle(s)
  p.hold=true;s.synchronize(state(80),enabled:true,foreground:true);await entered(p)
  s.synchronize(state(90),enabled:true,foreground:true)
  s.synchronize(state(),enabled:false,foreground:true)
  p.continuation?.resume();p.continuation=nil;try await settle(s)
  XCTAssertEqual(p.starts,1);XCTAssertFalse(p.active);XCTAssertNil(p.applied.last!)
 }
 @MainActor func testBackendFailureIsNotTimerMutationOrAutomaticRetryLoop() async throws {
  let p=ActivityBackendProbe(),s=TimerLiveActivitySession(backend:p);p.throwNext=true
  s.synchronize(state(),enabled:true,foreground:true,requestStart:true);try await settle(s)
  XCTAssertTrue(s.status.contains("could not"));XCTAssertEqual(p.starts,0)
  s.synchronize(state(),enabled:true,foreground:true);try await settle(s);XCTAssertTrue(p.applied.isEmpty)
  s.synchronize(state(),enabled:true,foreground:true,requestStart:true);try await settle(s);XCTAssertEqual(p.starts,1)
 }
}

extension TimerLiveActivityTests {
 func testLiveActivityPreferenceIsOptInAndMigratesWithoutEnablingMalformedValues() throws {
  XCTAssertFalse(try Snapshot.decodeMigrating(Data("{}".utf8)).timerLiveActivitiesEnabled)
  XCTAssertFalse(try Snapshot.decodeMigrating(Data("{\"timerLiveActivitiesEnabled\":\"true\"}".utf8)).timerLiveActivitiesEnabled)
  XCTAssertTrue(try Snapshot.decodeMigrating(Data("{\"timerLiveActivitiesEnabled\":true}".utf8)).timerLiveActivitiesEnabled)
  XCTAssertFalse(Snapshot().timerLiveActivitiesEnabled)
 }
}
