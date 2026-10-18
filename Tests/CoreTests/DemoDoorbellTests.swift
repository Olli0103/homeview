import Foundation
import XCTest
@testable import HomeViewCore

@MainActor
final class DemoDoorbellTests: XCTestCase {
  private let now = Date(timeIntervalSince1970: 1_800_000_000)
  private func event(_ camera: Int = 0, age: TimeInterval = 0) -> DemoDoorbellEvent {
    DemoDoorbellEvent(id: UUID(), cameraIndex: camera, occurredAt: now.addingTimeInterval(-age))
  }
  func testDismissAndReplayDoNotReopenTheCameraOrExtendItsDeadline() {
    let state = DemoDoorbell(), value = event()
    XCTAssertEqual(state.receive(value, now: now, uptime: 100, cameraAvailable: true, callInProgress: false), .shown)
    XCTAssertEqual(state.receive(value, now: now, uptime: 110, cameraAvailable: true, callInProgress: false), .duplicate)
    XCTAssertEqual(state.deadline, 130)
    state.dismiss()
    XCTAssertEqual(state.receive(value, now: now, uptime: 111, cameraAvailable: true, callInProgress: false), .duplicate)
    XCTAssertNil(state.current)
  }
  func testLatestDistinctEventReplacesThePresentationWithoutAHiddenQueue() {
    let state = DemoDoorbell(), first = event(), second = event(1)
    _ = state.receive(first, now: now, uptime: 100, cameraAvailable: true, callInProgress: false)
    XCTAssertEqual(state.receive(second, now: now, uptime: 101, cameraAvailable: true, callInProgress: false), .replaced)
    XCTAssertEqual(state.current, second)
    state.dismiss()
    state.reconcile(at: 102, cameraAvailable: true, callInProgress: false)
    XCTAssertNil(state.current)
  }
  func testOldInvalidAndFutureEventsNeverOpenACamera() {
    let state = DemoDoorbell()
    XCTAssertEqual(state.receive(event(age: 31), now: now, uptime: 100, cameraAvailable: true, callInProgress: false), .expired)
    XCTAssertEqual(state.receive(event(-1), now: now, uptime: 100, cameraAvailable: true, callInProgress: false), .invalid)
    XCTAssertEqual(state.receive(event(4), now: now, uptime: 100, cameraAvailable: true, callInProgress: false), .invalid)
    XCTAssertEqual(state.receive(event(age: -6), now: now, uptime: 100, cameraAvailable: true, callInProgress: false), .invalid)
    XCTAssertEqual(state.receive(event(), now: now, uptime: .nan, cameraAvailable: true, callInProgress: false), .invalid)
    XCTAssertNil(state.current)
  }
  func testUnavailableCameraAndActiveCallAreNotInterruptedOrQueuedForLater() {
    let state = DemoDoorbell(), offline = event(), call = event()
    XCTAssertEqual(state.receive(offline, now: now, uptime: 100, cameraAvailable: false, callInProgress: false), .cameraUnavailable)
    XCTAssertEqual(state.receive(call, now: now, uptime: 100, cameraAvailable: true, callInProgress: true), .callNotInterrupted)
    state.reconcile(at: 101, cameraAvailable: true, callInProgress: false)
    XCTAssertNil(state.current)
    XCTAssertEqual(state.receive(offline, now: now, uptime: 101, cameraAvailable: true, callInProgress: false), .duplicate)
    XCTAssertEqual(state.receive(call, now: now, uptime: 101, cameraAvailable: true, callInProgress: false), .duplicate)
  }
  func testPermissionLossAndCallStartDismissAnAlreadyPresentedEvent() {
    let state = DemoDoorbell()
    _ = state.receive(event(), now: now, uptime: 100, cameraAvailable: true, callInProgress: false)
    state.reconcile(at: 101, cameraAvailable: false, callInProgress: false)
    XCTAssertNil(state.current)
    _ = state.receive(event(), now: now, uptime: 102, cameraAvailable: true, callInProgress: false)
    state.reconcile(at: 103, cameraAvailable: true, callInProgress: true)
    XCTAssertNil(state.current)
  }
  func testExpiryUsesMonotonicTimeAndOnlyTheRemainingEventLifetime() {
    let state = DemoDoorbell()
    _ = state.receive(event(age: 25), now: now, uptime: 100, cameraAvailable: true, callInProgress: false)
    XCTAssertEqual(state.deadline, 105)
    state.reconcile(at: 104.9, cameraAvailable: true, callInProgress: false)
    XCTAssertNotNil(state.current)
    state.reconcile(at: 105, cameraAvailable: true, callInProgress: false)
    XCTAssertNil(state.current)
  }
  func testInvalidReconciliationTimeCannotLeaveAnIndefiniteOverlay() {
    let state = DemoDoorbell()
    _ = state.receive(event(), now: now, uptime: 100, cameraAvailable: true, callInProgress: false)
    state.reconcile(at: .nan, cameraAvailable: true, callInProgress: false)
    XCTAssertNil(state.current)
  }
}
