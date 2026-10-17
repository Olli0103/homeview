import Foundation

/// Public data services, constructed lazily after a connection action.
/// UI tests select the separate fixture provider. Apple Home stays disabled.
/// Permission dialogs and personal data are never part of automatic mock tests.
enum NativeServiceError: Error, LocalizedError {
  case permissionDenied, unavailable, realHomeDisabled
  var errorDescription: String? {
    switch self {
    case .permissionDenied: "Permission was not granted."
    case .unavailable: "This feature is unavailable on this platform."
    case .realHomeDisabled: "Real HomeKit access is disabled in this mock build."
    }
  }
}

#if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
  @preconcurrency import EventKit

  struct NativeCalendarItem: Identifiable, Sendable {
    let id: String
    let title: String
    let starts: Date
    let ends: Date
    let location: String?
  }
  @MainActor
  final class NativeCalendarService {
    private lazy var store = EKEventStore()
    func authorize() async throws {
      guard try await store.requestFullAccessToEvents() else {
        throw NativeServiceError.permissionDenied
      }
    }
    func events(from: Date, to: Date) throws -> [DeviceEvent] {
      guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
        throw NativeServiceError.permissionDenied
      }
      let query = store.predicateForEvents(withStart: from, end: to, calendars: nil)
      return store.events(matching: query).prefix(200).map {
        DeviceEvent(
          id: $0.eventIdentifier ?? UUID().uuidString, title: $0.title ?? "Untitled",
          start: $0.startDate, end: $0.endDate, location: $0.location ?? "",
          calendar: $0.calendar.title, cancelled: $0.status == .canceled)
      }.sorted { $0.start < $1.start }
    }
  }
  @MainActor
  final class NativeReminderService {
    private lazy var store = EKEventStore()
    func authorize() async throws {
      guard try await store.requestFullAccessToReminders() else {
        throw NativeServiceError.permissionDenied
      }
    }
    func read() async throws -> [DeviceReminder] {
      guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else {
        throw NativeServiceError.permissionDenied
      }
      let predicate = store.predicateForReminders(in: nil)
      return await withCheckedContinuation { continuation in
        store.fetchReminders(matching: predicate) { reminders in
          let values = (reminders ?? []).prefix(500).map {
            DeviceReminder(
              id: $0.calendarItemIdentifier, title: $0.title ?? "Untitled",
              completed: $0.isCompleted)
          }
          continuation.resume(returning: values)
        }
      }
    }
    func setCompleted(id: String, completed: Bool) throws {
      guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
        throw HomeError.notFound
      }
      reminder.isCompleted = completed
      try store.save(reminder, commit: true)
    }
    func remove(id: String) throws {
      guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
        throw HomeError.notFound
      }
      try store.remove(reminder, commit: true)
    }
    /// Creates only in our own named calendar; never changes existing personal reminders.
    func createInHomeViewList(title: String) throws {
      guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else {
        throw NativeServiceError.permissionDenied
      }
      let calendar: EKCalendar
      if let existing = store.calendars(for: .reminder).first(where: { $0.title == "HomeView" }) {
        calendar = existing
      } else {
        let c = EKCalendar(for: .reminder, eventStore: store)
        guard let source = store.defaultCalendarForNewReminders()?.source else {
          throw NativeServiceError.unavailable
        }
        c.title = "HomeView"
        c.source = source
        try store.saveCalendar(c, commit: true)
        calendar = c
      }
      let reminder = EKReminder(eventStore: store)
      reminder.title = title
      reminder.calendar = calendar
      try store.save(reminder, commit: true)
    }
  }
#endif

#if canImport(HomeKit) && (os(iOS) || os(visionOS))
  @preconcurrency import HomeKit

  /// Intentionally no live-manager instance in the shipped mock application.
  /// Construction is disabled in this revision, including outside mock tests.
  @MainActor
  final class NativeHomeKitService: NSObject, @preconcurrency HMHomeManagerDelegate {
    private var manager: HMHomeManager?
    private(set) var homes: [HMHome] = []
    init(disabledUntilSetup: Bool) throws {
      // Apple Home deliberately remains disconnected until an explicitly authorized setup.
      // No initializer path may construct an HMHomeManager in this revision.
      throw NativeServiceError.realHomeDisabled
    }
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) { homes = manager.homes }
    func executeScene(homeID: UUID, sceneID: UUID) async throws {
      guard let home = homes.first(where: { $0.uniqueIdentifier == homeID }),
        let scene = home.actionSets.first(where: { $0.uniqueIdentifier == sceneID })
      else { throw HomeError.notFound }
      try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, any Error>) in
        home.executeActionSet(scene) { error in
          if let error { c.resume(throwing: error) } else { c.resume() }
        }
      }
    }
    func write(accessoryID: UUID, characteristicType: String, value: Double) async throws {
      guard value.isFinite else { throw HomeError.invalidValue }
      guard
        let accessory = homes.flatMap(\.accessories).first(where: {
          $0.uniqueIdentifier == accessoryID
        }),
        let characteristic = accessory.services.flatMap(\.characteristics).first(where: {
          $0.characteristicType == characteristicType
            && $0.properties.contains(HMCharacteristicPropertyWritable)
        })
      else { throw HomeError.notFound }
      if let min = characteristic.metadata?.minimumValue?.doubleValue, value < min {
        throw HomeError.invalidValue
      }
      if let max = characteristic.metadata?.maximumValue?.doubleValue, value > max {
        throw HomeError.invalidValue
      }
      try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, any Error>) in
        characteristic.writeValue(NSNumber(value: value)) { error in
          if let error { c.resume(throwing: error) } else { c.resume() }
        }
      }
    }
  }
#endif

#if canImport(MusicKit) && (os(iOS) || os(macOS) || os(visionOS))
  import MusicKit
  @MainActor
  final class NativeMusicService {
    private var results: MusicItemCollection<Song> = []
    func search(_ text: String) async throws -> [DeviceTrack] {
      guard await MusicAuthorization.request() == .authorized else {
        throw NativeServiceError.permissionDenied
      }
      var request = MusicCatalogSearchRequest(term: text, types: [Song.self])
      request.limit = 20
      results = try await request.response().songs
      return results.map {
        DeviceTrack(
          id: $0.id.rawValue, title: $0.title, artist: $0.artistName,
          artwork: $0.artwork?.url(width: 512, height: 512))
      }
    }
    func play(index: Int) async throws {
      guard results.indices.contains(index) else { throw HomeError.notFound }
      let player = ApplicationMusicPlayer.shared
      player.queue = .init(for: [results[index]])
      try await player.play()
    }
    func pause() { ApplicationMusicPlayer.shared.pause() }
    var isPlaying: Bool { ApplicationMusicPlayer.shared.state.playbackStatus == .playing }
    var playbackTime: Double { ApplicationMusicPlayer.shared.playbackTime }
    func resume() async throws { try await ApplicationMusicPlayer.shared.play() }
    func authorize() async throws {
      guard await MusicAuthorization.request() == .authorized else {
        throw NativeServiceError.permissionDenied
      }
    }
  }
#endif
