import Foundation

/// Public Open-Meteo forecast. No account/key, GPS, personal store or HomeKit.
struct WeatherService {
  // A caller-owned session also permits isolated transport verification without
  // contacting a provider. Ordinary app requests use a fresh ephemeral session.
  var session: URLSession? = nil
  private struct Places: Decodable {
    struct Place: Decodable {
      let name: String
      let latitude: Double
      let longitude: Double
      let country: String?
    }
    let results: [Place]?
  }
  private func get<T: Decodable>(
    _ type: T.Type, host: String, path: String, query: [String: String], timeout: TimeInterval = 15
  ) async throws -> T {
    var c = URLComponents()
    c.scheme = "https"
    c.host = host
    c.path = path
    c.queryItems = query.sorted(by: { $0.key < $1.key }).map {
      URLQueryItem(name: $0.key, value: $0.value)
    }
    guard let url = c.url else { throw URLError(.badURL) }
    let session = self.session ?? URLSession(configuration: .ephemeral)
    defer { if self.session == nil { session.finishTasksAndInvalidate() } }
    var request = URLRequest(url: url)
    request.timeoutInterval = timeout
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
      OpenMeteoForecast.self, host: "api.open-meteo.com", path: "/v1/forecast",
      query: [
        "latitude": String(p.latitude), "longitude": String(p.longitude),
        "current": "temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,is_day,cloud_cover,precipitation",
        "daily": "temperature_2m_max,temperature_2m_min,sunrise,sunset", "temperature_unit": "fahrenheit",
        "hourly": "temperature_2m,precipitation_probability,wind_speed_10m,weather_code,is_day",
        "wind_speed_unit": "mph", "timezone": "auto", "timeformat": "unixtime",
        "forecast_days": "2",
      ])
    var reading = try f.reading(city: p.name)
    try Task.checkCancellation()
    // Optional, independently timed CAMS model. A failed pollution request must
    // not discard usable weather; cancellation still belongs to the caller.
    do {
      let air = try await get(OpenMeteoAirQuality.self,
        host: "air-quality-api.open-meteo.com", path: "/v1/air-quality",
        query: ["latitude": String(p.latitude), "longitude": String(p.longitude),
          "current": "european_aqi", "timeformat": "unixtime", "timezone": "GMT"], timeout: 8)
      reading.airQuality = air.reading
    } catch {
      try Task.checkCancellation()
      if error is CancellationError || (error as? URLError)?.code == .cancelled { throw error }
    }
    try Task.checkCancellation()
    return reading
  }
}
