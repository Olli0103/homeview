import Foundation
import XCTest
@testable import HomeViewCore

final class CalendarBoundaryTests: XCTestCase {
  private let utc = TimeZone(secondsFromGMT: 0)!
  private func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }
  func testLeapDayKeepsAllSixRowsAndCorrectAdjacentMonthDates() {
    let value = MonthLayout(date:date("2024-02-29T12:00:00Z"),timeZone:utc)
    let expected = [28,29,30,31,1,2,3, 4,5,6,7,8,9,10,
      11,12,13,14,15,16,17, 18,19,20,21,22,23,24,
      25,26,27,28,29,1,2, 3,4,5,6,7,8,9]
    XCTAssertEqual((0..<42).map(value.displayDay),expected)
    XCTAssertEqual((0..<42).compactMap(value.day),Array(1...29))
    XCTAssertEqual(value.day(at:32),value.selectedDay)
    XCTAssertNil(value.day(at:0))
    XCTAssertNil(value.day(at:34))
  }
  func testSixWeekAugustDoesNotLoseTheLastTwoCurrentMonthDays() {
    let value = MonthLayout(date:date("2026-08-31T12:00:00Z"),timeZone:utc)
    XCTAssertEqual(value.cellCount,42)
    XCTAssertEqual((0..<42).map(value.displayDay),[
      26,27,28,29,30,31,1, 2,3,4,5,6,7,8, 9,10,11,12,13,14,15,
      16,17,18,19,20,21,22, 23,24,25,26,27,28,29, 30,31,1,2,3,4,5])
    XCTAssertEqual(value.day(at:35),30)
    XCTAssertEqual(value.day(at:36),31)
    XCTAssertNil(value.day(at:37))
  }
  func testSameInstantCanBelongToDifferentLocalYearsWithoutMixingTheirGrids() {
    let instant = date("2026-12-31T23:30:00Z")
    let west = MonthLayout(date:instant,timeZone:TimeZone(identifier:"America/Los_Angeles")!)
    let east = MonthLayout(date:instant,timeZone:TimeZone(identifier:"Pacific/Kiritimati")!)
    XCTAssertEqual(west.selectedDay,31)
    XCTAssertEqual(west.firstWeekdayIndex,2)
    XCTAssertEqual(Array((0..<7).map(west.displayDay)),[29,30,1,2,3,4,5])
    XCTAssertEqual(east.selectedDay,1)
    XCTAssertEqual(east.firstWeekdayIndex,5)
    XCTAssertEqual(Array((0..<7).map(east.displayDay)),[27,28,29,30,31,1,2])
    XCTAssertEqual(Array((35..<42).map(east.displayDay)),[31,1,2,3,4,5,6])
  }
  func testCenturyLeapRulesDoNotInventFebruary29In2100() {
    XCTAssertEqual(MonthLayout(date:date("2000-02-29T12:00:00Z"),timeZone:utc).dayCount,29)
    let common = MonthLayout(date:date("2100-02-28T12:00:00Z"),timeZone:utc)
    XCTAssertEqual(common.dayCount,28)
    XCTAssertEqual((0..<42).compactMap(common.day),Array(1...28))
  }
}
