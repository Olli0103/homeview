import Foundation

enum WeatherUnits: String, CaseIterable {
  case fahrenheit = "°F / mph", celsius = "°C / km/h"
  func temperature(_ fahrenheit: Double?) -> String {
    guard let v = WeatherReading.valid(fahrenheit, in: -150...180) else { return "—" }
    return "\(Int((self == .celsius ? (v - 32) * 5 / 9 : v).rounded()))°"
  }
  func wind(_ mph: Double?) -> String {
    guard let v = WeatherReading.valid(mph, in: 0...400) else { return "—" }
    return "\(Int((self == .celsius ? v * 1.609344 : v).rounded())) \(self == .celsius ? "km/h" : "mph")"
  }
}

struct WeatherReading: Sendable {
  let city: String
  let temperature: Double?
  let high: Double?
  let low: Double?
  let humidity: Double?
  let wind: Double?
  let code: Int?
  let sunset: Date?
  let utcOffset: Int
  let observedAt: Date
  var sunrise: Date?
  var isDay: Bool?
  var cloudCover: Double?
  var precipitation: Double?
  static func valid(_ value: Double?, in range: ClosedRange<Double>) -> Double? {
    guard let value, value.isFinite, range.contains(value) else { return nil }
    return value
  }
  var condition: String {
    switch code {
    case 0: "Clear"
    case 1, 2: "Partly Cloudy"
    case 3: "Overcast"
    case 45, 48: "Fog"
    case 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82: "Rain"
    case 71, 73, 75, 77, 85, 86: "Snow"
    case 95, 96, 99: "Thunderstorms"
    default: "Condition unavailable"
    }
  }
  var symbol: String {
    switch condition {
    case "Clear": isDay == false ? "moon.stars.fill" : "sun.max.fill"
    case "Partly Cloudy": isDay == false ? "cloud.moon.fill" : "cloud.sun.fill"
    case "Fog": "cloud.fog.fill"
    case "Rain": "cloud.rain.fill"
    case "Snow": "cloud.snow.fill"
    case "Thunderstorms": "cloud.bolt.rain.fill"
    case "Overcast": "cloud.fill"
    default: "questionmark.circle"
    }
  }
  func sunLabel(_ date: Date?) -> String {
    guard let date else { return "—" }
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US")
    f.timeZone = TimeZone(secondsFromGMT: utcOffset)
    f.dateFormat = "h:mm a"
    return f.string(from: date)
  }
  var sunsetLabel: String { sunLabel(sunset) }
  func stale(at now: Date) -> Bool {
    now.timeIntervalSince(observedAt) > 3600 || observedAt.timeIntervalSince(now) > 300
  }
}

/// Open-Meteo's fixed Fahrenheit/mph response. Optional/null metrics stay unknown.
/// A missing/invalid observation time fails the response rather than inventing freshness.
struct OpenMeteoForecast: Decodable {
  struct Current: Decodable {
    let time: Double
    var temperature_2m: Double?
    var relative_humidity_2m: Double?
    var weather_code: Int?
    var wind_speed_10m: Double?
    var is_day: Int?
    var cloud_cover: Double?
    var precipitation: Double?
  }
  struct Daily: Decodable {
    var temperature_2m_max: [Double?]?
    var temperature_2m_min: [Double?]?
    var sunrise: [Double?]?
    var sunset: [Double?]?
  }
  let utc_offset_seconds: Int
  let current: Current
  var daily: Daily?
  func reading(city: String) throws -> WeatherReading {
    guard WeatherReading.valid(current.time, in: 0...32_503_680_000) != nil,
      (-64_800...64_800).contains(utc_offset_seconds) else { throw URLError(.cannotParseResponse) }
    func first(_ values: [Double?]?) -> Double? { values?.first ?? nil }
    func date(_ values: [Double?]?) -> Date? {
      guard let seconds = WeatherReading.valid(first(values), in: 1...32_503_680_000) else { return nil }
      return Date(timeIntervalSince1970: seconds)
    }
    return WeatherReading(city: city,
      temperature: WeatherReading.valid(current.temperature_2m, in: -150...180),
      high: WeatherReading.valid(first(daily?.temperature_2m_max), in: -150...180),
      low: WeatherReading.valid(first(daily?.temperature_2m_min), in: -150...180),
      humidity: WeatherReading.valid(current.relative_humidity_2m, in: 0...100),
      wind: WeatherReading.valid(current.wind_speed_10m, in: 0...400),
      code: current.weather_code, sunset: date(daily?.sunset), utcOffset: utc_offset_seconds,
      observedAt: Date(timeIntervalSince1970: current.time), sunrise: date(daily?.sunrise),
      isDay: current.is_day == 0 ? false : current.is_day == 1 ? true : nil,
      cloudCover: WeatherReading.valid(current.cloud_cover, in: 0...100),
      precipitation: WeatherReading.valid(current.precipitation, in: 0...10_000))
  }
}
