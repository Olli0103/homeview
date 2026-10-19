import XCTest
@testable import HomeViewCore

@MainActor
final class DeviceConnectionTests: XCTestCase {
  private final class Provider: DeviceDataProvider {
    var hasPermission = true
    var revoked:Set<DataConnection> = []
    var delayReminders=false
    var reminderReply:CheckedContinuation<[DeviceReminder],any Error>?
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
    var musicPermissionRequests=0
    var playCalls=0
    var resumeCalls=0
    var delayPlayback = false
    var playbackReply: CheckedContinuation<Void, any Error>?
    var resumeReply: CheckedContinuation<Void, any Error>?
    var onPlayback: (() -> Void)?
    func authorized(_ kind: DataConnection) -> Bool { hasPermission && !revoked.contains(kind) }
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
      if delayReminders { return try await withCheckedThrowingContinuation { reminderReply=$0;onStart?() } }
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
    func authorizeMusic() async throws {
      musicPermissionRequests+=1
      if delayAuthorization {
        try await withCheckedThrowingContinuation { authorizationReply=$0;onStart?() }
      }
    }
    func searchMusic(_ text: String) async throws -> [DeviceTrack] {
      try await withCheckedThrowingContinuation { reply in
        searchReplies[text] = reply
        onSearch?(text)
      }
    }
    func playMusic(_ index: Int) async throws {
      playCalls+=1
      if delayPlayback { try await withCheckedThrowingContinuation { playbackReply=$0;onPlayback?() } }
    }
    func resumeMusic() async throws {
      resumeCalls+=1
      if delayPlayback { try await withCheckedThrowingContinuation { resumeReply=$0;onPlayback?() } }
    }
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

