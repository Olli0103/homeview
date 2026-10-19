import AVFoundation
import CryptoKit
import ImageIO
import Observation
import SwiftUI

@MainActor @Observable
final class AppModel {
  #if !os(watchOS)
    let connections = DeviceConnections()
    let podcastPlayer = PodcastPlaybackController()
    let recipeHandoff = RecipeHandoffController()
    var recipeHandoffFixtureInstalled = false
    var podcastStatus = "Public RSS feeds · No Apple Podcasts account sync"
    var podcastLoading = false
    var podcastFeedGeneration = 0

    private let albumPhotoProvider: any AlbumPhotoProvider
    let albumCatalogue: AlbumCatalogueSession
    let albumUpdates: AlbumDisplaySession
    private var albumRefreshTask: Task<Void,Never>?
  #endif
  let demoDoorbell = DemoDoorbell()
  private let repeatedDoorbellFixtureID = UUID()
  var faceDirection = 1
  var data: Snapshot
  var route: Route = .face
  var profile: String? = nil
  var pendingPage: AppPage? = nil
  var toast: String? = nil
  var error: String? = nil
  private(set) var storeReadOnly = false
  private(set) var storeRecoveryNote: String?
  let assistantAI = AssistantConversation(provider:makeAssistantAnswers())
  private(set) var assistantUsesAI = false
  var assistantInput = ""
  private(set) var personalSessionGeneration = 0
  var assistantReply = "What can I help you with?"
  var playing = false
  var podcastPlaying = false
  var startingMusic = false
  var startingPodcast = false
  var audioGeneration = 0
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
  private(set) var cookingInProgress = false
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
    if photoAnalysis?.diagnostic == "fixture_mac_native_alpha_replay" { return "DEMO · MASK REPLAY" }
    let title = data.albumDisplay?.album.title ?? data.photoGalleryTitle ?? "PHOTOS"
    return gallery.count > 1 ? "\(title.uppercased()) · \(photoIndex + 1) OF \(gallery.count)" : title.uppercased()
  }
  var hasPhotoSelection: Bool {
    photoData != nil || data.photoSelection == .single || data.photoSelection == .gallery
      || data.photoSelection == .album || !data.photoIDs.isEmpty
  }
  var photoSelectionStatus: String {
    #if !os(watchOS)
      if data.albumDisplay != nil { return albumUpdates.status }
    #endif
    return "Selected photos are unavailable."
  }
  var photoData: Data? = nil
  var photoForegroundData: Data? = nil
  private(set) var photoAnalysisFinished = true
  private(set) var photoComposition = PhotoComposition()
  private var photoAnalysis: PhotoAnalysis?
  private var photoAnalysisTask: Task<Void, Never>?
  private var photoKey: String?
  #if !os(watchOS)
    private var photoInkKey = ""
    private var photoInkCandidates: [PhotoClockInkCandidate] = []
    private(set) var photoInkRevision = 0
    var photoInkControlImage: CGImage? {
      PhotoClockInkRasterizer.controlImage(photoInkCandidates.first { $0.frame == photoComposition.clockFrame })
    }
  #endif
  var photoAnalysisDiagnostic: String { photoAnalysis?.diagnostic ?? "none" }
  var photoProtectedRegionCount: Int { photoAnalysis?.protectedRegions.count ?? 0 }
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
    var candidates: [PhotoClockInkCandidate]?
    #if !os(watchOS)
      if photoAnalysis.mask != nil, photoForegroundData != nil {
        let key = dateLabel("hh mm")
        if key != photoInkKey {
          photoInkCandidates = PhotoClockGlyphLayout.digits(in:key).map {
            PhotoClockInkRasterizer.candidates(digits:$0)
          } ?? []
          photoInkKey = key
          photoInkRevision += 1
        }
        candidates = photoInkCandidates
      }
    #endif
    photoComposition = PhotoPlacement.choose(
      aspect: photoAnalysis.aspect, mask: photoAnalysis.mask,
      protectedRegions: photoAnalysis.protectedRegions,
      foregroundAvailable: photoForegroundData != nil, adjustment: photoAdjustment,
      inkCandidates:candidates)
  }
  var now = Date()
  var referenceClock: Bool
  private let testReferenceDate: Date?
  private let testReferenceTimeZone: TimeZone?
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
  private let photoClockTestStart = ProcessInfo.processInfo.systemUptime
  private var photoClockTestStep = 0
  var clock: Date {
    let base = referenceClock ? (testReferenceDate ?? Fixtures.date) : now
    return base.addingTimeInterval(Double(photoClockTestStep)*60)
  }
  var recipe: RecipeDocument {
    get { data.recipe }
    set {
      #if !os(watchOS)
        recipeHandoff.stop()
      #endif
      data.recipe = newValue
      data.pinnedRecipe = data.pinnedRecipes.contains(where: { $0.id == newValue.id })
      cookingStep = 0
      cookingInProgress = false
      persist()
    }
  }
  func addWorldCity(_ zone: String) {
    guard data.worldClockZones.count < 12,
      WorldCity.catalogue.contains(where: { $0.zone == zone }),
      !data.worldClockZones.contains(zone) else { return }
    data.worldClockZones.append(zone)
    persist()
  }
  func removeWorldCity(_ zone: String) {
    data.worldClockZones.removeAll { $0 == zone }
    persist()
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
  var displayTimeZone: TimeZone {
    referenceClock ? (testReferenceTimeZone ?? TimeZone(secondsFromGMT:0)!) : .current
  }
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
    // Fixed clocks never read a calendar store and cannot override a normal
    // app launch. The reference clock toggle retains its existing semantics.
    testReferenceDate = {
      guard args.contains("--uitesting"), let i=args.firstIndex(of:"--reference-date"),
            args.indices.contains(i+1),args[i+1].count<=64 else { return nil }
      return ISO8601DateFormatter().date(from:args[i+1])
    }()
    testReferenceTimeZone = {
      guard args.contains("--uitesting"),let i=args.firstIndex(of:"--reference-zone"),
            args.indices.contains(i+1),args[i+1].count<=128 else { return nil }
      return TimeZone(identifier:args[i+1])
    }()
    #if !os(watchOS)
      let albumProvider = makeAlbumPhotoProvider()
      albumPhotoProvider = albumProvider
      albumCatalogue = AlbumCatalogueSession(provider:albumProvider)
      albumUpdates = AlbumDisplaySession(provider:albumProvider)
      if args.contains("--uitesting") { albumUpdates.minimumInterval = 1 }
    #endif
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
    data = Snapshot()
    // Synthetic corruption fixtures can only target an explicitly owned UUID test store.
    if testID != nil, args.contains("--uitesting"),
       args.contains("--state-future-fixture") || args.contains("--state-corrupt-fixture") {
      do {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if args.contains("--state-future-fixture") {
          try Data("{\"version\":99}".utf8).write(to: store, options: .atomic)
        } else {
          var fixture = Snapshot(); fixture.home.temperature = 69
          var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(fixture)) as! [String: Any]
          object["recipe"] = ["corrupt": true]
          try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]).write(to: store, options: .atomic)
        }
      } catch { self.error = "The synthetic test store could not be prepared." }
    }
    // Seed only a fresh, explicitly owned UUID store. The ordinary reader and
    // original-byte preservation below must perform the actual recovery.
    if testID != nil, args.contains("--uitesting"),
       let index = args.firstIndex(of:"--face-configuration-fixture"),
       args.indices.contains(index+1), ["legacy","future-widget"].contains(args[index+1]),
       !FileManager.default.fileExists(atPath:store.path) {
      do {
        let legacy = args[index+1] == "legacy"
        var fixture = Snapshot();fixture.face = .modular;fixture.home.temperature = 74
        fixture.personal["Alex"] = PersonalContent()
        fixture.personal["Alex"]!.messages = ["Synthetic face recovery note"]
        var object = try JSONSerialization.jsonObject(with:JSONEncoder().encode(fixture)) as! [String:Any]
        let slots = ["panel0":legacy ? "Weather":"Future Radar","panel1":"Clock","panel2":"Timer"]
        var configuration: [String:Any] = ["complications":slots,"theme":1]
        if !legacy { configuration["flowTypeface"] = 1;configuration["flowBackground"] = false }
        object["faceConfigurations"] = [
          "Modular":configuration,
          "Flow":["complications":[:],"theme":0,"flowTypeface":1,"flowBackground":false]
        ] as [String:Any]
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        try JSONSerialization.data(withJSONObject:object,options:[.sortedKeys])
          .write(to:store,options:.atomic)
      } catch { self.error = "The synthetic face configuration store could not be prepared." }
    }
    if !ephemeral, FileManager.default.fileExists(atPath: store.path) {
      do {
        let bytes = try Data(contentsOf: store)
        let saved = try Snapshot.decodeMigrating(bytes)
        let normalized = try JSONEncoder().encode(saved)
        if try Snapshot.canonicalBytes(bytes) != Snapshot.canonicalBytes(normalized) {
          try preserveOriginalStore(bytes)
          storeRecoveryNote = "Supported saved fields recovered. The original file was preserved."
        }
        data = saved
      } catch {
        storeReadOnly = true
        storeRecoveryNote = "Original saved data is unchanged. This file could not be safely opened; changes are not saved."
      }
    }
    #if !os(watchOS)
      if testID != nil,args.contains("--uitesting"),args.contains("--legacy-photo-file-fixture"),
         let fixture=PhotoLayoutFixture.make("top") {
        try? FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        try? fixture.bytes.write(to:dir.appendingPathComponent("selected-photo.data"),options:.atomic)
      }
    #endif
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
    var restoredPhotoFiles: [String:Data] = [:]
    if !ephemeral && !storeReadOnly {
      let storedFiles = data.photoSelection == .single || data.photoSelection == .gallery
        || data.photoSelection == .album || (data.photoSelection == .legacy && !data.photoIDs.isEmpty)
      if storedFiles {
        let limit = data.photoSelection == .single ? 40_000_000 : 5_000_000
        let budget = data.photoSelection == .single ? 40_000_000 : 30_000_000
        var used = 0
        for id in data.photoIDs.prefix(10) {
          guard let bytes = storedPhoto(id,limit:limit),used+bytes.count <= budget else { continue }
          restoredPhotoFiles[id] = bytes;used += bytes.count
          gallery.append(bytes)
        }
        if let first=gallery.first { showPhoto(first) }
      } else if data.photoSelection == .legacy {
        let file=dir.appendingPathComponent("selected-photo.data")
        if let selected=boundedPhotoFile(file,limit:40_000_000) {
          gallery=[selected];showPhoto(selected)
        }
      }
    }
    if args.contains("--screen-thermostat") { route = .thermostat }
    if args.contains("--screen-recipe") { route = .recipe }
    if args.contains("--uitesting"), args.contains("--reference-timer") {
      let long = args.contains("--reference-timer-long")
      var timer = Countdown(title: long ? "24 hours":"15 min", seconds: long ? 86_400:900)
      timer.deadline = nil
      timer.pausedRemaining = long ? 86_399:656
      data.timers = [timer]
      selectedTimer = timer.id
      route = .app(.timers)
    }
    if args.contains("--uitesting"), args.contains("--multiple-timers-fixture") {
      let fixtures:[(String,Double,Double)] = [("Tea",300,180),("Pasta",600,480),("Bread",900,600)]
      data.timers=fixtures.enumerated().map { index,value in
        var timer=Countdown(title:value.0,seconds:value.1)
        timer.id=UUID(uuidString:String(format:"00000000-0000-0000-0000-%012d",index+101))!
        timer.deadline=nil;timer.pausedRemaining=value.2
        return timer
      }
      selectedTimer=nil
      route = .app(.timers)
    }
    if args.contains("--uitesting"), args.contains("--timer-overflow-fixture") {
      data.timers=(1...12).map { index in
        var timer=Countdown(title:"Timer \(index)",seconds:Double(index)*60)
        timer.id=UUID(uuidString:String(format:"00000000-0000-0000-0000-%012d",index+200))!
        timer.deadline=nil
        return timer
      }
      selectedTimer=nil
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
    #if !os(watchOS)
      albumUpdates.apply = { [weak self] album,photos in
        guard let self else { return false }
        let saved = self.storePhotos(photos.map(\.bytes),selection:album == nil ? .none:.album,
          title:album?.title,album:album,assets:photos,navigate:false)
        if album == nil && !saved {
          // Stop displaying disconnected copies even when storage is unwritable.
          self.data.albumDisplay = nil;self.data.photoSelection = .none
          self.data.photoIDs = [];self.data.photoGalleryTitle = nil
          self.gallery = [];self.photoIndex = 0;self.showPhoto(nil)
        }
        return saved
      }
      if let grant=data.albumDisplay {
        let cached=grant.cache.compactMap { reference -> AlbumPhoto? in
          restoredPhotoFiles[reference.fileID].map {
            AlbumPhoto(id:reference.assetID,revision:reference.revision,bytes:$0)
          }
        }
        albumUpdates.restore(grant,photos:cached)
      }
    #endif
  }
  func setPhoto(_ bytes: Data?) {
    guard (bytes?.count ?? 0) <= 40_000_000 else {
      error = "Choose a photo smaller than 40 MB."
      return
    }
    guard storePhotos(bytes.map { [$0] } ?? [],selection:bytes == nil ? .none:.single,
      title:nil,album:nil,assets:[],navigate:true) else { return }
    #if !os(watchOS)
      albumRefreshTask?.cancel()
      albumUpdates.stop(clearDisplay:false)
    #endif
  }
  private func showPhoto(_ bytes: Data?) {
    photoAnalysisTask?.cancel()
    photoData = bytes
    photoForegroundData = nil
    photoAnalysisFinished = bytes == nil
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
          guard !Task.isCancelled, photoData == bytes else { return }
          if let analysis {
            photoAnalysis = analysis
            photoForegroundData = analysis.foreground
            updatePhotoComposition()
          }
          photoAnalysisFinished = true
        }
      }
    #else
      photoAnalysisFinished = true
    #endif
  }
  @discardableResult
  func setGallery(_ images: [Data], title: String? = nil) -> Bool {
    guard !images.isEmpty else { error = "Choose at least one photo.";return false }
    guard storePhotos(images,selection:.gallery,title:title,album:nil,assets:[],navigate:true) else { return false }
    #if !os(watchOS)
      albumRefreshTask?.cancel()
      albumUpdates.stop(clearDisplay:false)
    #endif
    return true
  }
  func openPhotoFace() {
    data.face = .photos
    persist()
    route = .face
  }
  func nextPhoto() {
    guard gallery.count > 1 else { return }
    photoIndex = (photoIndex + 1) % gallery.count
    showPhoto(gallery[photoIndex])
  }
  private func boundedPhotoFile(_ file:URL,limit:Int) -> Data? {
    guard let size=(try? FileManager.default.attributesOfItem(atPath:file.path)[.size]) as? NSNumber,
          size.intValue > 0,size.intValue <= limit,
          let bytes=try? Data(contentsOf:file),bytes.count <= limit,
          let source=CGImageSourceCreateWithData(bytes as CFData,nil),
          let properties=CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any],
          let width=properties[kCGImagePropertyPixelWidth] as? Double,
          let height=properties[kCGImagePropertyPixelHeight] as? Double,
          width.isFinite,height.isFinite,width>0,height>0,width*height <= 16_000_000 else { return nil }
    return bytes
  }
  private func storedPhoto(_ id:String,limit:Int) -> Data? {
    guard UUID(uuidString:id) != nil else { return nil }
    return boundedPhotoFile(store.deletingLastPathComponent().appendingPathComponent("photos/"+id+".jpg"),limit:limit)
  }
  /// New identities + an atomic metadata commit prevent old selected-photo.data
  /// from resurfacing after removal, an empty linked album, or a failed write.
  private func storePhotos(_ images:[Data],selection:PhotoSelectionKind,title:String?,
                           album:DisplayAlbum?,assets:[AlbumPhoto],navigate:Bool) -> Bool {
    guard !storeReadOnly else {
      error = "Saved data is read-only. The photo selection was not changed."
      return false
    }
    let single=selection == .single
    guard images.count <= (single ? 1:10),
          images.allSatisfy({ !$0.isEmpty && $0.count <= (single ? 40_000_000:5_000_000) }),
          images.reduce(0,{$0+$1.count}) <= (single ? 40_000_000:30_000_000),
          album == nil || (album!.valid && assets.count == images.count) else {
      error = "Choose up to ten photos, at most 30 MB in total."
      return false
    }
    let reusable = gallery == images && data.photoIDs.count == images.count
    let ids = reusable ? data.photoIDs : images.map { _ in UUID().uuidString }
    var candidate=data
    candidate.photoSelection=selection
    candidate.photoIDs=ids
    candidate.photoGalleryTitle=title.map { String($0.prefix(120)) }
    candidate.albumDisplay=album.map { descriptor in
      AlbumDisplayGrant(album:descriptor,approvedForDisplay:true,
        cache:zip(assets,ids).map { AlbumCacheReference(assetID:$0.0.id,revision:$0.0.revision,fileID:$0.1) })
    }
    if navigate { candidate.face = .photos }
    let oldIDs=data.photoIDs
    let folder=store.deletingLastPathComponent().appendingPathComponent("photos",isDirectory:true)
    if !ephemeral {
      do {
        try FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
        if !reusable {
          for (id,bytes) in zip(ids,images) { try bytes.write(to:folder.appendingPathComponent(id+".jpg"),options:.atomic) }
        }
        try JSONEncoder().encode(candidate).write(to:store,options:.atomic)
      } catch {
        if !reusable {
          for id in ids { try? FileManager.default.removeItem(at:folder.appendingPathComponent(id+".jpg")) }
        }
        self.error = "Could not save the photos. The previous selection is unchanged."
        return false
      }
    }
    data=candidate
    if !ephemeral {
      for id in oldIDs where UUID(uuidString:id) != nil && !ids.contains(id) {
        try? FileManager.default.removeItem(at:folder.appendingPathComponent(id+".jpg"))
      }
      let legacy=store.deletingLastPathComponent().appendingPathComponent("selected-photo.data")
      if FileManager.default.fileExists(atPath:legacy.path) { try? FileManager.default.removeItem(at:legacy) }
    }
    if !reusable || photoData != images.first {
      let current=photoData.flatMap { images.firstIndex(of:$0) } ?? 0
      gallery=images;photoIndex=current
      showPhoto(images.indices.contains(current) ? images[current]:nil)
    }
    if navigate { route = .face }
    return true
  }

  #if !os(watchOS)
  func requestAlbumUnlock() {
    pendingPage = .settings
    route = .deviceUnlock
  }
  func loadAlbumChoices() async {
    let generation=personalSessionGeneration
    await albumCatalogue.load { [weak self] in
      self?.connections.personalUnlocked == true && self?.personalSessionGeneration == generation
    }
  }
  func importAlbumOnce(_ album:DisplayAlbum) async {
    guard connections.personalUnlocked,albumCatalogue.albums.contains(album) else { return }
    let generation=personalSessionGeneration
    do {
      let batch=try await albumPhotoProvider.readAlbum(album.id,known:[])
      guard !Task.isCancelled,connections.personalUnlocked,personalSessionGeneration == generation else { return }
      let values=batch.orderedIDs.compactMap { id in batch.photos.first { $0.id == id }?.bytes }
      guard !values.isEmpty else { error="No photos could be imported.";return }
      _ = setGallery(values,title:album.title)
    } catch {
      guard !Task.isCancelled,connections.personalUnlocked,personalSessionGeneration == generation else { return }
      self.error="The selected album could not be imported."
    }
  }
  func linkAlbumForDisplay(_ album:DisplayAlbum) {
    guard connections.personalUnlocked,albumCatalogue.albums.contains(album) else { return }
    if albumUpdates.select(album,deviceAuthenticated:connections.personalUnlocked,explicitDisplayConsent:true) {
      data.face = .photos;persist();route = .face
      refreshDisplayAlbum()
    }
  }
  func refreshDisplayAlbum() {
    guard !albumUpdates.busy else { return }
    albumRefreshTask?.cancel()
    albumRefreshTask=Task { await albumUpdates.refresh(force:true) }
  }
  func disconnectDisplayAlbum() {
    albumRefreshTask?.cancel()
    albumUpdates.stop()
  }
  func setAlbumDisplayActive(_ value:Bool) {
    if !value { albumRefreshTask?.cancel() }
    albumUpdates.setActive(value)
  }
  var albumFixtureReport:String? { (albumPhotoProvider as? FixtureAlbumPhotoProvider)?.report }
  func changeAlbumFixture() { (albumPhotoProvider as? FixtureAlbumPhotoProvider)?.changeWindow() }
  func revokeAlbumFixture() { (albumPhotoProvider as? FixtureAlbumPhotoProvider)?.revoke() }
  #endif

  private func preserveOriginalStore(_ bytes: Data) throws {
    let folder = store.deletingLastPathComponent().appendingPathComponent("State Recovery", isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let digest = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    let backup = folder.appendingPathComponent("original-" + digest + ".json")
    if FileManager.default.fileExists(atPath: backup.path) {
      guard try Data(contentsOf: backup) == bytes else { throw SnapshotReadError.malformed }
    } else {
      let existing = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
      guard existing.filter({ $0.lastPathComponent.hasPrefix("original-") }).count < 8 else {
        throw SnapshotReadError.oversized
      }
      try bytes.write(to: backup, options: .atomic)
      guard try Data(contentsOf: backup) == bytes else { throw SnapshotReadError.malformed }
    }
  }
  private func writableStore() -> Bool {
    guard !storeReadOnly else { error = storeRecoveryNote; return false }
    return true
  }
  func updateLocalControls(_ change: (inout Snapshot) -> Void) {
    let previous = data
    change(&data)
    guard persist() else { data = previous; return }
    if data.volume != previous.volume { audio.setVolume(Float(data.volume)) }
  }
  @discardableResult
  func persist() -> Bool {
    guard !ephemeral else { return true }
    guard writableStore() else { return false }
    do {
      try FileManager.default.createDirectory(
        at: store.deletingLastPathComponent(), withIntermediateDirectories: true)
      try JSONEncoder().encode(data).write(to: store, options: .atomic)
      return true
    } catch { self.error = "Could not save local demo state."; return false }
  }
  var doorbellFixtureRoute: String {
    switch route {
    case .face: "face"
    case .app(let page): "app:" + page.rawValue
    case .cooking: "cooking"
    case .privacy: "privacy"
    default: String(describing:route)
    }
  }
  func simulateDoorbell(repeatFixture: Bool = false) {
    if repeatFixture {
      let args = ProcessInfo.processInfo.arguments
      guard args.contains("--uitesting"), args.contains("--doorbell-fixture") else { return }
    }
    interact()
    let event = DemoDoorbellEvent(id:repeatFixture ? repeatedDoorbellFixtureID:UUID(),
      cameraIndex:0,occurredAt:Date())
    let result = demoDoorbell.receive(event,now:Date(),
      uptime:ProcessInfo.processInfo.systemUptime,cameraAvailable:data.home.online,
      callInProgress:incomingCall || route == .call)
    switch result {
    case .shown,.replaced: talking=false
    case .cameraUnavailable: banner("Demo doorbell unavailable · Mock camera offline")
    case .callNotInterrupted: banner("Demo doorbell · Current call was not interrupted")
    default: break
    }
  }
  func finishTimerForDoorbellFixture() {
    let args = ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"),args.contains("--doorbell-fixture"),
          let index = data.timers.firstIndex(where: { $0.id == selectedTimer }) else { return }
    data.timers[index].deadline = Date().addingTimeInterval(-1)
    data.timers[index].didAlert = false
  }
  func dismissDemoDoorbell() {
    demoDoorbell.dismiss()
    talking=false
  }
  private func reconcileDemoDoorbell() {
    let presented = demoDoorbell.current != nil
    demoDoorbell.reconcile(at:ProcessInfo.processInfo.systemUptime,
      cameraAvailable:data.home.online,callInProgress:incomingCall || route == .call)
    if presented, demoDoorbell.current == nil { talking=false }
  }
  func interact() { lastInteraction = Date() }
  func command(_ command: HomeCommand) {
    do {
      try data.home.transact(command, authorized: authorized)
      persist()
    } catch { self.error = error.localizedDescription }
  }
  func navigate(_ page: AppPage) {
    if demoDoorbell.current != nil { dismissDemoDoorbell() }
    interact()
    #if !os(watchOS)
      if page == .calendar && connections.requested.contains(.calendar)
        || page == .reminders && connections.requested.contains(.reminders)
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
    guard Fixtures.profiles.contains(name) else { return }
    lockPersonalAccess()
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
    assistantAI.deselect()
    assistantUsesAI=false
    #if !os(watchOS)
      recipeHandoff.stop()
    #endif
    dismissDemoDoorbell()
    personalSessionGeneration += 1
    #if !os(watchOS)
      connections.lock()
      albumCatalogue.invalidate()
    #endif
    profile = nil
    assistantInput = ""
    assistantReply = "What can I help you with?"
    messageText = ""
    toastTask?.cancel()
    toast = nil
  }
  func homeGesture() {
    if demoDoorbell.current != nil { dismissDemoDoorbell(); return }
    interact()
    switch route {
    case .face: route = .personal
    case .personal: route = .drawer
    case .drawer: route = .face
    default: route = .personal
    }
  }
  func nextFace(_ delta: Int) {
    guard demoDoorbell.current == nil else { return }
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
    let args = ProcessInfo.processInfo.arguments
    if args.contains("--uitesting"), args.contains("--fast-photo-clock") {
      photoClockTestStep = Int((ProcessInfo.processInfo.systemUptime-photoClockTestStart)/3)
    }
    #if !os(watchOS)
      if photoAnalysis?.mask != nil, photoForegroundData != nil,
         dateLabel("hh mm") != photoInkKey { updatePhotoComposition() }
    #endif
    reconcileDemoDoorbell()
    #if !os(watchOS)
      connections.tick()
      podcastPlayer.poll()
      if data.podcasts.selectedEpisode != nil {
        podcastPlaying=podcastPlayer.playing
        if let id=podcastPlayer.episodeID,
           abs((data.podcasts.positions[id] ?? 0)-podcastPlayer.position)>=5 { savePodcastPosition() }
      }
      if albumUpdates.shouldRefresh() {
        albumRefreshTask=Task { await albumUpdates.refresh() }
      }
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
  @discardableResult
  func addTimer(seconds: TimeInterval, title: String = "Timer") -> Bool {
    guard writableStore() else { return false }
    guard seconds.isFinite, seconds > 0, seconds <= 86400, data.timers.count < 12 else {
      error = "Choose 1 second to 24 hours, up to 12 timers."
      return false
    }
    let timer = Countdown(title: title, seconds: seconds)
    let previousSelection = selectedTimer
    data.timers.append(timer)
    selectedTimer = timer.id
    guard persist() else {
      data.timers.removeAll { $0.id == timer.id }
      selectedTimer = previousSelection
      return false
    }
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
    return true
  }
  func toggleTimer(_ id: UUID) {
    guard writableStore() else { return }
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
    guard writableStore() else { return }
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
    guard writableStore() else { return }
    guard (0...23).contains(hour), (0...59).contains(minute), data.alarms.count < 24 else {
      error = "Choose a valid time, up to 24 alarms."
      return
    }
    let alarm = AlarmItem(hour: hour, minute: minute)
    data.alarms.append(alarm)
    guard persist() else { data.alarms.removeAll { $0.id == alarm.id }; return }
    scheduleNativeAlarm(alarm)
  }
  private func scheduleNativeAlarm(_ alarm: AlarmItem) {
    guard writableStore() else { return }
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
    guard writableStore() else { return }
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
    guard writableStore() else { return }
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
    guard !storeReadOnly else { return }
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
  #if !os(watchOS)
  @discardableResult
  func applyRecipeTransfer(_ transfer:RecipeTransfer) -> Bool {
    guard !Task.isCancelled,connections.personalUnlocked else { return false }
    do {
      let target=try RecipeContinuity.resolve(transfer,recipes:[data.recipe]+data.pinnedRecipes)
      let previous=data
      data.recipe=target;data.pinnedRecipe=data.pinnedRecipes.contains { $0.id==target.id }
      guard persist() else { data=previous;recipeHandoff.status="Recipe could not be saved. Nothing was changed.";return false }
      cookingStep=transfer.step;cookingInProgress=true;route = .cooking
      return true
    } catch {
      recipeHandoff.status=(error as? LocalizedError)?.errorDescription ?? "Recipe handoff is unavailable."
      return false
    }
  }
  #endif
  func startCooking() {
    guard !recipe.steps.isEmpty else { error = "This recipe has no cooking steps."; return }
    cookingStep = 0
    cookingInProgress = true
    route = .cooking
  }
  func moveCookingStep(_ delta: Int) {
    guard cookingInProgress, recipe.steps.indices.contains(cookingStep) else { return }
    if delta > 0, cookingStep == recipe.steps.count - 1 {
      cookingInProgress = false
      route = .recipe
      banner("Enjoy your meal!")
    } else {
      cookingStep = min(recipe.steps.count - 1, max(0, cookingStep + delta))
      route = .cooking
    }
  }
  private func runEverydayCommand() -> Bool {
    switch EverydayVoiceCommand(assistantInput) {
    case .timer(let seconds, let title):
      let count = data.timers.count
      addTimer(seconds: Double(seconds), title: title)
      assistantReply = data.timers.count > count
        ? "Your \(title) timer is running (\(seconds) seconds)."
        : error ?? "The timer was not started."
    case .step(let delta):
      guard cookingInProgress, recipe.steps.indices.contains(cookingStep) else {
        assistantReply = "Open a recipe and start cooking first."
        assistantInput = ""
        return true
      }
      moveCookingStep(delta)
      assistantReply = cookingInProgress ? recipe.steps[cookingStep].text : "Cooking finished."
    case .repeatStep:
      assistantReply = cookingInProgress && recipe.steps.indices.contains(cookingStep)
        ? "Step \(cookingStep + 1): " + recipe.steps[cookingStep].text
        : "Open a recipe and start cooking first."
    case .clarify(let message): assistantReply = message
    case .unrelated: return false
    }
    assistantInput = ""
    return true
  }
  func selectAssistantAnswers(_ enabled:Bool) {
    assistantAI.deselect();assistantUsesAI=enabled
    if enabled { assistantAI.select() }
  }
  func runAssistant() {
    guard !Task.isCancelled else { return }
    interact()
    if assistantUsesAI {
      if assistantAI.ask(assistantInput) { assistantInput="" }
      return
    }
    if runEverydayCommand() { return }
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
    case .timer:
      assistantReply = "Specify an explicit timer duration, for example ‘set a timer for 5 minutes’."
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
      pauseFeedPodcast()
    #endif
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
      pauseFeedPodcast()
    #endif
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
      if data.podcasts.selectedEpisode != nil { toggleFeedPodcast();return }
    #endif
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
