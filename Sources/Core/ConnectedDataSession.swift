import Foundation
import Observation

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

@MainActor @Observable
final class DeviceConnections {
  private let provider: any DeviceDataProvider
  private let testing: Bool
  private var generation: [DataConnection: Int] = [:]
  private var unlockGeneration = 0
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
  init(provider: any DeviceDataProvider, testing: Bool = true) {
    self.testing = testing
    self.provider = provider
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
        if personalUnlocked { events = values }
      case .reminders:
        let values = try await provider.reminders()
        guard generation[kind] == ticket else { return }
        if personalUnlocked { reminders = values }
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
    unlockGeneration += 1
    let ticket = unlockGeneration
    let granted = await provider.unlock()
    guard unlockGeneration == ticket else { return false }
    guard granted, !Task.isCancelled else {
      lock()
      return false
    }
    personalUnlocked = granted
    return personalUnlocked
  }
  func lock() {
    unlockGeneration += 1
    personalUnlocked = false
    for kind in [DataConnection.calendar, .reminders] {
      generation[kind, default: 0] += 1
      if enabled.contains(kind) {
        status[kind] = "Locked · unlock to view"
      } else if busy.contains(kind) {
        status[kind] = "Not connected"
      }
      busy.remove(kind)
    }
    events = []
    reminders = []
  }
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
    generation[.reminders, default: 0] += 1
    let ticket = generation[.reminders]
    busy.insert(.reminders)
    defer { if generation[.reminders] == ticket { busy.remove(.reminders) } }
    do {
      try await action()
      guard generation[.reminders] == ticket, personalUnlocked else { return }
      let values = try await provider.reminders()
      guard generation[.reminders] == ticket, personalUnlocked else { return }
      reminders = values
    } catch {
      guard generation[.reminders] == ticket, personalUnlocked else { return }
      status[.reminders] = "The reminder could not be saved. Refresh to check its state."
    }
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
