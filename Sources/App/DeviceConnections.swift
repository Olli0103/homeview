import Foundation
import Observation

#if canImport(LocalAuthentication)
  import LocalAuthentication
#endif
#if canImport(EventKit) && !os(tvOS)
  import EventKit
#endif
#if canImport(MusicKit) && !os(tvOS)
  import MusicKit
#endif

enum DataConnection: String, CaseIterable, Identifiable {
  case calendar = "Calendar"
  case reminders = "Reminders"
  case music = "Apple Music"
  case weather = "Weather"
  var id: String { rawValue }
}
@MainActor
protocol DeviceDataProvider: AnyObject {
  func authorized(_ kind: DataConnection) -> Bool
  func events(from: Date, to: Date) async throws -> [DeviceEvent]
  func reminders() async throws -> [DeviceReminder]
  func addReminder(_ title: String) async throws
  func completeReminder(_ id: String, completed: Bool) async throws
  func removeReminder(_ id: String) async throws
  func authorizeMusic() async throws
  func searchMusic(_ text: String) async throws -> [DeviceTrack]
  func playMusic(_ index: Int) async throws
  func resumeMusic() async throws
  func pauseMusic()
  var musicPlaying: Bool { get }
  var musicTime: Double { get }
  func weather(_ city: String) async throws -> WeatherReading
  func unlock() async -> Bool
}

@MainActor
final class SystemDeviceDataProvider: DeviceDataProvider {
  #if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
    private lazy var calendar = NativeCalendarService()
    private lazy var lists = NativeReminderService()
  #endif
  #if canImport(MusicKit) && (os(iOS) || os(macOS) || os(visionOS))
    private lazy var music = NativeMusicService()
    private var musicCreated = false
  #endif
  func authorized(_ kind: DataConnection) -> Bool {
    switch kind {
    case .weather: return true
    case .calendar:
      #if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
        return EKEventStore.authorizationStatus(for: .event) == .fullAccess
      #else
        return false
      #endif
    case .reminders:
      #if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
        return EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
      #else
        return false
      #endif
    case .music:
      #if canImport(MusicKit) && (os(iOS) || os(macOS) || os(visionOS))
        return MusicAuthorization.currentStatus == .authorized
      #else
        return false
      #endif
    }
  }
  func events(from: Date, to: Date) async throws -> [DeviceEvent] {
    #if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
      return try await calendar.events(from: from, to: to)
    #else
      throw NativeServiceError.unavailable
    #endif
  }
  func reminders() async throws -> [DeviceReminder] {
    #if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
      return try await lists.read()
    #else
      throw NativeServiceError.unavailable
    #endif
  }
  func addReminder(_ title: String) async throws {
    #if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
      try await lists.createInHomeViewList(title: title)
    #else
      throw NativeServiceError.unavailable
    #endif
  }
  func completeReminder(_ id: String, completed: Bool) async throws {
    #if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
      try lists.setCompleted(id: id, completed: completed)
    #else
      throw NativeServiceError.unavailable
    #endif
  }
  func removeReminder(_ id: String) async throws {
    #if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
      try lists.remove(id: id)
    #else
      throw NativeServiceError.unavailable
    #endif
  }
  func authorizeMusic() async throws {
    #if canImport(MusicKit) && (os(iOS) || os(macOS) || os(visionOS))
      musicCreated = true
      try await music.authorize()
    #else
      throw NativeServiceError.unavailable
    #endif
  }
  func searchMusic(_ text: String) async throws -> [DeviceTrack] {
    #if canImport(MusicKit) && (os(iOS) || os(macOS) || os(visionOS))
      return try await music.search(text)
    #else
      throw NativeServiceError.unavailable
    #endif
  }
  func playMusic(_ index: Int) async throws {
    #if canImport(MusicKit) && (os(iOS) || os(macOS) || os(visionOS))
      try await music.play(index: index)
    #else
      throw NativeServiceError.unavailable
    #endif
  }
  func resumeMusic() async throws {
    #if canImport(MusicKit) && (os(iOS) || os(macOS) || os(visionOS))
      try await music.resume()
    #else
      throw NativeServiceError.unavailable
    #endif
  }
  func pauseMusic() {
    #if canImport(MusicKit) && (os(iOS) || os(macOS) || os(visionOS))
      if musicCreated { music.pause() }
    #endif
  }
  var musicPlaying: Bool {
    #if canImport(MusicKit) && (os(iOS) || os(macOS) || os(visionOS))
      musicCreated && music.isPlaying
    #else
      false
    #endif
  }
  var musicTime: Double {
    #if canImport(MusicKit) && (os(iOS) || os(macOS) || os(visionOS))
      musicCreated ? music.playbackTime : 0
    #else
      0
    #endif
  }
  func weather(_ city: String) async throws -> WeatherReading {
    try await WeatherService().fetch(city: city)
  }
  func unlock() async -> Bool {
    #if canImport(LocalAuthentication) && !os(tvOS)
      let context = LAContext()
      return
        (try? await context.evaluatePolicy(
          .deviceOwnerAuthentication, localizedReason: "Show your connected calendar and reminders."
        )) == true
    #else
      return false
    #endif
  }
}

