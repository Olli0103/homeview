import Foundation

enum HomeError: Error, Equatable, LocalizedError {
  case offline, unauthorized, invalidValue, notFound
  var errorDescription: String? {
    switch self {
    case .offline: "The mock home is offline. No changes were made."
    case .unauthorized: "Device authentication is required for this mock security action."
    case .invalidValue: "That value is outside the supported range."
    case .notFound: "This accessory is unavailable."
    }
  }
}

enum Face: String, CaseIterable, Codable, Identifiable, Sendable {
  case modular = "Modular"
  case watchModular = "Watch Modular"
  case infographModular = "Infograph Modular"
  case modularDuo = "Modular Duo"
  case modularCompact = "Modular Compact"
  case home = "Home Modular"
  case homeClock = "Home Modular Clock"
  case photos = "Photos"
  case weather = "Weather"
  case calendar = "Calendar"
  case flow = "Flow"
  case fade = "Fade"
  case numerals = "Numerals"
  case cameras = "Home Camera"
  var id: String { rawValue }
}
enum AppPage: String, CaseIterable, Identifiable, Sendable {
  case home = "Home"
  case calendar = "Calendar"
  case music = "Music"
  case weather = "Weather"
  case timers = "Timers"
  case reminders = "Reminders"
  case recipes = "Recipes"
  case cameras = "Cameras"
  case intercom = "Intercom"
  case messages = "Messages"
  case faceTime = "FaceTime"
  case findMy = "Find My"
  case alarms = "Alarms"
  case worldClock = "World Clock"
  case safari = "Safari"
  case podcasts = "Podcasts"
  case mirror = "Mirror"
  case settings = "Settings"
  var id: String { rawValue }
  var symbol: String {
    switch self {
    case .home: "house.fill"
    case .calendar: "calendar"
    case .music: "music.note"
    case .weather: "cloud.sun.fill"
    case .timers: "timer"
    case .reminders: "checklist"
    case .recipes: "fork.knife"
    case .cameras: "video.fill"
    case .intercom: "waveform"
    case .messages: "message.fill"
    case .faceTime: "video.fill"
    case .findMy: "location.fill"
    case .alarms: "alarm.fill"
    case .worldClock: "globe"
    case .safari: "safari"
    case .podcasts: "mic.circle.fill"
    case .mirror: "person.crop.rectangle"
    case .settings: "gearshape.fill"
    }
  }
  var isPersonal: Bool { [.calendar, .reminders, .messages, .faceTime, .findMy].contains(self) }
}
enum Route: Equatable {
  case face, personal, drawer
  case app(AppPage)
  case thermostat, light, lock
  case camera(Int)
  case recipe, ingredients, cooking, handoff, assistant, assistantRecipePreview
  case editor, controlCenter, privacy, call, deviceUnlock
}

