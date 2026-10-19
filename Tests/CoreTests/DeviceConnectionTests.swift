import XCTest
@testable import HomeViewCore

@MainActor
final class DeviceConnectionTests: XCTestCase {
  private final class Provider: DeviceDataProvider {
    var hasPermission = true
    var permissionRequests = 0
    var queriedInterval: DateInterval?
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
    var reminderWrites = 0
    var ignoreReminderWrites = false
    var reminderItems = [DeviceReminder(id: "private", title: "Synthetic private reminder", completed: false)]
    var eventReads = 0
    var weatherReply: CheckedContinuation<WeatherReading, any Error>?
    var weatherValue: WeatherReading?
    var delayWeather = false
    var searchReplies: [String:CheckedContinuation<[DeviceTrack], any Error>] = [:]
    var onSearch: ((String)->Void)?
    var pauseCalls = 0
    func authorized(_ kind: DataConnection) -> Bool { hasPermission }
    func authorizePersonal(_ kind: DataConnection) async throws {
      permissionRequests += 1
      if delayAuthorization {
        try await withCheckedThrowingContinuation {
          authorizationReply = $0
          onStart?()
        }
      }
    }
    func events(from: Date, to: Date) async throws -> [DeviceEvent] {
      eventReads += 1
      queriedInterval = DateInterval(start: from, end: to)
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
      return reminderItems
    }
    func addReminder(_ title: String) async throws -> String {
      reminderWrites += 1
      if delayReminderWrite {
        try await withCheckedThrowingContinuation {
          writeReply = $0
          onStart?()
        }
      }
      let id = UUID().uuidString
      if !ignoreReminderWrites { reminderItems.append(DeviceReminder(id: id, title: title, completed: false)) }
      return id
    }
    func completeReminder(_ id: String, completed: Bool) async throws {
      reminderWrites += 1
      if !ignoreReminderWrites {
        reminderItems = reminderItems.map {
          $0.id == id ? DeviceReminder(id: id, title: $0.title, completed: completed) : $0
        }
      }
    }
    func removeReminder(_ id: String) async throws {
      reminderWrites += 1
      if !ignoreReminderWrites { reminderItems.removeAll { $0.id == id } }
    }
    func authorizeMusic() async throws {}
    func searchMusic(_ text: String) async throws -> [DeviceTrack] {
      try await withCheckedThrowingContinuation { reply in
        searchReplies[text] = reply
        onSearch?(text)
      }
    }
    func playMusic(_ index: Int) async throws {}
    func resumeMusic() async throws {}
    func pauseMusic() { pauseCalls += 1 }
    var musicPlaying: Bool { false }
    var musicTime: Double { 0 }
    func weather(_ city: String) async throws -> WeatherReading {
      if delayWeather {
        return try await withCheckedThrowingContinuation { weatherReply = $0; onStart?() }
      }
      if let weatherValue { return weatherValue }
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

  func testPersistedConnectionRevocationSurvivesSessionRecreation() async {
    let suite = "org.example.homeview.tests.connections." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let provider = Provider()
    provider.weatherValue = WeatherReading(city:"Berlin",temperature:68,high:70,low:50,humidity:50,wind:10,code:0,sunset:nil,utcOffset:0,observedAt:Date())
    let session = DeviceConnections(provider:provider,testing:false,defaults:defaults)
    session.weatherUnits = .celsius
    for kind in DataConnection.allCases {
      await session.connect(kind)
      XCTAssertTrue(defaults.bool(forKey:"HomeView.connected." + kind.rawValue))
    }
    XCTAssertEqual(provider.eventReads,0)
    XCTAssertEqual(provider.reminderReads,0)
    let requests = provider.permissionRequests
    let restored = DeviceConnections(provider:provider,testing:false,defaults:defaults)
    await restored.restore()
    XCTAssertEqual(restored.enabled,Set(DataConnection.allCases))
    XCTAssertEqual(restored.weatherUnits,.celsius)
    XCTAssertEqual(restored.city,"Berlin")
    XCTAssertEqual(provider.permissionRequests,requests)
    XCTAssertEqual(provider.eventReads,0)
    XCTAssertEqual(provider.reminderReads,0)
    for kind in DataConnection.allCases {
      restored.disconnect(kind)
      XCTAssertFalse(defaults.bool(forKey:"HomeView.connected." + kind.rawValue))
    }
    let disconnected = DeviceConnections(provider:provider,testing:false,defaults:defaults)
    await disconnected.restore()
    XCTAssertTrue(disconnected.enabled.isEmpty)
    XCTAssertTrue(disconnected.requested.isEmpty)
    XCTAssertNil(disconnected.weather)
    XCTAssertEqual(provider.permissionRequests,requests)
  }
  func testLatePermissionCannotPersistARevokedConnection() async {
    let suite = "org.example.homeview.tests.connections." + UUID().uuidString
    let defaults = UserDefaults(suiteName:suite)!
    defer { defaults.removePersistentDomain(forName:suite) }
    let provider = Provider();provider.delayAuthorization = true
    let session = DeviceConnections(provider:provider,testing:false,defaults:defaults)
    let started = expectation(description:"permission suspended")
    provider.onStart = { started.fulfill() }
    let task = Task { await session.connect(.calendar) }
    await fulfillment(of:[started],timeout:2)
    session.disconnect(.calendar)
    provider.authorizationReply?.resume()
    await task.value
    XCTAssertFalse(defaults.bool(forKey:"HomeView.connected.Calendar"))
    XCTAssertEqual(session.status[.calendar],"Disconnected")
    XCTAssertTrue(session.enabled.isEmpty)
    XCTAssertEqual(provider.eventReads,0)
    let next = DeviceConnections(provider:provider,testing:false,defaults:defaults)
    await next.restore()
    XCTAssertTrue(next.requested.isEmpty)
  }

  func testLateMusicSearchFailureCannotReplaceDisconnectedStatus() async {
    let provider = Provider();let session = DeviceConnections(provider:provider)
    await session.connect(.music)
    let started = expectation(description:"old search")
    provider.onSearch = { _ in started.fulfill() }
    let task = Task { await session.searchMusic("old") }
    await fulfillment(of:[started],timeout:2)
    session.disconnect(.music)
    provider.searchReplies["old"]?.resume(throwing:CocoaError(.fileReadUnknown))
    await task.value
    XCTAssertEqual(session.status[.music],"Disconnected")
    XCTAssertTrue(session.tracks.isEmpty)
    XCTAssertFalse(session.busy.contains(.music))
  }
  func testOldMusicSearchCleanupCannotFinishANewerSearch() async {
    let provider = Provider();let session = DeviceConnections(provider:provider)
    await session.connect(.music)
    let oldStarted = expectation(description:"old search")
    let newStarted = expectation(description:"new search")
    provider.onSearch = { text in (text == "old" ? oldStarted:newStarted).fulfill() }
    let old = Task { await session.searchMusic("old") }
    await fulfillment(of:[oldStarted],timeout:2)
    session.disconnect(.music);await session.connect(.music)
    let current = Task { await session.searchMusic("new") }
    await fulfillment(of:[newStarted],timeout:2)
    provider.searchReplies["old"]?.resume(throwing:CocoaError(.fileReadUnknown))
    await old.value
    XCTAssertTrue(session.busy.contains(.music))
    XCTAssertEqual(session.status[.music],"Connected · synthetic source")
    provider.searchReplies["new"]?.resume(returning:[DeviceTrack(id:"new",title:"Synthetic",artist:"Fixture",artwork:nil)])
    await current.value
    XCTAssertFalse(session.busy.contains(.music))
    XCTAssertEqual(session.tracks.map(\.id),["new"])
  }
  func testCancelledMusicSearchCannotInstallResultsOrPauseAudio() async {
    let provider = Provider();let session = DeviceConnections(provider:provider)
    await session.connect(.music)
    let started = expectation(description:"cancelled search")
    provider.onSearch = { _ in started.fulfill() }
    let task = Task { await session.searchMusic("cancel") }
    await fulfillment(of:[started],timeout:2)
    task.cancel()
    provider.searchReplies["cancel"]?.resume(returning:[DeviceTrack(id:"stale",title:"Synthetic",artist:"Fixture",artwork:nil)])
    await task.value
    XCTAssertTrue(session.tracks.isEmpty)
    XCTAssertEqual(provider.pauseCalls,0)
    XCTAssertFalse(session.busy.contains(.music))
  }

  func testWeatherNeverFallsBackToDemoAfterFailedConnection() async {
    let provider = Provider(); let session = DeviceConnections(provider: provider)
    XCTAssertTrue(session.weatherDemo)
    await session.connect(.weather)
    XCTAssertFalse(session.weatherDemo); XCTAssertEqual(session.weatherTemperature,"—")
    XCTAssertTrue(session.weatherSource(at: Date()).contains("unavailable"))
    session.disconnect(.weather)
    XCTAssertTrue(session.weatherDemo)
  }
  func testWeatherChangedCityDiscardsDelayedResponseAndDisconnectInvalidatesIt() async {
    for changeCity in [true,false] {
      let provider = Provider(); provider.delayWeather = true
      let session = DeviceConnections(provider: provider)
      let started = expectation(description:"weather started")
      provider.onStart = { started.fulfill() }
      let task = Task { await session.connect(.weather) }
      await fulfillment(of:[started],timeout:2)
      if changeCity { session.city = "Paris" } else { session.disconnect(.weather) }
      provider.weatherReply?.resume(returning: WeatherReading(city:"Berlin",temperature:70,high:70,low:50,humidity:50,wind:10,code:0,sunset:nil,utcOffset:0,observedAt:Date()))
      await task.value
      XCTAssertNil(session.weather); XCTAssertFalse(session.enabled.contains(.weather))
      XCTAssertFalse(session.busy.contains(.weather))
      XCTAssertEqual(session.weatherDemo,!changeCity)
    }
  }
  func testWeatherOfflineRetainsOnlySameCityReadingWithExplicitStatus() async {
    let provider = Provider()
    provider.weatherValue = WeatherReading(city:"Berlin",temperature:68,high:70,low:50,humidity:50,wind:10,code:0,sunset:nil,utcOffset:0,observedAt:Date())
    let session = DeviceConnections(provider:provider)
    await session.connect(.weather)
    session.weatherUnits = .celsius
    XCTAssertEqual(session.weatherTemperature,"20°")
    provider.weatherValue = nil
    await session.connect(.weather)
    XCTAssertEqual(session.weatherTemperature,"20°")
    XCTAssertTrue(session.weatherSource(at:Date()).hasPrefix("Offline"))
    session.city = "Paris"
    XCTAssertEqual(session.weatherTemperature,"—")
    await session.connect(.weather)
    XCTAssertNil(session.weather)
  }

  func testReminderReadOnlySnapshotBlocksBothMutationPathsInTheModel() async {
    let provider = Provider()
    let connections = DeviceConnections(provider: provider)
    _ = await connections.unlock(); await connections.connect(.reminders)
    let item = DeviceReminder(id: "private", title: "Synthetic private reminder", completed: false,
      listTitle: "Shared", writable: false)
    await connections.completeReminder(item); await connections.removeReminder(item)
    XCTAssertEqual(provider.reminderWrites, 0)
    XCTAssertTrue(connections.status[.reminders]?.contains("read-only") == true)
  }
  func testReminderWriteAcknowledgmentRequiresExactReadbackAndNeverRetries() async {
    let provider = Provider()
    let session = DeviceConnections(provider: provider)
    _ = await session.unlock(); await session.connect(.reminders)
    provider.ignoreReminderWrites = true
    let item = session.reminders[0]
    await session.completeReminder(item)
    XCTAssertTrue(session.status[.reminders]?.contains("not confirmed") == true)
    let added = await session.addReminder("Synthetic new item")
    XCTAssertFalse(added)
    await session.removeReminder(item)
    XCTAssertEqual(provider.reminderWrites, 3)
    XCTAssertEqual(provider.reminderReads, 4)
    XCTAssertEqual(session.reminders.count, 1)
    XCTAssertFalse(session.reminders[0].completed)
  }
  func testReminderPositiveReadbackAndRevocationWithoutPermissionPrompt() async {
    let provider = Provider()
    let connections = DeviceConnections(provider: provider)
    _ = await connections.unlock(); await connections.connect(.reminders)
    await connections.completeReminder(connections.reminders[0])
    XCTAssertTrue(connections.reminders[0].completed)
    XCTAssertTrue(connections.status[.reminders]?.contains("confirmed by source") == true)
    let added = await connections.addReminder("Synthetic new item")
    XCTAssertTrue(added)
    XCTAssertEqual(connections.reminders.count, 2)
    let reads = provider.reminderReads
    provider.hasPermission = false
    await connections.refreshReminders()
    XCTAssertEqual(provider.reminderReads, reads)
    XCTAssertEqual(provider.permissionRequests, 1)
    XCTAssertTrue(connections.reminders.isEmpty)
    XCTAssertTrue(connections.requested.contains(.reminders))
  }

  func testCalendarRefreshUsesDisplayedZoneAndNeverRequestsPermissionAgain() async {
    let provider = Provider()
    let connections = DeviceConnections(provider: provider)
    await connections.connect(.calendar)
    _ = await connections.unlock()
    let date = ISO8601DateFormatter().date(from: "2026-03-29T12:00:00Z")!
    await connections.refreshCalendar(date, timeZone: TimeZone(identifier: "Europe/Berlin")!)
    XCTAssertEqual(provider.permissionRequests, 1)
    XCTAssertEqual(provider.queriedInterval?.duration, 23 * 3600)
    provider.hasPermission = false
    let reads = provider.eventReads
    await connections.refreshCalendar(date)
    XCTAssertEqual(provider.permissionRequests, 1)
    XCTAssertEqual(provider.eventReads, reads)
    XCTAssertTrue(connections.events.isEmpty)
    XCTAssertFalse(connections.enabled.contains(.calendar))
    XCTAssertTrue(connections.requested.contains(.calendar))
    XCTAssertTrue(connections.status[.calendar]?.contains("access changed") == true)
    connections.disconnect(.calendar)
    XCTAssertFalse(connections.requested.contains(.calendar))
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
