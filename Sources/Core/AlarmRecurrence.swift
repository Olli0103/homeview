import Foundation

/// Explicit app-owned schedule choices, not a reconstruction of the original UI.
enum AlarmRecurrence: String, Codable, CaseIterable, Sendable {
  case once, daily, weekdays, weekends
  var title: String {
    switch self {
    case .once: "Once"
    case .daily: "Every day"
    case .weekdays: "Mon–Fri"
    case .weekends: "Sat–Sun"
    }
  }
  /// Foundation weekday numbering is independent of the user's first weekday.
  var weekdays: [Int] {
    switch self {
    case .once: []
    case .daily: Array(1...7)
    case .weekdays: Array(2...6)
    case .weekends: [1, 7]
    }
  }
}

extension AlarmItem {
  /// Foreground only: one minute of eligibility, never a backlog of missed alerts.
  /// Missing wall time advances to the first valid time; repeated time uses its
  /// first occurrence. Calendar/time zone are injected, never changed globally.
  func occurrence(on day: Date, calendar: Calendar) -> Date? {
    guard (0...23).contains(hour), (0...59).contains(minute),
      recurrence == .once || recurrence.weekdays.contains(calendar.component(.weekday, from: day))
    else { return nil }
    let start = calendar.startOfDay(for: day)
    // Calendar.nextDate(.nextTime) on the supported Foundation can skip a
    // half-hour DST gap entirely (Lord Howe). Resolve a forward offset gap
    // explicitly before the ordinary matching path; keep the policy unchanged.
    if let transition = calendar.timeZone.nextDaylightSavingTimeTransition(after: start.addingTimeInterval(-1)),
      calendar.isDate(transition, inSameDayAs: day) {
      func wallSeconds(_ date: Date) -> Int {
        let c=calendar.dateComponents([.hour,.minute,.second],from:date)
        return (c.hour ?? 0)*3600 + (c.minute ?? 0)*60 + (c.second ?? 0)
      }
      let before=wallSeconds(transition.addingTimeInterval(-1))+1
      let after=wallSeconds(transition), requested=hour*3600+minute*60
      if after>before, requested>=before, requested<after { return transition }
    }
    guard let next = calendar.nextDate(after: start.addingTimeInterval(-1),
      matching: DateComponents(hour: hour, minute: minute, second: 0),
      matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward),
      calendar.isDate(next, inSameDayAs: day) else { return nil }
    return next
  }
  @discardableResult
  mutating func acknowledgeForegroundOccurrence(at now: Date, calendar: Calendar) -> Bool {
    let day = "\(calendar.component(.year, from: now))-\(calendar.ordinality(of: .day, in: .year, for: now) ?? 0)"
    guard enabled, lastFiredDay != day, let occurrence = occurrence(on: now, calendar: calendar),
      armedAfter.map({ occurrence > $0 }) ?? true,
      (0..<60).contains(now.timeIntervalSince(occurrence)) else { return false }
    lastFiredDay=day
    if recurrence == .once { enabled=false }
    return true
  }
}