struct MockHome: Codable, Equatable, Sendable {
  var temperature = 68
  var entryLight = true
  var bedroomLight = true
  var brightness = 75.0
  var fan = true
  var fanSpeed = 45.0
  var locked = true
  var blinds = 80.0
  var online = true
  var lastScene = ""
  var audit: [String] = []
  mutating func transact(_ command: HomeCommand, authorized: Bool = false) throws {
    guard online else { throw HomeError.offline }
    guard !command.requiresDeviceAuthentication || authorized else { throw HomeError.unauthorized }
    switch command {
    case .temperature(let t):
      guard (50...90).contains(t) else { throw HomeError.invalidValue }
      temperature = t
    case .entryLight: entryLight.toggle()
    case .bedroomLight: bedroomLight.toggle()
    case .brightness(let v):
      guard (0...100).contains(v) else { throw HomeError.invalidValue }
      brightness = v
    case .fan: fan.toggle()
    case .fanSpeed(let v):
      guard (0...100).contains(v) else { throw HomeError.invalidValue }
      fanSpeed = v
    case .lock:
      guard authorized else { throw HomeError.unauthorized }
      locked.toggle()
    case .blinds(let v):
      guard (0...100).contains(v) else { throw HomeError.invalidValue }
      blinds = v
    case .scene(let scene):
      guard
        ["Good Night", "Good Morning", "Movie Time", "Chill Out", "Dinner Time"].contains(scene)
      else {
        throw HomeError.notFound
      }
      lastScene = scene
      if scene == "Good Night" {
        entryLight = false
        bedroomLight = false
        locked = true
        blinds = 0
        temperature = 66
      } else if scene == "Good Morning" {
        entryLight = true
        bedroomLight = true
        blinds = 100
        temperature = 70
      } else if scene == "Dinner Time" {
        entryLight = true
        bedroomLight = false
        brightness = 75
        temperature = 70
      } else {
        entryLight = false
        bedroomLight = false
        brightness = 20
        blinds = 0
      }
    }
    audit.append(command.description)
    audit = Array(audit.suffix(100))
  }
}
enum HomeCommand: Sendable {
  case temperature(Int)
  case entryLight, bedroomLight
  case brightness(Double)
  case fan
  case fanSpeed(Double)
  case lock
  case blinds(Double)
  case scene(String)
  var requiresDeviceAuthentication:Bool {
    if case .lock = self { return true }
    if case .scene(let name) = self { return name == "Good Night" }
    return false
  }
  var description: String {
    switch self {
    case .temperature(let t): "Thermostat set to \(t)°"
    case .entryLight: "Entryway light toggled"
    case .bedroomLight: "Bedroom light toggled"
    case .brightness(let v): "Brightness \(Int(v))%"
    case .fan: "Office fan toggled"
    case .fanSpeed(let v): "Fan speed \(Int(v))%"
    case .lock: "Front door lock toggled"
    case .blinds(let v): "Blinds \(Int(v))%"
    case .scene(let s): "Scene: \(s)"
    }
  }
}

struct Countdown: Identifiable, Codable, Equatable, Sendable {
  var id = UUID()
  var title: String
  var duration: TimeInterval
  var deadline: Date?
  var pausedRemaining: TimeInterval
  var didAlert = false
  init(title: String, seconds: TimeInterval, now: Date = Date()) {
    self.title = title
    duration = max(1, seconds)
    pausedRemaining = max(1, seconds)
    deadline = now.addingTimeInterval(max(1, seconds))
  }
  func remaining(at date: Date) -> TimeInterval {
    max(0, deadline.map { $0.timeIntervalSince(date) } ?? pausedRemaining)
  }
  func display(at date: Date) -> String {
    let t = Int(ceil(remaining(at: date)))
    return t >= 3600
      ? String(format: "%d:%02d:%02d", t / 3600, (t / 60) % 60, t % 60)
      : String(format: "%02d:%02d", t / 60, t % 60)
  }
  mutating func pause(at date: Date) {
    pausedRemaining = remaining(at: date)
    deadline = nil
  }
  mutating func resume(at date: Date) {
    guard deadline == nil, pausedRemaining > 0 else { return }
    deadline = date.addingTimeInterval(pausedRemaining)
  }
}
struct ReminderItem: Codable, Identifiable, Equatable, Sendable {
  var id = UUID()
  var title: String
  var completed = false
}
struct AlarmItem: Codable, Identifiable, Equatable, Sendable {
  var id = UUID()
  var hour: Int
  var minute: Int
  var enabled = true
  var lastFiredDay = ""
}
struct PersonalContent: Codable, Sendable {
  var reminders = [
    ReminderItem(title: "Pick up groceries"), ReminderItem(title: "Water the plants"),
  ]
  var messages = ["Hey! Are we still on for dinner?", "Yes, see you at six."]
}