  func testPersonalSourceRevocationPollingClearsOnlyRevokedCalendarAndRequiresReconnect() async {
    let p=Provider()
    let session=DeviceConnections(provider:p)
    _ = await session.unlock();await session.connect(.calendar);await session.connect(.reminders)
    XCTAssertFalse(session.events.isEmpty);XCTAssertFalse(session.reminders.isEmpty)
    let reads=p.eventReads,requests=p.permissionRequests
    p.revoked.insert(.calendar);session.tick()
    XCTAssertTrue(session.events.isEmpty);XCTAssertFalse(session.enabled.contains(.calendar))
    XCTAssertTrue(session.requested.contains(.calendar));XCTAssertTrue(session.personalUnlocked)
    XCTAssertFalse(session.reminders.isEmpty);XCTAssertTrue(session.enabled.contains(.reminders))
    XCTAssertEqual(p.eventReads,reads);XCTAssertEqual(p.permissionRequests,requests)
    p.revoked.remove(.calendar);session.tick()
    XCTAssertTrue(session.events.isEmpty);XCTAssertFalse(session.enabled.contains(.calendar))
    await session.connect(.calendar);XCTAssertFalse(session.events.isEmpty)
  }
  func testPersonalSourceRevocationPollingClearsOnlyRevokedReminders() async {
    let p=Provider();let s=DeviceConnections(provider:p)
    _ = await s.unlock();await s.connect(.calendar);await s.connect(.reminders)
    let reads=p.reminderReads;p.revoked.insert(.reminders);s.tick()
    XCTAssertTrue(s.reminders.isEmpty);XCTAssertFalse(s.enabled.contains(.reminders))
    XCTAssertFalse(s.events.isEmpty);XCTAssertTrue(s.enabled.contains(.calendar))
    XCTAssertTrue(s.personalUnlocked);XCTAssertEqual(p.reminderReads,reads)
  }
  func testPersonalSourceRevocationDropsLateCalendarWithoutWaitingForPoll() async throws {
    let p=Provider();let s=DeviceConnections(provider:p);_ = await s.unlock()
    p.delayEvents=true;let started=expectation(description:"calendar read suspended");p.onStart={started.fulfill()}
    let read=Task { await s.connect(.calendar) };await fulfillment(of:[started],timeout:2)
    p.revoked.insert(.calendar);try XCTUnwrap(p.eventReply).resume(returning:[Provider.event]);await read.value
    XCTAssertTrue(s.events.isEmpty);XCTAssertFalse(s.enabled.contains(.calendar))
    XCTAssertTrue(s.requested.contains(.calendar));XCTAssertFalse(s.busy.contains(.calendar))
  }
  func testPersonalSourceRevocationDropsLateRemindersWithoutWaitingForPoll() async throws {
    let p=Provider();let s=DeviceConnections(provider:p);_ = await s.unlock()
    p.delayReminders=true;let started=expectation(description:"reminder read suspended");p.onStart={started.fulfill()}
    let read=Task { await s.connect(.reminders) };await fulfillment(of:[started],timeout:2)
    p.revoked.insert(.reminders);try XCTUnwrap(p.reminderReply).resume(returning:p.reminderItems);await read.value
    XCTAssertTrue(s.reminders.isEmpty);XCTAssertFalse(s.enabled.contains(.reminders))
    XCTAssertTrue(s.requested.contains(.reminders));XCTAssertFalse(s.busy.contains(.reminders))
  }
  func testPersonalSourceRevocationPreventsAllNewReminderWrites() async {
    let p=Provider();let s=DeviceConnections(provider:p);_ = await s.unlock();await s.connect(.reminders)
    let item=s.reminders[0],reads=p.reminderReads;p.revoked.insert(.reminders)
    let added=await s.addReminder("Synthetic revoked draft");await s.completeReminder(item);await s.removeReminder(item)
    XCTAssertFalse(added);XCTAssertEqual(p.reminderWrites,0);XCTAssertEqual(p.reminderReads,reads)
    XCTAssertTrue(s.reminders.isEmpty);XCTAssertFalse(s.enabled.contains(.reminders))
  }
  func testPersonalSourceRevocationAfterSubmittedWriteStartsNoPrivateReadback() async throws {
    let p=Provider();let s=DeviceConnections(provider:p);_ = await s.unlock();await s.connect(.reminders)
    let reads=p.reminderReads;p.delayReminderWrite=true
    let started=expectation(description:"write already submitted");p.onStart={started.fulfill()}
    let write=Task { await s.addReminder("Synthetic already submitted item") };await fulfillment(of:[started],timeout:2)
    p.revoked.insert(.reminders);try XCTUnwrap(p.writeReply).resume();let confirmed=await write.value
    XCTAssertFalse(confirmed);XCTAssertEqual(p.reminderWrites,1);XCTAssertEqual(p.reminderReads,reads)
    XCTAssertTrue(s.reminders.isEmpty);XCTAssertFalse(s.enabled.contains(.reminders))
    XCTAssertEqual(p.reminderItems.count,2,"Already submitted provider write is not falsely claimed rolled back")
  }
  func testPersonalSourceRevocationRechecksPermissionAfterAuthorizationReturns() async {
    for kind in [DataConnection.calendar,.reminders] {
      let p=Provider();let s=DeviceConnections(provider:p);_ = await s.unlock()
      p.revoked.insert(kind);await s.connect(kind)
      XCTAssertEqual(p.permissionRequests,1);XCTAssertEqual(p.eventReads,0);XCTAssertEqual(p.reminderReads,0)
      XCTAssertFalse(s.enabled.contains(kind));XCTAssertTrue(s.requested.contains(kind))
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
      if kind == .music { _ = await session.unlock() }
      await session.connect(kind)
      if kind == .music { session.lock() }
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
    XCTAssertFalse(restored.musicAccessAllowed)
    XCTAssertFalse(restored.guestMusicShared)
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
    _ = await session.unlock();await session.connect(.music)
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
    _ = await session.unlock();await session.connect(.music)
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
    _ = await session.unlock();await session.connect(.music)
    let started = expectation(description:"cancelled search")
    provider.onSearch = { _ in started.fulfill() }
    let task = Task { await session.searchMusic("cancel") }
    await fulfillment(of:[started],timeout:2)
    let pausesAtCancellation=provider.pauseCalls
    task.cancel()
    provider.searchReplies["cancel"]?.resume(returning:[DeviceTrack(id:"stale",title:"Synthetic",artist:"Fixture",artwork:nil)])
    await task.value
    XCTAssertTrue(session.tracks.isEmpty)
    XCTAssertEqual(provider.pauseCalls,pausesAtCancellation)
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


extension DeviceConnectionTests {
  private func seedPlayback(_ provider:Provider,_ session:DeviceConnections) async {
    _ = await session.unlock();await session.connect(.music)
    let started=expectation(description:"synthetic search entered")
    provider.onSearch={ _ in started.fulfill() }
    let search=Task { await session.searchMusic("seed") }
    await fulfillment(of:[started],timeout:2)
    provider.searchReplies["seed"]?.resume(returning:[DeviceTrack(id:"own",title:"Synthetic song",artist:"Fixture",artwork:nil)])
    await search.value
  }
  func testPlaybackFailureAfterDisconnectCannotRestoreStatus() async {
    let p=Provider();let s=DeviceConnections(provider:p);await seedPlayback(p,s)
    p.delayPlayback=true;let entered=expectation(description:"play entered");p.onPlayback={entered.fulfill()}
    let play=Task { await s.playMusic(0) };await fulfillment(of:[entered],timeout:2)
    s.disconnect(.music);p.playbackReply?.resume(throwing:CocoaError(.fileReadUnknown));await play.value
    XCTAssertEqual(s.status[.music],"Disconnected");XCTAssertNil(s.currentTrack)
  }
  func testPlaybackSuccessAfterDisconnectCannotRestoreSelection() async {
    let p=Provider();let s=DeviceConnections(provider:p);await seedPlayback(p,s)
    p.delayPlayback=true;let entered=expectation(description:"play entered");p.onPlayback={entered.fulfill()}
    let play=Task { await s.playMusic(0) };await fulfillment(of:[entered],timeout:2)
    s.disconnect(.music);p.playbackReply?.resume();await play.value
    XCTAssertNil(s.currentTrack);XCTAssertTrue(s.tracks.isEmpty);XCTAssertFalse(s.musicPlaying)
  }
  func testCancelledPlaybackCannotSelectTrack() async {
    let p=Provider();let s=DeviceConnections(provider:p);await seedPlayback(p,s)
    p.delayPlayback=true;let entered=expectation(description:"play entered");p.onPlayback={entered.fulfill()}
    let play=Task { await s.playMusic(0) };await fulfillment(of:[entered],timeout:2)
    play.cancel();p.playbackReply?.resume();await play.value
    XCTAssertNil(s.currentTrack)
  }
  func testResumeFailureAfterDisconnectCannotRestoreStatus() async {
    let p=Provider();let s=DeviceConnections(provider:p);await seedPlayback(p,s);await s.playMusic(0)
    p.delayPlayback=true;let entered=expectation(description:"resume entered");p.onPlayback={entered.fulfill()}
    let play=Task { await s.toggleMusic() };await fulfillment(of:[entered],timeout:2)
    s.disconnect(.music);p.resumeReply?.resume(throwing:CocoaError(.fileReadUnknown));await play.value
    XCTAssertEqual(s.status[.music],"Disconnected");XCTAssertNil(s.currentTrack)
  }
}


extension DeviceConnectionTests {
  func testGlobalRestoreRevocationStopsPreviouslyConnectedSuccessor() async throws {
    let suite="HomeViewReset-"+UUID().uuidString
    let defaults=try XCTUnwrap(UserDefaults(suiteName:suite))
    defer { defaults.removePersistentDomain(forName:suite) }
    defaults.set(true,forKey:"HomeView.connected.Calendar")
    defaults.set(true,forKey:"HomeView.connected.Reminders")
    let p=Provider();p.delayEvents=true
    let c=DeviceConnections(provider:p,testing:false,defaults:defaults)
    _ = await c.unlock()
    let entered=expectation(description:"old restore calendar read")
    p.onStart={entered.fulfill()}
    let restore=Task { await c.restore() }
    await fulfillment(of:[entered],timeout:2)
    c.cancelRestoration();c.disconnect(.calendar)
    p.eventReply?.resume(returning:[Provider.event]);await restore.value
    XCTAssertEqual(p.reminderReads,0,"Revoked restore must not start the next personal service")
    XCTAssertTrue(c.requested.isEmpty);XCTAssertTrue(c.enabled.isEmpty)
  }
}


extension DeviceConnectionTests {
  func testExplicitEmptyConsentOverridesOldDefaultsWithoutProviderRequests() async throws {
    let suite="ResetConsent-"+UUID().uuidString
    let defaults=try XCTUnwrap(UserDefaults(suiteName:suite))
    defer { defaults.removePersistentDomain(forName:suite) }
    for kind in DataConnection.allCases { defaults.set(true,forKey:"HomeView.connected."+kind.rawValue) }
    let p=Provider()
    let session=DeviceConnections(provider:p,testing:false,defaults:defaults)
    await session.restore(allowed:[])
    XCTAssertTrue(session.requested.isEmpty);XCTAssertTrue(session.enabled.isEmpty)
    XCTAssertEqual(p.permissionRequests,0);XCTAssertEqual(p.reminderReads,0);XCTAssertEqual(p.eventReads,0)
  }
  func testExplicitConsentOnlyRestoresThatServiceNotOtherLegacyFlags() async throws {
    let suite="ResetConsent-"+UUID().uuidString
    let defaults=try XCTUnwrap(UserDefaults(suiteName:suite));defer { defaults.removePersistentDomain(forName:suite) }
    for kind in DataConnection.allCases { defaults.set(true,forKey:"HomeView.connected."+kind.rawValue) }
    let p=Provider()
    let c=DeviceConnections(provider:p,testing:false,defaults:defaults)
    await c.restore(allowed:[.calendar])
    XCTAssertEqual(c.enabled,[.calendar]);XCTAssertEqual(c.requested,[.calendar])
    XCTAssertEqual(p.permissionRequests,0);XCTAssertEqual(p.eventReads,0)
  }
  func testResetLocalPreferencesClearsCachesCityAndConnectionFlagsButNotSourceListIdentity() async throws {
    let suite="ResetConsent-"+UUID().uuidString
    let defaults=try XCTUnwrap(UserDefaults(suiteName:suite));defer { defaults.removePersistentDomain(forName:suite) }
    defaults.set("Synthetic City",forKey:"HomeView.weather.city")
    defaults.set("SYNTHETIC_SOURCE_LIST_ID",forKey:"HomeView.reminders.ownedCalendarID")
    let p=Provider()
    let s=DeviceConnections(provider:p,testing:false,defaults:defaults)
    await s.connect(.calendar);s.resetLocalPreferences()
    XCTAssertTrue(s.requested.isEmpty);XCTAssertTrue(s.enabled.isEmpty);XCTAssertFalse(s.personalUnlocked)
    XCTAssertEqual(s.city,"Berlin");XCTAssertEqual(s.weatherUnits,.fahrenheit)
    XCTAssertNil(defaults.object(forKey:"HomeView.connected.Calendar"))
    XCTAssertEqual(defaults.string(forKey:"HomeView.reminders.ownedCalendarID"),"SYNTHETIC_SOURCE_LIST_ID")
  }
}

extension DeviceConnectionTests {
  func testUnsharedMusicIsNotReadableOrSearchableAfterDeviceLock() async {
    let provider=Provider()
    // Use one explicitly owned synthetic provider, not a system account.
    let connected=DeviceConnections(provider:provider)
    _ = await connected.unlock();await connected.connect(.music)
    var searches=0
    provider.onSearch = { text in
      searches+=1
      provider.searchReplies.removeValue(forKey:text)?.resume(returning:[DeviceTrack(id:"private-queue",title:"SYNTHETIC_OWNER_QUEUE",artist:"Synthetic",artwork:nil)])
    }
    defer { provider.onSearch=nil }
    await connected.searchMusic("owner selection")
    XCTAssertEqual(connected.tracks.count,1,"Positive authenticated source control")
    connected.lock();searches=0
    XCTAssertTrue(connected.tracks.isEmpty,"No implicit guest sharing of the owner's queue")
    await connected.searchMusic("guest search")
    XCTAssertEqual(searches,0,"Locked guest cannot invoke an account-backed search without authority")
    XCTAssertTrue(connected.tracks.isEmpty,"Private search results cannot reappear after lock")
  }
}

extension DeviceConnectionTests {
  private func prepareImmediateMusic(_ p:Provider,_ c:DeviceConnections) async {
    _ = await c.unlock();await c.connect(.music)
    p.onSearch = { text in p.searchReplies.removeValue(forKey:text)?.resume(returning:[DeviceTrack(id:text,title:"SYNTHETIC_SHARED_QUEUE",artist:"Synthetic",artwork:nil)]) }
    await c.searchMusic("approved queue");await c.playMusic(0)
  }
  func testGuestCannotConnectOrCreateMusicSharingWithoutDeviceAuthentication() async {
    let p=Provider()
    let session=DeviceConnections(provider:p)
    await session.connect(.music)
    XCTAssertEqual(p.musicPermissionRequests,0);XCTAssertFalse(session.enabled.contains(.music))
    XCTAssertFalse(session.requested.contains(.music));XCTAssertFalse(session.setGuestMusicSharing(true))
    XCTAssertFalse(session.guestMusicShared);XCTAssertFalse(session.musicAccessAllowed)
  }
  func testExplicitCurrentQueueSharingSurvivesLockButNeverSharesSearchAndCanBeRevoked() async {
    let p=Provider()
    let session=DeviceConnections(provider:p)
    await prepareImmediateMusic(p,session);defer { p.onSearch=nil }
    XCTAssertTrue(session.setGuestMusicSharing(true));session.lock()
    XCTAssertTrue(session.guestMusicShared);XCTAssertTrue(session.musicAccessAllowed);XCTAssertFalse(session.musicSearchAllowed)
    XCTAssertEqual(session.tracks.map(\.id),["approved queue"])
    var guestSearches=0
    p.onSearch = { text in guestSearches+=1;p.searchReplies.removeValue(forKey:text)?.resume(returning:[]) }
    await session.searchMusic("not approved")
    XCTAssertEqual(guestSearches,0)
    let before=p.playCalls;await session.playMusic(0);XCTAssertEqual(p.playCalls,before+1)
    XCTAssertTrue(session.setGuestMusicSharing(false));XCTAssertFalse(session.musicAccessAllowed);XCTAssertTrue(session.tracks.isEmpty)
    let revoked=p.playCalls;await session.playMusic(0);await session.toggleMusic();XCTAssertEqual(p.playCalls,revoked);XCTAssertEqual(p.resumeCalls,0)
    XCTAssertTrue(p.pauseCalls>0)
  }
  func testNewSearchAndBackgroundSessionEndCannotReuseGuestQueueConsent() async {
    let p=Provider()
    let c=DeviceConnections(provider:p)
    await prepareImmediateMusic(p,c);defer { p.onSearch=nil }
    XCTAssertTrue(c.setGuestMusicSharing(true))
    await c.searchMusic("different queue")
    XCTAssertFalse(c.guestMusicShared);XCTAssertEqual(c.tracks.map(\.id),["different queue"])
    await c.playMusic(0);XCTAssertTrue(c.setGuestMusicSharing(true));c.lock()
    c.endGuestMusicSession()
    XCTAssertFalse(c.guestMusicShared);XCTAssertTrue(c.tracks.isEmpty);XCTAssertNil(c.currentTrack)
  }
  func testSourcePermissionRevocationImmediatelyBlocksGuestAccessAndPollingClearsQueue() async {
    let p=Provider();let session=DeviceConnections(provider:p)
    await prepareImmediateMusic(p,session);defer { p.onSearch=nil }
    XCTAssertTrue(session.setGuestMusicSharing(true));session.lock();p.hasPermission=false
    XCTAssertFalse(session.musicAccessAllowed)
    let plays=p.playCalls;await session.playMusic(0);XCTAssertEqual(p.playCalls,plays)
    session.pollMusic()
    XCTAssertFalse(session.guestMusicShared);XCTAssertTrue(session.tracks.isEmpty);XCTAssertNil(session.currentTrack)
    XCTAssertTrue(session.status[.music]?.contains("revoked") == true)
  }
  func testLockDuringMusicPermissionAndLateSearchCannotRestorePrivateQueue() async throws {
    let p=Provider();let session=DeviceConnections(provider:p)
    _ = await session.unlock();p.delayAuthorization=true
    let permission=expectation(description:"actual owned music permission entered");p.onStart={permission.fulfill()}
    let connect=Task { await session.connect(.music) };await fulfillment(of:[permission],timeout:2)
    session.lock();try XCTUnwrap(p.authorizationReply).resume();await connect.value
    XCTAssertFalse(session.enabled.contains(.music));XCTAssertFalse(session.busy.contains(.music))
    p.delayAuthorization=false;_ = await session.unlock();await session.connect(.music)
    let searchStarted=expectation(description:"actual owned search entered");p.onSearch={_ in searchStarted.fulfill()}
    let search=Task {await session.searchMusic("stale private queue")};await fulfillment(of:[searchStarted],timeout:2)
    session.lock();try XCTUnwrap(p.searchReplies["stale private queue"]).resume(returning:[DeviceTrack(id:"stale",title:"PRIVATE_CANARY",artist:"Synthetic",artwork:nil)])
    await search.value
    XCTAssertTrue(session.tracks.isEmpty);XCTAssertNil(session.currentTrack);XCTAssertFalse(session.busy.contains(.music))
    p.onSearch=nil;p.onStart=nil
  }
  func testReconnectAndFreshSessionNeverInheritGuestSharing() async {
    let p=Provider();let session=DeviceConnections(provider:p)
    await prepareImmediateMusic(p,session);defer { p.onSearch=nil }
    XCTAssertTrue(session.setGuestMusicSharing(true));session.disconnect(.music)
    XCTAssertFalse(session.guestMusicShared);XCTAssertTrue(session.tracks.isEmpty)
    await session.connect(.music)
    XCTAssertFalse(session.guestMusicShared);XCTAssertNil(session.currentTrack)
    await session.searchMusic("new authorized queue");await session.playMusic(0)
    XCTAssertTrue(session.setGuestMusicSharing(true));session.resetLocalPreferences()
    XCTAssertFalse(session.guestMusicShared);XCTAssertTrue(session.tracks.isEmpty);XCTAssertTrue(session.enabled.isEmpty)
    let fresh=DeviceConnections(provider:Provider())
    XCTAssertFalse(fresh.guestMusicShared);XCTAssertTrue(fresh.tracks.isEmpty)
  }
}
