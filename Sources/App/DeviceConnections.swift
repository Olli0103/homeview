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

extension DeviceConnections {
  convenience init() {
    let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
    self.init(provider: testing ? FixtureDeviceDataProvider() : SystemDeviceDataProvider(),
              testing: testing)
  }
}
