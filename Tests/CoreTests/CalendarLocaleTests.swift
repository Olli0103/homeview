import XCTest
@testable import HomeViewCore

final class CalendarLocaleTests:XCTestCase {
  private let utc=TimeZone(secondsFromGMT:0)!
  private func date(_ value:String)->Date {ISO8601DateFormatter().date(from:value)!}
  func testEnglishReferenceRetainsSundayFirstAprilAndToday() {
    let p=CalendarPresentation(date:date("2026-04-01T10:09:00Z"),timeZone:utc,locale:Locale(identifier:"en_US"))
    XCTAssertEqual(p.monthTitle,"April 2026");XCTAssertEqual(p.monthName,"April")
    XCTAssertEqual(p.weekdaySymbols,["S","M","T","W","T","F","S"])
    XCTAssertEqual(p.calendar.firstWeekday,1);XCTAssertEqual(p.layout.firstWeekdayIndex,3)
    XCTAssertEqual(p.dayText(p.layout.selectedDay),"1");XCTAssertEqual(p.todayText,"Today")
    XCTAssertFalse(p.rightToLeft)
  }
  func testGermanLeapMonthUsesMondayFirstWithoutMovingDatesToWrongWeekday() {
    let p=CalendarPresentation(date:date("2024-02-29T12:00:00Z"),timeZone:utc,locale:Locale(identifier:"de_DE"))
    XCTAssertEqual(p.monthTitle,"Februar 2024");XCTAssertEqual(p.monthName,"Februar")
    XCTAssertEqual(p.calendar.firstWeekday,2);XCTAssertEqual(p.layout.firstWeekdayIndex,3)
    XCTAssertEqual(p.weekdaySymbols,["M","D","M","D","F","S","S"])
    XCTAssertEqual(p.layout.day(at:31),29);XCTAssertEqual(p.dayText(29),"29")
    XCTAssertEqual(p.todayText,"Heute");XCTAssertFalse(p.rightToLeft)
    XCTAssertEqual(p.weekdayIndex(at:date("2024-02-29T12:00:00Z")),3)
  }
  func testArabicRegionKeepsGregorianYearAndLocalizedDigitsAndRTLWeekOrder() {
    let p=CalendarPresentation(date:date("2026-04-01T10:09:00Z"),timeZone:utc,locale:Locale(identifier:"ar_EG"))
    XCTAssertEqual(p.calendar.identifier,.gregorian)
    XCTAssertEqual(p.calendar.firstWeekday,7);XCTAssertEqual(p.layout.firstWeekdayIndex,4)
    XCTAssertEqual(p.dayText(1),"١");XCTAssertEqual(p.dayText(30),"٣٠")
    XCTAssertTrue(p.monthTitle.contains("٢٠٢٦"));XCTAssertEqual(p.layout.dayCount,30)
    XCTAssertTrue(p.rightToLeft);XCTAssertEqual(p.weekdaySymbols.count,7)
    XCTAssertEqual(p.weekdayIndex(at:date("2026-04-01T10:09:00Z")),4)
    XCTAssertEqual((0..<42).compactMap(p.layout.day),Array(1...30))
  }
  func testLocaleCannotReplaceDisplayZoneOrGregorianDateAtYearBoundary() {
    let instant=date("2026-12-31T23:30:00Z")
    for locale in ["en_US","de_DE","ar_EG","ja_JP","fr_FR"] {
      let a=CalendarPresentation(date:instant,timeZone:TimeZone(identifier:"America/Los_Angeles")!,locale:Locale(identifier:locale))
      let b=CalendarPresentation(date:instant,timeZone:TimeZone(identifier:"Pacific/Kiritimati")!,locale:Locale(identifier:locale))
      XCTAssertEqual(a.layout.selectedDay,31);XCTAssertEqual(b.layout.selectedDay,1)
      XCTAssertEqual(a.calendar.component(.year,from:instant),2026)
      XCTAssertEqual(b.calendar.component(.year,from:instant),2027)
      for p in [a,b] {
        let first=p.calendar.dateInterval(of:.weekOfYear,for:instant)!.start
        let selected=p.calendar.date(byAdding:.day,value:p.weekdayIndex(at:instant),to:first)!
        XCTAssertTrue(p.calendar.isDate(selected,inSameDayAs:instant))
        XCTAssertEqual(p.weekdaySymbols.count,7)
        XCTAssertEqual((0..<42).compactMap(p.layout.day),Array(1...31))
      }
    }
  }
  func testWeekStartValidationAndDSTWeekUseCalendarDaysNotFixedSeconds() {
    let instant=date("2026-03-29T01:30:00Z"),zone=TimeZone(identifier:"Europe/Berlin")!
    let p=CalendarPresentation(date:instant,timeZone:zone,locale:Locale(identifier:"de_DE"))
    let week=p.calendar.dateInterval(of:.weekOfYear,for:instant)!
    XCTAssertEqual(week.duration,167*3600)
    let day=p.calendar.date(byAdding:.day,value:p.weekdayIndex(at:instant),to:week.start)!
    XCTAssertEqual(p.calendar.component(.day,from:day),29)
    XCTAssertEqual(p.layout.dayCount,31)
    for invalid in [0,8,-1,Int.max] {
      XCTAssertEqual(MonthLayout(date:instant,timeZone:zone,firstWeekday:invalid).firstWeekdayIndex,
        MonthLayout(date:instant,timeZone:zone).firstWeekdayIndex)
    }
  }
}
