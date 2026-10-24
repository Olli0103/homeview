import Foundation

struct WorldCity: Identifiable, Sendable {
  let name: String
  let zone: String
  /// Curated coordinates only. Derived zones carry none, so no sun position is
  /// invented for them.
  let latitude: Double?
  let longitude: Double?
  var id: String { zone }
  var timeZone: TimeZone { TimeZone(identifier: zone) ?? TimeZone(secondsFromGMT: 0)! }
  var hasCoordinates: Bool { latitude != nil && longitude != nil }
  static let catalogue: [Self] = [
    .init(name: "San Francisco", zone: "America/Los_Angeles", latitude: 37.77, longitude: -122.42),
    .init(name: "New York", zone: "America/New_York", latitude: 40.71, longitude: -74.01),
    .init(name: "Berlin", zone: "Europe/Berlin", latitude: 52.52, longitude: 13.41),
    .init(name: "Tokyo", zone: "Asia/Tokyo", latitude: 35.68, longitude: 139.69),
    .init(name: "London", zone: "Europe/London", latitude: 51.51, longitude: -0.13),
    .init(name: "Paris", zone: "Europe/Paris", latitude: 48.86, longitude: 2.35),
    .init(name: "Honolulu", zone: "Pacific/Honolulu", latitude: 21.31, longitude: -157.86),
    .init(name: "Auckland", zone: "Pacific/Auckland", latitude: -36.85, longitude: 174.76),
    .init(name: "Sydney", zone: "Australia/Sydney", latitude: -33.87, longitude: 151.21),
    .init(name: "Adelaide", zone: "Australia/Adelaide", latitude: -34.93, longitude: 138.60),
    .init(name: "Kathmandu", zone: "Asia/Kathmandu", latitude: 27.72, longitude: 85.32),
    .init(name: "Delhi", zone: "Asia/Kolkata", latitude: 28.61, longitude: 77.21),
    .init(name: "Singapore", zone: "Asia/Singapore", latitude: 1.35, longitude: 103.82),
    .init(name: "Dubai", zone: "Asia/Dubai", latitude: 25.20, longitude: 55.27),
    .init(name: "Reykjavik", zone: "Atlantic/Reykjavik", latitude: 64.15, longitude: -21.94),
    .init(name: "Tromsø", zone: "Europe/Oslo", latitude: 69.65, longitude: 18.96),
    .init(name: "São Paulo", zone: "America/Sao_Paulo", latitude: -23.55, longitude: -46.63)
  ]
  static let defaults = Array(catalogue.prefix(4).map(\.zone))

  /// Every IANA identifier this platform knows. Curated zones keep their
  /// coordinates and display names; all others are named after their last
  /// identifier component and carry no coordinates.
  static let allZones: [Self] = TimeZone.knownTimeZoneIdentifiers.sorted().compactMap(derivedZone)

  static func city(for zone: String) -> Self? {
    catalogue.first { $0.zone == zone } ?? derivedZone(zone)
  }

  static func derivedZone(_ zone: String) -> Self? {
    guard TimeZone(identifier: zone) != nil else { return nil }
    let parts = zone.split(separator: "/")
    let raw = parts.count > 1 ? parts[parts.count - 1] : parts[0]
    let name = raw.replacingOccurrences(of: "_", with: " ")
    return .init(name: name.isEmpty ? zone : name, zone: zone, latitude: nil, longitude: nil)
  }

  static func normalized(_ identifiers: [String]) -> [String] {
    var seen = Set<String>()
    return Array(identifiers.filter { id in
      TimeZone(identifier: id) != nil && seen.insert(id).inserted
    }.prefix(12))
  }
}

/// Bounded day/night estimate for one calendar day in the city's own zone.
/// Derived from the same low-order solar model as `WorldClockReading.daylight`.
struct DaylightWindow: Sendable, Equatable {
  enum Kind: Sendable, Equatable { case normal, polarDay, polarNight, unavailable }
  var kind: Kind = .unavailable
  var sunrise: Date?
  var sunset: Date?
  /// Position of the crossing inside the local day, 0 at midnight and 1 at the
  /// next midnight. Absent when no crossing exists.
  var sunriseFraction: Double?
  var sunsetFraction: Double?

