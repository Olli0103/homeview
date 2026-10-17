import Foundation

enum PersonalHomeLayout: String, Codable, CaseIterable, Sendable {
  case photos, media
}

/// Layout preferences, not identity or permission to open a personal store.
struct PersonalHomeConfiguration: Codable, Equatable, Sendable {
  var layout = PersonalHomeLayout.photos
  var favorites = ["FaceTime", "Home", "Music", "Messages"]
  static let mediaFavorites = ["Music", "FaceTime", "Messages", "Calendar"]
  var apps: [AppPage] {
    var result: [AppPage] = []
    for raw in favorites + PersonalHomeConfiguration().favorites {
      if let page = AppPage(rawValue: raw), !result.contains(page) { result.append(page) }
      if result.count == 4 { break }
    }
    return result
  }
  var normalized: Self {
    var result = self
    result.favorites = apps.map(\.rawValue)
    return result
  }
  mutating func select(_ page: AppPage, at index: Int) {
    guard (0..<4).contains(index) else { return }
    var values = apps
    if let other = values.firstIndex(of: page) { values.swapAt(index, other) }
    else { values[index] = page }
    favorites = values.map(\.rawValue)
  }
  mutating func usePreset(_ value: PersonalHomeLayout) {
    layout = value
    favorites = value == .media ? Self.mediaFavorites : Self().favorites
  }
}

extension Snapshot {
  func personalHome(for profile: String?) -> PersonalHomeConfiguration {
    guard let profile, Fixtures.profiles.contains(profile) else { return .init() }
    return (personalHomeConfigurations[profile] ?? .init()).normalized
  }
  @discardableResult
  mutating func setPersonalHome(_ value: PersonalHomeConfiguration, for profile: String?) -> Bool {
    guard let profile, Fixtures.profiles.contains(profile) else { return false }
    personalHomeConfigurations[profile] = value.normalized
    return true
  }
}
