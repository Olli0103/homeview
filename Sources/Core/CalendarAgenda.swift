import Foundation

enum CalendarAgendaError: Error, LocalizedError {
  case tooManyEvents, permissionRequired
  var errorDescription: String? {
    switch self {
    case .tooManyEvents: "Too many events for this day. Agenda was not loaded."
    case .permissionRequired: "Calendar access changed. Connect again in Settings."
    }
  }
}
enum CalendarAgenda {
  static func day(containing date: Date, timeZone: TimeZone) -> DateInterval {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return calendar.dateInterval(of: .day, for: date)!
  }
  /// No silent prefix: a bounded agenda is either complete or explicitly fails.
  static func events(_ values: [DeviceEvent], in interval: DateInterval) throws -> [DeviceEvent] {
    let matching = values.filter { event in
      if event.end == event.start { return event.start >= interval.start && event.start < interval.end }
      return event.start < interval.end && event.end > interval.start && event.end > event.start
    }
    guard matching.count <= 200 else { throw CalendarAgendaError.tooManyEvents }
    return matching.sorted {
      if $0.allDay != $1.allDay { return $0.allDay }
      if $0.start != $1.start { return $0.start < $1.start }
      return $0.id < $1.id
    }
  }
  static func occurrenceID(item: String, start: Date) -> String {
    item + "@" + String(start.timeIntervalSinceReferenceDate.bitPattern, radix: 16)
  }
}
