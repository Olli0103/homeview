import XCTest
@testable import HomeViewCore
final class PowerAdapterInformationTests:XCTestCase {
  func testOnlyPresentPositiveWholeIntegerReportedFieldsAreReturned() {
    XCTAssertNil(PowerAdapterInformation(reportedNumber:nil).reportedWatts)
    XCTAssertEqual(PowerAdapterInformation(reportedNumber:NSNumber(value:67)).reportedWatts,67)
    XCTAssertEqual(PowerAdapterInformation(reportedNumber:NSNumber(value:140)).reportedWatts,140)
    XCTAssertEqual(PowerAdapterInformation(reportedNumber:NSNumber(value:3000)).reportedWatts,3000)
  }
  func testBooleanZeroNegativeFractionalAndNonfiniteAreNeverReportedAsWatts() {
    for value in [NSNumber(value:true),NSNumber(value:false),NSNumber(value:0),NSNumber(value:-1),
      NSNumber(value:0.8),NSNumber(value:67.5),NSNumber(value:Double.nan),NSNumber(value:Double.infinity)] {
      XCTAssertNil(PowerAdapterInformation(reportedNumber:value).reportedWatts)
    }
  }
  func testIntegerRangeIsValidatedInsteadOfClampingOrTrapping() {
    XCTAssertEqual(PowerAdapterInformation(reportedNumber:NSNumber(value:Int32.max)).reportedWatts,Int(Int32.max))
    XCTAssertNil(PowerAdapterInformation(reportedNumber:NSNumber(value:Int64(Int32.max)+1)).reportedWatts)
    XCTAssertNil(PowerAdapterInformation(reportedNumber:NSNumber(value:UInt64.max)).reportedWatts)
  }
}
