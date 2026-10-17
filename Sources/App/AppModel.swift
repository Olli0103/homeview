import AVFoundation
import CryptoKit
import ImageIO
import Observation
import SwiftUI

@MainActor @Observable
final class AppModel {
  #if !os(watchOS)
    let connections = DeviceConnections()
  #endif
  var faceDirection = 1
  var data: Snapshot
  var route: Route = .face
  var profile: String? = nil
  var pendingPage: AppPage? = nil
  var toast: String? = nil
  var error: String? = nil
  var assistantInput = ""
  var assistantReply = "What can I help you with?"
  var playing = false
  var podcastPlaying = false
  private var startingMusic = false
  private var startingPodcast = false
  private var audioGeneration = 0
  var currentMusicTitle: String {
    #if !os(watchOS)
      if connections.enabled.contains(.music) {
        if let index = connections.currentTrack, connections.tracks.indices.contains(index) {
          return connections.tracks[index].title
        }
        return "Apple Music"
      }
    #endif
    return Fixtures.songs[song]
  }
  var currentMusicArtist: String {
    #if !os(watchOS)
      if connections.enabled.contains(.music) {
        if let index = connections.currentTrack, connections.tracks.indices.contains(index) {
          return connections.tracks[index].artist
        }
        return "Choose a song"
      }
    #endif
    return "Demo Artist"
  }
  var musicIsPlaying: Bool {
    #if !os(watchOS)
      if connections.enabled.contains(.music) { return connections.musicPlaying }
    #endif
    return playing
  }
  var song = 0
  var progress = 0.0
  var cookingStep = 0
  var selectedTimer: UUID?
  var talking = false
  var muted = false
  var videoEnabled = true
  var incomingCall = false
  var intercomText = "Dinner is ready!"
  var intercomHistory: [String] = []
  var messageText = ""
  var messages: [String] {
    get {
      guard authorized, let name = profile else { return [] }
      return data.personal[name]?.messages ?? []
    }
    set {
      guard authorized, let name = profile else { return }
      data.personal[name, default: PersonalContent()].messages = newValue
      persist()
    }
  }
  var reminders: [ReminderItem] {
    get {
      guard authorized, let name = profile else { return [] }
      return data.personal[name]?.reminders ?? []
    }
    set {
      guard authorized, let name = profile else { return }
      data.personal[name, default: PersonalContent()].reminders = newValue
      persist()
    }
  }
  var simulatedPresence = true
  var ringLight = true
  var mirrorZoom = 1.0
  private var gallery: [Data] = []
  private(set) var photoIndex = 0
  private var photoChangedAt = Date()
  var photoCount: Int { gallery.count }
  var photoCaption: String {
    gallery.count > 1 ? "PHOTOS · \(photoIndex + 1) OF \(gallery.count)" : "PHOTOS"
  }
  var photoData: Data? = nil
  var photoForegroundData: Data? = nil
  private(set) var photoComposition = PhotoComposition()
  private var photoAnalysis: PhotoAnalysis?
  private var photoAnalysisTask: Task<Void, Never>?
  private var photoKey: String?
  var photoAdjustment: PhotoAdjustment {
    photoKey.flatMap { data.photoAdjustments[$0] } ?? .init()
  }
  func adjustPhoto(_ adjustment: PhotoAdjustment) {
    guard let photoKey else { return }
    if data.photoAdjustments.count >= 100, data.photoAdjustments[photoKey] == nil,
       let oldestKey = data.photoAdjustments.keys.sorted().first {
      data.photoAdjustments.removeValue(forKey: oldestKey)
    }
    data.photoAdjustments[photoKey] = adjustment
    updatePhotoComposition()
    persist()
  }
  private func updatePhotoComposition() {
    guard let photoAnalysis else { photoComposition = .init(); return }
    photoComposition = PhotoPlacement.choose(aspect: photoAnalysis.aspect, mask: photoAnalysis.mask,
                                            adjustment: photoAdjustment)
  }
  var now = Date()
  var referenceClock: Bool
  var lastInteraction = Date()
  var idleSeconds = 120.0
  let audio = LocalAudioEngine()
  let display = DisplayWakeController()
  private let store: URL
  private let ephemeral: Bool
  private let systemAlarmsAllowed: Bool
  #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
    private var nativeAlarms = NativeAlarmService()
  #endif
  private var toastTask: Task<Void, Never>?
  var clock: Date { referenceClock ? Fixtures.date : now }
  var recipe: RecipeDocument {
    get { data.recipe }
    set {
      data.recipe = newValue
      data.pinnedRecipe = data.pinnedRecipes.contains(where: { $0.id == newValue.id })
      cookingStep = 0
      persist()
    }
  }
  func pinRecipe() {
    if data.pinnedRecipes.contains(where: { $0.id == recipe.id }) {
      data.pinnedRecipes.removeAll { $0.id == recipe.id }
      data.pinnedRecipe = false
    } else {
      guard data.pinnedRecipes.count < 50 else {
        error = "You can save up to 50 recipes."
        return
      }
      data.pinnedRecipes.append(recipe)
      data.pinnedRecipe = true
    }
    persist()
  }
  var displayTimeZone: TimeZone { referenceClock ? TimeZone(secondsFromGMT: 0)! : .current }
  var monthLayout: MonthLayout { MonthLayout(date: clock, timeZone: displayTimeZone) }
  func dateLabel(_ format: String) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US")
    f.timeZone = displayTimeZone
    f.dateFormat = format
    return f.string(from: clock)
  }
  var authorized: Bool { profile != nil && simulatedPresence }
  init() {
    let args = ProcessInfo.processInfo.arguments
    let testID: UUID? = {
      guard args.contains("--uitesting"), let i = args.firstIndex(of: "--persistence-test"),
        args.indices.contains(i + 1)
      else { return nil }
      return UUID(uuidString: args[i + 1])
    }()
    ephemeral = args.contains("--uitesting") && testID == nil
    systemAlarmsAllowed = !args.contains("--uitesting") || args.contains("--system-alarms")
    referenceClock = args.contains("--reference-clock")
    var dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("HomeViewReplica", isDirectory: true)
    if let id = testID {
      dir = dir.appendingPathComponent("test-" + id.uuidString, isDirectory: true)
      if args.contains("--reset-test-store") { try? FileManager.default.removeItem(at: dir) }
    }
    store = dir.appendingPathComponent("mock-state.json")
    if !ephemeral, let bytes = try? Data(contentsOf: store),
      let saved = try? Snapshot.decodeMigrating(bytes), saved.version == 1,
      saved.widgets.count == 4, !saved.recipe.steps.isEmpty
    {
      data = saved
    } else {
      data = Snapshot()
    }
    if let i = args.firstIndex(of: "--face"), args.indices.contains(i + 1),
      let face = Face(rawValue: args[i + 1])
    {
      data.face = face
    }
    if let i = args.firstIndex(of: "--page"), args.indices.contains(i + 1),
      let page = AppPage(rawValue: args[i + 1])
    {
      route = .app(page)
    }
    if !ephemeral {
      if let selected = try? Data(contentsOf: dir.appendingPathComponent("selected-photo.data")) {
        showPhoto(selected)
      }
    }
    if !ephemeral {
      gallery = data.photoIDs.prefix(10).compactMap { id in
        guard UUID(uuidString: id) != nil else { return nil }
        return try? Data(contentsOf: dir.appendingPathComponent("photos/" + id + ".jpg"))
      }
      if let first = gallery.first { showPhoto(first) }
    }
    if args.contains("--screen-thermostat") { route = .thermostat }
    if args.contains("--screen-recipe") { route = .recipe }
    if args.contains("--uitesting"), args.contains("--reference-timer") {
      var timer = Countdown(title: "15 min", seconds: 900)
      timer.deadline = nil
      timer.pausedRemaining = 656
      data.timers = [timer]
      selectedTimer = timer.id
      route = .app(.timers)
    }
    #if !os(watchOS)
      if args.contains("--uitesting"), let index = args.firstIndex(of: "--photo-layout-fixture"),
         args.indices.contains(index + 1), let fixture = PhotoLayoutFixture.make(args[index+1]) {
        setPhoto(fixture.bytes)
        photoAnalysisTask?.cancel()
        photoAnalysis = fixture.analysis
        photoForegroundData = fixture.analysis.foreground
        updatePhotoComposition()
        if args.contains("--photo-layout-settings") { route = .app(.settings) }
      }
    #endif
  }
  func setPhoto(_ bytes: Data?) {
    guard (bytes?.count ?? 0) <= 40_000_000 else {
      error = "Choose a photo smaller than 40 MB."
      return
    }
    gallery = []
    photoIndex = 0
    data.photoIDs = []
    showPhoto(bytes)
    if !ephemeral {
      let url = store.deletingLastPathComponent().appendingPathComponent("selected-photo.data")
      let maskURL = store.deletingLastPathComponent().appendingPathComponent(
        "selected-photo-mask.png")
      if FileManager.default.fileExists(atPath: maskURL.path) {
        try? FileManager.default.removeItem(at: maskURL)
      }
      do {
        try FileManager.default.createDirectory(
          at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let bytes {
          try bytes.write(to: url, options: .atomic)
        } else if FileManager.default.fileExists(atPath: url.path) {
          try FileManager.default.removeItem(at: url)
        }
      } catch { self.error = "Could not save the selected photo." }
    }
    data.face = .photos
    persist()
    route = .face
  }
  private func showPhoto(_ bytes: Data?) {
    photoAnalysisTask?.cancel()
    photoData = bytes
    photoForegroundData = nil
    photoAnalysis = nil
    photoKey = bytes.map { SHA256.hash(data: $0).map { String(format: "%02x", $0) }.joined() }
    // Establish crop and manual placement immediately, before slower Vision segmentation.
    if let bytes, let source = CGImageSourceCreateWithData(bytes as CFData, nil),
       let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
       let width = properties[kCGImagePropertyPixelWidth] as? Double,
       let height = properties[kCGImagePropertyPixelHeight] as? Double, height > 0 {
      let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
      let rotated = (5...8).contains(orientation)
      photoAnalysis = PhotoAnalysis(aspect: rotated ? height/width : width/height, mask: nil,
                                    foreground: nil)
    }
    updatePhotoComposition()
    photoChangedAt = Date()
    #if canImport(Vision) && (os(iOS) || os(macOS) || os(visionOS))
      if let bytes {
        photoAnalysisTask = Task {
          guard !Task.isCancelled else { return }
          let analysis = try? await Task.detached(priority: .utility) {
            try NativeSubjectExtractor.analyze(bytes)
          }.value
          guard !Task.isCancelled, photoData == bytes, let analysis else { return }
          photoAnalysis = analysis
          photoForegroundData = analysis.foreground
          updatePhotoComposition()
        }
      }
    #endif
  }
  func setGallery(_ images: [Data]) {
    guard !images.isEmpty, images.count <= 10,
      images.allSatisfy({ !$0.isEmpty && $0.count <= 5_000_000 }),
      images.reduce(0, { $0 + $1.count }) <= 30_000_000
    else {
      error = "Choose up to ten photos, at most 30 MB in total."
      return
    }
    let ids = images.map { _ in UUID().uuidString }
    let folder = store.deletingLastPathComponent().appendingPathComponent("photos")
    let oldIDs = data.photoIDs
    if !ephemeral {
      do {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (id, bytes) in zip(ids, images) {
          try bytes.write(to: folder.appendingPathComponent(id + ".jpg"), options: .atomic)
        }
        var candidate = data
        candidate.photoIDs = ids
        candidate.face = .photos
        try JSONEncoder().encode(candidate).write(to: store, options: .atomic)
      } catch {
        for id in ids {
          try? FileManager.default.removeItem(at: folder.appendingPathComponent(id + ".jpg"))
        }
        self.error = "Could not save the selected photos. Your previous selection is unchanged."
        return
      }
      for id in oldIDs where UUID(uuidString: id) != nil {
        try? FileManager.default.removeItem(at: folder.appendingPathComponent(id + ".jpg"))
      }
    }
    gallery = images
    photoIndex = 0
    data.photoIDs = ids
    data.face = .photos
    showPhoto(images[0])
    route = .face
  }
  func nextPhoto() {
    guard gallery.count > 1 else { return }
    photoIndex = (photoIndex + 1) % gallery.count
    showPhoto(gallery[photoIndex])
  }
  func persist() {
    guard !ephemeral else { return }
    do {
      try FileManager.default.createDirectory(
        at: store.deletingLastPathComponent(), withIntermediateDirectories: true)
      try JSONEncoder().encode(data).write(to: store, options: .atomic)
    } catch { self.error = "Could not save local demo state." }
  }
  func interact() { lastInteraction = Date() }
  func command(_ command: HomeCommand) {
    do {
      try data.home.transact(command, authorized: authorized)
      persist()
    } catch { self.error = error.localizedDescription }
  }
  func navigate(_ page: AppPage) {
    interact()
    #if !os(watchOS)
      if page == .calendar && connections.enabled.contains(.calendar)
        || page == .reminders && connections.enabled.contains(.reminders)
      {
        pendingPage = page
        route = connections.personalUnlocked ? .app(page) : .deviceUnlock
        return
      }
    #endif
    if page.isPersonal && !authorized {
      pendingPage = page
      route = .privacy
    } else {
      route = .app(page)
    }
  }
  func signIn(_ name: String) {
    #if !os(watchOS)
      connections.lock()
    #endif
    guard Fixtures.profiles.contains(name) else { return }
    profile = name
    if data.personal[name] == nil {
      data.personal[name] = PersonalContent()
      persist()
    }
    simulatedPresence = true
    route = pendingPage.map { .app($0) } ?? .personal
    pendingPage = nil
  }
  func signOut() {
    lockPersonalAccess()
    pendingPage = nil
    simulatedPresence = false
    incomingCall = false
    route = .privacy
  }
  func lockPersonalAccess() {
    #if !os(watchOS)
      connections.lock()
    #endif
    profile = nil
    assistantInput = ""
    assistantReply = "What can I help you with?"
    messageText = ""
    toastTask?.cancel()
    toast = nil
  }
  func homeGesture() {
    interact()
    switch route {
    case .face: route = .personal
    case .personal: route = .drawer
    case .drawer: route = .face
    default: route = .personal
    }
  }
  func nextFace(_ delta: Int) {
    faceDirection = delta
    let all = Face.allCases
    let index = all.firstIndex(of: data.face) ?? 0
    data.face = all[(index + delta + all.count) % all.count]
    persist()
  }
  func banner(_ value: String) {
    toast = value
    toastTask?.cancel()
    toastTask = Task {
      try? await Task.sleep(for: .seconds(3))
      if !Task.isCancelled { toast = nil }
    }
  }
  func tick() {
    now = Date()
    #if !os(watchOS)
      connections.tick()
    #endif
    let photoInterval =
      ProcessInfo.processInfo.arguments.contains("--fast-photo-rotation") ? 3.0 : 30.0
    if route == .face, data.face == .photos, data.rotatePhotos,
      now.timeIntervalSince(photoChangedAt) >= photoInterval
    {
      nextPhoto()
    }
    if playing {
      progress += 1
      if progress >= 180 {
        song = (song + 1) % Fixtures.songs.count
        progress = 0
      }
    }
    var changed = false
    for i in data.timers.indices
    where !data.timers[i].didAlert && data.timers[i].remaining(at: now) <= 0 {
      data.timers[i].didAlert = true
      selectedTimer = data.timers[i].id
      banner("\(data.timers[i].title) finished")
      changed = true
      if !data.nativeTimerIDs.contains(data.timers[i].id) { playChime() }
    }
    let cal = Calendar.current
    let day =
      "\(cal.component(.year, from: now))-\(cal.ordinality(of: .day, in: .year, for: now) ?? 0)"
    for i in data.alarms.indices where data.alarms[i].enabled && data.alarms[i].lastFiredDay != day
    {
      if cal.component(.hour, from: now) == data.alarms[i].hour
        && cal.component(.minute, from: now) == data.alarms[i].minute
      {
        data.alarms[i].lastFiredDay = day
        banner("Alarm")
        if !data.nativeAlarmIDs.contains(data.alarms[i].id) { playChime() }
        changed = true
      }
    }
    if changed { persist() }
    if route != .face && now.timeIntervalSince(lastInteraction) > idleSeconds && !incomingCall {
      route = .face
      lockPersonalAccess()
    }
  }
  func addTimer(seconds: TimeInterval, title: String = "Timer") {
    guard seconds.isFinite, seconds > 0, seconds <= 86400, data.timers.count < 12 else {
      error = "Choose 1 second to 24 hours, up to 12 timers."
      return
    }
    let timer = Countdown(title: title, seconds: seconds)
    data.timers.append(timer)
    selectedTimer = timer.id
    persist()
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      if systemAlarmsAllowed {
        Task {
          do {
            try await nativeAlarms.scheduleTimer(id: timer.id, seconds: seconds, title: title)
            if data.timers.contains(where: { $0.id == timer.id }) {
              data.nativeTimerIDs.insert(timer.id)
              persist()
            } else {
              try nativeAlarms.cancel(timer.id)
            }
          } catch {
            self.error =
              "The timer is running in the foreground, but the system alert could not be scheduled: \(error.localizedDescription)"
          }
        }
      }
    #endif
  }
  func toggleTimer(_ id: UUID) {
    guard let i = data.timers.firstIndex(where: { $0.id == id }) else { return }
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      if data.nativeTimerIDs.contains(id) {
        do {
          if data.timers[i].deadline == nil {
            try nativeAlarms.resume(id)
          } else {
            try nativeAlarms.pause(id)
          }
        } catch {
          self.error = "Could not update the system timer. \(error.localizedDescription)"
          return
        }
      }
    #endif
    if data.timers[i].deadline == nil {
      data.timers[i].resume(at: now)
    } else {
      data.timers[i].pause(at: now)
    }
    persist()
  }
  func removeTimer(_ id: UUID) {
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      if data.nativeTimerIDs.contains(id) {
        do { try nativeAlarms.cancel(id) } catch {
          self.error =
            "The system alarm could not be cancelled. The timer was kept. \(error.localizedDescription)"
          return
        }
      }
    #endif
    data.timers.removeAll { $0.id == id }
    data.nativeTimerIDs.remove(id)
    persist()
  }
  func addAlarm(hour: Int, minute: Int) {
    guard (0...23).contains(hour), (0...59).contains(minute), data.alarms.count < 24 else {
      error = "Choose a valid time, up to 24 alarms."
      return
    }
    let alarm = AlarmItem(hour: hour, minute: minute)
    data.alarms.append(alarm)
    persist()
    scheduleNativeAlarm(alarm)
  }
  private func scheduleNativeAlarm(_ alarm: AlarmItem) {
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      if systemAlarmsAllowed {
        Task {
          do {
            try await nativeAlarms.scheduleAlarm(
              id: alarm.id, hour: alarm.hour, minute: alarm.minute)
            if data.alarms.contains(where: { $0.id == alarm.id && $0.enabled }) {
              data.nativeAlarmIDs.insert(alarm.id)
              persist()
            } else {
              try nativeAlarms.cancel(alarm.id)
            }
          } catch {
            self.error =
              "The alarm is foreground-only because the system could not schedule it: \(error.localizedDescription)"
          }
        }
      }
    #endif
  }
  func toggleAlarm(_ id: UUID) {
    guard let i = data.alarms.firstIndex(where: { $0.id == id }) else { return }
    if data.alarms[i].enabled {
      #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
        if data.nativeAlarmIDs.contains(id) {
          do { try nativeAlarms.cancel(id) } catch {
            self.error = error.localizedDescription
            return
          }
        }
      #endif
      data.nativeAlarmIDs.remove(id)
      data.alarms[i].enabled = false
    } else {
      data.alarms[i].enabled = true
      scheduleNativeAlarm(data.alarms[i])
    }
    persist()
  }
  func removeAlarm(_ id: UUID) {
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      if data.nativeAlarmIDs.contains(id) {
        do { try nativeAlarms.cancel(id) } catch {
          self.error = error.localizedDescription
          return
        }
      }
    #endif
    data.alarms.removeAll { $0.id == id }
    data.nativeAlarmIDs.remove(id)
    persist()
  }
  func reconcileSystemAlarms() {
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      guard !data.nativeTimerIDs.isEmpty || !data.nativeAlarmIDs.isEmpty else { return }
      do {
        let active = try nativeAlarms.activeIDs()
        for i in data.alarms.indices
        where data.nativeAlarmIDs.contains(data.alarms[i].id) && !active.contains(data.alarms[i].id)
        { data.alarms[i].enabled = false }
        data.nativeAlarmIDs.formIntersection(active)
        for i in data.timers.indices
        where data.nativeTimerIDs.contains(data.timers[i].id) && !active.contains(data.timers[i].id)
        {
          data.timers[i].pausedRemaining = 0
          data.timers[i].deadline = nil
          data.timers[i].didAlert = true
        }
        data.nativeTimerIDs.formIntersection(active)
        persist()
      } catch {
        self.error = "Could not reconcile own system alarms. \(error.localizedDescription)"
      }
    #endif
  }
  func runAssistant() {
    interact()
    switch AssistantIntent(assistantInput) {
    case .scene(let s):
      command(.scene(s))
      assistantReply = error ?? "\(s) is set in the mock home."
    case .temperature(let t):
      command(.temperature(t))
      assistantReply = error ?? "The mock thermostat is set to \(t)°."
    case .light:
      command(.entryLight)
      assistantReply = error ?? "The entryway light is \(data.home.entryLight ? "on" : "off")."
    case .timer(let m):
      addTimer(seconds: Double(m * 60), title: "\(m) min")
      assistantReply = "Your \(m)-minute timer is running."
    case .recipe:
      route = .recipe
      assistantReply = "Here’s the soup recipe."
    case .calendar:
      navigate(.calendar)
      assistantReply = "Opening your calendar."
    case .music:
      let wasPlaying = musicIsPlaying || startingMusic
      togglePlayback()
      #if !os(watchOS)
        if connections.enabled.contains(.music) {
          assistantReply =
            connections.currentTrack == nil
            ? "Choose a song in Apple Music."
            : wasPlaying ? "Pause requested." : "Playback requested."
          break
        }
      #endif
      assistantReply = wasPlaying ? "Paused." : "Starting the bundled demo audio."
    case .unknown:
      assistantReply =
        "Try ‘set a timer for 5 minutes’, ‘temperature 70’, ‘good night’, ‘lights’, or ‘show recipe’. This is a local demo assistant, not Siri AI."
    }
    assistantInput = ""
  }
  func playChime() {
    Task {
      if !(await audio.playChime(volume: Float(data.volume))) {
        error = "The demo sound could not be played."
      }
    }
  }
  func stopAudioForVoice() {
    #if !os(watchOS)
      connections.pauseMusic()
    #endif
    audioGeneration += 1
    playing = false
    podcastPlaying = false
    startingMusic = false
    startingPodcast = false
    audio.stopMusic()
    audio.stopPodcast()
  }
  func togglePlayback() {
    #if !os(watchOS)
      if connections.enabled.contains(.music) {
        if connections.currentTrack == nil {
          route = .app(.music)
        } else {
          Task { await connections.toggleMusic() }
        }
        return
      }
    #endif
    audioGeneration += 1
    let generation = audioGeneration
    if playing || startingMusic {
      playing = false
      startingMusic = false
      audio.stopMusic()
      return
    }
    startingMusic = true
    startingPodcast = false
    podcastPlaying = false
    audio.stopPodcast()
    Task {
      let started = await audio.playMusic(volume: Float(data.volume))
      guard audioGeneration == generation else { return }
      startingMusic = false
      playing = started
      if !started { error = "The demo track could not be played." }
    }
  }
  func togglePodcast() {
    #if !os(watchOS)
      connections.pauseMusic()
    #endif
    audioGeneration += 1
    let generation = audioGeneration
    if podcastPlaying || startingPodcast {
      podcastPlaying = false
      startingPodcast = false
      audio.stopPodcast()
      return
    }
    startingPodcast = true
    startingMusic = false
    playing = false
    audio.stopMusic()
    Task {
      let started = await audio.playPodcast(volume: Float(data.volume))
      guard audioGeneration == generation else { return }
      startingPodcast = false
      podcastPlaying = started
      if !started { error = "The demo episode could not be played." }
    }
  }
}
