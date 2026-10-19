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
      return try CalendarAgenda.events(store.events(matching: query).map {
        DeviceEvent(
          id: CalendarAgenda.occurrenceID(item: $0.calendarItemIdentifier, start: $0.startDate), title: $0.title ?? "Untitled",
          start: $0.startDate, end: $0.endDate, location: $0.location ?? "",
          calendar: $0.calendar.title, cancelled: $0.status == .canceled, allDay: $0.isAllDay)
      }, in: DateInterval(start: from, end: to))
    }
  }
  @MainActor
  final class NativeReminderService {
    private lazy var store = EKEventStore()
    private let ownListKey = "HomeView.reminders.ownedCalendarID"
    private func requireAccess() throws {
      guard EKEventStore.authorizationStatus(for: .reminder) == .fullAccess else {
        throw NativeServiceError.permissionDenied
      }
    }
    func authorize() async throws {
      guard try await store.requestFullAccessToReminders() else {
        throw NativeServiceError.permissionDenied
      }
    }
    func read() async throws -> [DeviceReminder] {
      try requireAccess()
      let predicate = store.predicateForReminders(in: nil)
      let values: [DeviceReminder] = try await withCheckedThrowingContinuation { continuation in
        store.fetchReminders(matching: predicate) { reminders in
          guard let reminders else {
            continuation.resume(throwing: ReminderStoreError.fetchFailed); return
          }
          guard reminders.count <= 500 else {
            continuation.resume(throwing: ReminderStoreError.tooManyItems); return
          }
          continuation.resume(returning: reminders.map {
            DeviceReminder(id: $0.calendarItemIdentifier, title: $0.title ?? "Untitled",
              completed: $0.isCompleted, listTitle: $0.calendar.title,
              writable: $0.calendar.allowsContentModifications)
          }.sorted {
            if $0.listTitle != $1.listTitle { return $0.listTitle < $1.listTitle }
            if $0.title != $1.title { return $0.title < $1.title }
            return $0.id < $1.id
          })
        }
      }
      try requireAccess()
      return values
    }
    private func editable(_ id: String) throws -> EKReminder {
      try requireAccess()
      guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
        throw HomeError.notFound
      }
      guard reminder.calendar.allowsContentModifications else { throw ReminderStoreError.readOnly }
      return reminder
    }
    func setCompleted(id: String, completed: Bool) throws {
      let reminder = try editable(id)
      reminder.isCompleted = completed
      try store.save(reminder, commit: true)
    }
    func remove(id: String) throws {
      try store.remove(editable(id), commit: true)
    }
    /// A same-named user/shared list is never treated as application-owned.
    func createInHomeViewList(title: String) throws -> String {
      try requireAccess()
      let calendar: EKCalendar
      if let id = UserDefaults.standard.string(forKey: ownListKey) {
        guard let existing = store.calendar(withIdentifier: id),
          existing.allowsContentModifications else { throw ReminderStoreError.ownListUnavailable }
        calendar = existing
      } else {
        let created = EKCalendar(for: .reminder, eventStore: store)
        guard let source = store.defaultCalendarForNewReminders()?.source else {
          throw NativeServiceError.unavailable
        }
        created.title = "HomeView"
        created.source = source
        try store.saveCalendar(created, commit: true)
        UserDefaults.standard.set(created.calendarIdentifier, forKey: ownListKey)
        calendar = created
      }
      let reminder = EKReminder(eventStore: store)
      reminder.title = title
      reminder.calendar = calendar
      try store.save(reminder, commit: true)
      return reminder.calendarItemIdentifier
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
    private var searchGeneration = 0
    private let playback = MusicPlaybackGate(pause: { ApplicationMusicPlayer.shared.pause() })
    func search(_ text: String) async throws -> [DeviceTrack] {
      searchGeneration += 1;let ticket=searchGeneration
      try Task.checkCancellation()
      guard await MusicAuthorization.request() == .authorized else {
        throw NativeServiceError.permissionDenied
      }
      guard searchGeneration==ticket,!Task.isCancelled else { throw CancellationError() }
      var request = MusicCatalogSearchRequest(term: text, types: [Song.self])
      request.limit = 20
      let songs = try await request.response().songs
      guard searchGeneration==ticket,!Task.isCancelled else { throw CancellationError() }
      results = songs
      return songs.map {
        DeviceTrack(
          id: $0.id.rawValue, title: $0.title, artist: $0.artistName,
          artwork: $0.artwork?.url(width: 512, height: 512))
      }
    }
    func play(index: Int) async throws {
      guard results.indices.contains(index) else { throw HomeError.notFound }
      let song=results[index]
      try await playback.run {
        let player=ApplicationMusicPlayer.shared
        player.queue = .init(for:[song])
        try await player.play()
      }
    }
    func pause() { searchGeneration += 1;playback.stop() }
    var isPlaying: Bool { ApplicationMusicPlayer.shared.state.playbackStatus == .playing }
    var playbackTime: Double { ApplicationMusicPlayer.shared.playbackTime }
    func resume() async throws {
      try await playback.run { try await ApplicationMusicPlayer.shared.play() }
    }
    func authorize() async throws {
      guard await MusicAuthorization.request() == .authorized else {
        throw NativeServiceError.permissionDenied
      }
    }
  }
#endif
