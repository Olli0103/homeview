import Foundation

struct DeviceEvent: Identifiable, Sendable {
  let id: String
  let title: String
  let start: Date
  let end: Date
  let location: String
  let calendar: String
  let cancelled: Bool
  var allDay = false
}
struct DeviceReminder: Identifiable, Sendable {
  let id: String
  let title: String
  let completed: Bool
  var listTitle = ""
  var writable = true
}
enum ReminderStoreError: Error, LocalizedError {
  case readOnly, ownListUnavailable, tooManyItems, fetchFailed
  var errorDescription: String? {
    switch self {
    case .readOnly: "This reminder list is read-only."
    case .ownListUnavailable: "The app-created reminder list is unavailable or read-only. No reminder was added."
    case .tooManyItems: "More than 500 reminders. The list was not loaded."
    case .fetchFailed: "Reminders could not be loaded. Check the account and access."
    }
  }
}
struct DeviceTrack: Identifiable, Sendable {
  let id: String
  let title: String
  let artist: String
  let artwork: URL?
}
struct WeatherReading: Sendable {
  let city: String
  let temperature: Double
  let high: Double
  let low: Double
  let humidity: Double
  let wind: Double
  let code: Int
  let sunset: Date
  let utcOffset: Int
  let observedAt: Date
  var condition: String {
    switch code {
    case 0: "Clear"
    case 1, 2: "Partly Cloudy"
    case 3: "Overcast"
    case 45, 48: "Fog"
    case 51...67, 80...82: "Rain"
    case 71...77, 85, 86: "Snow"
    case 95...99: "Thunderstorms"
    default: "Weather"
    }
  }
  var symbol: String {
    switch code {
    case 0: "sun.max.fill"
    case 1, 2: "cloud.sun.fill"
    case 45, 48: "cloud.fog.fill"
    case 51...67, 80...82: "cloud.rain.fill"
    case 71...77, 85, 86: "cloud.snow.fill"
    case 95...99: "cloud.bolt.rain.fill"
    default: "cloud.fill"
    }
  }
  var sunsetLabel: String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US")
    f.timeZone = TimeZone(secondsFromGMT: utcOffset)
    f.dateFormat = "h:mm a"
    return f.string(from: sunset)
  }
}
