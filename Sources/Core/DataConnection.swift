import Foundation

enum DataConnection: String, CaseIterable, Identifiable, Codable, Sendable {
  case calendar = "Calendar"
  case reminders = "Reminders"
  case music = "Apple Music"
  case weather = "Weather"
  var id: String { rawValue }
}
