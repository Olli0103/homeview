import XCTest
@testable import HomeViewCore

final class WorldClockTests: XCTestCase {
  private func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }
  private func city(_ zone: String) -> WorldCity { WorldCity.catalogue.first { $0.zone == zone }! }
  func testDaylightPositionsRetainActualDSTDayLength() throws {
    let berlin = city("Europe/Berlin")
    var calendar = Calendar(identifier: .gregorian); calendar.timeZone = berlin.timeZone
    for (instant, hours) in [("2026-03-29T12:00:00Z", 23.0), ("2026-10-25T12:00:00Z", 25.0)] {
      let day = try XCTUnwrap(calendar.dateInterval(of: .day, for: date(instant)))
      XCTAssertEqual(day.duration, hours * 3600)
      let window = DaylightWindow.compute(latitude: berlin.latitude, longitude: berlin.longitude,
        dayOf: date(instant), zone: berlin.timeZone)
      let rise = try XCTUnwrap(window.sunrise), set = try XCTUnwrap(window.sunset)
      XCTAssertEqual(try XCTUnwrap(window.sunriseFraction), rise.timeIntervalSince(day.start) / day.duration)
      XCTAssertEqual(try XCTUnwrap(window.sunsetFraction), set.timeIntervalSince(day.start) / day.duration)
      XCTAssertTrue(day.contains(rise)); XCTAssertTrue(day.contains(set))
    }
  }
  func testDaylightChangesAtLocalMidnightWithoutLosingSameDayIdentity() throws {
    let berlin = city("Europe/Berlin")
    func window(_ instant: String) -> DaylightWindow {
      DaylightWindow.compute(latitude: berlin.latitude, longitude: berlin.longitude,
        dayOf: date(instant), zone: berlin.timeZone)
    }
    XCTAssertEqual(window("2026-06-21T12:00:00Z"), window("2026-06-21T21:59:59Z"))
    let before = window("2026-06-21T21:59:59Z"), after = window("2026-06-21T22:00:00Z")
    XCTAssertGreaterThan(try XCTUnwrap(after.sunrise), try XCTUnwrap(before.sunrise))
    XCTAssertNotEqual(before, after)
  }
  func testDifferentCoordinatesWithinOneZoneCannotShareTheSolarWindow() {
    let instant = date("2026-06-21T12:00:00Z"), zone = TimeZone(identifier: "Europe/Oslo")!
    let tromso = DaylightWindow.compute(latitude: 69.65, longitude: 18.96, dayOf: instant, zone: zone)
    let oslo = DaylightWindow.compute(latitude: 59.91, longitude: 10.75, dayOf: instant, zone: zone)
    XCTAssertEqual(tromso.kind, .polarDay)
    XCTAssertEqual(oslo.kind, .normal)
    XCTAssertNotNil(oslo.sunrise)
    XCTAssertNotEqual(tromso, oslo)
  }
  func testChangedZoneAndUnknownCoordinatesKeepTheirOwnWindow() {
    let instant = date("2026-06-21T22:30:00Z")
    let berlin = TimeZone(identifier: "Europe/Berlin")!, utc = TimeZone(secondsFromGMT: 0)!
    let a = DaylightWindow.compute(latitude: 52.52, longitude: 13.41, dayOf: instant, zone: berlin)
    let b = DaylightWindow.compute(latitude: 52.52, longitude: 13.41, dayOf: instant, zone: utc)
    XCTAssertNotEqual(a.sunrise, b.sunrise)
    let missing = DaylightWindow.compute(latitude: nil, longitude: nil, dayOf: instant, zone: berlin)
    XCTAssertEqual(missing.kind, .unavailable)
    XCTAssertTrue(missing.daylightIntervals.isEmpty)
  }
  func testAucklandCanBeTwoCalendarDatesAheadOfUTCMinusTwelve() {
    let reading=WorldClockReading(city:city("Pacific/Auckland"),
      instant:date("2026-01-01T11:30:00Z"),referenceZone:TimeZone(identifier:"Etc/GMT+12")!,
      locale:Locale(identifier:"en_GB"))
    XCTAssertEqual(reading.date,"Fri 2 Jan")
    XCTAssertEqual(reading.time,"00:30")
    XCTAssertEqual(reading.dayDifference,2)
    XCTAssertEqual(reading.dayRelation,"2 days ahead")
  }
  func testDateRelationRetainsSingleDayLabelsAndHandlesReverseExtreme() {
    let utc=TimeZone(secondsFromGMT:0)!,locale=Locale(identifier:"en_GB")
    func reading(_ zone:String,_ instant:String)->WorldClockReading {
      WorldClockReading(city:city(zone),instant:date(instant),referenceZone:utc,locale:locale)
    }
    XCTAssertEqual(reading("Pacific/Auckland","2026-01-01T23:30:00Z").dayRelation,"Next day")
    XCTAssertEqual(reading("Pacific/Honolulu","2026-01-01T00:30:00Z").dayRelation,"Previous day")
    XCTAssertNil(reading("Europe/Berlin","2026-01-01T12:00:00Z").dayRelation)
    // Synthetic IANA city validates the reverse formatter boundary; it is not
    // claimed as an additional selectable city in the current curated list.
    let reverse=WorldClockReading(city:WorldCity(name:"Synthetic UTC-12",zone:"Etc/GMT+12",latitude:0,longitude:-180),
      instant:date("2026-01-01T10:30:00Z"),referenceZone:TimeZone(identifier:"Pacific/Kiritimati")!,locale:locale)
    XCTAssertEqual(reverse.date,"Wed 31 Dec")
    XCTAssertEqual(reverse.dayDifference,-2)
    XCTAssertEqual(reverse.dayRelation,"2 days behind")
  }
  func testFractionalOffsetsAndOppositeDatesUseZoneRules() {
    let instant = date("2026-01-01T00:30:00Z"), utc = TimeZone(secondsFromGMT: 0)!
    let locale = Locale(identifier: "en_GB")
    let nepal = WorldClockReading(city: city("Asia/Kathmandu"), instant: instant, referenceZone: utc, locale: locale)
    XCTAssertEqual(nepal.time, "06:15")
    XCTAssertEqual(nepal.offset, "UTC+05:45")
    let india = WorldClockReading(city: city("Asia/Kolkata"), instant: instant, referenceZone: utc, locale: locale)
    XCTAssertEqual(india.time, "06:00")
    let hawaii = WorldClockReading(city: city("Pacific/Honolulu"), instant: instant, referenceZone: utc, locale: locale)
    XCTAssertEqual(hawaii.dayDifference, -1)
    XCTAssertEqual(hawaii.time, "14:30")
    let tomorrow = WorldClockReading(city: city("Pacific/Auckland"), instant: date("2026-01-01T23:30:00Z"), referenceZone: utc, locale: locale)
    XCTAssertEqual(tomorrow.dayDifference, 1)
    XCTAssertEqual(tomorrow.time, "12:30")
  }
  func testDifferentDSTChangeDatesAndSouthernHemisphere() {
    let utc = TimeZone(secondsFromGMT: 0)!, locale = Locale(identifier: "en_GB")
    let instant = date("2026-03-15T12:00:00Z")
    XCTAssertEqual(WorldClockReading(city: city("Europe/Berlin"), instant: instant, referenceZone: utc, locale: locale).offset, "UTC+01:00")
    XCTAssertEqual(WorldClockReading(city: city("America/New_York"), instant: instant, referenceZone: utc, locale: locale).offset, "UTC−04:00")
    let adelaide = city("Australia/Adelaide")
    XCTAssertEqual(WorldClockReading(city: adelaide, instant: instant, referenceZone: utc, locale: locale).offset, "UTC+10:30")
    XCTAssertEqual(WorldClockReading(city: adelaide, instant: date("2026-07-01T12:00:00Z"), referenceZone: utc, locale: locale).offset, "UTC+09:30")
  }
  func testDSTMissingAndRepeatedHourDoNotInventAClockTime() {
    let berlin = city("Europe/Berlin"), utc = TimeZone(secondsFromGMT: 0)!, locale = Locale(identifier: "en_GB")
    func reading(_ value: String) -> WorldClockReading {
      WorldClockReading(city: berlin, instant: date(value), referenceZone: utc, locale: locale)
    }
    XCTAssertEqual(reading("2026-03-29T00:59:00Z").time, "01:59")
    XCTAssertEqual(reading("2026-03-29T01:00:00Z").time, "03:00")
    XCTAssertEqual(reading("2026-10-25T00:30:00Z").time, "02:30")
    XCTAssertEqual(reading("2026-10-25T01:30:00Z").time, "02:30")
    XCTAssertNotEqual(reading("2026-10-25T00:30:00Z").offset, reading("2026-10-25T01:30:00Z").offset)
  }
  func testOfflineSunEstimateHandlesPolarDayAndNight() {
    let oslo = city("Europe/Oslo")
    for hour in ["00", "12"] {
      XCTAssertGreaterThan(SolarPosition.altitude(at: date("2026-06-21T\(hour):00:00Z"), latitude: oslo.latitude!, longitude: oslo.longitude!), -0.833)
      XCTAssertLessThan(SolarPosition.altitude(at: date("2026-12-21T\(hour):00:00Z"), latitude: oslo.latitude!, longitude: oslo.longitude!), -0.833)
    }
    XCTAssertGreaterThan(SolarPosition.altitude(at: date("2026-03-20T12:00:00Z"), latitude: 0, longitude: 0), 85)
    XCTAssertLessThan(SolarPosition.altitude(at: date("2026-03-20T00:00:00Z"), latitude: 0, longitude: 0), -85)
  }
  func testSelectionMigrationIsBoundedAndPreservesAnIntentionallyEmptyList() throws {
    let list = WorldCity.normalized(["garbage"] + WorldCity.catalogue.map(\.zone) + WorldCity.defaults)
    XCTAssertEqual(list.count, 12)
    XCTAssertEqual(Set(list).count, 12)
    XCTAssertTrue(WorldCity.catalogue.allSatisfy { TimeZone(identifier: $0.zone) != nil })
    let old = try Snapshot.decodeMigrating(Data("{}".utf8))
    XCTAssertEqual(old.worldClockZones, WorldCity.defaults)
    let empty = try Snapshot.decodeMigrating(Data("{\"worldClockZones\":[]}".utf8))
    XCTAssertTrue(empty.worldClockZones.isEmpty)
    let malformed = try Snapshot.decodeMigrating(Data("{\"worldClockZones\":42}".utf8))
    XCTAssertEqual(malformed.worldClockZones, WorldCity.defaults)
    let saved = try Snapshot.decodeMigrating(Data("{\"worldClockZones\":[\"Asia/Kathmandu\",\"Asia/Kathmandu\",\"bad\"]}".utf8))
    XCTAssertEqual(saved.worldClockZones,["Asia/Kathmandu"])
  }

  func testEveryKnownZoneResolvesWithoutInventingASunPosition() {
    let identifiers = TimeZone.knownTimeZoneIdentifiers
    XCTAssertGreaterThan(identifiers.count, 300)
    for zone in identifiers {
      let city = WorldCity.city(for: zone)
      XCTAssertNotNil(city, zone)
      guard let city else { continue }
      XCTAssertEqual(city.zone, zone)
      XCTAssertFalse(city.name.isEmpty)
      if WorldCity.catalogue.contains(where: { $0.zone == zone }) { continue }
      XCTAssertFalse(city.hasCoordinates, zone)
      let reading = WorldClockReading(city: city, instant: date("2026-06-21T12:00:00Z"),
        referenceZone: TimeZone(secondsFromGMT: 0)!, locale: Locale(identifier: "en_GB"))
      XCTAssertNil(reading.daylight, zone)
      XCTAssertEqual(reading.sun.kind, .unavailable, zone)
      XCTAssertNil(reading.sun.sunriseFraction, zone)
    }
    XCTAssertNil(WorldCity.city(for: "Mars/Olympus"))
    XCTAssertNil(WorldCity.derivedZone("not a zone"))
  }
  func testDaylightWindowPlacementInsideTheLocalDay() {
    let utc = TimeZone(secondsFromGMT: 0)!, locale = Locale(identifier: "en_GB")
    let berlin = city("Europe/Berlin")
    let reading = WorldClockReading(city: berlin, instant: date("2026-06-21T12:00:00Z"),
      referenceZone: utc, locale: locale)
    XCTAssertEqual(reading.sun.kind, .normal)
    let sunrise = try? XCTUnwrap(reading.sun.sunrise)
    let sunset = try? XCTUnwrap(reading.sun.sunset)
    guard let sunrise, let sunset else { return XCTFail("missing crossings") }
    XCTAssertLessThan(sunrise, sunset)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = berlin.timeZone
    XCTAssertEqual(calendar.component(.hour, from: sunrise), 4)
    XCTAssertEqual(calendar.component(.hour, from: sunset), 21)
    for fraction in [reading.sun.sunriseFraction!, reading.sun.sunsetFraction!] {
      XCTAssertGreaterThan(fraction, 0)
      XCTAssertLessThan(fraction, 1)
    }
    XCTAssertGreaterThan(reading.sun.sunsetFraction!, reading.sun.sunriseFraction!)
  }
  func testPolarDayAndNightReportTheirOwnKind() {
    let utc = TimeZone(secondsFromGMT: 0)!, locale = Locale(identifier: "en_GB")
    let tromso = city("Europe/Oslo")
    let summer = WorldClockReading(city: tromso, instant: date("2026-06-21T12:00:00Z"), referenceZone: utc, locale: locale)
    XCTAssertEqual(summer.sun.kind, .polarDay)
    XCTAssertNil(summer.sun.sunrise)
    XCTAssertEqual(summer.daylight, true)
    let winter = WorldClockReading(city: tromso, instant: date("2026-12-21T12:00:00Z"), referenceZone: utc, locale: locale)
    XCTAssertEqual(winter.sun.kind, .polarNight)
    XCTAssertNil(winter.sun.sunset)
    XCTAssertEqual(winter.daylight, false)
  }
  func testNormalizedAcceptsAnyKnownZoneAndRejectsUnknown() {
    let list = WorldCity.normalized(["Asia/Shanghai", "Asia/Shanghai", "Mars/Olympus", "UTC"]
      + WorldCity.catalogue.map(\.zone))
    XCTAssertEqual(list.first, "Asia/Shanghai")
    XCTAssertTrue(list.contains("UTC"))
    XCTAssertFalse(list.contains("Mars/Olympus"))
    XCTAssertEqual(list.count, 12)
    XCTAssertEqual(Set(list).count, 12)
    let derived = WorldCity.city(for: "America/Argentina/Buenos_Aires")
    XCTAssertEqual(derived?.name, "Buenos Aires")
    XCTAssertFalse(derived?.hasCoordinates ?? true)
    let underscore = WorldCity.city(for: "America/Port_of_Spain")
    XCTAssertEqual(underscore?.name, "Port of Spain")
  }
  func testReykjavikDaylightWrapsAcrossLocalMidnight() throws {
    let reykjavik=city("Atlantic/Reykjavik")
    let window=DaylightWindow.compute(latitude:reykjavik.latitude,longitude:reykjavik.longitude,
      dayOf:date("2026-06-21T12:00:00Z"),zone:reykjavik.timeZone)
    XCTAssertEqual(window.kind,.normal)
    let rise=try XCTUnwrap(window.sunriseFraction),set=try XCTUnwrap(window.sunsetFraction)
    XCTAssertLessThan(set,rise,"The previous solar day's sunset falls just after local midnight")
    // The existing renderer subtracts these in the opposite order and clamps
    // to zero, incorrectly painting this 21-hour daylight day entirely dark.
    XCTAssertGreaterThan(set + 1 - rise,0.85)
    XCTAssertEqual(window.daylightIntervals,[0...set,rise...1])
    XCTAssertFalse(window.daylightIntervals.contains { $0.contains((rise+set)/2) })
  }
  func testDaylightIntervalsAgreeWithSunPositionAcrossPolarTransitionsAndDST() throws {
    let dates=["2026-03-29T12:00:00Z","2026-10-25T12:00:00Z","2026-05-17T12:00:00Z",
      "2026-07-26T12:00:00Z","2026-06-21T12:00:00Z","2026-12-21T12:00:00Z"]
    var singleCrossings=0
    for identifier in ["Europe/Oslo","Atlantic/Reykjavik","Europe/Berlin","Australia/Sydney"] {
      let place=city(identifier)
      var calendar=Calendar(identifier:.gregorian);calendar.timeZone=place.timeZone
      for value in dates {
        let instant=date(value),day=try XCTUnwrap(calendar.dateInterval(of:.day,for:instant))
        let sun=DaylightWindow.compute(latitude:place.latitude,longitude:place.longitude,dayOf:instant,zone:place.timeZone)
        if (sun.sunrise == nil) != (sun.sunset == nil) { singleCrossings+=1 }
        for span in sun.daylightIntervals {
          XCTAssertGreaterThanOrEqual(span.lowerBound,0);XCTAssertLessThanOrEqual(span.upperBound,1)
        }
        for minute in stride(from:5,to:Int(day.duration/60),by:10) {
          let fraction=Double(minute)*60/day.duration
          let altitude=SolarPosition.altitude(at:day.start.addingTimeInterval(Double(minute)*60),
            latitude:place.latitude!,longitude:place.longitude!)
          XCTAssertEqual(sun.daylightIntervals.contains { $0.contains(fraction) },altitude >= -0.833,"\(identifier) \(value) minute \(minute)")
        }
      }
    }
    XCTAssertGreaterThan(singleCrossings,0,"Include at least one sunrise-only or sunset-only local day")
  }
}
