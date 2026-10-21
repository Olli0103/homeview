import XCTest
@testable import HomeViewCore

/// QA-05's six saved-data families, on one checkpoint. All values are invented.
final class PersistenceAcceptanceTests: XCTestCase {
  private let first = "00000000-0000-4000-8000-000000000001"
  private let second = "00000000-0000-4000-8000-000000000002"
  private func record<T: Encodable>(_ value:T) throws -> Any {
    try JSONSerialization.jsonObject(with:JSONEncoder().encode(value))
  }
  private func base() throws -> [String:Any] {
    var state=Snapshot();state.connectionConsent=[];state.home.temperature=73
    var content=PersonalContent();content.messages=["OWNED_ALEX_ONLY"];content.reminders=[]
    state.personal=["Alex":content];content.messages=["OWNED_JAMIE_ONLY"];state.personal["Jamie"]=content
    return try XCTUnwrap(record(state) as? [String:Any])
  }
  private func restore(_ raw:[String:Any],changing keys:Set<String>) throws -> Snapshot {
    let value=try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject:raw))
    let again=try Snapshot.decodeMigrating(JSONEncoder().encode(value))
    XCTAssertEqual(try Snapshot.canonicalBytes(JSONEncoder().encode(value)),
      try Snapshot.canonicalBytes(JSONEncoder().encode(again)),"Canonical save/reload must be idempotent")
    // Every unrelated field is compared, not just a single canary.
    var before=raw,after=try XCTUnwrap(record(value) as? [String:Any])
    for key in keys { before.removeValue(forKey:key);after.removeValue(forKey:key) }
    XCTAssertEqual(try Snapshot.canonicalBytes(JSONSerialization.data(withJSONObject:before)),
      try Snapshot.canonicalBytes(JSONSerialization.data(withJSONObject:after)))
    return value
  }
  func testFaceLegacyMissingLaterOptionsKeepsSavedStyle() throws {
    var raw=try base();raw["face"]="Flow";raw["faceConfigurations"]=["Flow":["theme":1]]
    let s=try restore(raw,changing:["face","faceConfigurations"])
    XCTAssertEqual(s.face,.flow);XCTAssertEqual(s.configuration(for:.flow).theme,1)
    XCTAssertEqual(s.configuration(for:.flow).flowTypeface,0)
  }
  func testFaceDamagedOptionCannotDiscardHealthyStyleOrOtherFace() throws {
    var raw=try base();raw["faceConfigurations"]=["Flow":["theme":1,"flowTypeface":"broken"],"Modular":["theme":1]]
    let s=try restore(raw,changing:["faceConfigurations"])
    XCTAssertEqual(s.configuration(for:.flow).theme,1);XCTAssertEqual(s.configuration(for:.modular).theme,1)
    XCTAssertEqual(s.configuration(for:.flow).flowTypeface,0)
  }
  func testSlotLegacyFourWidgetShapeStaysReadable() throws {
    var raw=try base();raw.removeValue(forKey:"faceConfigurations")
    raw["widgets"]=["Clock","Weather","Timer","Date"]
    let s=try restore(raw,changing:["widgets","faceConfigurations"])
    XCTAssertEqual(s.widgets,["Clock","Weather","Timer","Date"])
    XCTAssertEqual(s.complication(for:.modular,slot:Face.modular.slots[0]),.clock)
  }
  func testSlotDamagedMemberKeepsHealthySiblingAndFamilyRules() throws {
    var raw=try base();raw["faceConfigurations"]=["Modular":["complications":["panel0":"Weather","panel1":17,"panel2":"Timer"]]]
    let s=try restore(raw,changing:["faceConfigurations"])
    XCTAssertEqual(s.configuration(for:.modular).complications["panel0"],.weather)
    XCTAssertNil(s.configuration(for:.modular).complications["panel1"])
    XCTAssertEqual(s.configuration(for:.modular).complications["panel2"],.timer)
  }
  func testGalleryLegacyIDsWithoutLaterDiscriminatorRemainOrdered() throws {
    var raw=try base();raw.removeValue(forKey:"photoSelection");raw["photoIDs"]=[first,second]
    let s=try restore(raw,changing:["photoIDs","photoSelection"])
    XCTAssertEqual(s.photoSelection,.legacy);XCTAssertEqual(s.photoIDs,[first,second])
  }
  func testGalleryDamagedAndDuplicateIDsCannotEraseHealthyOrderedMembers() throws {
    var raw=try base();raw["photoSelection"]="gallery";raw["photoIDs"]=[first,17,"../outside",first,second]
    let s=try restore(raw,changing:["photoIDs","photoSelection"])
    XCTAssertEqual(s.photoIDs,[first,second]);XCTAssertEqual(s.photoSelection,.gallery)
  }
  func testTimerLegacyShapeRetainsIDDeadlineAndAcknowledgement() throws {
    var timer=Countdown(title:"OWNED_TIMER",seconds:90,now:Date(timeIntervalSince1970:1_800_000_000))
    timer.id=UUID(uuidString:first)!;timer.didAlert=true
    var raw=try base();raw.removeValue(forKey:"nativeTimerIDs");raw["timers"]=[try record(timer)]
    let s=try restore(raw,changing:["timers","nativeTimerIDs"])
    XCTAssertEqual(s.timers,[timer]);XCTAssertTrue(s.nativeTimerIDs.isEmpty)
  }
  func testTimerDamagedAndDuplicateMembersCannotResetHealthyPeer() throws {
    var timer=Countdown(title:"OWNED_TIMER",seconds:90);timer.id=UUID(uuidString:first)!
    var raw=try base();raw["timers"]=[["bad":true],try record(timer),try record(timer)]
    let s=try restore(raw,changing:["timers"]);XCTAssertEqual(s.timers,[timer])
  }
  func testRecipeLegacyShapeWithoutLaterOptionalMetadataKeepsIdentityAndSteps() throws {
    var recipe=try XCTUnwrap(record(RecipeDocument.soup) as? [String:Any])
    for key in ["coverAsset","imageURL","prepMinutes","cookMinutes"] {recipe.removeValue(forKey:key)}
    var raw=try base();raw["recipe"]=recipe;raw["pinnedRecipes"]=[recipe]
    let s=try restore(raw,changing:["recipe","pinnedRecipes","pinnedRecipe"])
    XCTAssertEqual(s.recipe.id,RecipeDocument.soup.id);XCTAssertEqual(s.recipe.steps.count,Fixtures.steps.count)
    XCTAssertEqual(s.pinnedRecipes.map(\.id),[RecipeDocument.soup.id]);XCTAssertTrue(s.pinnedRecipe)
  }
  func testRecipeDamagedSelectedRecordKeepsValidPinnedSiblingWithoutDuplicate() throws {
    var raw=try base();let recipe=try record(RecipeDocument.soup)
    raw["recipe"]=["bad":true];raw["pinnedRecipes"]=[["bad":true],recipe,recipe]
    let s=try restore(raw,changing:["recipe","pinnedRecipes","pinnedRecipe"])
    XCTAssertEqual(s.recipe.id,RecipeDocument.soup.id)
    XCTAssertEqual(s.pinnedRecipes.map(\.id),[RecipeDocument.soup.id]);XCTAssertTrue(s.pinnedRecipe)
  }
  func testProfileLegacyMissingListDoesNotInventContentOrCrossProfile() throws {
    var raw=try base();raw["personal"]=["Alex":["messages":["OWNED_ALEX_ONLY"]],"Jamie":["reminders":[]]]
    let s=try restore(raw,changing:["personal"])
    XCTAssertEqual(s.personal["Alex"]?.messages,["OWNED_ALEX_ONLY"]);XCTAssertEqual(s.personal["Alex"]?.reminders,[])
    XCTAssertEqual(s.personal["Jamie"]?.messages,[])
  }
  func testProfileDamagedMembersKeepOnlyTheirOwnUniqueReminderActions() throws {
    var item=ReminderItem(title:"OWNED_REMINDER");item.id=UUID(uuidString:first)!
    var raw=try base();raw["personal"]=["Alex":["messages":[17,"OWNED_ALEX_ONLY"],"reminders":[try record(item),17,try record(item)]],"Jamie":["messages":["OWNED_JAMIE_ONLY"],"reminders":[]]]
    let s=try restore(raw,changing:["personal"])
    XCTAssertEqual(s.personal["Alex"]?.messages,["OWNED_ALEX_ONLY"]);XCTAssertEqual(s.personal["Alex"]?.reminders,[item])
    XCTAssertEqual(s.personal["Jamie"]?.messages,["OWNED_JAMIE_ONLY"]);XCTAssertEqual(s.personal["Jamie"]?.reminders,[])
  }
  func testDamagedNativeOwnershipListRetainsHealthyIDsButNeverRepairsConsent() throws {
    var raw=try base();raw["nativeTimerIDs"]=[first,17,first,"bad",second]
    raw["nativeAlarmIDs"]=[first,"bad",second];raw["connectionConsent"]=["Calendar",17]
    let s=try restore(raw,changing:["nativeTimerIDs","nativeAlarmIDs","connectionConsent"])
    XCTAssertEqual(s.nativeTimerIDs,Set([UUID(uuidString:first)!,UUID(uuidString:second)!]))
    XCTAssertEqual(s.nativeAlarmIDs,s.nativeTimerIDs);XCTAssertEqual(s.connectionConsent,[])
  }
  func testDamagedAlbumGrantAndPhotoDiscriminatorRemainFailClosed() throws {
    for kind in ["album","unknown"] {
      var raw=try base();raw["photoSelection"]=kind;raw["photoIDs"]=[first];raw["albumDisplay"]=["approvedForDisplay":true,"cache":[]]
      let s=try restore(raw,changing:["photoSelection","photoIDs","albumDisplay"])
      XCTAssertEqual(s.photoSelection,.none);XCTAssertTrue(s.photoIDs.isEmpty);XCTAssertNil(s.albumDisplay)
    }
  }
}