struct Snapshot: Codable, Sendable {
  var introduction = SetupIntroduction.pending
  /// Missing is legacy defaults; an explicit empty set forbids automatic restoration.
  var connectionConsent:Set<DataConnection>?
  var personal: [String: PersonalContent] = [:]
  var personalHomeConfigurations: [String: PersonalHomeConfiguration] = [:]
  var version = 1
  var home = MockHome()
  var face = Face.home
  var theme = 0
  var night = false
  var far = false
  var volume = 0.55
  var screenBrightness = 1.0
  var keepDisplayOn = false
  var timerLiveActivitiesEnabled = false
  var photoIDs: [String] = []
  var photoSelection = PhotoSelectionKind.legacy
  var photoGalleryTitle: String?
  var albumDisplay: AlbumDisplayGrant?
  var rotatePhotos = true
  var photoAdjustments: [String: PhotoAdjustment] = [:]
  var timers: [Countdown] = []
  var nativeTimerIDs: Set<UUID> = []
  var nativeAlarmIDs: Set<UUID> = []
  var reminders = [
    ReminderItem(title: "Pick up groceries"), ReminderItem(title: "Water the plants"),
    ReminderItem(title: "Book a family dinner"),
  ]
  var alarms = [AlarmItem(hour: 7, minute: 0, enabled: false)]
  var recipe = RecipeDocument.soup
  var pinnedRecipes: [RecipeDocument] = []
  var pinnedRecipe = false
  var faceConfigurations: [String: FaceConfiguration] = [:]
  var widgets = ["Date", "Clock", "Music", "Weather"]
  var podcasts = PodcastLibrary()
  var worldClockZones = WorldCity.defaults

}
struct CalendarEntry: Identifiable, Sendable {
  let id: String
  let time: String
  let title: String
  let subtitle: String
  let color: Int
  var cancelled = false
  static let fixtures = [
    CalendarEntry(
      id: "1", time: "9:00 AM", title: "Morning walk", subtitle: "Waterfront Park", color: 0),
    CalendarEntry(
      id: "2", time: "11:00 AM", title: "Design review", subtitle: "Studio · 1 hour", color: 1),
    CalendarEntry(
      id: "3", time: "2:30 PM", title: "Coffee with Jamie", subtitle: "Cancelled", color: 2,
      cancelled: true),
    CalendarEntry(id: "4", time: "6:00 PM", title: "Family dinner", subtitle: "Home", color: 0),
  ]
}
struct RecipeStep: Codable, Sendable {
  var text: String
  var minutes: Int?
}
enum Fixtures {
  static let date = Date(timeIntervalSince1970: 1_775_038_170)  // Apr 1, 2026, 10:09:30 UTC
  static let profiles = ["Alex", "Jamie", "Sam", "Taylor", "Casey", "Morgan"]
  static let ingredients = [
    "1 butternut squash, peeled and cubed", "1 onion, chopped", "2 tbsp olive oil",
    "3 cups vegetable stock", "2 fresh sage leaves", "Salt and pepper",
  ]
  static let steps = [
    RecipeStep(
      text: "Heat the olive oil in a large pot. Add the onion and cook until soft.", minutes: 5),
    RecipeStep(
      text:
        "Add the squash and vegetable stock. Bring to a boil, then reduce the heat and simmer until tender.",
      minutes: 20),
    RecipeStep(
      text:
        "Blend until smooth. Season with salt and pepper. Serve with sage and a drizzle of olive oil.",
      minutes: nil),
  ]
  static let songs = ["FEVER DREAM", "A Little Sunshine", "Evening Light"]
}

