import XCTest
@testable import HomeViewCore

@MainActor
final class MusicPlaybackGateTests: XCTestCase {
  func testStopDuringPendingPlayPausesLateBackendStart() async {
    var playing=false;var pauses=0
    let gate=MusicPlaybackGate { playing=false;pauses+=1 }
    let entered=expectation(description:"backend entered")
    var reply:CheckedContinuation<Void,Error>?
    let first=Task {
      try await gate.run {
        try await withCheckedThrowingContinuation { reply=$0;entered.fulfill() }
        playing=true // Simulate a backend ignoring cancellation until completion.
      }
    }
    await fulfillment(of:[entered],timeout:2)
    gate.stop();XCTAssertFalse(playing)
    reply?.resume()
    do { try await first.value;XCTFail("revoked play must not succeed") }
    catch { XCTAssertTrue(error is CancellationError) }
    XCTAssertFalse(playing);XCTAssertEqual(pauses,2)
  }
  func testSuccessorWaitsUntilStaleCompletionPausesAndCannotBePausedByItLater() async {
    var playing=false;var events:[String]=[]
    let gate=MusicPlaybackGate { playing=false;events.append("pause") }
    let entered=expectation(description:"old entered");let queued=expectation(description:"successor queued")
    var reply:CheckedContinuation<Void,Error>?
    let old=Task {
      try await gate.run {
        events.append("old entered")
        try await withCheckedThrowingContinuation { reply=$0;entered.fulfill() }
        playing=true;events.append("old completion")
      }
    }
    await fulfillment(of:[entered],timeout:2)
    let current=Task {
      queued.fulfill()
      try await gate.run { playing=true;events.append("current started") }
    }
    await fulfillment(of:[queued],timeout:2)
    XCTAssertEqual(events,["old entered"])
    reply?.resume()
    do { try await old.value;XCTFail("old request was superseded") }
    catch { XCTAssertTrue(error is CancellationError) }
    do { try await current.value } catch { XCTFail("current request must succeed") }
    XCTAssertTrue(playing)
    XCTAssertEqual(events,["old entered","old completion","pause","current started"])
  }
  func testCancelledQueuedRequestNeverInvokesBackend() async {
    var playing=false;var secondStarted=false
    let gate=MusicPlaybackGate { playing=false }
    let entered=expectation(description:"old entered");let queued=expectation(description:"queued")
    var reply:CheckedContinuation<Void,Error>?
    let first=Task {
      try await gate.run {
        try await withCheckedThrowingContinuation { reply=$0;entered.fulfill() }
        playing=true
      }
    }
    await fulfillment(of:[entered],timeout:2)
    let second=Task {
      queued.fulfill()
      try await gate.run { secondStarted=true;playing=true }
    }
    await fulfillment(of:[queued],timeout:2)
    second.cancel();reply?.resume()
    _ = try? await first.value
    do { try await second.value;XCTFail("cancelled queue entry must fail") }
    catch { XCTAssertTrue(error is CancellationError) }
    XCTAssertFalse(secondStarted);XCTAssertFalse(playing)
  }
  func testFailedBackendIsPausedBeforeAnotherRequestCanSucceed() async {
    var playing=false
    let gate=MusicPlaybackGate { playing=false }
    do {
      try await gate.run { playing=true;throw CocoaError(.fileReadUnknown) }
      XCTFail("backend error must be preserved")
    } catch { XCTAssertFalse(error is CancellationError) }
    XCTAssertFalse(playing)
    do { try await gate.run { playing=true } } catch { XCTFail("new request must succeed") }
    XCTAssertTrue(playing)
  }
}
