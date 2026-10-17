import XCTest
@testable import HomeViewCore

@MainActor
final class DeviceConnectionTests: XCTestCase {
  private final class Provider: DeviceDataProvider {
    var delayUnlock = false
    var unlockGranted = true
    var delayEvents = false
    var delayReminderWrite = false
    var delayAuthorization = false
    var authorizationReply: CheckedContinuation<Void, any Error>?
    var unlockReply: CheckedContinuation<Bool, Never>?
    var eventReply: CheckedContinuation<[DeviceEvent], any Error>?
    var writeReply: CheckedContinuation<Void, any Error>?
    var onStart: (() -> Void)?
    var reminderReads = 0
    var eventReads = 0
    func authorized(_ kind: DataConnection) -> Bool { true }
    func authorizePersonal(_ kind: DataConnection) async throws {
      if delayAuthorization {
        try await withCheckedThrowingContinuation {
          authorizationReply = $0
          onStart?()
        }
      }
    }
    func events(from: Date, to: Date) async throws -> [DeviceEvent] {
      eventReads += 1
      if delayEvents {
        return try await withCheckedThrowingContinuation {
          eventReply = $0
          onStart?()
        }
      }
      return [Self.event]
    }
    static var event: DeviceEvent {
      DeviceEvent(id: "private", title: "Synthetic private meeting", start: Date(), end: Date(),
                  location: "", calendar: "Test", cancelled: false)
    }
    func reminders() async throws -> [DeviceReminder] {
      reminderReads += 1
      return [DeviceReminder(id: "private", title: "Synthetic private reminder", completed: false)]
    }
    func addReminder(_ title: String) async throws {
      if delayReminderWrite {
        try await withCheckedThrowingContinuation {
          writeReply = $0
          onStart?()
        }
      }
    }
    func completeReminder(_ id: String, completed: Bool) async throws {}
    func removeReminder(_ id: String) async throws {}
    func authorizeMusic() async throws {}
    func searchMusic(_ text: String) async throws -> [DeviceTrack] { [] }
    func playMusic(_ index: Int) async throws {}
    func resumeMusic() async throws {}
    func pauseMusic() {}
    var musicPlaying: Bool { false }
    var musicTime: Double { 0 }
    func weather(_ city: String) async throws -> WeatherReading {
      throw CocoaError(.featureUnsupported)
    }
    func unlock() async -> Bool {
      if delayUnlock {
        return await withCheckedContinuation {
          unlockReply = $0
          onStart?()
        }
      }
      return unlockGranted
    }
  }

  func testLateUnlockCannotReopenLockedSession() async throws {
    let provider = Provider()
    provider.delayUnlock = true
    let started = expectation(description: "authentication started")
    provider.onStart = { started.fulfill() }
    let connections = DeviceConnections(provider: provider)
    let attempt = Task { await connections.unlock() }
    await fulfillment(of: [started], timeout: 2)
    connections.lock()
    try XCTUnwrap(provider.unlockReply).resume(returning: true)
    let granted = await attempt.value
    XCTAssertFalse(granted)
    XCTAssertFalse(connections.personalUnlocked)
  }

  func testLockClearsPersonalCachesButKeepsConnectionChoice() async {
    let connections = DeviceConnections(provider: Provider())
    _ = await connections.unlock()
    await connections.connect(.calendar)
    await connections.connect(.reminders)
    XCTAssertEqual(connections.events.count, 1)
    XCTAssertEqual(connections.reminders.count, 1)
    connections.lock()
    XCTAssertTrue(connections.events.isEmpty)
    XCTAssertTrue(connections.reminders.isEmpty)
    XCTAssertEqual(connections.enabled, [.calendar, .reminders])
  }

  func testDeniedReauthenticationClearsExistingPrivateCache() async {
    let provider = Provider()
    let connections = DeviceConnections(provider: provider)
    _ = await connections.unlock()
    await connections.connect(.calendar)
    provider.unlockGranted = false
    let granted = await connections.unlock()
    XCTAssertFalse(granted)
    XCTAssertFalse(connections.personalUnlocked)
    XCTAssertTrue(connections.events.isEmpty)
  }