/// Deliberately local command grammar, not Siri AI or access to personal Apple data.
enum AssistantIntent: Equatable {
  case scene(String)
  case temperature(Int)
  case light
  case timer(Int)
  case recipe, calendar, music, unknown
  init(_ input: String) {
    let s=input.lowercased().trimmingCharacters(in:.whitespacesAndNewlines)
      .trimmingCharacters(in:CharacterSet(charactersIn:".!?"))
      .split(whereSeparator: { $0.isWhitespace }).joined(separator:" ")
    guard s.count<=AssistantLimits.transcriptCharacters else { self = .unknown;return }
    if ["good night","gute nacht"].contains(s) {
      self = .scene("Good Night")
    } else if ["good morning","guten morgen"].contains(s) {
      self = .scene("Good Morning")
    } else if s.range(of:#"^(?:(?:set (?:the )?)?temperature (?:to )?|temperatur (?:auf )?)[0-9]{1,3}$"#,options:.regularExpression) != nil,
      let value=s.split(separator:" ").last.flatMap({Int($0)}) {
      self = .temperature(value)
    } else if ["light","lights","licht","toggle lights","toggle the light","toggle entryway light"].contains(s) {
      self = .light
    } else if s.range(of:#"^(?:set a timer for |set timer for |timer )[0-9]{1,12} minutes?$"#,options:.regularExpression) != nil,
      let n=s.split(separator:" ").compactMap({Int($0)}).first {
      // Legacy parser value only; runEverydayCommand validates actual durations first.
      self = .timer(min(1440,max(1,n)))
    } else if ["recipe","show recipe","show the recipe","soup","rezept","zeige rezept"].contains(s) {
      self = .recipe
    } else if ["calendar","open calendar","show calendar","kalender","öffne kalender"].contains(s) {
      self = .calendar
    } else if ["music","musik","toggle music","toggle playback"].contains(s) {
      self = .music
    } else { self = .unknown }
  }
}

struct MonthLayout: Sendable {
  let firstWeekdayIndex: Int
  let dayCount: Int
  let selectedDay: Int
  let previousMonthDayCount: Int
  init(date: Date, timeZone: TimeZone) {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let start = calendar.dateInterval(of: .month, for: date)!.start
    firstWeekdayIndex = calendar.component(.weekday, from: start) - 1
    dayCount = calendar.range(of: .day, in: .month, for: date)!.count
    selectedDay = calendar.component(.day, from: date)
    let previous = calendar.date(byAdding: .month, value: -1, to: start)!
    previousMonthDayCount = calendar.range(of: .day, in: .month, for: previous)!.count
  }
  var cellCount: Int { ((firstWeekdayIndex + dayCount + 6) / 7) * 7 }
  /// Six-row calendar face includes the adjacent month dates seen in UI08.
  func displayDay(at cell: Int) -> Int {
    let day = cell - firstWeekdayIndex + 1
    if day < 1 { return previousMonthDayCount + day }
    return day > dayCount ? day - dayCount : day
  }
  func day(at cell: Int) -> Int? {
    let day = cell - firstWeekdayIndex + 1
    return (1...dayCount).contains(day) ? day : nil
  }
}

struct RecipeDocument: Codable, Identifiable, Sendable {
  var id = UUID()
  var title: String
  var source: String
  var durationMinutes: Int
  var servings: String
  var ingredients: [String]
  var steps: [RecipeStep]
  var coverAsset: String?
  var imageURL: URL?
  var prepMinutes: Int?
  var cookMinutes: Int?
  var durationLabel: String {
    if durationMinutes > 0 { return "\(durationMinutes) min." }
    if let cookMinutes { return "Cook \(cookMinutes) min." }
    if let prepMinutes { return "Prep \(prepMinutes) min." }
    return "Duration not provided"
  }
  var servingsLabel: String { servings.isEmpty ? "Servings not provided" : "Serves " + servings }
  static let soup = RecipeDocument(
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, title: "Butternut Squash Soup",
    source: "Home Cookbook", durationMinutes: 35, servings: "4", ingredients: Fixtures.ingredients,
    steps: Fixtures.steps, coverAsset: "Soup")
}
enum RecipeParseError: Error, LocalizedError {
  case noRecipe, oversized, pageChanged
  var errorDescription: String? {
    switch self {
    case .noRecipe: "This page has no supported structured recipe."
    case .oversized: "The page's structured recipe is too large."
    case .pageChanged: "The page changed while reading the recipe. Read it again."
    }
  }
}
/// Shared angular calculations avoid hour/minute discontinuities at midnight.
struct ClockGeometry: Sendable {
  let hours: Double
  let minutes: Double
  let seconds: Double
  init(date: Date, timeZone: TimeZone) {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    seconds =
      Double(calendar.component(.second, from: date)) + Double(
        calendar.component(.nanosecond, from: date)) / 1_000_000_000
    minutes = Double(calendar.component(.minute, from: date)) + seconds / 60
    hours = Double(calendar.component(.hour, from: date) % 12) + minutes / 60
  }
  /// Proposed interpolation of the single UI12 state, not an Apple timing spec.
  func fadeOpacity(hour: Int) -> Double {
    let raw = abs(Double(hour % 12) - minutes / 5)
    let distance = min(raw, 12 - raw)
    let t = max(0, min(1, (3.2 - distance) / 1.2))
    return t * t * (3 - 2 * t)
  }
}
