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
}