/// Only used by --uitesting, before constructing any system provider.
@MainActor
final class FixtureDeviceDataProvider: DeviceDataProvider {
  private var list = [
    DeviceReminder(id: "fixture", title: "Device fixture reminder", completed: false)
  ]
  private var playing = false
  func authorized(_ kind: DataConnection) -> Bool { true }
  func events(from: Date, to: Date) async throws -> [DeviceEvent] {
    if ProcessInfo.processInfo.arguments.contains("--connection-denied") {
      throw NativeServiceError.permissionDenied
    }
    return [
      DeviceEvent(
        id: "fixture", title: "Device fixture meeting", start: from.addingTimeInterval(36000),
        end: from.addingTimeInterval(39600), location: "Test room", calendar: "Synthetic calendar",
        cancelled: false)
    ]
  }
  func reminders() async throws -> [DeviceReminder] { list }
  func addReminder(_ title: String) async throws {
    list.append(DeviceReminder(id: UUID().uuidString, title: title, completed: false))
  }
  func completeReminder(_ id: String, completed: Bool) async throws {
    list = list.map {
      $0.id == id ? DeviceReminder(id: id, title: $0.title, completed: completed) : $0
    }
  }
  func removeReminder(_ id: String) async throws { list.removeAll { $0.id == id } }
  func authorizeMusic() async throws {}
  func searchMusic(_ text: String) async throws -> [DeviceTrack] {
    [
      DeviceTrack(
        id: "song1", title: "Connected fixture song", artist: "Synthetic Artist", artwork: nil),
      DeviceTrack(
        id: "song2", title: "Second fixture song", artist: "Synthetic Artist", artwork: nil),
    ]
  }
  func playMusic(_ index: Int) async throws { playing = true }
  func resumeMusic() async throws { playing = true }
  func pauseMusic() { playing = false }
  var musicPlaying: Bool { playing }
  var musicTime: Double { 12 }
  func weather(_ city: String) async throws -> WeatherReading {
    WeatherReading(
      city: "Fixture City", temperature: 55, high: 60, low: 48, humidity: 70, wind: 8, code: 2,
      sunset: Fixtures.date, utcOffset: 0, observedAt: Fixtures.date)
  }
  func unlock() async -> Bool { true }
}

