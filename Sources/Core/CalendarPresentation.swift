import Foundation

/// The face is explicitly Gregorian (UI08), with locale week order/labels/numerals.
/// Source display zone remains independent of region; no location or calendar-store read.
struct CalendarPresentation:Sendable {
  let calendar:Calendar
  let layout:MonthLayout
  let locale:Locale
  let weekdaySymbols:[String]
  let monthTitle:String
  let monthName:String
  let todayText:String
  let rightToLeft:Bool
  private let numbers:[String]
  init(date:Date,timeZone:TimeZone,locale:Locale) {
    self.locale=locale
    var calendar=Calendar(identifier:.gregorian)
    calendar.locale=locale;calendar.timeZone=timeZone
    self.calendar=calendar
    layout=MonthLayout(date:date,timeZone:timeZone,firstWeekday:calendar.firstWeekday)
    let f=DateFormatter();f.locale=locale;f.calendar=calendar;f.timeZone=timeZone
    let symbols=f.veryShortStandaloneWeekdaySymbols ?? ["S","M","T","W","T","F","S"]
    weekdaySymbols=(0..<7).map {symbols[($0+calendar.firstWeekday-1)%7]}
    f.setLocalizedDateFormatFromTemplate("MMMM yyyy");monthTitle=f.string(from:date)
    f.dateFormat="MMMM";monthName=f.string(from:date)
    let n=NumberFormatter();n.locale=locale;n.numberStyle = .decimal
    n.usesGroupingSeparator=false;n.maximumFractionDigits=0
    numbers=(0...31).map {n.string(from:NSNumber(value:$0)) ?? String($0)}
    let relative=RelativeDateTimeFormatter();relative.locale=locale;relative.dateTimeStyle = .named
    todayText=relative.localizedString(from:DateComponents(day:0)).capitalized(with:locale)
    rightToLeft=locale.language.characterDirection == .rightToLeft
  }
  func dayText(_ day:Int)->String {numbers.indices.contains(day) ? numbers[day]:String(day)}
  func weekdayIndex(at date:Date)->Int {(calendar.component(.weekday,from:date)-calendar.firstWeekday+7)%7}
}
