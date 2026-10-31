import XCTest
@testable import HomeViewCore

final class AlarmScheduleAdmissionTests:XCTestCase {
  @MainActor func testExpiredAndInvalidDeadlinesNeverRequestAuthorization() async throws {
    let now=Date(timeIntervalSince1970:1000)
    for seconds in [-1.0,0,86401,.infinity,.nan] {
      var authorizations=0,effects=0
      let submitted=try await AlarmScheduleAdmission.perform(deadline:now.addingTimeInterval(seconds),
        isCurrent:{true},now:{now},authorize:{authorizations+=1},schedule:{_ in effects+=1})
      XCTAssertFalse(submitted);XCTAssertEqual(authorizations,0);XCTAssertEqual(effects,0)
    }
  }
  @MainActor func testRevokedActionDoesNotRequestAuthorization() async throws {
    var authorizations=0,effects=0
    let submitted=try await AlarmScheduleAdmission.perform(isCurrent:{false},
      authorize:{authorizations+=1},schedule:{_ in effects+=1})
    XCTAssertFalse(submitted);XCTAssertEqual(authorizations,0);XCTAssertEqual(effects,0)
  }
  @MainActor func testAuthorizationCannotResurrectDeletedOrSupersededAction() async throws {
    var current=true,effects=0
    let submitted=try await AlarmScheduleAdmission.perform(isCurrent:{current},
      authorize:{current=false},schedule:{_ in effects+=1})
    XCTAssertFalse(submitted);XCTAssertEqual(effects,0)
  }
  @MainActor func testDeadlineReachedWhileAuthorizingDoesNotScheduleAnotherSecond() async throws {
    let start=Date(timeIntervalSince1970:1000),deadline=start.addingTimeInterval(10)
    for late in [0.0,5] {
      var now=start,effects=0
      let submitted=try await AlarmScheduleAdmission.perform(deadline:deadline,isCurrent:{true},now:{now},
        authorize:{now=deadline.addingTimeInterval(late)},schedule:{_ in effects+=1})
      XCTAssertFalse(submitted);XCTAssertEqual(effects,0)
    }
  }
  @MainActor func testTimerRecomputesRemainingTimeAfterAuthorizationWithoutRoundingUp() async throws {
    let start=Date(timeIntervalSince1970:1000)
    var now=start,submittedDuration:TimeInterval?
    let submitted=try await AlarmScheduleAdmission.perform(deadline:start.addingTimeInterval(10),
      isCurrent:{true},now:{now},authorize:{now=start.addingTimeInterval(9.75)},schedule:{submittedDuration=$0})
    XCTAssertTrue(submitted);XCTAssertEqual(submittedDuration,0.25)
  }
  @MainActor func testAlarmWithoutCountdownStillRechecksAuthority() async throws {
    var events:[String]=[],receivedDuration:TimeInterval?
    let submitted=try await AlarmScheduleAdmission.perform(isCurrent:{events.count<2},
      authorize:{events.append("authorized")},schedule:{duration in receivedDuration=duration;events.append("scheduled")})
    XCTAssertTrue(submitted);XCTAssertNil(receivedDuration);XCTAssertEqual(events,["authorized","scheduled"])
  }
  @MainActor func testAuthorizationFailureIsNotSuccessAndNeverSchedules() async {
    var effects=0
    do {
      _=try await AlarmScheduleAdmission.perform(isCurrent:{true},authorize:{throw CocoaError(.userCancelled)},schedule:{_ in effects+=1})
      XCTFail("Authorization error must propagate")
    } catch {XCTAssertEqual((error as? CocoaError)?.code,.userCancelled)}
    XCTAssertEqual(effects,0)
  }
  @MainActor func testProviderFailureIsNotAnAcceptedSchedule() async {
    do {
      _=try await AlarmScheduleAdmission.perform(isCurrent:{true},authorize:{},schedule:{_ in throw CocoaError(.fileWriteUnknown)})
      XCTFail("Provider error must propagate")
    } catch {XCTAssertEqual((error as? CocoaError)?.code,.fileWriteUnknown)}
  }
  @MainActor func testCancellationDuringAuthorizationDoesNotReachProvider() async {
    var effects=0
    let task=Task { @MainActor in
      try await AlarmScheduleAdmission.perform(isCurrent:{true},authorize:{
        withUnsafeCurrentTask {$0?.cancel()}
      },schedule:{_ in effects+=1})
    }
    do {let result=try await task.value;XCTAssertFalse(result)} catch {XCTFail("Unexpected error: \(error)")}
    XCTAssertEqual(effects,0)
  }
}
