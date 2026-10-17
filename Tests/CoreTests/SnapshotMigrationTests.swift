import XCTest
@testable import HomeViewCore

final class SnapshotMigrationTests: XCTestCase {
  private func object(_ state: Snapshot) throws -> [String: Any] {
    try JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as! [String: Any]
  }
  private func decode(_ object: [String: Any]) throws -> Snapshot {
    try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject: object))
  }
  func testCorruptRecipeAndWidgetsCannotResetHealthyHomeOrPersonalFields() throws {
    var state = Snapshot();state.home.temperature=69
    state.personal["Alex"] = PersonalContent()
    state.personal["Alex"]!.messages=["Synthetic saved note"]
    var json = try object(state)
    json["recipe"]=["broken":true];json["widgets"]=["only one"]
    let restored = try decode(json)
    XCTAssertEqual(restored.home.temperature,69)
    XCTAssertEqual(restored.personal["Alex"]?.messages,["Synthetic saved note"])
    XCTAssertEqual(restored.widgets.count,4)
    XCTAssertEqual(restored.recipe.id,RecipeDocument.soup.id)
  }
  func testBadCollectionEntryDoesNotDiscardValidSiblingsAndBoundsAreApplied() throws {
    var state = Snapshot()
    let timer = Countdown(title:"Synthetic timer",seconds:90)
    state.timers=[timer]
    var json=try object(state)
    var timers=json["timers"] as! [Any]
    timers.insert(["corrupt":true],at:0);timers.append(timers[1]);json["timers"]=timers
    json["volume"]=3;json["screenBrightness"] = -4;json["theme"]=99
    let restored=try decode(json)
    XCTAssertEqual(restored.timers.count,1)
    XCTAssertEqual(restored.timers[0].id,timer.id)
    XCTAssertEqual(restored.volume,1)
    XCTAssertEqual(restored.screenBrightness,0)
    XCTAssertEqual(restored.theme,1)
  }
  func testUnknownVersionAndNonObjectNeverBecomeFreshWritableState() {
    for text in ["{\"version\":99}","{\"version\":true}","[]","null","broken json"] {
      XCTAssertThrowsError(try Snapshot.decodeMigrating(Data(text.utf8)),text)
    }
  }
  func testHealthySnapshotRoundTripPreservesAllCurrentFields() throws {
    var state=Snapshot();state.home.temperature=70;state.theme=1;state.night=true;state.far=true
    state.volume=0.2;state.screenBrightness=0.7;state.keepDisplayOn=true
    state.photoIDs=[UUID().uuidString];state.rotatePhotos=false
    state.photoAdjustments=["synthetic":PhotoAdjustment()]
    state.timers=[Countdown(title:"Synthetic",seconds:30)]
    state.nativeTimerIDs=[state.timers[0].id];state.nativeAlarmIDs=[state.alarms[0].id]
    state.personal["Alex"]=PersonalContent();state.face = .flow
    state.pinnedRecipes=[.soup];state.pinnedRecipe=true
    state.worldClockZones=["Asia/Kathmandu"]
    let bytes=try JSONEncoder().encode(state)
    let restored=try Snapshot.decodeMigrating(bytes)
    let restoredBytes = try JSONEncoder().encode(restored)
    XCTAssertEqual(try Snapshot.canonicalBytes(bytes), try Snapshot.canonicalBytes(restoredBytes))
  }
  func testOversizedAndInvalidTimerStateCannotReachCountdownRendering() throws {
    var state=Snapshot();state.home.temperature=71
    var invalid=Countdown(title:"Invalid",seconds:60);invalid.duration=1e100
    state.timers=[invalid,Countdown(title:"Valid",seconds:30)]
    let restored=try Snapshot.decodeMigrating(JSONEncoder().encode(state))
    XCTAssertEqual(restored.home.temperature,71)
    XCTAssertEqual(restored.timers.map(\.title),["Valid"])
    XCTAssertThrowsError(try Snapshot.decodeMigrating(Data(repeating:32,count:32_000_001)))
  }
}
