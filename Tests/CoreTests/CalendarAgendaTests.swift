import XCTest
@testable import HomeViewCore

final class CalendarAgendaTests: XCTestCase {
  func testSelectedZoneDayUsesDSTCalendarBoundaries() {
    let berlin = TimeZone(identifier: "Europe/Berlin")!
    let spring = CalendarAgenda.day(containing: ISO8601DateFormatter().date(from: "2026-03-29T12:00:00Z")!, timeZone: berlin)
    let fall = CalendarAgenda.day(containing: ISO8601DateFormatter().date(from: "2026-10-25T12:00:00Z")!, timeZone: berlin)
    XCTAssertEqual(spring.duration, 23 * 3600)
    XCTAssertEqual(fall.duration, 25 * 3600)
    let nepal = CalendarAgenda.day(containing: ISO8601DateFormatter().date(from: "2026-01-01T00:00:00Z")!, timeZone: TimeZone(identifier: "Asia/Kathmandu")!)
    XCTAssertEqual(nepal.start, ISO8601DateFormatter().date(from: "2025-12-31T18:15:00Z"))
  }
  func testAgendaIncludesOvernightAndAllDayButNotExclusiveEnd() throws {
    let day = DateInterval(start: Date(timeIntervalSince1970: 100000), duration: 86400)
    func event(_ id: String, _ start: Double, _ end: Double, _ allDay: Bool = false, _ cancelled: Bool = false) -> DeviceEvent {
      DeviceEvent(id: id, title: id, start: day.start.addingTimeInterval(start), end: day.start.addingTimeInterval(end), location: "", calendar: "Test", cancelled: cancelled, allDay: allDay)
    }
    let values = [event("later",3600,7200),event("all",0,86400,true),event("night",-3600,3600),event("ends",-10,0),event("tomorrow",86400,86500),event("instant",0,0),event("cancelled",1800,2400,false,true)]
    let agenda = try CalendarAgenda.events(values, in: day)
    XCTAssertEqual(agenda.map(\.id),["all","night","instant","cancelled","later"])
    XCTAssertTrue(agenda[3].cancelled)
    XCTAssertEqual(agenda[0].calendar,"Test")
  }
  func testRecurringOccurrencesKeepDistinctStableIdentities() {
    let a = CalendarAgenda.occurrenceID(item: "repeated", start: Date(timeIntervalSince1970: 100000))
    XCTAssertEqual(a, CalendarAgenda.occurrenceID(item: "repeated", start: Date(timeIntervalSince1970: 100000)))
    XCTAssertNotEqual(a, CalendarAgenda.occurrenceID(item: "repeated", start: Date(timeIntervalSince1970: 200000)))
  }
  func testOverflowFailsInsteadOfTruncatingOrHidingEarliestEvents() throws {
    let start = Date(), day = CalendarAgenda.day(containing: start, timeZone: .current)
    let values = (0..<201).reversed().map {
      DeviceEvent(id: String($0),title: "Synthetic",start: day.start.addingTimeInterval(Double($0)),end: day.start.addingTimeInterval(Double($0+1)),location: "",calendar: "Test",cancelled: false)
    }
    XCTAssertThrowsError(try CalendarAgenda.events(values,in: day))
    XCTAssertEqual(try CalendarAgenda.events(Array(values.prefix(200)),in: day).count,200)
  }
}