@MainActor @Observable
final class DeviceConnections {
  private let provider: any DeviceDataProvider
  private let testing: Bool
  private var generation: [DataConnection: Int] = [:]
  private(set) var enabled: Set<DataConnection> = []
  private(set) var busy: Set<DataConnection> = []
  private(set) var status: [DataConnection: String] = [:]
  private(set) var events: [DeviceEvent] = []
  private(set) var reminders: [DeviceReminder] = []
  private(set) var tracks: [DeviceTrack] = []
  private(set) var currentTrack: Int?
  private(set) var musicPlaying = false
  private(set) var musicTime = 0.0
  private(set) var weather: WeatherReading?
  private(set) var personalUnlocked = false
  var city = "Berlin"
  private var lastWeatherFetch = Date.distantPast
  init() {
    testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
    provider = testing ? FixtureDeviceDataProvider() : SystemDeviceDataProvider()
    if !testing { city = UserDefaults.standard.string(forKey: "HomeView.weather.city") ?? "Berlin" }
  }
  func connect(_ kind: DataConnection, date: Date = Date()) async {
    guard !busy.contains(kind) || kind == .calendar else { return }
    let wasEnabled = enabled.contains(kind)
    busy.insert(kind)
    generation[kind, default: 0] += 1
    let ticket = generation[kind]
    status[kind] = "Connecting…"
    defer { if generation[kind] == ticket { busy.remove(kind) } }
    do {
      switch kind {
      case .calendar:
        let c = Calendar.current
        let from = c.startOfDay(for: date)
        let values = try await provider.events(
          from: from, to: c.date(byAdding: .day, value: 1, to: from)!)
        guard generation[kind] == ticket else { return }
        events = values
      case .reminders:
        let values = try await provider.reminders()
        guard generation[kind] == ticket else { return }
        reminders = values
      case .music: try await provider.authorizeMusic()
      case .weather:
        let reading = try await provider.weather(city)
        guard generation[kind] == ticket else { return }
        weather = reading
        lastWeatherFetch = Date()
      }
      guard generation[kind] == ticket else { return }
      enabled.insert(kind)
      status[kind] = testing ? "Connected · synthetic source" : "Connected"
      if !testing {
        UserDefaults.standard.set(true, forKey: "HomeView.connected." + kind.rawValue)
        if kind == .weather { UserDefaults.standard.set(city, forKey: "HomeView.weather.city") }
      }
    } catch {
      guard generation[kind] == ticket else { return }
      if kind == .weather && wasEnabled { enabled.insert(kind) } else { enabled.remove(kind) }
      status[kind] =
        kind == .weather
        ? "Weather unavailable. Check the city and connection."
        : "Access unavailable. Check permissions and your account."
      if kind == .calendar { events = [] }
      if kind == .reminders { reminders = [] }
    }
  }
  func restore() async {
    guard !testing else { return }
    for kind in DataConnection.allCases
    where UserDefaults.standard.bool(forKey: "HomeView.connected." + kind.rawValue) {
      if provider.authorized(kind) {
        await connect(kind)
      } else {
        status[kind] = "Access needed. Connect again."
      }
    }
  }
  func disconnect(_ kind: DataConnection) {
    generation[kind, default: 0] += 1
    busy.remove(kind)
    enabled.remove(kind)
    status[kind] = "Disconnected"
    switch kind {
    case .calendar: events = []
    case .reminders: reminders = []
    case .music:
      provider.pauseMusic()
      tracks = []
      currentTrack = nil
      musicPlaying = false
    case .weather: weather = nil
    }
    if !testing { UserDefaults.standard.set(false, forKey: "HomeView.connected." + kind.rawValue) }
  }
  func unlock() async -> Bool {
    personalUnlocked = await provider.unlock()
    return personalUnlocked
  }
  func lock() { personalUnlocked = false }
  func refreshCalendar(_ date: Date) async {
    if enabled.contains(.calendar), personalUnlocked { await connect(.calendar, date: date) }
  }
  func refreshReminders() async {
    if enabled.contains(.reminders), personalUnlocked, !busy.contains(.reminders) {
      await connect(.reminders)
    }
  }
  func addReminder(_ title: String) async {
    let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, value.count <= 200 else {
      status[.reminders] = "Use a reminder title up to 200 characters."
      return
    }
    await editReminder { try await self.provider.addReminder(value) }
  }
  func completeReminder(_ item: DeviceReminder) async {
    await editReminder {
      try await self.provider.completeReminder(item.id, completed: !item.completed)
    }
  }
  func removeReminder(_ item: DeviceReminder) async {
    await editReminder { try await self.provider.removeReminder(item.id) }
  }
  private func editReminder(_ action: () async throws -> Void) async {
    guard personalUnlocked, enabled.contains(.reminders), !busy.contains(.reminders) else { return }
    let ticket = generation[.reminders]
    busy.insert(.reminders)
    defer { busy.remove(.reminders) }
    do {
      try await action()
      let values = try await provider.reminders()
      guard generation[.reminders] == ticket else { return }
      reminders = values
    } catch { status[.reminders] = "The reminder could not be saved. Refresh to check its state." }
  }
  func searchMusic(_ query: String) async {
    guard enabled.contains(.music), !busy.contains(.music),
      !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { return }
    let ticket = generation[.music]
    busy.insert(.music)
    defer { busy.remove(.music) }
    do {
      let values = try await provider.searchMusic(String(query.prefix(200)))
      guard generation[.music] == ticket else { return }
      provider.pauseMusic()
      musicPlaying = false
      currentTrack = nil
      tracks = values
    } catch { status[.music] = "Music search unavailable. Check access and your subscription." }
  }
  func playMusic(_ index: Int) async {
    guard enabled.contains(.music), tracks.indices.contains(index) else { return }
    do {
      try await provider.playMusic(index)
      currentTrack = index
      pollMusic()
    } catch {
      status[.music] = "This song could not be played. Check your subscription and connection."
    }
  }
  func toggleMusic() async {
    guard enabled.contains(.music) else { return }
    if musicPlaying {
      provider.pauseMusic()
    } else {
      do { try await provider.resumeMusic() } catch { status[.music] = "Playback unavailable." }
    }
    pollMusic()
  }
  func pauseMusic() {
    provider.pauseMusic()
    pollMusic()
  }
  func pollMusic() {
    guard enabled.contains(.music) else { return }
    musicPlaying = provider.musicPlaying
    musicTime = provider.musicTime
  }
  func tick() {
    pollMusic()
    if enabled.contains(.weather), Date().timeIntervalSince(lastWeatherFetch) > 900,
      !busy.contains(.weather)
    {
      lastWeatherFetch = Date()
      Task { await connect(.weather) }
    }
  }
}