  static func compute(latitude: Double?, longitude: Double?, dayOf instant: Date, zone: TimeZone) -> Self {
    guard let latitude, let longitude else { return .init() }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = zone
    guard let interval = calendar.dateInterval(of: .day, for: instant) else { return .init() }
    let start = interval.start, end = interval.end, span = end.timeIntervalSince(start)
    guard span > 0 else { return .init() }
    func altitude(_ date: Date) -> Double {
      SolarPosition.altitude(at: date, latitude: latitude, longitude: longitude)
    }
    let horizon = -0.833
    var sunrise: Date?, sunset: Date?
    var previous = altitude(start)
    var cursor = start
    while cursor < end {
      let step = min(cursor.addingTimeInterval(600), end)
      let current = altitude(step)
      if (previous >= horizon) != (current >= horizon) {
        var low = cursor, high = step
        let startsAbove = previous >= horizon
        for _ in 0..<24 {
          let mid = low.addingTimeInterval(high.timeIntervalSince(low) / 2)
          if (altitude(mid) >= horizon) == startsAbove { low = mid } else { high = mid }
        }
        let crossing = low.addingTimeInterval(high.timeIntervalSince(low) / 2)
        if startsAbove { sunset = crossing } else { sunrise = crossing }
      }
      previous = current
      cursor = step
    }
    if sunrise == nil && sunset == nil {
      let noon = start.addingTimeInterval(span / 2)
      return .init(kind: altitude(noon) >= horizon ? .polarDay : .polarNight)
    }
    return .init(kind: .normal, sunrise: sunrise, sunset: sunset,
      sunriseFraction: sunrise.map { $0.timeIntervalSince(start) / span },
      sunsetFraction: sunset.map { $0.timeIntervalSince(start) / span })
  }
}

struct WorldClockReading: Sendable {
  let time: String
  let date: String
  let dayDifference: Int
  let offset: String
  /// `nil` when the zone has no coordinates and no sun position is known.
  let daylight: Bool?
  let sun: DaylightWindow
  var dayRelation: String? {
    switch dayDifference {
    case 0: nil
    case -1: "Previous day"
    case 1: "Next day"
    default: "\(abs(dayDifference)) days \(dayDifference < 0 ? "behind" : "ahead")"
    }
  }
  init(city: WorldCity, instant: Date, referenceZone: TimeZone, locale: Locale = .current) {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.timeZone = city.timeZone
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    time = formatter.string(from: instant)
    formatter.timeStyle = .none
    formatter.setLocalizedDateFormatFromTemplate("EEE MMM d")
    date = formatter.string(from: instant)
    var calendar = Calendar(identifier: .gregorian)
    func localDay(_ zone: TimeZone) -> Date {
      calendar.timeZone = zone
      let components = calendar.dateComponents([.year,.month,.day], from: instant)
      calendar.timeZone = TimeZone(secondsFromGMT: 0)!
      return calendar.date(from: components)!
    }
    let target = localDay(city.timeZone), origin = localDay(referenceZone)
    dayDifference = Int((target.timeIntervalSince(origin) / 86400).rounded())
    let seconds = city.timeZone.secondsFromGMT(for: instant)
    offset = String(format: "UTC%@%02d:%02d", seconds < 0 ? "−" : "+", abs(seconds) / 3600, abs(seconds) / 60 % 60)
    if let latitude = city.latitude, let longitude = city.longitude {
      daylight = SolarPosition.altitude(at: instant, latitude: latitude, longitude: longitude) >= -0.833
    } else {
      daylight = nil
    }
    sun = DaylightWindow.compute(latitude: city.latitude, longitude: city.longitude,
      dayOf: instant, zone: city.timeZone)
  }
}

/// Low-order solar position, offline estimate. Not weather, moon phase or an
/// exact sunrise/set ephemeris. Equations: NOAA fractional-year solar model.
enum SolarPosition {
  static func altitude(at date: Date, latitude: Double, longitude: Double) -> Double {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(secondsFromGMT: 0)!
    let day = c.ordinality(of: .day, in: .year, for: date)!
    let hour = Double(c.component(.hour, from: date)) + Double(c.component(.minute, from: date)) / 60
      + Double(c.component(.second, from: date)) / 3600
    let yearDays = c.range(of: .day, in: .year, for: date)!.count
    let gamma = 2 * Double.pi / Double(yearDays) * (Double(day - 1) + (hour - 12) / 24)
    let equation = 229.18 * (0.000075 + 0.001868 * cos(gamma) - 0.032077 * sin(gamma)
      - 0.014615 * cos(2 * gamma) - 0.040849 * sin(2 * gamma))
    let declination = 0.006918 - 0.399912 * cos(gamma) + 0.070257 * sin(gamma)
      - 0.006758 * cos(2 * gamma) + 0.000907 * sin(2 * gamma)
      - 0.002697 * cos(3 * gamma) + 0.00148 * sin(3 * gamma)
    let solarMinutes = hour * 60 + equation + 4 * longitude
    let hourAngle = (solarMinutes / 4 - 180) * .pi / 180
    let lat = latitude * .pi / 180
    return asin(min(1,max(-1,sin(lat) * sin(declination) + cos(lat) * cos(declination) * cos(hourAngle)))) * 180 / .pi
  }
}