  func testCancelledAuthenticationCannotGrantPersonalAccess() async throws {
    let provider = Provider()
    provider.delayUnlock = true
    let started = expectation(description: "authentication started")
    provider.onStart = { started.fulfill() }
    let connections = DeviceConnections(provider: provider)
    let attempt = Task { await connections.unlock() }
    await fulfillment(of: [started], timeout: 2)
    attempt.cancel()
    try XCTUnwrap(provider.unlockReply).resume(returning: true)
    let granted = await attempt.value
    XCTAssertFalse(granted)
    XCTAssertFalse(connections.personalUnlocked)
  }

  func testLockedConnectDoesNotRetainPrivateRecords() async {
    let provider = Provider()
    let connections = DeviceConnections(provider: provider)
    await connections.connect(.calendar)
    await connections.connect(.reminders)
    XCTAssertTrue(connections.events.isEmpty)
    XCTAssertTrue(connections.reminders.isEmpty)
    XCTAssertEqual(connections.enabled, [.calendar, .reminders])
    XCTAssertEqual(provider.eventReads, 0)
    XCTAssertEqual(provider.reminderReads, 0)
    _ = await connections.unlock()
    await connections.refreshCalendar(Date())
    await connections.refreshReminders()
    XCTAssertEqual(connections.events.count, 1)
    XCTAssertEqual(connections.reminders.count, 1)
  }
  func testLockWhileGrantingOSPermissionDoesNotStartPrivateRead() async throws {
    let provider = Provider()
    let connections = DeviceConnections(provider: provider)
    _ = await connections.unlock()
    provider.delayAuthorization = true
    let started = expectation(description: "OS permission request started")
    provider.onStart = { started.fulfill() }
    let connect = Task { await connections.connect(.calendar) }
    await fulfillment(of: [started], timeout: 2)
    connections.lock()
    try XCTUnwrap(provider.authorizationReply).resume()
    await connect.value
    XCTAssertEqual(provider.eventReads, 0)
    XCTAssertTrue(connections.events.isEmpty)
  }

  func testOldCalendarResponseCannotReplaceNewSessionOrClearItsBusyFlag() async throws {
    let provider = Provider()
    let connections = DeviceConnections(provider: provider)
    _ = await connections.unlock()
    provider.delayEvents = true
    let firstStarted = expectation(description: "old fetch started")
    provider.onStart = { firstStarted.fulfill() }
    let first = Task { await connections.connect(.calendar) }
    await fulfillment(of: [firstStarted], timeout: 2)
    let firstReply = try XCTUnwrap(provider.eventReply)
    connections.lock()
    _ = await connections.unlock()
    let secondStarted = expectation(description: "new fetch started")
    provider.onStart = { secondStarted.fulfill() }
    let second = Task { await connections.connect(.calendar) }
    await fulfillment(of: [secondStarted], timeout: 2)
    firstReply.resume(returning: [Provider.event])
    await first.value
    XCTAssertTrue(connections.events.isEmpty)
    XCTAssertTrue(connections.busy.contains(.calendar))
    try XCTUnwrap(provider.eventReply).resume(returning: [Provider.event])
    await second.value
    XCTAssertEqual(connections.events.count, 1)
    XCTAssertFalse(connections.busy.contains(.calendar))
  }

  func testLockDuringReminderWriteDoesNotStartPrivateReadback() async throws {
    let provider = Provider()
    let connections = DeviceConnections(provider: provider)
    _ = await connections.unlock()
    await connections.connect(.reminders)
    provider.delayReminderWrite = true
    let started = expectation(description: "write started")
    provider.onStart = { started.fulfill() }
    let write = Task { await connections.addReminder("Synthetic item") }
    await fulfillment(of: [started], timeout: 2)
    let readsBeforeLock = provider.reminderReads
    connections.lock()
    try XCTUnwrap(provider.writeReply).resume()
    await write.value
    XCTAssertEqual(provider.reminderReads, readsBeforeLock)
    XCTAssertTrue(connections.reminders.isEmpty)
    XCTAssertFalse(connections.busy.contains(.reminders))
  }
}
