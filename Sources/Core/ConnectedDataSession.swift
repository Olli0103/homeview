import Foundation
import Observation

@MainActor
protocol DeviceDataProvider: AnyObject {
  func authorized(_ kind: DataConnection) -> Bool
  func authorizePersonal(_ kind: DataConnection) async throws
  func events(from: Date, to: Date) async throws -> [DeviceEvent]
  func reminders() async throws -> [DeviceReminder]
  func addReminder(_ title: String) async throws -> String
  func completeReminder(_ id: String, completed: Bool) async throws
  func removeReminder(_ id: String) async throws
  func authorizeMusic() async throws
  func searchMusic(_ text: String) async throws -> [DeviceTrack]
  func playMusic(_ index: Int) async throws
  func resumeMusic() async throws
  func pauseMusic()
  func resetLocalCaches()
  var musicPlaying: Bool { get }
  var musicTime: Double { get }
  func weather(_ city: String) async throws -> WeatherReading
  func unlock() async -> Bool
}

extension DeviceDataProvider {
  func resetLocalCaches() { pauseMusic() }
}

@MainActor @Observable
final class DeviceConnections {
  private let provider: any DeviceDataProvider
  private let testing: Bool
  private let defaults: UserDefaults
  private var generation: [DataConnection: Int] = [:]
  private var restoreGeneration = 0
  private var unlockGeneration = 0
  private var musicActionGeneration = 0
  private(set) var enabled: Set<DataConnection> = []
  private(set) var requested: Set<DataConnection> = []
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
  /// Explicitly approved current queue, RAM only. Not source/OS permission.
  private(set) var guestMusicShared=false
  private var accessRole:LocalAccessRole { personalUnlocked ? .deviceAuthenticated:.guest }
  var musicAccessAllowed:Bool {
    enabled.contains(.music) && provider.authorized(.music)
      && GuestAccessPolicy.allows(.connectedMusicPlayback,role:accessRole,sharedMusicQueue:guestMusicShared)
  }
  var musicSearchAllowed:Bool {
    enabled.contains(.music) && provider.authorized(.music)
      && GuestAccessPolicy.allows(.connectedMusicSearch,role:accessRole)
  }
  @discardableResult
  func setGuestMusicSharing(_ share:Bool)->Bool {
    if share {
      guard personalUnlocked,enabled.contains(.music),provider.authorized(.music),
        !busy.contains(.music),let index=currentTrack,tracks.indices.contains(index) else {
        status[.music]="Authenticate and choose a current queue before sharing it.";return false
      }
      guestMusicShared=true
      status[.music]="Current queue shared with guests for this app session. Search is not shared."
    } else {
      let wasShared=guestMusicShared
      guestMusicShared=false;generation[.music,default:0]+=1;musicActionGeneration+=1
      busy.remove(.music);provider.pauseMusic();musicPlaying=false;musicTime=0
      if !personalUnlocked { tracks=[];currentTrack=nil }
      if wasShared { status[.music]="Guest queue sharing is off." }
    }
    return true
  }
  func endGuestMusicSession() { _ = setGuestMusicSharing(false) }
  var city = "Berlin" {
    didSet {
      guard city != oldValue else { return }
      generation[.weather, default: 0] += 1
      weather = nil
      weatherFetchFailed = false
      enabled.remove(.weather)
      busy.remove(.weather)
      if requested.contains(.weather) { status[.weather] = "City changed · update weather" }
    }
  }
  var weatherUnits = WeatherUnits.fahrenheit {
    didSet { if !testing { defaults.set(weatherUnits.rawValue, forKey: "HomeView.weather.units") } }
  }
  private(set) var weatherFetchFailed = false
  private var lastWeatherFetch = Date.distantPast
  init(provider: any DeviceDataProvider, testing: Bool = true, defaults: UserDefaults = .standard) {
    self.defaults = defaults
    self.testing = testing
    self.provider = provider
    if !testing {
      city = defaults.string(forKey: "HomeView.weather.city") ?? "Berlin"
      weatherUnits = WeatherUnits(rawValue: defaults.string(forKey: "HomeView.weather.units") ?? "") ?? .fahrenheit
    }
  }
  func connect(_ kind: DataConnection, date: Date = Date(),
               timeZone: TimeZone = .current, requestPermission: Bool = true) async {
    guard !Task.isCancelled, !busy.contains(kind) || kind == .calendar else { return }
    if kind == .music {
      guard !requestPermission || personalUnlocked else {
        status[.music]="Authenticate before connecting Apple Music.";return
      }
      endGuestMusicSession();tracks=[];currentTrack=nil
    }
    requested.insert(kind)
    let wasEnabled = enabled.contains(kind)
    let previousStatus = status[kind]
    busy.insert(kind)
    generation[kind, default: 0] += 1
    let ticket = generation[kind]
    status[kind] = "Connecting…"
    defer {
      if generation[kind] == ticket {
        busy.remove(kind)
        if Task.isCancelled, kind == .calendar || kind == .reminders {
          status[kind] = previousStatus ?? "Not connected"
        }
      }
    }
    do {
      if kind == .calendar || kind == .reminders {
        if requestPermission {
          try await provider.authorizePersonal(kind)
        } else if !provider.authorized(kind) {
          throw CalendarAgendaError.permissionRequired
        }
        guard generation[kind] == ticket, !Task.isCancelled else { return }
        guard personalSourceAvailable(kind) else { return }
      }
      switch kind {
      case .calendar:
        guard personalUnlocked else { break }
        let interval = CalendarAgenda.day(containing: date, timeZone: timeZone)
        let values = try await provider.events(from: interval.start, to: interval.end)
        guard generation[kind] == ticket, !Task.isCancelled else { return }
        guard personalSourceAvailable(kind) else { return }
        if personalUnlocked { events = try CalendarAgenda.events(values, in: interval) }
      case .reminders:
        guard personalUnlocked else { break }
        let values = try await provider.reminders()
        guard generation[kind] == ticket, !Task.isCancelled else { return }
        guard personalSourceAvailable(kind) else { return }
        if personalUnlocked { reminders = values }
      case .music:
        if requestPermission { try await provider.authorizeMusic() }
        else if !provider.authorized(.music) { throw CalendarAgendaError.permissionRequired }
      case .weather:
        let queryCity = city
        lastWeatherFetch = Date()
        let reading = try await provider.weather(queryCity)
        guard generation[kind] == ticket, city == queryCity, !Task.isCancelled else { return }
        weather = reading
        weatherFetchFailed = false
      }
      guard generation[kind] == ticket else { return }
      enabled.insert(kind)
      status[kind] = testing ? "Connected · synthetic source" : "Connected"
      if !testing {
        defaults.set(true, forKey: "HomeView.connected." + kind.rawValue)
        if kind == .weather { defaults.set(city, forKey: "HomeView.weather.city") }
      }
    } catch {
      guard generation[kind] == ticket else { return }
      if Task.isCancelled, kind == .calendar || kind == .reminders { return }
      if kind == .weather && wasEnabled { enabled.insert(kind) } else { enabled.remove(kind) }
      if kind == .weather { weatherFetchFailed = true }
      status[kind] =
        kind == .weather
        ? "Weather unavailable. Check the city and connection."
        : "Access unavailable. Check permissions and your account."
      if kind == .calendar {
        events = []
        if let error = error as? CalendarAgendaError { status[kind] = error.localizedDescription }
      }
      if kind == .reminders {
        reminders = []
        if let error = error as? ReminderStoreError { status[kind] = error.localizedDescription }
      }
    }
  }
  func cancelRestoration() { restoreGeneration+=1 }
  func restore(allowed:Set<DataConnection>?=nil) async {
    guard !testing,!Task.isCancelled else { return }
    let ticket=restoreGeneration
    let choices=DataConnection.allCases.filter {
      allowed?.contains($0) ?? defaults.bool(forKey:"HomeView.connected."+$0.rawValue)
    }
    for kind in choices {
      guard ticket==restoreGeneration,!Task.isCancelled else { return }
      if provider.authorized(kind) {
        await connect(kind, requestPermission: false)
      } else {
        requested.insert(kind)
        status[kind] = "Access needed. Connect again."
      }
    }
  }
  func resetLocalPreferences() {
    cancelRestoration();lock()
    for kind in DataConnection.allCases { disconnect(kind) }
    provider.resetLocalCaches()
    city="Berlin";weatherUnits = .fahrenheit;lastWeatherFetch = .distantPast
    if !testing {
      for kind in DataConnection.allCases { defaults.removeObject(forKey:"HomeView.connected."+kind.rawValue) }
      defaults.removeObject(forKey:"HomeView.weather.city")
      defaults.removeObject(forKey:"HomeView.weather.units")
    }
  }
  func disconnect(_ kind: DataConnection) {
    generation[kind, default: 0] += 1
    busy.remove(kind)
    enabled.remove(kind)
    requested.remove(kind)
    status[kind] = "Disconnected"
    switch kind {
    case .calendar: events = []
    case .reminders: reminders = []
    case .music:
      guestMusicShared=false
      musicActionGeneration += 1
      provider.pauseMusic()
      tracks = []
      currentTrack = nil
      musicPlaying = false
      musicTime = 0
    case .weather: weather = nil; weatherFetchFailed = false
    }
    if !testing { defaults.set(false, forKey: "HomeView.connected." + kind.rawValue) }
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
    if !guestMusicShared {
      endGuestMusicSession()
      if requested.contains(.music) { status[.music]="Locked · authenticate to use Apple Music." }
    }
  }
  func refreshCalendar(_ date: Date, timeZone: TimeZone = .current) async {
    if enabled.contains(.calendar), personalUnlocked {
      await connect(.calendar, date: date, timeZone: timeZone, requestPermission: false)
    }
  }
  func refreshReminders() async {
    if enabled.contains(.reminders), personalUnlocked, !busy.contains(.reminders) {
      await connect(.reminders, requestPermission: false)
    }
  }
  @discardableResult
  func addReminder(_ title: String) async -> Bool {
    let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !value.isEmpty, value.count <= 200 else {
      status[.reminders] = "Use a reminder title up to 200 characters."
      return false
    }
    return await editReminder({ try await self.provider.addReminder(value) }, verify: { values, id in
      values.contains { $0.id == id && $0.title == value && !$0.completed }
    })
  }
  func completeReminder(_ item: DeviceReminder) async {
    guard item.writable else { status[.reminders] = ReminderStoreError.readOnly.localizedDescription; return }
    _ = await editReminder({
      try await self.provider.completeReminder(item.id, completed: !item.completed)
      return item.id
    }, verify: { values, id in values.first { $0.id == id }?.completed == !item.completed })
  }
  func removeReminder(_ item: DeviceReminder) async {
    guard item.writable else { status[.reminders] = ReminderStoreError.readOnly.localizedDescription; return }
    _ = await editReminder({
      try await self.provider.removeReminder(item.id)
      return item.id
    }, verify: { values, id in !values.contains { $0.id == id } })
  }
  private func editReminder(_ action: () async throws -> String,
                            verify: ([DeviceReminder], String) -> Bool) async -> Bool {
    guard !Task.isCancelled, personalUnlocked, enabled.contains(.reminders), !busy.contains(.reminders) else { return false }
    guard personalSourceAvailable(.reminders) else { return false }
    generation[.reminders, default: 0] += 1
    let ticket = generation[.reminders]
    busy.insert(.reminders)
    defer { if generation[.reminders] == ticket { busy.remove(.reminders) } }
    do {
      let id = try await action()
      guard generation[.reminders] == ticket, personalUnlocked, !Task.isCancelled else { return false }
      guard personalSourceAvailable(.reminders) else { return false }
      let values = try await provider.reminders()
      guard generation[.reminders] == ticket, personalUnlocked, !Task.isCancelled else { return false }
      guard personalSourceAvailable(.reminders) else { return false }
      reminders = values
      let confirmed = verify(values, id)
      status[.reminders] = confirmed
        ? "Saved · confirmed by source"
        : "Change not confirmed. The current source state is shown; no automatic retry."
      return confirmed
    } catch {
      guard generation[.reminders] == ticket, personalUnlocked, !Task.isCancelled else { return false }
      status[.reminders] = (error as? ReminderStoreError)?.localizedDescription
        ?? "The reminder could not be saved. Refresh to check its state."
      return false
    }
  }
  func searchMusic(_ query: String) async {
    guard musicSearchAllowed, !busy.contains(.music),
      !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else { return }
    // A new search changes the queue; prior guest consent cannot follow it.
    _ = setGuestMusicSharing(false)
    let ticket = generation[.music]
    busy.insert(.music)
    defer { if generation[.music] == ticket { busy.remove(.music) } }
    do {
      let values = try await provider.searchMusic(String(query.prefix(200)))
      guard generation[.music] == ticket, musicSearchAllowed, !Task.isCancelled else { return }
      musicActionGeneration += 1
      provider.pauseMusic()
      musicPlaying = false
      currentTrack = nil
      tracks = values
    } catch {
      guard generation[.music] == ticket, musicSearchAllowed, !Task.isCancelled else { return }
      status[.music] = "Music search unavailable. Check access and your subscription."
    }
  }
  func playMusic(_ index: Int) async {
    guard musicAccessAllowed, tracks.indices.contains(index), !Task.isCancelled else { return }
    let connection = generation[.music]
    musicActionGeneration += 1
    let action = musicActionGeneration
    let id = tracks[index].id
    func current() -> Bool {
      generation[.music] == connection && musicActionGeneration == action
        && musicAccessAllowed && !Task.isCancelled
        && tracks.indices.contains(index) && tracks[index].id == id
    }
    do {
      try await provider.playMusic(index)
      guard current() else { return }
      currentTrack = index
      pollMusic()
    } catch {
      guard current() else { return }
      status[.music] = "This song could not be played. Check your subscription and connection."
    }
  }
  func toggleMusic() async {
    guard musicAccessAllowed, let index=currentTrack, tracks.indices.contains(index),
      !Task.isCancelled else { return }
    musicActionGeneration += 1
    let action=musicActionGeneration;let connection=generation[.music]
    if musicPlaying { provider.pauseMusic() }
    else {
      do { try await provider.resumeMusic() }
      catch {
        guard generation[.music]==connection,musicActionGeneration==action,
          musicAccessAllowed,!Task.isCancelled else { return }
        status[.music] = "Playback unavailable."
      }
    }
    guard generation[.music]==connection,musicActionGeneration==action,
      musicAccessAllowed,!Task.isCancelled else { return }
    pollMusic()
  }
  func pauseMusic() {
    musicActionGeneration += 1
    provider.pauseMusic()
    pollMusic()
  }
  func pollMusic() {
    guard enabled.contains(.music) else { return }
    guard provider.authorized(.music) else {
      endGuestMusicSession();tracks=[];currentTrack=nil
      status[.music]="Music source permission was revoked.";return
    }
    guard musicAccessAllowed else { musicPlaying=false;musicTime=0;return }
    musicPlaying = provider.musicPlaying
    musicTime = provider.musicTime
  }
  /// Authorization status only: no permission prompt or personal read. Keep the
  /// user's connection choice, but require explicit reconnect after revocation.
  private func personalSourceAvailable(_ kind: DataConnection) -> Bool {
    guard kind == .calendar || kind == .reminders else { return true }
    guard provider.authorized(kind) else {
      generation[kind, default: 0] += 1
      busy.remove(kind)
      enabled.remove(kind)
      if kind == .calendar { events = [] } else { reminders = [] }
      status[kind] = kind == .calendar
        ? CalendarAgendaError.permissionRequired.localizedDescription
        : "Reminders access changed. Connect again in Settings."
      return false
    }
    return true
  }
  func tick() {
    for kind in [DataConnection.calendar, .reminders]
    where enabled.contains(kind) || busy.contains(kind) {
      _ = personalSourceAvailable(kind)
    }
    pollMusic()
    if enabled.contains(.weather), Date().timeIntervalSince(lastWeatherFetch) > 900,
      !busy.contains(.weather)
    {
      lastWeatherFetch = Date()
      Task { await connect(.weather) }
    }
  }
  var weatherDemo: Bool { !requested.contains(.weather) }
  var weatherTemperature: String { weatherUnits.temperature(weatherDemo ? 54 : weather?.temperature) }
  var weatherHighLow: String {
    "H:\(weatherUnits.temperature(weatherDemo ? 57 : weather?.high)) L:\(weatherUnits.temperature(weatherDemo ? 49 : weather?.low))"
  }
  var weatherCondition: String { weatherDemo ? "Partly Cloudy · Demo" : weather?.condition ?? "Weather unavailable" }
  var weatherSymbol: String { weatherDemo ? "cloud.sun.fill" : weather?.symbol ?? "questionmark.circle" }
  var weatherCity: String { weatherDemo ? "San Francisco · Demo" : weather?.city ?? city }
  func weatherSource(at now: Date) -> String {
    if weatherDemo { return "Demo · synthetic weather · \(weatherUnits.rawValue)" }
    guard let weather else {
      return busy.contains(.weather) ? "Loading weather…" : "Weather unavailable · update in Settings"
    }
    let quality = weatherFetchFailed ? "Offline · last reading" : weather.stale(at: now) ? "Stale reading" : "Observed"
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.timeZone = weather.timeZone
    formatter.dateFormat = "MMM d, HH:mm"
    return "\(quality) · \(formatter.string(from: weather.observedAt)) · \(weatherUnits.rawValue)"
  }
}
