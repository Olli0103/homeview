import XCTest
@testable import HomeViewCore

final class WorldClockTests: XCTestCase {
  private func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }
  private func city(_ zone: String) -> WorldCity { WorldCity.catalogue.first { $0.zone == zone }! }
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
      XCTAssertGreaterThan(SolarPosition.altitude(at: date("2026-06-21T\(hour):00:00Z"), latitude: oslo.latitude, longitude: oslo.longitude), -0.833)
      XCTAssertLessThan(SolarPosition.altitude(at: date("2026-12-21T\(hour):00:00Z"), latitude: oslo.latitude, longitude: oslo.longitude), -0.833)
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
}
