import Foundation

/// Public Open-Meteo forecast. No account/key, GPS, personal store or HomeKit.
struct WeatherService {
  private struct Places: Decodable {
    struct Place: Decodable {
      let name: String
      let latitude: Double
      let longitude: Double
      let country: String?
    }
    let results: [Place]?
  }
  private struct Forecast: Decodable {
    struct Current: Decodable {
      let time: Double
      let temperature_2m: Double
      let relative_humidity_2m: Double
      let weather_code: Int
      let wind_speed_10m: Double
    }
    struct Daily: Decodable {
      let temperature_2m_max: [Double]
      let temperature_2m_min: [Double]
      let sunset: [Double]
    }
    let utc_offset_seconds: Int
    let current: Current
    let daily: Daily
  }
  private func get<T: Decodable>(
    _ type: T.Type, host: String, path: String, query: [String: String]
  ) async throws -> T {
    var c = URLComponents()
    c.scheme = "https"
    c.host = host
    c.path = path
    c.queryItems = query.sorted(by: { $0.key < $1.key }).map {
      URLQueryItem(name: $0.key, value: $0.value)
    }
    guard let url = c.url else { throw URLError(.badURL) }
    let session = URLSession(configuration: .ephemeral)
    defer { session.finishTasksAndInvalidate() }
    var request = URLRequest(url: url)
    request.timeoutInterval = 15
    let (bytes, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200, bytes.count < 1_000_000
    else { throw URLError(.badServerResponse) }
    return try JSONDecoder().decode(T.self, from: bytes)
  }
  func fetch(city: String) async throws -> WeatherReading {
    let name = city.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty, name.count <= 100 else { throw URLError(.badURL) }
    let places = try await get(
      Places.self, host: "geocoding-api.open-meteo.com", path: "/v1/search",
      query: ["name": name, "count": "1", "language": "en", "format": "json"])
    guard let p = places.results?.first else { throw URLError(.resourceUnavailable) }
    let f = try await get(
      Forecast.self, host: "api.open-meteo.com", path: "/v1/forecast",
      query: [
        "latitude": String(p.latitude), "longitude": String(p.longitude),
        "current": "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m",
        "daily": "temperature_2m_max,temperature_2m_min,sunset", "temperature_unit": "fahrenheit",
        "wind_speed_unit": "mph", "timezone": "auto", "timeformat": "unixtime",
        "forecast_days": "1",
      ])
    guard let high = f.daily.temperature_2m_max.first, let low = f.daily.temperature_2m_min.first,
      let sunset = f.daily.sunset.first,
      f.current.temperature_2m.isFinite, f.current.relative_humidity_2m.isFinite,
      f.current.wind_speed_10m.isFinite
    else { throw URLError(.cannotParseResponse) }
    return WeatherReading(
      city: p.name, temperature: f.current.temperature_2m, high: high, low: low,
      humidity: f.current.relative_humidity_2m, wind: f.current.wind_speed_10m,
      code: f.current.weather_code, sunset: Date(timeIntervalSince1970: sunset),
      utcOffset: f.utc_offset_seconds, observedAt: Date(timeIntervalSince1970: f.current.time))
  }
}
