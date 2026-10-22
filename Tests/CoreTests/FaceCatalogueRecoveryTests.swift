import XCTest
@testable import HomeViewCore

final class FaceCatalogueRecoveryTests:XCTestCase {
  private func restore(face:Any,configurations:[String:Any]) throws -> Snapshot {
    var state=Snapshot();state.home.temperature=76;state.connectionConsent=[]
    var content=PersonalContent();content.messages=["OWNED_CATALOGUE_PROFILE"];content.reminders=[]
    state.personal=["Alex":content]
    var raw=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as? [String:Any])
    raw["face"]=face;raw["faceConfigurations"]=configurations
    let restored=try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject:raw))
    XCTAssertEqual(restored.home.temperature,76);XCTAssertEqual(restored.connectionConsent,[])
    XCTAssertEqual(restored.personal["Alex"]?.messages,["OWNED_CATALOGUE_PROFILE"])
    XCTAssertEqual(restored.personal["Alex"]?.reminders,[])
    return restored
  }
  func testRemovedOrUnknownStoredFaceFallsBackWithoutBorrowingItsConfiguration() throws {
    let restored=try restore(face:"UNAVAILABLE_OR_FUTURE_FACE",configurations:[
      "UNAVAILABLE_OR_FUTURE_FACE":["theme":1,"complications":["panel0":"Music"]]])
    XCTAssertEqual(restored.face,.home)
    XCTAssertEqual(restored.configuration(for:.home).theme,0)
    XCTAssertNil(restored.configuration(for:.home).complications["panel0"])
    XCTAssertEqual(restored.faceConfigurations["UNAVAILABLE_OR_FUTURE_FACE"]?.theme,1)
  }
  func testEmptyOrMalformedFaceSelectionRetainsOtherSavedData() throws {
    for raw:Any in ["",17,NSNull(),["not":"a face"]] {
      let restored=try restore(face:raw,configurations:[:])
      XCTAssertEqual(restored.face,.home)
      XCTAssertTrue(restored.faceConfigurations.isEmpty)
    }
  }
  func testEveryNewlySelectedFaceUsesItsOwnDefaultsInsteadOfExistingOtherFaceStyle() throws {
    for face in Face.allCases {
      var others:[String:Any]=[:]
      for other in Face.allCases where other != face {
        others[other.id]=["theme":1,"flowTypeface":1,"flowBackground":false]
      }
      let restored=try restore(face:face.rawValue,configurations:others)
      XCTAssertEqual(restored.face,face)
      XCTAssertEqual(restored.configuration(for:face),FaceConfiguration())
      for slot in face.slots {XCTAssertTrue(slot.choices.contains(restored.complication(for:face,slot:slot)))}
    }
  }
  func testKnownFaceAndIndependentStyleSurviveSaveWhileUnknownRecordsRemainInert() throws {
    for face in Face.allCases {
      let restored=try restore(face:face.rawValue,configurations:[face.id:["theme":1],"FUTURE_FACE":["theme":0]])
      let reloaded=try Snapshot.decodeMigrating(JSONEncoder().encode(restored))
      XCTAssertEqual(reloaded.face,face)
      XCTAssertEqual(reloaded.configuration(for:face).theme,1)
      XCTAssertEqual(reloaded.faceConfigurations["FUTURE_FACE"]?.theme,0)
      XCTAssertEqual(reloaded.personal["Alex"]?.messages,["OWNED_CATALOGUE_PROFILE"])
    }
  }
}
