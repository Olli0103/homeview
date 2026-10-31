import AVFoundation
#if canImport(Darwin)
import Darwin
#endif
import CryptoKit
import ImageIO
import Observation
import SwiftUI

@MainActor @Observable
final class AppModel {
  @ObservationIgnored private var homeDeviceStorage:MockHomeDevice?
  @ObservationIgnored private var homeSessionStorage:HomeDeviceSession?
  private var homeForeground=false
  private(set) var lastHomeCommandState:HomeControlOperationState = .idle
  var homeControlsActive:Bool {homeForeground && !storeReadOnly && homeSessionStorage?.active == true}
  var homeControls:HomeDeviceSession {
    if let homeSessionStorage {return homeSessionStorage}
    let provider=MockHomeDevice(model:self);homeDeviceStorage=provider
    let values=HomeMockControls.values(data.home)
    let initial=Dictionary(uniqueKeysWithValues:provider.descriptors.values.compactMap {descriptor -> (HomeCharacteristicID,HomeCharacteristicReading)? in
      guard let value=values[descriptor.id] else {return nil}
      return(descriptor.id,HomeCharacteristicReading(descriptor:descriptor,value:value))
    })
    let session=HomeDeviceSession(provider:provider,initial:initial,contextAllowed:{[weak self] in
      self?.homeForeground == true && self?.storeReadOnly == false
    },failure:{[weak self] failure in self?.showHomeControlFailure(failure)})
    homeSessionStorage=session;return session
  }
  func setHomeControlsForeground(_ active:Bool) {
    homeForeground=active
    if active {homeControls.start()} else {homeSessionStorage?.stop()}
  }
  func homeControlState(_ slot:HomeControlSlot)->HomeControlOperationState {
    homeSessionStorage?.state(HomeMockControls.id(slot)) ?? .idle
  }
  func homeControlDescriptor(_ slot:HomeControlSlot)->HomeCharacteristicDescriptor? {
    homeControls.descriptor(HomeMockControls.id(slot))
  }
  func canWriteHomeControl(_ slot:HomeControlSlot)->Bool {homeControls.canWrite(HomeMockControls.id(slot))}
  var observedHome:MockHome {
    guard let homeSessionStorage else {return data.home}
    var result=data.home
    // Only values actually observed by the session replace this last-known local projection.
    for slot in HomeControlSlot.allCases {
      guard let value=homeSessionStorage.readings[HomeMockControls.id(slot)]?.value else {continue}
      switch slot {
      case .temperature:if let n=value.number {result.temperature=Int(n)}
      case .thermostatMode:result.thermostatMode=value.mode
      case .entryLight:if let b=value.flag {result.entryLight=b}
      case .bedroomLight:if let b=value.flag {result.bedroomLight=b}
      case .brightness:if let n=value.number {result.brightness=n}
      case .fan:if let b=value.flag {result.fan=b}
      case .fanSpeed:if let n=value.number {result.fanSpeed=n}
      case .blinds:if let n=value.number {result.blinds=n}
      }
    }
    return result
  }
  func stepHomeControl(_ slot:HomeControlSlot,direction:Int) {
    guard writableStore() else {return}
    guard let domain=homeControlDescriptor(slot)?.numeric,
      let current=homeControls.readings[HomeMockControls.id(slot)]?.value.number,
      let next=domain.next(from:current,direction:direction,continuousIncrement:slot == .temperature ? 1:10) else {return}
    requestHomeControl(slot,value:.number(next))
  }
  @discardableResult func requestHomeControl(_ slot:HomeControlSlot,value:HomeControlValue)->HomeControlOperationState {
    guard writableStore() else {return .failed(.readOnly)}
    let result=homeControls.request(HomeMockControls.id(slot),value:value);lastHomeCommandState=result
    if case .failed(let failure)=result {showHomeControlFailure(failure)}
    return result
  }
  private func showHomeControlFailure(_ failure:HomeControlFailure) {
    #if !os(watchOS)
      // A confirmed multi-step plan owns its per-step result presentation.
      // A second global alert hides that result and blocks the phone scroll path.
      if route == .assistant,demoPlan != nil {return}
    #endif
    error=failure.localizedDescription
  }
  func readMockControlSnapshot() throws -> MockHome {
    if ephemeral || storeReadOnly {return data.home}
    guard let bytes=try LocalStateFileReader.read(store) else {return data.home}
    return try Snapshot.decodeMigrating(bytes).home
  }
  @discardableResult func commitMockHomeControl(_ home:MockHome)->Bool {
    guard homeControlsActive,updateLocalControls({$0.home=home}) else {return false}
    do {
      guard try readMockControlSnapshot()==home else {throw HomeControlFailure.unverified}
      return true
    } catch {
      storeReadOnly=true;storeRecoveryNote="A mock device write could not be verified. Restart and recover saved state before writing again."
      return false
    }
  }
  #if !os(watchOS)
    let connections = DeviceConnections()
    @ObservationIgnored private var lockSessionStorage: LockActionSession?
    private var lockForeground=false
    var securityLock: LockActionSession {
      if let lockSessionStorage { return lockSessionStorage }
      let value=LockActionSession(provider:MockLockDevice(model:self),context:{ [weak self] in
        guard let self else { return LockAccessContext(generation:0,active:false,authenticated:false) }
        return LockAccessContext(generation:self.personalSessionGeneration,
          active:self.lockForeground && self.route == .lock && !self.incomingCall && self.demoDoorbell.current == nil,
          authenticated:self.canControlMockSecurity)
      })
      lockSessionStorage=value;return value
    }
    func revokeLockApproval() { lockSessionStorage?.revoke() }
    // Never publish the provider's just-written value as a UI success before its read-back.
    var observedMockLockState: LockReportedState {
      if let lockSessionStorage { return lockSessionStorage.reading?.state ?? .unknown }
      guard data.home.online else { return .unknown }
      return data.home.locked ? .locked:.unlocked
    }
    var observedMockLockSymbol: String {
      switch observedMockLockState {
      case .locked: "lock.fill"
      case .unlocked: "lock.open.fill"
      case .unknown,.jammed: "exclamationmark.shield"
      }
    }
    func setLockForeground(_ active: Bool) { lockForeground=active;if !active { revokeLockApproval() } }
    @discardableResult func commitMockLock(_ home: MockHome) -> Bool {
      guard lockForeground,route == .lock,canControlMockSecurity,
        lockSessionStorage?.phase == .sending,lockSessionStorage?.busy == true else { return false }
      return updateLocalControls { $0.home=home }
    }
    let houseNotices=HouseNoticeInbox()
    private var noticeDemoAnchor:Date?
    var houseNoticeStatus="No demo sequence loaded. Apple Home stays disconnected."
    let noticeHouseholds:Set<NoticeHousehold> = [.demoHouse]
    func loadHouseNoticeDemo() {
      let anchor=noticeDemoAnchor ?? clock
      switch houseNotices.ingest(HouseNoticeInbox.demoSequence(at:anchor),at:clock) {
      case .accepted:
        noticeDemoAnchor=anchor
        houseNoticeStatus="Mock sequence loaded. Replays ignore duplicate events."
      case .invalid:houseNoticeStatus="Demo sequence rejected: invalid event. History unchanged."
      case .conflict:houseNoticeStatus="Conflicting duplicate rejected. History unchanged."
      case .capacity:houseNoticeStatus="Demo history is full. Clear it explicitly before loading more."
      }
    }
    func clearHouseNotices() {
      houseNotices.clear();noticeDemoAnchor=nil
      houseNoticeStatus="Demo history cleared. No source or device was changed."
    }
    @discardableResult func openHouseNotice(_ key:HouseNoticeKey)->Bool {
      guard let target=houseNotices.destination(for:key,at:clock,allowed:noticeHouseholds,online:data.home.online) else {return false}
      switch target {
      case .home:route = .app(.home)
      case .cameras:route = .app(.cameras)
      case .door:route = .lock
      }
      return true
    }

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
    private var albumImportGeneration = 0
    private(set) var demoPlan:DemoActionPlan?
    private var demoPlanTask:Task<Void,Never>?
    private var demoPlanGeneration=0
    // A boundary before claim/mutation lets revocation stop the next step.
    @ObservationIgnored private var demoPlanBeforeStep:@MainActor () async -> Void = { await Task.yield() }
    var demoPlanBusy:Bool { demoPlan?.busy == true }
  #endif
  let demoDoorbell = DemoDoorbell()
  private let repeatedDoorbellFixtureID = UUID()
  var faceDirection = 1
  var data: Snapshot
  var route: Route = .face {
    didSet {
      #if !os(watchOS)
        if oldValue == .lock,route != .lock { revokeLockApproval() }
      #endif
      guard oldValue == .assistant,route != .assistant else { return }
      assistantAI.clear();stopAnswerSpeech();assistantDocument=nil
      #if !os(watchOS)
        discardDemoPlan(restoreDraft:true)
      #endif
    }
  }
  var showingIntroduction=false
  private(set) var localResetGeneration=0
  var showingLocalReset=false
  var localResetCleanupPending=false
  var localResetStatus="Authenticate, then confirm separately. Nothing is reset by opening this page."
  var localResetAuthorizing=false
  var localResetForeground=false
  var nativeSchedulesInFlight=0
  private var localResetAttempt=0
  private var localResetAuthorizedSession:Int?
  private var localResetAuthorizationDeadline:ContinuousClock.Instant?
  var localResetRequestGeneration:Int { localResetAttempt }
  var localResetAuthorized:Bool {
    localResetAuthorizedSession==personalSessionGeneration && localResetAuthorizedSession != nil
      && (localResetAuthorizationDeadline.map { ContinuousClock.now<$0 } ?? false)
  }
  var profile: String? = nil
  var pendingPage: AppPage? = nil
  var toast: String? = nil
  var error: String? = nil
  private(set) var storeReadOnly = false
  private(set) var storeRecoveryNote: String?
  let answerSpeech = AnswerSpeechSession(backend:makeAnswerSpeechBackend())
  let timerLiveActivity=TimerLiveActivitySession(backend:makeTimerActivityBackend())
  private var timerActivityForeground=false
  private var committedActivityTimers:[TimerActivityInput]=[]
  private var committedActivityEnabled=false
  private var timerActivityRevoked=false
  private(set) var timerActivityPreferenceSavePending=false
  var timerActivitiesEnabled:Bool {committedActivityEnabled && !timerActivityRevoked}
  var answerSpeechAttempt=0
  var authorizingAnswerSpeech=false
  var showAnswerSpeechStatus=false
  var preparingAnswerSpeech=false
  var answerSpeechForeground=false
  let assistantAI = AssistantConversation(provider:makeAssistantAnswers())
  private(set) var assistantUsesAI = false
  var assistantInput = ""
  private(set) var personalSessionGeneration = 0
  var assistantDeviceControl:HomeControlSlot?
  var assistantReply = "What can I help you with?" { didSet {assistantDocument=nil;assistantDeviceControl=nil} }
  private(set) var assistantDocument:AssistantResponseDocument?
  var playing = false
  var podcastPlaying = false
  var startingMusic = false
  var startingPodcast = false
  var audioGeneration = 0
  var sharedMusicIsPlaying: Bool {
    #if !os(watchOS)
    if connections.requested.contains(.music) {
      return connections.sharedMusicTrack != nil && connections.musicPlaying
    }
    #endif
    return playing
  }
  var sharedMusicTitle: String {
    #if !os(watchOS)
    if connections.requested.contains(.music) {
      return connections.sharedMusicTrack?.title ?? "Music not shared"
    }
    #endif
    return Fixtures.songs[song]
  }
  var sharedMusicSource: String {
    #if !os(watchOS)
    if connections.requested.contains(.music) {
      guard connections.sharedMusicTrack != nil else { return "Private · Not shared" }
      return "Shared · Apple Music"
    }
    #endif
    return "Demo Artist · Synthetic media"
  }
  func toggleSharedMusic() {
    #if !os(watchOS)
    if connections.requested.contains(.music),connections.sharedMusicTrack == nil {
      navigate(.music);return
    }
    #endif
    togglePlayback()
  }
  var currentMusicTitle: String {
    #if !os(watchOS)
      if connections.enabled.contains(.music) {
        guard connections.musicAccessAllowed else { return "Apple Music · Locked" }
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
        guard connections.musicAccessAllowed else { return "Device authentication required" }
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
      if connections.enabled.contains(.music) { return connections.musicAccessAllowed && connections.musicPlaying }
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
      updateLocalControls { $0.personal[name, default: PersonalContent()].messages = newValue }
    }
  }
  var reminders: [ReminderItem] {
    get {
      guard authorized, let name = profile else { return [] }
      return data.personal[name]?.reminders ?? []
    }
    set {
      guard authorized, let name = profile else { return }
      updateLocalControls { $0.personal[name, default: PersonalContent()].reminders = newValue }
    }
  }
  @discardableResult
  func addLocalReminder(_ title:String) -> Bool {
    guard authorized,let name=profile else { return false }
    return updateLocalControls { $0.personal[name,default:PersonalContent()].reminders.append(ReminderItem(title:title)) }
  }
  @discardableResult
  func appendLocalMessage(_ text:String) -> Bool {
    guard authorized,let name=profile else { return false }
    return updateLocalControls { $0.personal[name,default:PersonalContent()].messages.append(text) }
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
    guard updateLocalControls({
      if $0.photoAdjustments.count >= 100,$0.photoAdjustments[photoKey] == nil,
         let oldestKey=$0.photoAdjustments.keys.sorted().first {
        $0.photoAdjustments.removeValue(forKey:oldestKey)
      }
      $0.photoAdjustments[photoKey]=adjustment
    }) else { return }
    updatePhotoComposition()
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
  private let testReferenceLocale: Locale?
  private var idleLockApplied = false
  var lastInteraction = Date() { didSet { idleLockApplied = false } }
  var idleSeconds = 120.0
  let audio = LocalAudioEngine()
  let display = DisplayWakeController()
  private let store: URL
  private let ephemeral: Bool
  private let systemAlarmsAllowed: Bool
  #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
    private var nativeAlarms = NativeAlarmService()
    private var nativeScheduleTokens:[UUID:UUID]=[:]
    private var nativeScheduleTasks:[UUID:(token:UUID,task:Task<Void,Never>)]=[:]
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
    set { setRecipe(newValue) }
  }
  @discardableResult
  func setRecipe(_ value:RecipeDocument) -> Bool {
    guard updateLocalControls({
      $0.recipe=value
      $0.pinnedRecipe=$0.pinnedRecipes.contains { $0.id == value.id }
    }) else { return false }
    #if !os(watchOS)
      recipeHandoff.stop()
    #endif
    cookingStep=0;cookingInProgress=false
    return true
  }
  @discardableResult
  func addWorldCity(_ zone: String) -> Bool {
    guard data.worldClockZones.count < 12,
      WorldCity.city(for: zone) != nil,
      !data.worldClockZones.contains(zone) else { return false }
    return updateLocalControls { $0.worldClockZones.append(zone) }
  }
  func removeWorldCity(_ zone: String) {
    updateLocalControls { $0.worldClockZones.removeAll { $0 == zone } }
  }
  @discardableResult
  func pinRecipe() -> Bool {
    // Capture the selected document before a mutating access to Snapshot.
    // Reading the computed recipe inside removeAll overlaps data's write access.
    let selected=recipe
    if data.pinnedRecipes.contains(where: { $0.id == selected.id }) {
      return updateLocalControls {
        $0.pinnedRecipes.removeAll { $0.id == selected.id }
        $0.pinnedRecipe=false
      }
    }
    guard data.pinnedRecipes.count < 50 else {
      error = "You can save up to 50 recipes."
      return false
    }
    return updateLocalControls {
      $0.pinnedRecipes.append(selected)
      $0.pinnedRecipe=true
    }
  }
  var displayTimeZone: TimeZone {
    referenceClock ? (testReferenceTimeZone ?? TimeZone(secondsFromGMT:0)!) : .current
  }
  var calendarLocale:Locale {
    if referenceClock,ProcessInfo.processInfo.arguments.contains("--uitesting") {
      return testReferenceLocale ?? Locale(identifier:"en_US")
    }
    return .current
  }
  var calendarPresentation:CalendarPresentation {
    CalendarPresentation(date:clock,timeZone:displayTimeZone,locale:calendarLocale)
  }
  var monthLayout: MonthLayout { calendarPresentation.layout }
  func dateLabel(_ format: String) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US")
    f.timeZone = displayTimeZone
    f.dateFormat = format
    return f.string(from: clock)
  }
  var authorized: Bool { profile != nil && simulatedPresence }
  var canControlMockSecurity:Bool {
    #if !os(watchOS)
      GuestAccessPolicy.allows(.mockSecurity,role:connections.personalUnlocked ? .deviceAuthenticated:.guest)
    #else
      false
    #endif
  }
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
    testReferenceLocale = {
      guard args.contains("--uitesting"),let i=args.firstIndex(of:"--reference-locale"),
        args.indices.contains(i+1),args[i+1].count<=128,
        Locale.availableIdentifiers.contains(args[i+1]) else {return nil}
      return Locale(identifier:args[i+1])
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
    let cleanupExists=FileManager.default.fileExists(atPath:dir.appendingPathComponent("reset-cleanup.json").path)
    localResetCleanupPending=cleanupExists
    if cleanupExists {
      localResetStatus="A previous reset cleanup is incomplete. Open Reset to retry cleanup without resetting current content."
    }
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
    if testID != nil,args.contains("--uitesting"),args.contains("--personal-field-recovery-fixture"),
       !FileManager.default.fileExists(atPath:store.path) {
      do {
        var fixture=Snapshot();fixture.home.temperature=74;fixture.connectionConsent=[]
        var object=try JSONSerialization.jsonObject(with:JSONEncoder().encode(fixture)) as! [String:Any]
        let first=ReminderItem(title:"OWNED_JAMIE_FIRST_REMINDER")
        let last=ReminderItem(title:"OWNED_JAMIE_LAST_REMINDER")
        var duplicate=first;duplicate.title="OWNED_DUPLICATE_REMINDER"
        let firstObject=try JSONSerialization.jsonObject(with:JSONEncoder().encode(first))
        let lastObject=try JSONSerialization.jsonObject(with:JSONEncoder().encode(last))
        let duplicateObject=try JSONSerialization.jsonObject(with:JSONEncoder().encode(duplicate))
        let messages=["OWNED_ALEX_FIRST_MESSAGE","OWNED_ALEX_LAST_MESSAGE"]
        if args.contains("--personal-field-legacy") {
          object["personal"]=["Alex":["messages":messages],
            "Jamie":["reminders":[firstObject,lastObject]]] as [String:Any]
        } else {
          object["personal"]=[
            "Alex":["messages":[messages[0],17,NSNull(),messages[1]],"reminders":"broken"] as [String:Any],
            "Jamie":["messages":["not":"a list"],
              "reminders":[firstObject,NSNull(),["broken":true],duplicateObject,lastObject]] as [String:Any]
          ] as [String:Any]
        }
        let bytes=try JSONSerialization.data(withJSONObject:object,options:[.sortedKeys])
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        try bytes.write(to:store,options:.atomic)
        let digest=SHA256.hash(data:bytes).map {String(format:"%02x",$0)}.joined()
        try Data((digest+"\n").utf8).write(to:dir.appendingPathComponent("personal-fixture-sha256.txt"),options:.atomic)
      } catch { self.error="The owned personal-field fixture could not be prepared." }
    }
    if testID != nil,args.contains("--uitesting"),args.contains("--state-table-pressure-fixture"),
       !FileManager.default.fileExists(atPath:store.path) {
      do {
        var fixture=Snapshot();fixture.face = .modular;fixture.home.temperature=73
        fixture.connectionConsent=[]
        var timer=Countdown(title:"Owned pressure canary timer",seconds:90)
        timer.deadline=nil;timer.pausedRemaining=90;fixture.timers=[timer]
        var object=try JSONSerialization.jsonObject(with:JSONEncoder().encode(fixture)) as! [String:Any]
        var slots=Dictionary(uniqueKeysWithValues:(0..<64).map {
          (String(format:"AA-future-%03d",$0),"Clock")
        })
        slots["panel0"]="Weather";slots["panel1"]="Clock"
        var faces:[String:Any]=Dictionary(uniqueKeysWithValues:(0..<Face.allCases.count).map {
          (String(format:"AA-unknown-%03d",$0),["theme":0] as Any)
        })
        faces["Modular"]=["complications":slots,"theme":1]
        faces["Flow"]=["flowTypeface":1,"flowBackground":false,"theme":1]
        var profiles:[String:Any]=[:]
        for i in 0..<Fixtures.profiles.count {
          profiles[String(format:"AA-unknown-%03d",i)]=["messages":["UNUSED_SYNTHETIC_\(i)"],"reminders":[]] as [String:Any]
        }
        profiles["Alex"]=["messages":["OWNED_ALEX_PRIVATE_CANARY"],"reminders":[]] as [String:Any]
        profiles["Jamie"]=["messages":["OWNED_JAMIE_PRIVATE_CANARY"],"reminders":[]] as [String:Any]
        var adjustments:[String:Any]=Dictionary(uniqueKeysWithValues:(0..<100).map {
          (String(format:"AA-broken-%03d",$0),"not an adjustment object" as Any)
        })
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        #if !os(watchOS)
          guard let photo=PhotoLayoutFixture.make("top") else { throw CocoaError(.fileReadUnknown) }
          try photo.bytes.write(to:dir.appendingPathComponent("selected-photo.data"),options:.atomic)
          let adjustmentKey=SHA256.hash(data:photo.bytes).map {String(format:"%02x",$0)}.joined()
        #else
          let adjustmentKey="synthetic"
        #endif
        adjustments[adjustmentKey]=["clock":"bottom","automaticCrop":false,"horizontal":0.23,"vertical":0.77]
        object["faceConfigurations"]=faces;object["personal"]=profiles;object["photoAdjustments"]=adjustments
        let bytes=try JSONSerialization.data(withJSONObject:object,options:[.sortedKeys])
        try bytes.write(to:store,options:.atomic)
        let digest=SHA256.hash(data:bytes).map {String(format:"%02x",$0)}.joined()
        try Data((digest+"\n").utf8).write(to:dir.appendingPathComponent("table-fixture-sha256.txt"),options:.atomic)
      } catch { self.error="The owned table-recovery fixture could not be prepared." }
    }
    if testID != nil,args.contains("--uitesting"),args.contains("--reset-content-fixture"),
       !FileManager.default.fileExists(atPath:store.path) {
      do {
        var seeded=Snapshot();seeded.introduction = .completed
        seeded.connectionConsent=[.calendar,.music]
        seeded.personal["Alex"]=PersonalContent()
        seeded.personal["Alex"]!.messages=["SYNTHETIC_RESET_LOCAL_MESSAGE"]
        seeded.timers=[Countdown(title:"Synthetic reset timer",seconds:3600)]
        let bytes=try JSONEncoder().encode(seeded)
        try FileManager.default.createDirectory(at:dir.appendingPathComponent("State Recovery"),withIntermediateDirectories:true)
        try FileManager.default.createDirectory(at:dir.appendingPathComponent("photos"),withIntermediateDirectories:true)
        try bytes.write(to:store,options:.atomic)
        try bytes.write(to:dir.appendingPathComponent("State Recovery/reset-fixture.json"))
        try Data("SYNTHETIC_ORPHAN_PHOTO_COPY".utf8).write(to:dir.appendingPathComponent("photos/orphan.jpg"))
        #if canImport(Darwin) && !os(watchOS)
          if args.contains("--reset-fifo-fixture") {
            guard mkfifo(dir.appendingPathComponent("pending.pipe").path,mode_t(0o600))==0 else {
              throw CocoaError(.fileWriteUnknown)
            }
          }
        #endif
      } catch { self.error="The owned reset fixture could not be prepared." }
    }
    if !ephemeral {
      do {
        // Missing is fresh state; dangling links and unsafe nodes are not missing.
        if let bytes=try LocalStateFileReader.read(store) {
          let saved = try Snapshot.decodeMigrating(bytes)
          let normalized = try JSONEncoder().encode(saved)
          if try Snapshot.canonicalBytes(bytes) != Snapshot.canonicalBytes(normalized) {
            try preserveOriginalStore(bytes)
            storeRecoveryNote = "Supported saved fields recovered. The original file was preserved."
          }
          data = saved
        }
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
    committedActivityTimers=data.timers.map {TimerActivityInput(deadline:$0.deadline,pausedRemaining:$0.pausedRemaining)}
    committedActivityEnabled=data.timerLiveActivitiesEnabled
  }
  func setTimerActivityForeground(_ foreground:Bool) {
    timerActivityForeground=foreground;synchronizeTimerActivity()
  }
  func synchronizeTimerActivity(requestStart:Bool=false) {
    timerLiveActivity.synchronize(TimerActivityState.project(committedActivityTimers,at:Date()),
      enabled:timerActivitiesEnabled && !storeReadOnly,foreground:timerActivityForeground,
      requestStart:requestStart)
  }
  private func commitTimerActivityProjection() {
    committedActivityTimers=data.timers.map {TimerActivityInput(deadline:$0.deadline,pausedRemaining:$0.pausedRemaining)}
    committedActivityEnabled=data.timerLiveActivitiesEnabled
    synchronizeTimerActivity()
  }
  func setTimerLiveActivities(_ enabled:Bool) {
    // Revocation is effective now even if saving the preference is impossible.
    if !enabled {timerActivityRevoked=true;synchronizeTimerActivity()}
    guard updateLocalControls({$0.timerLiveActivitiesEnabled=enabled}) else {
      if !enabled {timerActivityPreferenceSavePending=true}
      return
    }
    timerActivityPreferenceSavePending=false;timerActivityRevoked = !enabled
    synchronizeTimerActivity(requestStart:enabled)
  }
  func showTimerLiveActivity() {synchronizeTimerActivity(requestStart:true)}
  func setPhoto(_ bytes: Data?) {
    guard (bytes?.count ?? 0) <= 40_000_000 else {
      error = "Choose a photo smaller than 40 MB."
      return
    }
    guard storePhotos(bytes.map { [$0] } ?? [],selection:bytes == nil ? .none:.single,
      title:nil,album:nil,assets:[],navigate:true) else { return }
    #if !os(watchOS)
      albumImportGeneration += 1
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
      albumImportGeneration += 1
      albumRefreshTask?.cancel()
      albumUpdates.stop(clearDisplay:false)
    #endif
    return true
  }
  func openPhotoFace() {
    guard updateLocalControls({ $0.face = .photos }) else { return }
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
    guard !Task.isCancelled,connections.personalUnlocked,albumCatalogue.albums.contains(album) else { return }
    guard albumPhotoProvider.authorizationGranted() else {
      albumCatalogue.invalidate(locked:false)
      error="Photos access is required before importing an album."
      return
    }
    let generation=personalSessionGeneration
    albumImportGeneration += 1
    let request=albumImportGeneration
    do {
      let batch=try await albumPhotoProvider.readAlbum(album.id,known:[])
      guard !Task.isCancelled,connections.personalUnlocked,personalSessionGeneration == generation,
            albumImportGeneration == request else { return }
      guard albumPhotoProvider.authorizationGranted() else {
        albumCatalogue.invalidate(locked:false)
        error="Photos access was revoked. The album was not imported."
        return
      }
      let values=batch.orderedIDs.compactMap { id in batch.photos.first { $0.id == id }?.bytes }
      guard !values.isEmpty else { error="No photos could be imported.";return }
      _ = setGallery(values,title:album.title)
    } catch {
      guard !Task.isCancelled,connections.personalUnlocked,personalSessionGeneration == generation,
            albumImportGeneration == request else { return }
      self.error="The selected album could not be imported."
    }
  }
  func linkAlbumForDisplay(_ album:DisplayAlbum) {
    guard connections.personalUnlocked,albumCatalogue.albums.contains(album) else { return }
    if albumUpdates.select(album,deviceAuthenticated:connections.personalUnlocked,explicitDisplayConsent:true) {
      albumImportGeneration += 1
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
    albumImportGeneration += 1
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
      guard try LocalStateFileReader.read(backup) == bytes else { throw SnapshotReadError.malformed }
    } else {
      let existing = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
      guard existing.filter({ $0.lastPathComponent.hasPrefix("original-") }).count < 8 else {
        throw SnapshotReadError.oversized
      }
      try bytes.write(to: backup, options: .atomic)
      guard try LocalStateFileReader.read(backup) == bytes else { throw SnapshotReadError.malformed }
    }
  }
  private func writableStore() -> Bool {
    guard !storeReadOnly else { error = storeRecoveryNote; return false }
    return true
  }
  #if !os(watchOS)
  func presentLocalReset() {
    localResetAttempt+=1;localResetAuthorizedSession=nil;localResetAuthorizing=false
    localResetStatus=localResetCleanupPending
      ? "A previous reset cleanup is incomplete. Authenticate and confirm to retry only that cleanup; current content is not reset again."
      : "Authenticate, then confirm separately. Nothing is reset by opening this page."
    interact();showingLocalReset=true
  }
  func cancelLocalReset() {
    localResetAttempt+=1;localResetAuthorizedSession=nil;localResetAuthorizing=false
    showingLocalReset=false
  }
  func authorizeLocalReset(expectedAttempt:Int) async {
    guard !Task.isCancelled,expectedAttempt==localResetAttempt,localResetForeground,showingLocalReset,
      route == .app(.settings),!localResetAuthorizing else { return }
    interact()
    localResetAttempt+=1;let attempt=localResetAttempt,session=personalSessionGeneration
    localResetAuthorizing=true;localResetAuthorizedSession=nil
    defer { if localResetAttempt==attempt { localResetAuthorizing=false } }
    let granted=await authenticateLocalResetOwner()
    // A native auth overlay may finish just before the scene becomes active.
    for _ in 0..<100 {
      guard !Task.isCancelled,localResetAttempt==attempt,personalSessionGeneration==session,
        showingLocalReset,route == .app(.settings) else { return }
      if localResetForeground { break }
      try? await Task.sleep(nanoseconds:20_000_000)
    }
    guard !Task.isCancelled,localResetAttempt==attempt,personalSessionGeneration==session,
      showingLocalReset,localResetForeground,route == .app(.settings) else { return }
    if granted {
      localResetAuthorizedSession=session
      localResetAuthorizationDeadline=ContinuousClock.now.advanced(by:.seconds(60))
      localResetStatus="Authenticated. Nothing has been reset. Type RESET, then use the separate reset button."
    } else { localResetStatus="Device authentication was not granted. Nothing was reset." }
  }
  @discardableResult
  func resetLocalAppData(confirmation:String)->Bool {
    guard !Task.isCancelled,confirmation=="RESET",localResetAuthorized,
      localResetForeground,showingLocalReset,route == .app(.settings) else {
      localResetStatus="A fresh device authentication and exact RESET confirmation are required. Nothing was reset."
      return false
    }
    guard !localResetCleanupPending else {
      localResetStatus="Finish the pending cleanup first. A new reset must not discard its recovery record."
      return false
    }
    guard !storeReadOnly else {
      localResetStatus="This saved state is read-only or from a newer version. Nothing was reset; recover or export it first."
      return false
    }
    guard nativeSchedulesInFlight==0 else {
      localResetStatus="A system-alarm request is still in progress. Wait for it to finish or cancel it before resetting."
      return false
    }
    guard data.nativeTimerIDs.isEmpty,data.nativeAlarmIDs.isEmpty else {
      localResetStatus="Cancel the app’s registered system timers and alarms first. Reset will not forget or silently cancel them."
      return false
    }
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      if systemAlarmsAllowed {
        do { guard try nativeAlarms.canResetLocalState() else {
          localResetStatus="HomeView still has a system alarm. Cancel it before resetting local data."
          return false
        } } catch {
          localResetStatus="System-alarm state could not be verified. Nothing was reset. Resolve alarm access in system settings first."
          return false
        }
      }
    #endif
    let fresh:Snapshot,removed:Bool,pathOwned:Bool
    do {
      if ephemeral {
        var empty=Snapshot();empty.photoSelection = .none;empty.connectionConsent=[]
        fresh=empty;removed=true;pathOwned=true
      } else {
        let result=try LocalStateReset.reset(directory:store.deletingLastPathComponent())
        fresh=result.snapshot;removed=result.oldFilesRemoved;pathOwned=result.storagePathOwned
      }
    } catch LocalResetError.cleanupPending {
      localResetCleanupPending=true
      localResetStatus="A previous reset cleanup is incomplete. Retry that cleanup instead of resetting new content."
      return false
    } catch LocalResetError.storagePathChanged {
      storeReadOnly=true;storeRecoveryNote="Storage identity changed during reset. Further local writes are blocked."
      localResetStatus="Storage identity changed. Nothing further is written; restart recovery is required."
      return false
    } catch {
      localResetStatus="Local data could not be replaced. The previous saved state was not reset."
      return false
    }
    // No await between the synchronous file commit and revoking old actor writers.
    localResetGeneration+=1;podcastFeedGeneration+=1;podcastLoading=false
    podcastPlayer.stop();podcastPlaying=false;podcastStatus="Public RSS feeds · No Apple Podcasts account sync"
    albumRefreshTask?.cancel();albumUpdates.stop(clearDisplay:false);albumCatalogue.invalidate()
    lockPersonalAccess();connections.resetLocalPreferences();clearHouseNotices()
    audioGeneration+=1;startingMusic=false;startingPodcast=false
    playing=false;audio.stopAll()
    error=nil;storeRecoveryNote=nil
    if !pathOwned {
      storeReadOnly=true;storeRecoveryNote="Storage identity changed during reset. Further local writes are blocked."
    }
    timerActivityRevoked=true;timerActivityPreferenceSavePending=false
    data=fresh;commitTimerActivityProjection();gallery=[];photoIndex=0;showPhoto(nil)
    pendingPage=nil;simulatedPresence=true
    referenceClock=ProcessInfo.processInfo.arguments.contains("--reference-clock")
    answerSpeech.resetPreferences();showAnswerSpeechStatus=false
    localResetCleanupPending = !removed
    selectedTimer=nil;cookingInProgress=false;cookingStep=0;song=0;progress=0
    incomingCall=false;talking=false;intercomHistory=[];intercomText="Dinner is ready!"
    muted=false;videoEnabled=true;ringLight=true;mirrorZoom=1
    display.apply(enabled:false);audio.setVolume(Float(data.volume))
    showingIntroduction=false;showingLocalReset=false;localResetAuthorizedSession=nil;localResetAttempt+=1
    localResetStatus = !pathOwned
      ? "New local state was prepared, but the storage path changed. Further writes are blocked; restart recovery is required."
      : removed ? "Local app content reset. Source libraries and OS permissions were not deleted."
      : "New local state is active, but old reset files or their cleanup record could not be fully removed. Cleanup needs attention."
    interact();route = .app(.settings)
    return true
  }
  @discardableResult
  func retryLocalResetCleanup(confirmation:String)->Bool {
    guard !Task.isCancelled,confirmation=="RESET",localResetAuthorized,
      localResetForeground,showingLocalReset,route == .app(.settings),!storeReadOnly,
      localResetCleanupPending else { return false }
    let removed=LocalStateReset.retryCleanup(directory:store.deletingLastPathComponent())
    localResetAuthorizedSession=nil;localResetAuthorizationDeadline=nil
    if removed {
      localResetCleanupPending=false
      localResetStatus="Old reset files and their cleanup record removed. Current app content is unchanged."
      showingLocalReset=false
    } else {
      localResetStatus="Old reset cleanup could not be fully verified. Its record is retained; current app content is unchanged."
    }
    return removed
  }
  func connectService(_ kind:DataConnection,expectedResetGeneration:Int) async {
    guard !Task.isCancelled,expectedResetGeneration==localResetGeneration else { return }
    guard kind != .music || connections.personalUnlocked else {
      error="Authenticate before connecting Apple Music. A demo profile is not device authentication.";return
    }
    let previous=data.connectionConsent
    var choices=previous ?? connections.requested;choices.insert(kind)
    data.connectionConsent=choices
    guard persist() else { data.connectionConsent=previous;return }
    await connections.connect(kind,date:clock,timeZone:displayTimeZone)
  }
  func beginGuestMusicUse() {
    guard connections.guestMusicShared,connections.musicAccessAllowed else { return }
    lockPersonalAccess();pendingPage=nil;route = .app(.music)
  }
  @discardableResult
  func disconnectService(_ kind:DataConnection)->Bool {
    let previous=data.connectionConsent
    var choices=previous ?? connections.requested;choices.remove(kind)
    data.connectionConsent=choices
    guard persist() else { data.connectionConsent=previous;return false }
    connections.disconnect(kind);return true
  }
  #endif
  func presentIntroductionOnLaunch() {
    let args=ProcessInfo.processInfo.arguments
    guard !storeReadOnly,data.introduction == .pending,
      !args.contains("--uitesting") || args.contains("--setup-introduction-fixture") else { return }
    showingIntroduction=true
  }
  @discardableResult
  func endIntroduction(deferred:Bool,openConnections:Bool=false)->Bool {
    // An informational sheet must never trap a recovered/read-only app.
    if deferred && storeReadOnly { showingIntroduction=false;return true }
    let previous=data.introduction
    data.introduction=deferred && previous != .completed ? .deferred:.completed
    guard persist() else {
      data.introduction=previous
      if deferred {
        showingIntroduction=false
        error="Introduction closed without saving. It may appear again after restart."
        return true
      }
      return false
    }
    showingIntroduction=false
    if openConnections { route = .app(.settings) }
    return true
  }
  @discardableResult
  func updateLocalControls(_ change: (inout Snapshot) -> Void) -> Bool {
    guard writableStore() else { return false }
    let previous = data
    change(&data)
    guard persist() else { data = previous; return false }
    if data.volume != previous.volume { audio.setVolume(Float(data.volume)) }
    return true
  }
  @discardableResult
  func persist() -> Bool {
    guard !ephemeral else { commitTimerActivityProjection();homeDeviceStorage?.publishChanges();return true }
    guard writableStore() else { return false }
    do {
      try FileManager.default.createDirectory(
        at: store.deletingLastPathComponent(), withIntermediateDirectories: true)
      try JSONEncoder().encode(data).write(to: store, options: .atomic)
      commitTimerActivityProjection()
      homeDeviceStorage?.publishChanges()
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
    lastHomeCommandState = .idle
    if case .lock=command {
      error="Open Front Door and confirm the mock security action separately. No command sent."
      return
    }
    guard writableStore() else {lastHomeCommandState = .failed(.readOnly);return}
    let control:(HomeControlSlot,HomeControlValue)? = switch command {
    case .temperature(let value):(.temperature,.number(Double(value)))
    case .thermostatMode(let value):(.thermostatMode,.mode(value))
    case .entryLight:(.entryLight,.flag(!observedHome.entryLight))
    case .bedroomLight:(.bedroomLight,.flag(!observedHome.bedroomLight))
    case .brightness(let value):(.brightness,.number(value))
    case .fan:(.fan,.flag(!observedHome.fan))
    case .fanSpeed(let value):(.fanSpeed,.number(value))
    case .blinds(let value):(.blinds,.number(value))
    case .lock,.scene:nil
    }
    if let (slot,value)=control {requestHomeControl(slot,value:value);return}
    do {
      // Scenes are still local mocks. Preserve the latest unrelated device
      // values/audit and honour current offline or unreadable stored state.
      var candidate=try readMockControlSnapshot()
      let before=HomeMockControls.values(candidate)
      try candidate.transact(command,authorized:canControlMockSecurity)
      let after=HomeMockControls.values(candidate)
      for slot in HomeControlSlot.allCases where before[HomeMockControls.id(slot)] != after[HomeMockControls.id(slot)] {
        guard canWriteHomeControl(slot),let value=after[HomeMockControls.id(slot)],
          homeControlDescriptor(slot)?.accepts(value,forWrite:true) == true else {throw HomeControlFailure.unavailable}
      }
      guard commitMockHomeControl(candidate) else {lastHomeCommandState = .unverified;return}
      lastHomeCommandState = .confirmed
    } catch { self.error = error.localizedDescription;lastHomeCommandState = .failed(.unavailable) }
  }
  func navigate(_ page: AppPage) {
    if demoDoorbell.current != nil { dismissDemoDoorbell() }
    interact()
    #if !os(watchOS)
      if page == .calendar && connections.requested.contains(.calendar)
        || page == .reminders && connections.requested.contains(.reminders)
        || page == .music && connections.enabled.contains(.music) && !connections.musicAccessAllowed
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
    if data.personal[name] == nil {
      guard updateLocalControls({ $0.personal[name] = PersonalContent() }) else { return }
    }
    profile = name
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
      revokeLockApproval()
      discardDemoPlan()
    #endif
    localResetAttempt+=1;localResetAuthorizedSession=nil;localResetAuthorizationDeadline=nil
    localResetAuthorizing=false
    stopAnswerSpeech()
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
    let all = Face.allCases
    let index = all.firstIndex(of: data.face) ?? 0
    guard updateLocalControls({ $0.face = all[(index + delta + all.count) % all.count] }) else { return }
    faceDirection = delta
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
    homeSessionStorage?.tick()
    #if !os(watchOS)
      lockSessionStorage?.expireApproval()
    #endif
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
    if now.timeIntervalSince(lastInteraction) > idleSeconds {
      // Private authority expires independently of the visible surface. A face
      // or incoming demo call must not keep it alive. Revoke once per idle
      // period; a real interaction arms the next deadline again.
      if !idleLockApplied {
        idleLockApplied = true
        lockPersonalAccess()
      }
      if route != .face && !incomingCall && !showingLocalReset && !showingIntroduction {
        route = .face
      }
    }
    var candidate=data
    var completions:[(timerID:UUID?,message:String,chime:Bool)]=[]
    for i in candidate.timers.indices
    where !candidate.timers[i].didAlert && candidate.timers[i].remaining(at:now)<=0 {
      candidate.timers[i].didAlert=true
      let timer=candidate.timers[i]
      completions.append((timer.id,"\(timer.title) finished",!candidate.nativeTimerIDs.contains(timer.id)))
    }
    let cal=Calendar.current
    for i in candidate.alarms.indices {
      let id=candidate.alarms[i].id
      // Native alarms remain OS-owned; reconciliation handles stopped/deleted
      // entries. Do not prematurely disable one while its native alert is active.
      guard !candidate.nativeAlarmIDs.contains(id) else { continue }
      if candidate.alarms[i].acknowledgeForegroundOccurrence(at:now,calendar:cal) {
        completions.append((nil,"Alarm",true))
      }
    }
    // Commit the local receipt before any banner/readout interruption/chime
    // request. A failed write must not acknowledge the same event twice after
    // restart. This is not an atomic transaction with an OS alarm or speaker.
    if !completions.isEmpty,updateLocalControls({ $0=candidate }) {
      for completion in completions {
        if let id=completion.timerID { selectedTimer=id }
        banner(completion.message)
        if completion.chime { playChime() }
      }
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
    synchronizeTimerActivity(requestStart:true)
    scheduleNativeTimer(timer)
    return true
  }
  #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
    /// A failed local save must not dispatch a system effect. If the effect
    /// fails, restore the last committed state; surface a failed rollback too.
    private func updateNativeAlarmState(_ change:(inout Snapshot)->Void,effect:() throws -> Void) -> Bool {
      let previous=data
      guard updateLocalControls(change) else { return false }
      do {try effect();return true}
      catch {
        data=previous
        let restored=persist()
        if !restored {storeReadOnly=true}
        self.error=restored ? "Could not update the system alert. The previous local state was restored."
          : "Could not update the system alert or restore its saved state. Local writes are blocked; check system alerts before restarting."
        return false
      }
    }
    private func invalidateNativeSchedule(_ id:UUID) {nativeScheduleTokens.removeValue(forKey:id)}
    /// Serialize each system identity: cleanup of an old completion must finish
    /// before its replacement starts. Different identities remain independent.
    private func queueNativeSchedule(_ id:UUID,wanted:@escaping @MainActor ()->Bool,
      schedule:@escaping @MainActor (@escaping @MainActor ()->Bool) async throws -> Bool,
      record:@escaping (inout Snapshot)->Void) {
      let predecessor=nativeScheduleTasks[id]?.task,token=UUID()
      nativeScheduleTokens[id]=token;nativeSchedulesInFlight+=1
      let task=Task {
        defer {
          nativeSchedulesInFlight-=1
          if nativeScheduleTasks[id]?.token==token {nativeScheduleTasks.removeValue(forKey:id)}
          if nativeScheduleTokens[id]==token {nativeScheduleTokens.removeValue(forKey:id)}
        }
        if let predecessor {await predecessor.value}
        let isCurrent: @MainActor ()->Bool = {
          self.nativeScheduleTokens[id]==token && !Task.isCancelled && !self.storeReadOnly && wanted()
        }
        guard isCurrent() else {return}
        do {
          do {guard try await schedule(isCurrent) else {return}}
          catch {
            guard nativeScheduleTokens[id]==token,wanted() else {return}
            throw error
          }
          guard nativeScheduleTokens[id]==token,!Task.isCancelled,wanted() else {
            try nativeAlarms.cancel(id);return
          }
          // No uncommitted ownership claim: undo the new system schedule if
          // recording it fails. A failed cleanup is explicit, never success.
          guard updateLocalControls(record) else {try nativeAlarms.cancel(id);return}
        } catch {
          // A failed stale cleanup still needs attention; suppressing it would
          // hide a potentially orphaned system alert.
          self.error="System alert scheduling or cleanup failed. Check system alerts. \(error.localizedDescription)"
        }
      }
      nativeScheduleTasks[id]=(token,task)
    }
  #endif
  private func scheduleNativeTimer(_ timer:Countdown) {
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      guard systemAlarmsAllowed,let deadline=timer.deadline else {return}
      queueNativeSchedule(timer.id,wanted:{
        self.data.timers.contains {$0.id==timer.id && $0.deadline==deadline && !$0.didAlert}
      },schedule:{ isCurrent in
        try await self.nativeAlarms.scheduleTimer(id:timer.id,deadline:deadline,title:timer.title,isCurrent:isCurrent)
      },record:{$0.nativeTimerIDs.insert(timer.id)})
    #endif
  }
  func toggleTimer(_ id: UUID) {
    guard writableStore() else { return }
    guard let i=data.timers.firstIndex(where: { $0.id==id }) else { return }
    let pause=data.timers[i].deadline != nil,at=now
    let change:(inout Snapshot)->Void = { state in
      if pause { state.timers[i].pause(at:at) }
      else { state.timers[i].resume(at:at) }
    }
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      if data.nativeTimerIDs.contains(id) {
        if updateNativeAlarmState(change,effect:{
          if pause { try nativeAlarms.pause(id) }
          else { try nativeAlarms.resume(id) }
        }) {
          invalidateNativeSchedule(id)
          if !pause {synchronizeTimerActivity(requestStart:true)}
        }
        return
      }
    #endif
    guard updateLocalControls(change) else {return}
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      invalidateNativeSchedule(id)
    #endif
    if !pause {synchronizeTimerActivity(requestStart:true);scheduleNativeTimer(data.timers[i])}
  }
  func removeTimer(_ id: UUID) {
    guard writableStore() else { return }
    let change:(inout Snapshot)->Void = {
      $0.timers.removeAll { $0.id==id }
      $0.nativeTimerIDs.remove(id)
    }
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      if data.nativeTimerIDs.contains(id) {
        if updateNativeAlarmState(change,effect:{try nativeAlarms.cancel(id)}) {invalidateNativeSchedule(id)}
        return
      }
    #endif
    if updateLocalControls(change) {
      #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
        invalidateNativeSchedule(id)
      #endif
    }
  }
  func addAlarm(hour: Int, minute: Int, recurrence: AlarmRecurrence = .once) {
    guard writableStore() else { return }
    guard (0...23).contains(hour), (0...59).contains(minute), data.alarms.count < 24 else {
      error = "Choose a valid time, up to 24 alarms."
      return
    }
    let alarm = AlarmItem(hour: hour, minute: minute, recurrence: recurrence, armedAfter: Date())
    data.alarms.append(alarm)
    guard persist() else { data.alarms.removeAll { $0.id == alarm.id }; return }
    scheduleNativeAlarm(alarm)
  }
  private func scheduleNativeAlarm(_ alarm: AlarmItem) {
    guard writableStore() else { return }
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      guard systemAlarmsAllowed else {return}
      queueNativeSchedule(alarm.id,wanted:{
        self.data.alarms.contains {$0.id==alarm.id && $0.enabled && $0.hour==alarm.hour && $0.minute==alarm.minute && $0.recurrence==alarm.recurrence}
      },schedule:{ isCurrent in
        try await self.nativeAlarms.scheduleAlarm(id:alarm.id,hour:alarm.hour,minute:alarm.minute,recurrence:alarm.recurrence,isCurrent:isCurrent)
      },record:{$0.nativeAlarmIDs.insert(alarm.id)})
    #endif
  }
  func toggleAlarm(_ id: UUID) {
    guard writableStore() else { return }
    guard let i=data.alarms.firstIndex(where: { $0.id==id }) else { return }
    let enabled = !data.alarms[i].enabled
    let change:(inout Snapshot)->Void = {
      $0.alarms[i].enabled=enabled
      if enabled { $0.alarms[i].armedAfter=Date() }
      if !enabled { $0.nativeAlarmIDs.remove(id) }
    }
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      if !enabled,data.nativeAlarmIDs.contains(id) {
        if updateNativeAlarmState(change,effect:{try nativeAlarms.cancel(id)}) {invalidateNativeSchedule(id)}
        return
      }
    #endif
    guard updateLocalControls(change) else { return }
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      invalidateNativeSchedule(id)
    #endif
    // Never queue even a permitted native schedule for an unsaved enable.
    if enabled { scheduleNativeAlarm(data.alarms[i]) }
  }
  func removeAlarm(_ id: UUID) {
    guard writableStore() else { return }
    let change:(inout Snapshot)->Void = {
      $0.alarms.removeAll { $0.id==id }
      $0.nativeAlarmIDs.remove(id)
    }
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      if data.nativeAlarmIDs.contains(id) {
        if updateNativeAlarmState(change,effect:{try nativeAlarms.cancel(id)}) {invalidateNativeSchedule(id)}
        return
      }
    #endif
    if updateLocalControls(change) {
      #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
        invalidateNativeSchedule(id)
      #endif
    }
  }
  func reconcileSystemAlarms() {
    guard !storeReadOnly else { return }
    #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
      guard !data.nativeTimerIDs.isEmpty || !data.nativeAlarmIDs.isEmpty else { return }
      do {
        let active = try nativeAlarms.activeIDs()
        updateLocalControls { state in
          for i in state.alarms.indices
          where state.nativeAlarmIDs.contains(state.alarms[i].id) && !active.contains(state.alarms[i].id)
          {state.alarms[i].enabled=false}
          state.nativeAlarmIDs.formIntersection(active)
          for i in state.timers.indices
          where state.nativeTimerIDs.contains(state.timers[i].id) && !active.contains(state.timers[i].id) {
            state.timers[i].pausedRemaining=0;state.timers[i].deadline=nil;state.timers[i].didAlert=true
          }
          state.nativeTimerIDs.formIntersection(active)
        }
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
  /// Model authorization, not merely a hidden/disabled UI control. No profile,
  /// source permission or device unlock grants implicit assistant context access.
  var assistantInteractionActive:Bool {
    answerSpeechForeground && route == .assistant
      && demoDoorbell.current == nil && !incomingCall
  }
  func selectAssistantAnswers(_ enabled:Bool) {
    guard !enabled || assistantInteractionActive else { return }
    #if !os(watchOS)
      discardDemoPlan()
    #endif
    stopAnswerSpeech();assistantDocument=nil
    assistantAI.deselect();assistantUsesAI=enabled
    if enabled { assistantAI.select() }
  }
  #if !os(watchOS)
  private var demoPlanContextActive:Bool {
    // Root updates this scene-active flag for all assistant interaction.
    assistantInteractionActive && !assistantUsesAI
  }
  func discardDemoPlan(restoreDraft:Bool=false) {
    let previous=demoPlan
    demoPlanGeneration+=1;demoPlanTask?.cancel();demoPlanTask=nil
    demoPlan=nil
    if restoreDraft,let previous,previous.context==personalSessionGeneration,
      answerSpeechForeground,assistantInput.isEmpty,previous.phase == .preview {
      assistantInput=previous.request
    }
  }
  func cancelDemoPlan() {
    demoPlanGeneration+=1;demoPlanTask?.cancel();demoPlanTask=nil
    guard var plan=demoPlan else { return }
    plan.cancel();demoPlan=plan;assistantReply=plan.note
  }
  private func prepareDemoPlanIfRequested()->Bool {
    if demoPlanBusy {
      assistantReply="Cancel the running demo plan before sending another request."
      return true
    }
    switch DemoActionPlan.parse(assistantInput,context:personalSessionGeneration,
      uptime:ProcessInfo.processInfo.systemUptime) {
    case .notAPlan: return false
    case .rejected(let message):
      discardDemoPlan();assistantReply=message
    case .proposal(let plan):
      discardDemoPlan()
      guard demoPlanContextActive else {
        assistantReply="Open the active Assistant to review a local demo plan. Nothing ran."
        return true
      }
      demoPlan=plan
      assistantReply="Review the local demo plan below. Sending only creates a preview; no step has run."
    }
    assistantInput=""
    return true
  }
  @discardableResult
  func confirmDemoPlan(id:UUID)->Bool {
    guard !Task.isCancelled,var plan=demoPlan else { return false }
    guard !storeReadOnly else {
      plan.cancel(note:"Saved state is read-only. No plan step ran.")
      demoPlan=plan;assistantReply=plan.note;return false
    }
    guard let token=plan.confirm(id:id,context:personalSessionGeneration,
      uptime:ProcessInfo.processInfo.systemUptime,active:demoPlanContextActive) else {
      demoPlan=plan;assistantReply=plan.note;return false
    }
    stopAnswerSpeech();interact();demoPlan=plan
    let generation=demoPlanGeneration,context=personalSessionGeneration
    demoPlanTask=Task { [weak self] in
      while let self {
        await self.demoPlanBeforeStep()
        guard !Task.isCancelled,self.demoPlanGeneration==generation,
          self.personalSessionGeneration==context,self.demoPlan?.id==id else { return }
        guard self.demoPlanContextActive else { self.discardDemoPlan();return }
        guard var current=self.demoPlan,let step=current.claimNext(token:token) else { break }
        self.demoPlan=current
        // Local mutation, persistence and read-back contain no await. Cancellation
        // can stop the next step, but cannot invent rollback of a committed one.
        let outcome=self.applyDemoPlanStep(step)
        guard self.demoPlanGeneration==generation,var result=self.demoPlan,result.id==id else { return }
        result.record(step:step.id,token:token,result:outcome)
        self.demoPlan=result;self.assistantReply=result.note
        if !result.busy { break }
      }
      if let self,self.demoPlanGeneration==generation { self.demoPlanTask=nil }
    }
    return true
  }
  private var canonicalPlanStore:Data {
    get throws {
      guard let bytes=try LocalStateFileReader.read(store) else { throw SnapshotReadError.malformed }
      return try Snapshot.canonicalBytes(bytes)
    }
  }
  private func applyDemoPlanStep(_ step:DemoActionPlan.Step)->DemoActionPlan.Result {
    guard demoPlanContextActive,!storeReadOnly else { return .failed("Local demo authorization is no longer active.") }
    let device:(HomeControlSlot,HomeControlValue)? = switch step.operation {
    case .temperature(let value):(.temperature,.number(Double(value)))
    case .brightness(let value):(.brightness,.number(Double(value)))
    case .foregroundTimer:nil
    }
    if let (slot,value)=device {
      switch requestHomeControl(slot,value:value) {
      case .confirmed:return .confirmed(step.operation.summary+" · Device state read back")
      case .failed(let failure):return .failed(failure.localizedDescription)
      default:return .unverified("Device outcome is not confirmed. Further plan steps stopped; no automatic retry.")
      }
    }
    let previous=data
    var candidate=data
    do {
      switch step.operation {
      case .temperature,.brightness:return .failed("Unsupported plan dispatch. No change for this step.")
      case .foregroundTimer(let seconds,let title):
        guard candidate.timers.count<12,!candidate.timers.contains(where:{$0.id==step.id}) else {
          return .failed("Timer limit or duplicate step identifier. No duplicate timer was created.")
        }
        var timer=Countdown(title:title,seconds:Double(seconds));timer.id=step.id
        candidate.timers.append(timer)
      }
    } catch {
      return .failed("The mock home is offline or the local value was rejected. No change for this step.")
    }
    data=candidate
    let acknowledged=persist()
    if ephemeral {
      guard acknowledged else { data=previous;return .failed("The in-memory demo step could not be saved.") }
      if case .foregroundTimer = step.operation { selectedTimer=step.id }
      return .confirmed(step.operation.summary+" · In-memory demo state read back")
    }
    do {
      let actual=try canonicalPlanStore
      let expected=try Snapshot.canonicalBytes(JSONEncoder().encode(candidate))
      if actual==expected {
        if case .foregroundTimer = step.operation { selectedTimer=step.id }
        if error=="Could not save local demo state." { error=nil }
        return .confirmed(step.operation.summary+" · Saved local state read back")
      }
      if !acknowledged,actual == (try Snapshot.canonicalBytes(JSONEncoder().encode(previous))) {
        data=previous
        return .failed("The save failed; read-back confirms the previous saved state. No saved change for this step.")
      }
    } catch { /* A failed acknowledgement is not proof that a write had no effect. */ }
    if !acknowledged { data=previous }
    storeReadOnly=true
    storeRecoveryNote="A demo-plan write could not be verified. Restart and recover saved state before writing again."
    return .unverified("Saved state could not be verified. Further steps stopped; no automatic retry. Restart recovery is required.")
  }
  #endif
  func runAssistant() {
    guard !Task.isCancelled,assistantInteractionActive else { return }
    assistantDocument=nil
    stopAnswerSpeech()
    interact()
    if assistantUsesAI {
      if assistantAI.ask(assistantInput) { assistantInput="" }
      return
    }
    #if !os(watchOS)
      if prepareDemoPlanIfRequested() { return }
    #endif
    if runEverydayCommand() { return }
    switch AssistantIntent(assistantInput) {
    case .scene(let s):
      command(.scene(s))
      assistantReply = homeCommandReply("\(s) is set in the mock home.")
    case .temperature(let t):
      command(.temperature(t))
      assistantReply = homeCommandReply("The mock thermostat is set to \(t)°.")
      if lastHomeCommandState.pending {assistantDeviceControl = .temperature}
    case .light:
      command(.entryLight)
      assistantReply = homeCommandReply("The entryway light is \(observedHome.entryLight ? "on" : "off").")
      if lastHomeCommandState.pending {assistantDeviceControl = .entryLight}
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
  private func homeCommandReply(_ confirmed:String)->String {
    switch lastHomeCommandState {
    case .confirmed:return confirmed
    case .failed(let failure):return error ?? failure.localizedDescription
    case .checking,.writing,.verifying:return "Mock device command requested. Its current device status is shown below."
    case .idle,.unverified:return error ?? "Mock device outcome is unverified. No automatic retry."
    }
  }
  func showAssistantExample(_ example:AssistantResponseExample) {
    guard !Task.isCancelled,assistantInteractionActive,!assistantUsesAI else {return}
    #if !os(watchOS)
      guard !demoPlanBusy else {return}
      discardDemoPlan()
    #endif
    stopAnswerSpeech();interact()
    let document=example.document
    assistantReply=document.text;assistantDocument=document
    // Selecting a display example never sends, clears or executes a typed draft.
  }
  func openAssistantExampleRecipe() {
    guard !Task.isCancelled,assistantInteractionActive,!assistantUsesAI,
      assistantDocument?.recipeActionAvailable==true else {return}
    // The display example must not resolve through data.recipe or replace an
    // imported/active recipe just to show its bundled content.
    interact();route = .assistantRecipePreview
  }
  func playChime() {
    stopAnswerSpeech();let reset=localResetGeneration
    Task {
      guard !Task.isCancelled,reset==localResetGeneration else { return }
      let played=await audio.playChime(volume:Float(data.volume))
      guard !Task.isCancelled,reset==localResetGeneration else { return }
      if !played { error="The demo sound could not be played." }
    }
  }
  func stopAudioForVoice() {
    stopAnswerSpeech()
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
    stopAnswerSpeech()
    #if !os(watchOS)
      pauseFeedPodcast()
    #endif
    #if !os(watchOS)
      if connections.enabled.contains(.music) {
        guard connections.musicAccessAllowed else {
          pendingPage = .music;route = .deviceUnlock;return
        }
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
    stopAnswerSpeech()
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
