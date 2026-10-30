import XCTest
@testable import HomeViewCore

@MainActor final class LockActionSessionTests: XCTestCase {
  final class Access {
    var time: TimeInterval = 100
    var value=LockAccessContext(generation:1,active:true,authenticated:true)
  }
  final class Provider: LockDeviceProvider {
    var value=LockReading(state:.locked)
    var reads=0,writes=0,applied=0
    var denyWrite=false
    var failReads:Set<Int>=[]
    var returned:[Int:LockReading]=[:]
    var pauseReadAt:Int?
    var pauseWrite=false
    var paused:(()->Void)?
    var continuation:CheckedContinuation<Void,Never>?
    func read() async throws -> LockReading {
      reads+=1;let index=reads
      if pauseReadAt==index {
        await withCheckedContinuation { continuation=$0;paused?() }
      }
      if failReads.contains(index) { throw LockDeviceError.unavailable }
      return returned[index] ?? value
    }
    func setLocked(_ target:Bool,expected:LockReading) async throws {
      writes+=1
      if pauseWrite { await withCheckedContinuation { continuation=$0;paused?() } }
      if denyWrite { throw LockDeviceError.denied }
      guard value==expected else { throw LockDeviceError.stateChanged }
      value=LockReading(state:target ? .locked:.unlocked,batteryPercent:value.batteryPercent)
      applied+=1
    }
    func resume() { let pending=continuation;continuation=nil;pending?.resume() }
  }
  private func setup() -> (LockActionSession,Provider,Access) {
    let p=Provider(),a=Access()
    return (LockActionSession(provider:p,context:{a.value},uptime:{a.time}),p,a)
  }
  func testProposalAndCancellationSendNothing() async throws {
    let (s,p,_)=setup();await s.prepare()
    XCTAssertEqual(s.phase,.approval);XCTAssertEqual(s.reading?.state,.locked)
    let id=try XCTUnwrap(s.proposal?.id)
    XCTAssertEqual(p.writes,0);s.cancelProposal();await s.confirm(id:id)
    XCTAssertEqual(p.writes,0);XCTAssertEqual(p.value.state,.locked);XCTAssertNil(s.proposal)
  }
  func testMatchingReadbackAndConsumedApproval() async throws {
    let (s,p,_)=setup();await s.prepare();let id=try XCTUnwrap(s.proposal?.id)
    await s.confirm(id:id)
    XCTAssertEqual(p.writes,1);XCTAssertEqual(p.applied,1);XCTAssertEqual(p.reads,3)
    XCTAssertEqual(s.phase,.confirmed);XCTAssertEqual(s.reading?.state,.unlocked)
    await s.confirm(id:id);XCTAssertEqual(p.writes,1)
  }
  func testLateCancelCannotRelabelAnAlreadyConfirmedWriteAsNotSent() async throws {
    let (s,p,_)=setup();await s.prepare();await s.confirm(id:try XCTUnwrap(s.proposal?.id))
    let status=s.status;s.cancelProposal()
    XCTAssertEqual(s.phase,.confirmed);XCTAssertEqual(s.status,status);XCTAssertEqual(p.writes,1)
  }
  func testRelockingUsesAnExplicitTargetAndFreshApproval() async throws {
    let (s,p,_)=setup();p.value=LockReading(state:.unlocked)
    await s.prepare();XCTAssertEqual(s.proposal?.targetLocked,true)
    await s.confirm(id:try XCTUnwrap(s.proposal?.id))
    XCTAssertEqual(s.reading?.state,.locked);XCTAssertEqual(s.phase,.confirmed)
  }
  func testUnauthenticatedAndInactiveNeverStartAProviderRead() async {
    for access in [LockAccessContext(generation:1,active:true,authenticated:false),LockAccessContext(generation:1,active:false,authenticated:true)] {
      let (s,p,a)=setup();a.value=access;await s.prepare()
      XCTAssertEqual(p.reads,0);XCTAssertEqual(p.writes,0);XCTAssertNil(s.proposal)
    }
  }
  func testProfileBackgroundAndGrantRevocationInvalidateApproval() async throws {
    for access in [LockAccessContext(generation:2,active:true,authenticated:true),LockAccessContext(generation:1,active:false,authenticated:true),LockAccessContext(generation:1,active:true,authenticated:false)] {
      let (s,p,a)=setup();await s.prepare();let id=try XCTUnwrap(s.proposal?.id);a.value=access
      await s.confirm(id:id);XCTAssertEqual(p.writes,0);XCTAssertNil(s.proposal)
    }
  }
  func testExactExpiryBoundaryBackwardAndNonfiniteClocksRejectBeforeWrite() async throws {
    for time in [130.0,131,99,Double.nan,Double.infinity,-Double.infinity] {
      let (s,p,a)=setup();await s.prepare();let id=try XCTUnwrap(s.proposal?.id);a.time=time
      await s.confirm(id:id);XCTAssertEqual(p.writes,0);XCTAssertEqual(p.reads,1)
      XCTAssertEqual(s.phase,.expired)
    }
    let (s,p,a)=setup();await s.prepare();a.time=129.999
    await s.confirm(id:try XCTUnwrap(s.proposal?.id));XCTAssertEqual(p.writes,1);XCTAssertEqual(s.phase,.confirmed)
  }
  func testInvalidInitialClocksCreateNoProposalOrProviderRead() async {
    for time in [-1,Double.nan,Double.infinity] {
      let (s,p,a)=setup();a.time=time;await s.prepare()
      XCTAssertNil(s.proposal);XCTAssertEqual(p.reads,0);XCTAssertEqual(p.writes,0)
    }
  }
  func testUnknownJammedAndBatteryFaultAreVisibleButNotControllable() async {
    for value in [LockReading(state:.unknown),LockReading(state:.jammed,batteryPercent:10),LockReading(state:.locked,batteryFault:true)] {
      let (s,p,_)=setup();p.value=value;await s.prepare()
      XCTAssertEqual(s.reading,value);XCTAssertNil(s.proposal);XCTAssertEqual(p.writes,0)
      XCTAssertFalse(value.canCommand)
    }
  }
  func testBatteryRangeValidationAndLowBatteryDoNotInventAValue() async throws {
    XCTAssertEqual(LockReading(state:.locked).batteryText,"Battery level unavailable")
    XCTAssertEqual(LockReading(state:.locked,batteryPercent:15).batteryText,"Low battery · 15%")
    for percent in [-1,101] {
      let (s,p,_)=setup();p.value=LockReading(state:.locked,batteryPercent:percent);await s.prepare()
      XCTAssertNil(s.reading);XCTAssertNil(s.proposal);XCTAssertEqual(p.writes,0)
    }
    for percent in [0,15,100] {
      let (s,p,_)=setup();p.value=LockReading(state:.locked,batteryPercent:percent);await s.prepare()
      await s.confirm(id:try XCTUnwrap(s.proposal?.id));XCTAssertEqual(s.phase,.confirmed)
    }
  }
  func testForeignChangeAndInvalidReadBeforeWriteSendNothing() async throws {
    for value in [LockReading(state:.unlocked),LockReading(state:.unknown),LockReading(state:.jammed),LockReading(state:.locked,batteryFault:true),LockReading(state:.locked,batteryPercent:101)] {
      let (s,p,_)=setup();await s.prepare();let id=try XCTUnwrap(s.proposal?.id);p.returned[2]=value
      await s.confirm(id:id);XCTAssertEqual(p.writes,0);XCTAssertEqual(s.phase,.failed)
    }
  }
  func testWrongOrOldProposalIDCannotConsumeTheCurrentApproval() async throws {
    let (s,p,_)=setup();await s.prepare();let first=try XCTUnwrap(s.proposal?.id)
    s.cancelProposal();await s.prepare();let second=try XCTUnwrap(s.proposal?.id)
    await s.confirm(id:first);await s.confirm(id:UUID())
    XCTAssertEqual(s.proposal?.id,second);XCTAssertEqual(p.writes,0)
    await s.confirm(id:second);XCTAssertEqual(p.writes,1)
  }
  func testRefreshDiscardsAnOutstandingProposal() async throws {
    let (s,p,_)=setup();await s.prepare();let id=try XCTUnwrap(s.proposal?.id)
    await s.refresh();await s.confirm(id:id)
    XCTAssertNil(s.proposal);XCTAssertEqual(p.writes,0);XCTAssertEqual(s.reading?.state,.locked)
  }
  func testPrecancelledPreparationAndConfirmationDoNotReachTheProvider() async throws {
    let (s,p,_)=setup();let first=Task {await s.prepare()};first.cancel();await first.value
    XCTAssertEqual(p.reads,0);await s.prepare();let id=try XCTUnwrap(s.proposal?.id)
    let second=Task {await s.confirm(id:id)};second.cancel();await second.value
    XCTAssertEqual(p.reads,1);XCTAssertEqual(p.writes,0)
  }
  func testFailedPreflightReadSendsNothing() async throws {
    let (s,p,_)=setup();await s.prepare();p.failReads=[2]
    await s.confirm(id:try XCTUnwrap(s.proposal?.id))
    XCTAssertEqual(p.writes,0);XCTAssertEqual(s.phase,.failed)
  }
  func testWrongOrFailedReadbackNeverReportsSuccessAndCannotReplay() async throws {
    for result in [LockReading(state:.locked),LockReading(state:.unknown),LockReading(state:.jammed),LockReading(state:.unlocked,batteryFault:true),LockReading(state:.unlocked,batteryPercent:101)] {
      let (s,p,_)=setup();await s.prepare();let id=try XCTUnwrap(s.proposal?.id);p.returned[3]=result
      await s.confirm(id:id);XCTAssertEqual(s.phase,.unverified);XCTAssertEqual(p.writes,1)
      await s.confirm(id:id);XCTAssertEqual(p.writes,1)
    }
    let (s,p,_)=setup();await s.prepare();p.failReads=[3]
    await s.confirm(id:try XCTUnwrap(s.proposal?.id));XCTAssertEqual(s.phase,.unverified);XCTAssertEqual(p.writes,1)
  }
  func testRejectedWriteIsNotTurnedIntoConfirmedOrAutomaticallyRetried() async throws {
    let (s,p,_)=setup();await s.prepare();p.denyWrite=true
    await s.confirm(id:try XCTUnwrap(s.proposal?.id))
    XCTAssertEqual(s.phase,.unverified);XCTAssertEqual(p.writes,1);XCTAssertEqual(p.applied,0)
    XCTAssertEqual(p.value.state,.locked);XCTAssertNil(s.proposal)
  }
  func testRevocationWhilePreparingCannotRestoreApproval() async {
    let (s,p,a)=setup();let entered=expectation(description:"read entered")
    p.pauseReadAt=1;p.paused={entered.fulfill()}
    let task=Task {await s.prepare()};await fulfillment(of:[entered],timeout:2)
    a.value=LockAccessContext(generation:2,active:true,authenticated:true);s.revoke();p.resume();await task.value
    XCTAssertNil(s.proposal);XCTAssertNil(s.reading);XCTAssertEqual(p.writes,0);XCTAssertFalse(s.busy)
  }
  func testRevocationWhileCheckingStopsBeforeCommand() async throws {
    let (s,p,a)=setup();await s.prepare();let id=try XCTUnwrap(s.proposal?.id)
    let entered=expectation(description:"preflight entered");p.pauseReadAt=2;p.paused={entered.fulfill()}
    let task=Task {await s.confirm(id:id)};await fulfillment(of:[entered],timeout:2)
    a.value=LockAccessContext(generation:2,active:true,authenticated:true);s.revoke();p.resume();await task.value
    XCTAssertEqual(p.writes,0);XCTAssertNil(s.proposal);XCTAssertNil(s.reading);XCTAssertFalse(s.busy)
  }
  func testCancellationWhileCheckingStopsBeforeCommand() async throws {
    let (s,p,_)=setup();await s.prepare();let id=try XCTUnwrap(s.proposal?.id)
    let entered=expectation(description:"preflight entered");p.pauseReadAt=2;p.paused={entered.fulfill()}
    let task=Task {await s.confirm(id:id)};await fulfillment(of:[entered],timeout:2)
    task.cancel();p.resume();await task.value
    XCTAssertEqual(p.writes,0);XCTAssertNil(s.proposal);XCTAssertFalse(s.busy)
  }
  func testExpiryDuringReadSendsNothingAndCannotRearmAnApproval() async {
    let (s,p,a)=setup();let entered=expectation(description:"initial read entered")
    p.pauseReadAt=1;p.paused={entered.fulfill()}
    let task=Task {await s.prepare()};await fulfillment(of:[entered],timeout:2)
    a.time=130;s.expireApproval();XCTAssertEqual(s.phase,.expired)
    p.resume();await task.value;XCTAssertNil(s.proposal);XCTAssertEqual(p.writes,0)
  }
  func testInFlightWriteRevocationIsUncertainAndCannotStartAnotherAction() async throws {
    let (s,p,a)=setup();await s.prepare();let id=try XCTUnwrap(s.proposal?.id)
    let entered=expectation(description:"write entered");p.pauseWrite=true;p.paused={entered.fulfill()}
    let task=Task {await s.confirm(id:id)};await fulfillment(of:[entered],timeout:2)
    XCTAssertEqual(s.reading?.state,.locked,"Never optimistically show the requested unlocked state")
    a.value=LockAccessContext(generation:2,active:true,authenticated:true);s.revoke()
    XCTAssertEqual(s.phase,.unverified);let reads=p.reads;await s.prepare()
    XCTAssertEqual(p.reads,reads);XCTAssertEqual(p.writes,1)
    p.resume();await task.value;XCTAssertEqual(s.phase,.unverified);XCTAssertNil(s.reading);XCTAssertFalse(s.busy)
    XCTAssertEqual(p.value.state,.unlocked,"Possible completed effect is not falsely reported as cancelled")
  }
  func testReadbackStallExpiresWithoutSuccessOrAutomaticRetry() async throws {
    let (s,p,a)=setup();await s.prepare();let id=try XCTUnwrap(s.proposal?.id)
    let entered=expectation(description:"readback entered");p.pauseReadAt=3;p.paused={entered.fulfill()}
    let task=Task {await s.confirm(id:id)};await fulfillment(of:[entered],timeout:2)
    XCTAssertEqual(s.phase,.verifying);XCTAssertEqual(s.reading?.state,.locked)
    a.time=130;s.expireApproval();XCTAssertEqual(s.phase,.unverified)
    p.resume();await task.value;XCTAssertEqual(s.phase,.unverified);XCTAssertEqual(p.writes,1)
    XCTAssertFalse(s.busy);XCTAssertNil(s.proposal)
  }
  func testTwoConfirmationsWhileSuspendedHaveOnlyOneEffect() async throws {
    let (s,p,_)=setup();await s.prepare();let id=try XCTUnwrap(s.proposal?.id)
    let entered=expectation(description:"preflight entered");p.pauseReadAt=2;p.paused={entered.fulfill()}
    let first=Task {await s.confirm(id:id)};await fulfillment(of:[entered],timeout:2)
    await s.confirm(id:id);XCTAssertEqual(p.reads,2);XCTAssertEqual(p.writes,0)
    p.resume();await first.value;XCTAssertEqual(p.writes,1);XCTAssertEqual(s.phase,.confirmed)
  }
}
