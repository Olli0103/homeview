import XCTest
@testable import HomeViewCore

final class WeatherTests: XCTestCase {
  private func parse(_ json: String) throws -> WeatherReading {
    try JSONDecoder().decode(OpenMeteoForecast.self, from: Data(json.utf8)).reading(city: "Synthetic")
  }
  func testNullAndMissingMetricsAreUnknownNotDefaultWeather() throws {
    let reading = try parse(#"{"utc_offset_seconds":0,"current":{"time":1700000000,"temperature_2m":null},"daily":{"sunset":[null]}}"#)
    XCTAssertNil(reading.temperature); XCTAssertNil(reading.high); XCTAssertNil(reading.wind)
    XCTAssertNil(reading.sunrise); XCTAssertNil(reading.sunset)
    XCTAssertEqual(reading.sunsetLabel,"—"); XCTAssertEqual(reading.condition,"Condition unavailable")
    XCTAssertEqual(WeatherUnits.fahrenheit.temperature(reading.temperature),"—")
  }
  func testOutOfRangeMetricsDoNotReachIntegerRendering() throws {
    let reading = try parse(#"{"utc_offset_seconds":0,"current":{"time":1700000000,"temperature_2m":1e100,"relative_humidity_2m":101,"wind_speed_10m":-1,"is_day":2,"cloud_cover":120},"daily":{"temperature_2m_max":[200],"sunrise":[-1]}}"#)
    XCTAssertNil(reading.temperature); XCTAssertNil(reading.high); XCTAssertNil(reading.humidity)
    XCTAssertNil(reading.wind); XCTAssertNil(reading.isDay); XCTAssertNil(reading.cloudCover)
    XCTAssertNil(reading.sunrise)
    XCTAssertEqual(WeatherUnits.celsius.temperature(.infinity),"—")
    XCTAssertEqual(WeatherUnits.fahrenheit.wind(.nan),"—")
  }
  func testObservationTimeRequiredAndOffsetValidated() {
    for json in [#"{"utc_offset_seconds":0,"current":{}}"#,
      #"{"utc_offset_seconds":-9223372036854775808,"current":{"time":1700000000}}"#,
      #"{"utc_offset_seconds":0,"current":{"time":-1}}"#] {
      XCTAssertThrowsError(try parse(json))
    }
  }
  func testUnitsAndFractionalSunTimeUseSourceOffset() throws {
    let reading = try parse(#"{"utc_offset_seconds":20700,"current":{"time":1700000000,"temperature_2m":32,"wind_speed_10m":10},"daily":{"sunrise":[1700000000],"sunset":[1700000000]}}"#)
    XCTAssertEqual(WeatherUnits.celsius.temperature(reading.temperature),"0°")
    XCTAssertEqual(WeatherUnits.celsius.wind(reading.wind),"16 km/h")
    XCTAssertEqual(WeatherUnits.fahrenheit.wind(reading.wind),"10 mph")
    XCTAssertEqual(reading.sunsetLabel,"3:58 AM")
  }
  func testStaleAndFutureTimestampsAreNotFresh() throws {
    let reading = try parse(#"{"utc_offset_seconds":0,"current":{"time":1700000000}}"#)
    XCTAssertFalse(reading.stale(at: reading.observedAt.addingTimeInterval(3600)))
    XCTAssertTrue(reading.stale(at: reading.observedAt.addingTimeInterval(3601)))
    XCTAssertTrue(reading.stale(at: reading.observedAt.addingTimeInterval(-301)))
  }
  func testWeatherCodesAndDayNightAreExplicit() throws {
    let cases: [(Int,String)] = [(0,"Clear"),(3,"Overcast"),(48,"Fog"),(66,"Rain"),(86,"Snow"),(99,"Thunderstorms"),(98,"Condition unavailable")]
    for (code,condition) in cases {
      let reading = try parse("{\"utc_offset_seconds\":0,\"current\":{\"time\":1700000000,\"weather_code\":\(code),\"is_day\":0}}")
      XCTAssertEqual(reading.condition,condition)
      if code == 0 { XCTAssertEqual(reading.symbol,"moon.stars.fill") }
    }
  }
  func testHourlyMetricsStayAlignedWhenValuesAreNullMissingOrOutOfRange() throws {
    let reading=try parse(#"{"utc_offset_seconds":0,"current":{"time":1700000000},"hourly":{"time":[1700003600,1700007200,1700010800],"temperature_2m":[55,null],"precipitation_probability":[20,110,35],"wind_speed_10m":[-1,12],"weather_code":[2,61,0],"is_day":[1,0]}}"#)
    XCTAssertEqual(reading.upcomingHours.count,3)
    XCTAssertEqual(reading.hourly[0].temperature,55)
    XCTAssertNil(reading.hourly[1].temperature);XCTAssertNil(reading.hourly[2].temperature)
    XCTAssertNil(reading.hourly[1].rainChance);XCTAssertEqual(reading.hourly[2].rainChance,35)
    XCTAssertNil(reading.hourly[0].wind);XCTAssertEqual(reading.hourly[1].wind,12)
    XCTAssertEqual(reading.hourly[1].symbol,"cloud.rain.fill")
    XCTAssertNil(reading.hourly[2].isDay)
  }
  func testMalformedHourlyTimeDoesNotDestroyUsableCurrentWeather() throws {
    for times in ["[1700003600,1700003600]","[1700007200,1700003600]","[null]","[-1]",
      "["+Array(repeating:"1700003600",count:169).joined(separator:",")+"]"] {
      let reading=try parse("{\"utc_offset_seconds\":0,\"current\":{\"time\":1700000000,\"temperature_2m\":55},\"hourly\":{\"time\":\(times)}}")
      XCTAssertEqual(reading.temperature,55);XCTAssertTrue(reading.hourly.isEmpty)
    }
  }
  func testFutureHoursKeepFull24HourWindowAndDoNotInventHorizon() throws {
    let times=(0...30).map {1700000000+$0*3600}
    let json="{\"utc_offset_seconds\":0,\"current\":{\"time\":1700000000},\"hourly\":{\"time\":\(times)}}"
    let reading=try parse(json)
    XCTAssertEqual(reading.hourly.count,31);XCTAssertEqual(reading.upcomingHours.count,24)
    let missing=try parse(#"{"utc_offset_seconds":0,"current":{"time":1700000000}}"#)
    XCTAssertTrue(missing.upcomingHours.isEmpty)
  }
  func testHourlyLabelsUseSourceIANATimeZoneAcrossFallDST() throws {
    let formatter=ISO8601DateFormatter()
    let before=formatter.date(from:"2026-10-25T00:00:00Z")!,after=formatter.date(from:"2026-10-25T01:00:00Z")!
    let json="{\"timezone\":\"Europe/Berlin\",\"utc_offset_seconds\":7200,\"current\":{\"time\":\(before.timeIntervalSince1970)},\"hourly\":{\"time\":[\(before.timeIntervalSince1970),\(after.timeIntervalSince1970)]}}"
    let reading=try parse(json)
    XCTAssertEqual(reading.hourly[0].label(timeZone:reading.timeZone),"2AM")
    XCTAssertEqual(reading.hourly[1].label(timeZone:reading.timeZone),"2AM")
    XCTAssertNotEqual(reading.hourly[0].id,reading.hourly[1].id)
  }
  func testAllCurrentlyDocumentedWeatherCodesReachCurrentAndHourlyConditions() throws {
    // Open-Meteo's 30 October 2026 WW table includes heavy thunderstorm97.
    let groups:[([Int],String)]=[([0],"Clear"),([1,2],"Partly Cloudy"),([3],"Overcast"),
      ([45,48],"Fog"),([51,53,55,56,57,61,63,65,66,67,80,81,82],"Rain"),
      ([71,73,75,77,85,86],"Snow"),([95,96,97,99],"Thunderstorms")]
    XCTAssertEqual(groups.flatMap(\.0).count,29)
    for (codes,expected) in groups { for code in codes { for day in [0,1] {
      let reading=try parse("{\"utc_offset_seconds\":0,\"current\":{\"time\":1700000000,\"weather_code\":\(code),\"is_day\":\(day)},\"hourly\":{\"time\":[1700003600],\"weather_code\":[\(code)],\"is_day\":[\(day)]}}")
      XCTAssertEqual(reading.code,code);XCTAssertEqual(reading.condition,expected,"Current WW\(code),day\(day)")
      XCTAssertEqual(reading.hourly.count,1);XCTAssertEqual(reading.hourly[0].code,code)
      XCTAssertNotEqual(reading.symbol,"questionmark.circle","Current documented WW\(code)")
      XCTAssertNotEqual(reading.hourly[0].symbol,"questionmark.circle","Hourly documented WW\(code)")
      if expected=="Thunderstorms" {
        XCTAssertEqual(reading.symbol,"cloud.bolt.rain.fill")
        XCTAssertEqual(reading.hourly[0].symbol,"cloud.bolt.rain.fill")
      }
    }}}
    for code in [-1,4,49,98,100,Int.max] {
      XCTAssertEqual(WeatherReading.condition(for:code),"Condition unavailable")
      XCTAssertEqual(WeatherReading.symbol(for:code,isDay:false),"questionmark.circle")
    }
  }
  func testPolarSourceDaylightDoesNotRequireInventedSunriseOrSunset() throws {
    let dates=ISO8601DateFormatter()
    for (stamp,day) in [("2026-06-21T12:00:00Z",1),("2026-12-21T12:00:00Z",0)] {
      let time=dates.date(from:stamp)!.timeIntervalSince1970
      for missing in ["null","0"] {
        let reading=try parse("{\"timezone\":\"Arctic/Longyearbyen\",\"utc_offset_seconds\":3600,\"current\":{\"time\":\(time),\"weather_code\":0,\"is_day\":\(day)},\"daily\":{\"sunrise\":[\(missing)],\"sunset\":[\(missing)]}}")
        XCTAssertEqual(reading.isDay,day==1);XCTAssertNil(reading.sunrise);XCTAssertNil(reading.sunset)
        XCTAssertEqual(reading.sunLabel(reading.sunrise),"—");XCTAssertEqual(reading.sunsetLabel,"—")
        XCTAssertEqual(reading.symbol,day==1 ? "sun.max.fill":"moon.stars.fill")
        XCTAssertEqual(reading.observedAt.timeIntervalSince1970,time)
      }
    }
  }
  func testSolarEventsUseEventIANAOffsetAcrossDSTAndExplicitFallbackOnly() throws {
    let date=ISO8601DateFormatter().date(from:"2026-03-29T06:00:00Z")!.timeIntervalSince1970
    let json="{\"timezone\":\"Europe/Berlin\",\"utc_offset_seconds\":3600,\"current\":{\"time\":\(date-21600)},\"daily\":{\"sunrise\":[\(date)],\"sunset\":[\(date+36000)]}}"
    let reading=try parse(json)
    XCTAssertEqual(reading.sunLabel(reading.sunrise),"8:00 AM")
    XCTAssertEqual(reading.sunsetLabel,"6:00 PM")
    XCTAssertEqual(reading.sunrise?.timeIntervalSince1970,date,"Unix seconds must not receive a second timezone shift")
    for (zone,offset,label) in [("No/SuchZone",20700,"11:45 AM"),("",-12600,"2:30 AM")] {
      let fallback=try parse("{\"timezone\":\"\(zone)\",\"utc_offset_seconds\":\(offset),\"current\":{\"time\":\(date)},\"daily\":{\"sunrise\":[\(date)]}}")
      XCTAssertEqual(fallback.sunLabel(fallback.sunrise),label)
    }
  }
  func testMissingFirstDailySunEventDoesNotBorrowAnotherDaysEvent() throws {
    for values in ["[]","[null,1700003600]","[0,1700003600]","[-1,1700003600]"] {
      let reading=try parse("{\"utc_offset_seconds\":0,\"current\":{\"time\":1700000000,\"is_day\":1},\"daily\":{\"sunrise\":\(values),\"sunset\":\(values)}}")
      XCTAssertNil(reading.sunrise);XCTAssertNil(reading.sunset);XCTAssertEqual(reading.sunsetLabel,"—")
      XCTAssertEqual(reading.isDay,true)
    }
  }
  func testUnknownDaylightIsNotInferredFromAbsentSunEvents() throws {
    for day in ["null","-1","2"] {
      let reading=try parse("{\"utc_offset_seconds\":0,\"current\":{\"time\":1700000000,\"is_day\":\(day)},\"daily\":{\"sunrise\":[0],\"sunset\":[null]},\"hourly\":{\"time\":[1700003600],\"is_day\":[\(day)]}}")
      XCTAssertNil(reading.isDay);XCTAssertNil(reading.hourly[0].isDay)
      XCTAssertNil(reading.sunrise);XCTAssertNil(reading.sunset)
      XCTAssertEqual(reading.condition,"Condition unavailable")
    }
  }
  func testPolarDailyBoundaryMarkersAreNotPresentedAsActualSolarEvents() throws {
    // Official Open-Meteo SunRiseSet.swift: polar night=start/start;
    // polar day=start/start+86400. The daily boundary, not the host clock, binds the marker.
    let start=ISO8601DateFormatter().date(from:"2026-12-20T23:00:00Z")!.timeIntervalSince1970
    for duration in [0,86400] { for day in ["null","0","1"] {
      let reading=try parse("{\"timezone\":\"Arctic/Longyearbyen\",\"utc_offset_seconds\":3600,\"current\":{\"time\":\(start+43200),\"is_day\":\(day)},\"daily\":{\"time\":[\(start)],\"sunrise\":[\(start)],\"sunset\":[\(start+Double(duration))]}}")
      XCTAssertNil(reading.sunrise);XCTAssertNil(reading.sunset)
      XCTAssertEqual(reading.sunLabel(reading.sunrise),"—");XCTAssertEqual(reading.sunsetLabel,"—")
      XCTAssertEqual(reading.isDay,day=="null" ? nil:day=="1","Do not infer current daylight from a daily boundary pair")
    }}
    let ordinary=try parse("{\"utc_offset_seconds\":3600,\"current\":{\"time\":\(start+43200)},\"daily\":{\"time\":[\(start)],\"sunrise\":[\(start)],\"sunset\":[\(start+36000)]}}")
    XCTAssertEqual(ordinary.sunrise?.timeIntervalSince1970,start,"Midnight alone is not a polar marker")
    XCTAssertEqual(ordinary.sunset?.timeIntervalSince1970,start+36000)
    let oneEvent=try parse("{\"utc_offset_seconds\":3600,\"current\":{\"time\":\(start+43200)},\"daily\":{\"time\":[\(start)],\"sunrise\":[null],\"sunset\":[\(start+36000)]}}")
    XCTAssertNil(oneEvent.sunrise);XCTAssertEqual(oneEvent.sunset?.timeIntervalSince1970,start+36000)
  }
}
