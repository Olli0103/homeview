import XCTest
@testable import HomeViewCore

final class SetupIntroductionTests:XCTestCase {
  func testLegacyStateNeedsIntroductionWithoutLosingExistingLocalData() throws {
    var previous=Snapshot();previous.night=true
    previous.personal["Alex"]=PersonalContent()
    previous.personal["Alex"]!.messages=["Synthetic existing note"]
    var object=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(previous)) as? [String:Any])
    object.removeValue(forKey:"introduction")
    let state=try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject:object))
    XCTAssertEqual(state.introduction,.pending);XCTAssertTrue(state.night)
    XCTAssertEqual(state.personal["Alex"]?.messages,["Synthetic existing note"])
  }
  func testCompletionAndDeferralRoundTripWithoutAnyAccountIdentity() throws {
    for value in SetupIntroduction.allCases {
      var state=Snapshot();state.introduction=value;state.night=true
      let read=try Snapshot.decodeMigrating(JSONEncoder().encode(state))
      XCTAssertEqual(read.introduction,value);XCTAssertTrue(read.night)
      XCTAssertTrue(read.personal.isEmpty)
    }
  }
  func testMalformedIntroductionCannotMarkSetupCompleteOrDiscardOtherValidFields() throws {
    for value in ["true","42","\"future-owner-account\"","{}"] {
      let bytes=Data("{\"version\":1,\"introduction\":\(value),\"night\":true}".utf8)
      let read=try Snapshot.decodeMigrating(bytes)
      XCTAssertEqual(read.introduction,.pending);XCTAssertTrue(read.night)
    }
  }
}
