import Foundation

enum SnapshotReadError: Error { case malformed, unsupportedVersion, oversized }

extension Snapshot {
  /// Repair only the damaged field/item. The caller must preserve the original
  /// bytes before persisting a normalized snapshot; unknown versions fail closed.
  static func decodeMigrating(_ bytes: Data) throws -> Snapshot {
    guard bytes.count <= 32_000_000 else { throw SnapshotReadError.oversized }
    guard let stored = try JSONSerialization.jsonObject(with: bytes) as? [String: Any] else {
      throw SnapshotReadError.malformed
    }
    let decoder = JSONDecoder()
    if let raw = stored["version"] {
      let data = try JSONSerialization.data(withJSONObject: raw, options: [.fragmentsAllowed])
      guard (try? decoder.decode(Int.self, from: data)) == 1 else { throw SnapshotReadError.unsupportedVersion }
    }
    let fallback = Snapshot()
    var output = fallback
    func value<T: Decodable>(_ key: String, _ defaultValue: T) -> T {
      guard let raw = stored[key],
        let data = try? JSONSerialization.data(withJSONObject: raw, options: [.fragmentsAllowed]),
        let result = try? decoder.decode(T.self, from: data) else { return defaultValue }
      return result
    }
    func items<T: Decodable & Identifiable>(_ key: String, _ defaultValue: [T], limit: Int,
      valid: (T) -> Bool = { _ in true }) -> [T] {
      guard let raw = stored[key] as? [Any] else { return defaultValue }
      var seen = Set<T.ID>(), result: [T] = []
      for object in raw {
        if result.count == limit { break }
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.fragmentsAllowed]),
          let item = try? decoder.decode(T.self, from: data), valid(item), seen.insert(item.id).inserted else { continue }
        result.append(item)
      }
      return result
    }
    func table<T: Decodable>(_ key: String, limit: Int, validKey: (String) -> Bool = { _ in true }) -> [String: T] {
      guard let raw = stored[key] as? [String: Any] else { return [:] }
      var result: [String: T] = [:]
      for name in raw.keys.filter(validKey).sorted().prefix(limit) {
        guard name.count <= 128,
          let data = try? JSONSerialization.data(withJSONObject: raw[name]!, options: [.fragmentsAllowed]),
          let item = try? decoder.decode(T.self, from: data) else { continue }
        result[name] = item
      }
      return result
    }
    output.personal = table("personal", limit: 6)
    let homeConfigurations: [String: PersonalHomeConfiguration] = table("personalHomeConfigurations", limit: 6,
      validKey: { Fixtures.profiles.contains($0) })
    output.personalHomeConfigurations = homeConfigurations.mapValues { $0.normalized }
    output.home = value("home", fallback.home)
    output.home.temperature = min(90,max(50,output.home.temperature))
    output.home.brightness = min(100,max(0,output.home.brightness))
    output.home.fanSpeed = min(100,max(0,output.home.fanSpeed))
    output.home.blinds = min(100,max(0,output.home.blinds))
    output.home.audit = Array(output.home.audit.suffix(100)).map { String($0.prefix(200)) }
    output.face = value("face", fallback.face)
    output.theme = min(1,max(0,value("theme",fallback.theme)))
    output.night = value("night",fallback.night)
    output.far = value("far",fallback.far)
    output.volume = min(1,max(0,value("volume",fallback.volume)))
    output.screenBrightness = min(1,max(0,value("screenBrightness",fallback.screenBrightness)))
    output.keepDisplayOn = value("keepDisplayOn",fallback.keepDisplayOn)
    output.photoIDs = Array(value("photoIDs",fallback.photoIDs).filter { UUID(uuidString:$0) != nil }.prefix(10))
    // Missing means an older snapshot. A present but malformed discriminator
    // must not resurrect an unrelated legacy selected-photo.data file.
    output.photoSelection = stored["photoSelection"] == nil ? .legacy : value("photoSelection",.none)
    let galleryTitle: String? = value("photoGalleryTitle",nil)
    output.photoGalleryTitle = galleryTitle.flatMap {
      !$0.isEmpty && $0.count <= 120 && $0.utf8.count <= 2048
        && !$0.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains) ? $0:nil
    }
    let grant: AlbumDisplayGrant? = value("albumDisplay",nil)
    output.albumDisplay = grant.flatMap { item in
      item.valid && item.cache.map(\.fileID) == output.photoIDs ? item:nil
    }
    if output.photoSelection == .album, output.albumDisplay == nil {
      output.photoSelection = .none
    }
    if output.photoSelection == .none {
      output.photoIDs = []
      output.photoGalleryTitle = nil
    } else if output.photoSelection == .single {
      output.photoIDs = Array(output.photoIDs.prefix(1))
      output.photoGalleryTitle = nil
    }
    if output.photoSelection != .album { output.albumDisplay = nil }
    output.rotatePhotos = value("rotatePhotos",fallback.rotatePhotos)
    output.photoAdjustments = table("photoAdjustments",limit:100)
    output.timers = items("timers",fallback.timers,limit:12) {
      $0.duration.isFinite && (1...86400).contains($0.duration)
        && $0.pausedRemaining.isFinite && (0...1e12).contains($0.pausedRemaining)
        && $0.title.count <= 512
        && ($0.deadline.map { $0 >= .distantPast && $0 <= .distantFuture } ?? true)
    }
    output.nativeTimerIDs = Set(value("nativeTimerIDs",fallback.nativeTimerIDs).prefix(64))
    output.nativeAlarmIDs = Set(value("nativeAlarmIDs",fallback.nativeAlarmIDs).prefix(64))
    output.reminders = items("reminders",fallback.reminders,limit:500)
    output.alarms = items("alarms",fallback.alarms,limit:24) {
      (0...23).contains($0.hour) && (0...59).contains($0.minute)
    }
    func validRecipe(_ recipe: RecipeDocument) -> Bool {
      !recipe.title.isEmpty && recipe.title.count <= 200 && recipe.ingredients.count <= 200
        && (0...20160).contains(recipe.durationMinutes) && recipe.servings.count <= 160
        && recipe.ingredients.allSatisfy { $0.count <= 1000 }
        && !recipe.steps.isEmpty && recipe.steps.count <= 100
        && recipe.steps.allSatisfy { !$0.text.isEmpty && $0.text.count <= 3000
          && ($0.minutes.map { (1...1440).contains($0) } ?? true) }
    }
    let recipe = value("recipe",fallback.recipe)
    output.recipe = validRecipe(recipe) ? recipe : fallback.recipe
    output.pinnedRecipes = items("pinnedRecipes",fallback.pinnedRecipes,limit:50,valid:validRecipe)
    output.pinnedRecipe = output.pinnedRecipes.contains { $0.id == output.recipe.id }
    output.faceConfigurations = table("faceConfigurations",limit:Face.allCases.count)
    let widgets = value("widgets",fallback.widgets)
    output.widgets = widgets.count == 4 && widgets.allSatisfy({ $0.count <= 80 }) ? widgets : fallback.widgets
    output.worldClockZones = WorldCity.normalized(value("worldClockZones",fallback.worldClockZones))
    return output
  }
  static func canonicalBytes(_ bytes: Data) throws -> Data {
    guard var object = try JSONSerialization.jsonObject(with: bytes) as? [String: Any] else {
      throw SnapshotReadError.malformed
    }
    for key in ["nativeTimerIDs","nativeAlarmIDs"] {
      if let values = object[key] as? [String] { object[key] = values.sorted() }
    }
    return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
  }
}
