import XCTest
@testable import HomeViewCore

final class PersonalHomeTests: XCTestCase {
  func testWeatherPresetKeepsObservedTopAppOrderAndOtherProfiles() throws {
    var state=Snapshot(),media=PersonalHomeConfiguration(),weather=PersonalHomeConfiguration()
    media.usePreset(.media);weather.usePreset(.weather)
    XCTAssertEqual(weather.apps.map(\.rawValue),["Music","Podcasts","Safari","FaceTime"])
    state.setPersonalHome(media,for:"Alex");state.setPersonalHome(weather,for:"Jamie")
    let restored=try Snapshot.decodeMigrating(JSONEncoder().encode(state))
    XCTAssertEqual(restored.personalHome(for:"Alex"),media)
    XCTAssertEqual(restored.personalHome(for:"Jamie"),weather)
    XCTAssertEqual(restored.personalHome(for:nil).layout,.photos)
  }
  func testLayoutsRoundTripWithoutCrossProfileOrGuestInheritance() throws {
    var snapshot = Snapshot()
    var media = PersonalHomeConfiguration()
    media.usePreset(.media)
    media.select(.weather, at: 2)
    XCTAssertTrue(snapshot.setPersonalHome(media, for: "Alex"))
    XCTAssertFalse(snapshot.setPersonalHome(media, for: nil))
    XCTAssertFalse(snapshot.setPersonalHome(media, for: "Unknown"))
    let stored = try Snapshot.decodeMigrating(JSONEncoder().encode(snapshot))
    XCTAssertEqual(stored.personalHome(for: "Alex"), media)
    XCTAssertEqual(stored.personalHome(for: "Jamie"), .init())
    XCTAssertEqual(stored.personalHome(for: nil), .init())
  }
  func testSelectingExistingFavoriteSwapsRatherThanDuplicating() {
    var config = PersonalHomeConfiguration()
    config.select(.messages, at: 0)
    XCTAssertEqual(config.apps.map(\.rawValue), ["Messages", "Home", "Music", "FaceTime"])
    let old = config
    config.select(.weather, at: -1)
    config.select(.weather, at: 4)
    XCTAssertEqual(config, old)
  }
  func testMalformedFavoritesRecoverKnownAppsAndBoundTheGrid() throws {
    var snapshot = Snapshot()
    snapshot.home.temperature = 71
    var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot)) as! [String: Any]
    var configs: [String: Any] = ["Alex": ["layout": "media", "favorites": ["Unknown", "Music", "Music", "Calendar", "Weather", "Safari", "Home"]]]
    for index in 0..<8 { configs["0-unknown-\(index)"] = ["layout": "media", "favorites": ["Music"]] }
    object["personalHomeConfigurations"] = configs
    let bytes = try JSONSerialization.data(withJSONObject: object)
    let stored = try Snapshot.decodeMigrating(bytes)
    XCTAssertEqual(stored.personalHome(for: "Alex").apps.map(\.rawValue), ["Music", "Calendar", "Weather", "Safari"])
    XCTAssertEqual(stored.personalHomeConfigurations.count, 1)
    XCTAssertEqual(stored.home.temperature, 71)
  }
  func testOldAndIndividuallyCorruptLayoutsDoNotResetUnrelatedSettings() throws {
    let bytes = Data(#"{"volume":0.8,"personalHomeConfigurations":{"Alex":{"layout":"unknown","favorites":[]},"Jamie":{"layout":"media","favorites":["Music","FaceTime","Messages","Calendar"]}}}"#.utf8)
    let stored = try Snapshot.decodeMigrating(bytes)
    XCTAssertEqual(stored.volume, 0.8)
    XCTAssertEqual(stored.personalHome(for: "Alex"), .init())
    XCTAssertEqual(stored.personalHome(for: "Jamie").layout, .media)
    XCTAssertEqual(try Snapshot.decodeMigrating(Data("{}".utf8)).personalHome(for: "Alex"), .init())
  }
}
