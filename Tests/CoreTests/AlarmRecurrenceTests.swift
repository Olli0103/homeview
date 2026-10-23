import XCTest
@testable import HomeViewCore

final class AlarmRecurrenceTests: XCTestCase {
  private func date(_ text: String) -> Date { ISO8601DateFormatter().date(from: text)! }
  private func calendar(_ zone: String) -> Calendar {
    var c=Calendar(identifier: .gregorian); c.timeZone=TimeZone(identifier: zone)!; return c
  }
  func testOnceDisablesAndDailyDoesNotAndReceiptsSurviveEncoding() throws {
    let now=date("2026-10-23T05:00:15Z"), c=calendar("Europe/Berlin")
    for repeatMode in AlarmRecurrence.allCases {
      var alarm=AlarmItem(hour:7,minute:0,recurrence:repeatMode)
      let expected=repeatMode != .weekends
      XCTAssertEqual(alarm.acknowledgeForegroundOccurrence(at:now,calendar:c),expected)
      XCTAssertEqual(alarm.enabled,repeatMode != .once)
      var restored=try JSONDecoder().decode(AlarmItem.self,from:JSONEncoder().encode(alarm))
      XCTAssertEqual(restored,alarm)
      XCTAssertFalse(restored.acknowledgeForegroundOccurrence(at:now.addingTimeInterval(10),calendar:c))
    }
  }
  func testWeekSelectionDoesNotDependOnFirstWeekday() {
    var c=calendar("Europe/Berlin");c.firstWeekday=4
    for (day,expectedWeekday) in [("2026-10-23T05:00:00Z",true),("2026-10-24T05:00:00Z",false),("2026-10-25T06:00:00Z",false),("2026-10-26T06:00:00Z",true)] {
      for mode in [AlarmRecurrence.weekdays,.weekends] {
        var alarm=AlarmItem(hour:7,minute:0,recurrence:mode)
        XCTAssertEqual(alarm.acknowledgeForegroundOccurrence(at:date(day),calendar:c),mode == .weekdays ? expectedWeekday : !expectedWeekday)
      }
    }
  }
  func testSpringGapUsesFirstValidTimeAndDoesNotReplayMissedMinute() {
    let c=calendar("Europe/Berlin")
    var alarm=AlarmItem(hour:2,minute:30,recurrence:.daily)
    XCTAssertEqual(alarm.occurrence(on:date("2026-03-29T12:00:00Z"),calendar:c),date("2026-03-29T01:00:00Z"))
    XCTAssertFalse(alarm.acknowledgeForegroundOccurrence(at:date("2026-03-29T00:59:59Z"),calendar:c))
    XCTAssertTrue(alarm.acknowledgeForegroundOccurrence(at:date("2026-03-29T01:00:00Z"),calendar:c))
    alarm.lastFiredDay=""
    XCTAssertFalse(alarm.acknowledgeForegroundOccurrence(at:date("2026-03-29T01:01:00Z"),calendar:c))
  }
  func testRepeatedAutumnHourOnlyFirstOccurrenceEvenWithoutReceipt() {
    let c=calendar("Europe/Berlin")
    var alarm=AlarmItem(hour:2,minute:30,recurrence:.daily)
    XCTAssertTrue(alarm.acknowledgeForegroundOccurrence(at:date("2026-10-25T00:30:00Z"),calendar:c))
    alarm.lastFiredDay=""
    XCTAssertFalse(alarm.acknowledgeForegroundOccurrence(at:date("2026-10-25T01:30:00Z"),calendar:c))
    XCTAssertTrue(alarm.acknowledgeForegroundOccurrence(at:date("2026-10-26T01:30:00Z"),calendar:c))
  }
  func testHalfHourDSTGapAndNonWholeHourTimeZone() {
    let c=calendar("Australia/Lord_Howe")
    var alarm=AlarmItem(hour:2,minute:15,recurrence:.daily)
    XCTAssertEqual(alarm.occurrence(on:date("2026-10-04T02:00:00Z"),calendar:c),date("2026-10-03T15:30:00Z"))
    XCTAssertTrue(alarm.acknowledgeForegroundOccurrence(at:date("2026-10-03T15:30:00Z"),calendar:c))
    var nepal=AlarmItem(hour:7,minute:0)
    XCTAssertTrue(nepal.acknowledgeForegroundOccurrence(at:date("2026-10-23T01:15:00Z"),calendar:calendar("Asia/Kathmandu")))
  }
  func testArmingDuringMinuteWaitsUntilFutureOccurrenceAndDisableIsSilent() {
    let c=calendar("Europe/Berlin"), now=date("2026-10-23T05:00:15Z")
    var alarm=AlarmItem(hour:7,minute:0,armedAfter:now)
    XCTAssertFalse(alarm.acknowledgeForegroundOccurrence(at:now,calendar:c))
    XCTAssertTrue(alarm.acknowledgeForegroundOccurrence(at:date("2026-10-24T05:00:00Z"),calendar:c))
    alarm.enabled=false;alarm.lastFiredDay=""
    XCTAssertFalse(alarm.acknowledgeForegroundOccurrence(at:date("2026-10-25T06:00:00Z"),calendar:c))
  }
  func testTimeZoneIsEvaluatedAtUseNotStoredAsAbsoluteDailyInterval() {
    let now=date("2026-10-23T05:00:00Z")
    var alarm=AlarmItem(hour:7,minute:0,recurrence:.daily)
    XCTAssertFalse(alarm.acknowledgeForegroundOccurrence(at:now,calendar:calendar("America/New_York")))
    XCTAssertTrue(alarm.acknowledgeForegroundOccurrence(at:now,calendar:calendar("Europe/Berlin")))
    XCTAssertEqual(alarm.occurrence(on:date("2026-10-25T12:00:00Z"),calendar:calendar("Europe/Berlin")),date("2026-10-25T06:00:00Z"))
  }
  func testLegacyLocalDailyAndNativeOnceMigrationAndUnknownRepeatFailClosed() throws {
    var state=Snapshot();state.alarms=[AlarmItem(hour:7,minute:0),AlarmItem(hour:8,minute:0),AlarmItem(hour:9,minute:0,recurrence:.weekends)]
    state.nativeAlarmIDs=[state.alarms[1].id]
    var json=try JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as! [String:Any]
    var rows=json["alarms"] as! [[String:Any]]
    rows[0].removeValue(forKey:"recurrence");rows[1].removeValue(forKey:"recurrence")
    var invalid=rows[2];invalid["id"]=UUID().uuidString;invalid["recurrence"]="unknown";rows.append(invalid)
    json["alarms"]=rows
    let restored=try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject:json))
    XCTAssertEqual(restored.alarms.map(\.recurrence),[.daily,.once,.weekends])
    XCTAssertEqual(restored.nativeAlarmIDs,state.nativeAlarmIDs)
    XCTAssertEqual(restored.alarms.map(\.id),state.alarms.map(\.id))
    XCTAssertEqual(try Snapshot.decodeMigrating(JSONEncoder().encode(restored)).alarms,restored.alarms)
  }
  func testInvalidTimesDoNotProduceOccurrence() {
    for (h,m) in [(-1,0),(24,0),(7,-1),(7,60)] {
      var alarm=AlarmItem(hour:h,minute:m)
      XCTAssertFalse(alarm.acknowledgeForegroundOccurrence(at:date("2026-10-23T05:00:00Z"),calendar:calendar("Europe/Berlin")))
    }
  }
}
