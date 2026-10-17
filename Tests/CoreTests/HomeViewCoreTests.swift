import XCTest

@testable import HomeViewCore

final class HomeViewCoreTests: XCTestCase {
  func testOfflineCommandsAreAtomicAndDoNotLogSuccess() throws {
    var home = MockHome()
    home.online = false
    let before = home
    for c in [HomeCommand.temperature(71), .scene("Good Night"), .entryLight, .lock] {
      XCTAssertThrowsError(try home.transact(c, authorized: true)) {
        XCTAssertEqual($0 as? HomeError, .offline)
      }
      XCTAssertEqual(home, before)
    }
  }
  func testThermostatBoundsAndSuccessfulWrite() throws {
    var home = MockHome()
    try home.transact(.temperature(90))
    XCTAssertEqual(home.temperature, 90)
    let before = home
    XCTAssertThrowsError(try home.transact(.temperature(91)))
    XCTAssertEqual(home, before)
    XCTAssertThrowsError(try home.transact(.temperature(49)))
    XCTAssertEqual(home, before)
  }
  func testLockRequiresProfileAndSceneCannotUnlockIt() throws {
    var home = MockHome()
    let before = home
    XCTAssertThrowsError(try home.transact(.lock)) {
      XCTAssertEqual($0 as? HomeError, .unauthorized)
    }
    XCTAssertEqual(home, before)
    try home.transact(.lock, authorized: true)
    XCTAssertFalse(home.locked)
    try home.transact(.scene("Good Night"))
    XCTAssertTrue(home.locked)
    try home.transact(.scene("Good Morning"))
    XCTAssertTrue(home.locked)
  }
  func testScenesApplyCompleteStateAndUnknownSceneIsRejected() throws {
    var home = MockHome()
    try home.transact(.scene("Good Night"))
    XCTAssertFalse(home.entryLight)
    XCTAssertFalse(home.bedroomLight)
    XCTAssertEqual(home.blinds, 0)
    XCTAssertEqual(home.temperature, 66)
    try home.transact(.scene("Good Morning"))
    XCTAssertTrue(home.entryLight)
    XCTAssertTrue(home.bedroomLight)
    XCTAssertEqual(home.blinds, 100)
    XCTAssertEqual(home.temperature, 70)
    let before = home
    XCTAssertThrowsError(try home.transact(.scene("Missing")))
    XCTAssertEqual(home, before)
  }
  func testBrightnessAndCoverRejectOutOfRangeAndNaN() throws {
    var home = MockHome()
    let before = home
    for c in [HomeCommand.brightness(-1), .brightness(.nan), .blinds(101), .fanSpeed(.infinity)] {
      XCTAssertThrowsError(try home.transact(c))
      XCTAssertEqual(home, before)
    }
  }
  func testMultipleTimersAreIndependentAndSurviveSerialization() throws {
    let now = Date(timeIntervalSince1970: 1000)
    var snapshot = Snapshot()
    snapshot.timers = [
      Countdown(title: "Soup", seconds: 300, now: now),
      Countdown(title: "Tea", seconds: 60, now: now),
    ]
    snapshot.timers[0].pause(at: now.addingTimeInterval(20))
    let restored = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(snapshot))
    XCTAssertEqual(restored.timers[0].remaining(at: now.addingTimeInterval(100)), 280)
    XCTAssertEqual(restored.timers[1].remaining(at: now.addingTimeInterval(100)), 0)
    XCTAssertEqual(restored.timers[0].id, snapshot.timers[0].id)
  }
  func testPauseResumeUsesRemainingDurationNotOriginalDuration() {
    let now = Date(timeIntervalSince1970: 1000)
    var t = Countdown(title: "Tea", seconds: 60, now: now)
    t.pause(at: now.addingTimeInterval(20))
    XCTAssertEqual(t.remaining(at: now.addingTimeInterval(200)), 40)
    t.resume(at: now.addingTimeInterval(200))
    XCTAssertEqual(t.remaining(at: now.addingTimeInterval(230)), 10)
    t.resume(at: now.addingTimeInterval(231))
    XCTAssertEqual(t.remaining(at: now.addingTimeInterval(230)), 10)
    XCTAssertEqual(t.remaining(at: now.addingTimeInterval(250)), 0)
  }
  func testCountdownDisplayRoundingAndHours() {
    let now = Date(timeIntervalSince1970: 1000)
    let t = Countdown(title: "Short", seconds: 2, now: now)
    XCTAssertEqual(t.display(at: now.addingTimeInterval(0.2)), "00:02")
    XCTAssertEqual(t.display(at: now.addingTimeInterval(3)), "00:00")
    XCTAssertEqual(Countdown(title: "Long", seconds: 3661, now: now).display(at: now), "1:01:01")
  }
  func testLocalAssistantGrammarIsBoundedAndDoesNotInterpretArbitraryCommands() {
    XCTAssertEqual(AssistantIntent("Set a timer for 999999999 minutes"), .timer(1440))
    XCTAssertEqual(AssistantIntent("Temperatur 70"), .temperature(70))
    XCTAssertEqual(AssistantIntent("good night"), .scene("Good Night"))
    XCTAssertEqual(AssistantIntent("show my personal messages"), .unknown)
  }
  func testSnapshotRestoresLocalStateAndDoesNotContainCredentialsOrIdentity() throws {
    var snapshot = Snapshot()
    snapshot.reminders[0].completed = true
    snapshot.face = .modular
    snapshot.home.temperature = 72
    let bytes = try JSONEncoder().encode(snapshot)
    let result = try JSONDecoder().decode(Snapshot.self, from: bytes)
    XCTAssertEqual(result.home.temperature, 72)
    XCTAssertEqual(result.face, .modular)
    XCTAssertTrue(result.reminders[0].completed)
    let text = String(decoding: bytes, as: UTF8.self)
    for key in ["token", "profile", "password", "HomeKit"] { XCTAssertFalse(text.contains(key)) }
  }
  func testAuditHistoryIsBounded() throws {
    var home = MockHome()
    for _ in 0..<150 { try home.transact(.entryLight) }
    XCTAssertEqual(home.audit.count, 100)
  }
  func testPrivateAppClassificationDoesNotAccidentallyExposePersonalPages() {
    for page in [AppPage.calendar, .messages, .reminders, .findMy, .faceTime] {
      XCTAssertTrue(page.isPersonal)
    }
    for page in [AppPage.home, .weather, .timers, .music] { XCTAssertFalse(page.isPersonal) }
  }
  func testMonthLayoutLeapYearAndSixRowMonth() {
    let formatter = ISO8601DateFormatter()
    let utc = TimeZone(secondsFromGMT: 0)!
    let leap = MonthLayout(date: formatter.date(from: "2024-02-29T12:00:00Z")!, timeZone: utc)
    XCTAssertEqual(leap.dayCount, 29)
    XCTAssertEqual(leap.selectedDay, 29)
    let six = MonthLayout(date: formatter.date(from: "2026-08-01T12:00:00Z")!, timeZone: utc)
    XCTAssertEqual(six.cellCount, 42)
    XCTAssertEqual(six.day(at: 6), 1)
  }
  func testMonthLayoutUsesSelectedTimeZoneAtDayBoundary() {
    let date = ISO8601DateFormatter().date(from: "2026-04-01T00:30:00Z")!
    let west = MonthLayout(date: date, timeZone: TimeZone(identifier: "America/Los_Angeles")!)
    let utc = MonthLayout(date: date, timeZone: TimeZone(secondsFromGMT: 0)!)
    XCTAssertEqual(west.dayCount, 31)
    XCTAssertEqual(west.selectedDay, 31)
    XCTAssertEqual(utc.dayCount, 30)
    XCTAssertEqual(utc.selectedDay, 1)
  }
  func testPersonalContentValueCopiesDoNotShareMutableLists() {
    var data = Snapshot()
    data.personal["Alex"] = PersonalContent()
    data.personal["Jamie"] = PersonalContent()
    data.personal["Alex"]!.reminders.append(ReminderItem(title: "Private"))
    XCTAssertFalse(data.personal["Jamie"]!.reminders.contains(where: { $0.title == "Private" }))
    XCTAssertTrue(data.personal["Alex"]!.reminders.contains(where: { $0.title == "Private" }))
  }

  func testStructuredRecipeGraphAndNestedCookingSteps() throws {
    let json =
      #"{"@graph":[{"@type":"WebPage"},{"@type":["Thing","Recipe"],"name":"Pasta","totalTime":"PT1H15M","recipeYield":["6"],"recipeIngredient":["Tomatoes","Pasta"],"recipeInstructions":[{"@type":"HowToSection","itemListElement":[{"@type":"HowToStep","text":"Simmer for 20 minutes."},{"@type":"HowToStep","text":"Serve."}]}]}]}"#
    let recipe = try RecipeParser.parse(json: json, source: "fixture")
    XCTAssertEqual(recipe.title, "Pasta")
    XCTAssertEqual(recipe.durationMinutes, 75)
    XCTAssertEqual(recipe.servings, "6")
    XCTAssertEqual(recipe.steps.count, 2)
    XCTAssertEqual(recipe.steps[0].minutes, 20)
    XCTAssertNil(recipe.steps[1].minutes)
  }
  func testRecipeParserRejectsEmptyAndOversizedPayloads() {
    XCTAssertThrowsError(
      try RecipeParser.parse(
        json: #"{"@type":"Recipe","name":"Empty","recipeInstructions":[]}"#, source: "fixture"))
    XCTAssertThrowsError(
      try RecipeParser.parse(json: String(repeating: "x", count: 2_000_001), source: "fixture"))
    XCTAssertEqual(RecipeParser.duration("PT9223372036854775807H"), 1440)
  }
  func testPinnedRecipesSurviveSnapshotRoundTrip() throws {
    var state = Snapshot()
    state.pinnedRecipes = [.soup]
    state.pinnedRecipe = true
    let restored = try JSONDecoder().decode(Snapshot.self, from: JSONEncoder().encode(state))
    XCTAssertEqual(restored.pinnedRecipes.first?.title, RecipeDocument.soup.title)
    XCTAssertEqual(restored.pinnedRecipes.first?.steps.count, 3)
  }

  func testLegacySnapshotKeepsHomeAndDefaultsNewDisplaySettings() throws {
    var snapshot = Snapshot()
    try snapshot.home.transact(.temperature(72), authorized: true)
    var object =
      try JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot)) as! [String: Any]
    for key in ["keepDisplayOn", "photoIDs", "rotatePhotos"] { object.removeValue(forKey: key) }
    let restored = try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject: object))
    XCTAssertEqual(restored.home.temperature, 72)
    XCTAssertFalse(restored.keepDisplayOn)
    XCTAssertTrue(restored.photoIDs.isEmpty)
    XCTAssertTrue(restored.rotatePhotos)
  }

  func testCalendarFaceIncludesAdjacentMonthDaysAndLeapFebruary() {
    let utc = TimeZone(secondsFromGMT: 0)!
    let april = MonthLayout(date: Fixtures.date, timeZone: utc)
    XCTAssertEqual((0..<7).map { april.displayDay(at: $0) }, [29, 30, 31, 1, 2, 3, 4])
    XCTAssertEqual(april.displayDay(at: 41), 9)
    let marchDate = ISO8601DateFormatter().date(from: "2024-03-01T12:00:00Z")!
    let march = MonthLayout(date: marchDate, timeZone: utc)
    XCTAssertEqual(march.displayDay(at: 0), 25)
    XCTAssertEqual(march.displayDay(at: 4), 29)
    XCTAssertEqual(march.displayDay(at: 5), 1)
  }
  func testClockSubdivisionsTimeZonesAndMovingFadeWindow() {
    let clock = ClockGeometry(date: Fixtures.date, timeZone: TimeZone(secondsFromGMT: 0)!)
    XCTAssertEqual(clock.seconds, 30)
    XCTAssertEqual(clock.minutes, 9.5)
    XCTAssertEqual(clock.hours, 10 + 9.5 / 60, accuracy: 0.000001)
    XCTAssertEqual(clock.fadeOpacity(hour: 2), 1)
    XCTAssertEqual(clock.fadeOpacity(hour: 8), 0)
    let later = ClockGeometry(
      date: Fixtures.date.addingTimeInterval(1800), timeZone: TimeZone(secondsFromGMT: 0)!)
    XCTAssertEqual(later.fadeOpacity(hour: 8), 1)
    XCTAssertEqual(later.fadeOpacity(hour: 2), 0)
    let tokyo = ClockGeometry(date: Fixtures.date, timeZone: TimeZone(secondsFromGMT: 9 * 3600)!)
    XCTAssertEqual(tokyo.hours, 7 + 9.5 / 60, accuracy: 0.000001)
  }

  func testClockSubsecondSweepAndWeatherConditionMapping() {
    let date = Fixtures.date.addingTimeInterval(0.25)
    let clock = ClockGeometry(date: date, timeZone: TimeZone(secondsFromGMT: 0)!)
    XCTAssertEqual(clock.seconds, 30.25, accuracy: 0.0001)
    let weather = WeatherReading(
      city: "Test", temperature: 60, high: 65, low: 50, humidity: 70, wind: 5, code: 95,
      sunset: Fixtures.date, utcOffset: 7200, observedAt: Fixtures.date)
    XCTAssertEqual(weather.condition, "Thunderstorms")
    XCTAssertEqual(weather.symbol, "cloud.bolt.rain.fill")
    XCTAssertEqual(weather.sunsetLabel, "12:09 PM")
  }

}
