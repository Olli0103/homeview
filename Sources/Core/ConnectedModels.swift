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
/// Explicitly published fields only; no source record ID, location, attendee or account data.
/// RAM-only snapshot. A demo label is presentation, never proof of household identity.
struct SharedCalendarCard: Identifiable, Sendable {
  let id: UUID
  let label: String
  let title: String
  let start: Date
  let end: Date
  let calendar: String
  let allDay: Bool
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
