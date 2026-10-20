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

final class SnapshotTablePressureTests: XCTestCase {
  private func baseObject() throws -> [String:Any] {
    var state=Snapshot();state.home.temperature=73
    state.timers=[Countdown(title:"Owned pressure canary timer",seconds:90)]
    return try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as? [String:Any])
  }
  private func restore(_ object:[String:Any]) throws -> Snapshot {
    try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject:object,options:[.sortedKeys]))
  }
  private func personal(_ note:String) throws -> Any {
    var value=PersonalContent();value.messages=[note];value.reminders=[]
    return try JSONSerialization.jsonObject(with:JSONEncoder().encode(value))
  }
  func testUnknownFaceRecordsCannotCrowdKnownSavedConfigurations() throws {
    var object=try baseObject()
    var faces:[String:Any]=Dictionary(uniqueKeysWithValues:(0..<Face.allCases.count).map {
      (String(format:"AA-unknown-%03d",$0),["theme":0] as Any)
    })
    faces["Flow"]=["flowTypeface":1,"flowBackground":false,"theme":1]
    faces["Modular"]=["complications":["panel0":"Weather"],"theme":1]
    object["faceConfigurations"]=faces
    let state=try restore(object)
    XCTAssertEqual(state.configuration(for:.flow).flowTypeface,1)
    XCTAssertFalse(state.configuration(for:.flow).flowBackground)
    XCTAssertEqual(state.configuration(for:.flow).theme,1)
    XCTAssertEqual(state.configuration(for:.modular).complications["panel0"],.weather)
    XCTAssertEqual(state.configuration(for:.modular).theme,1)
    XCTAssertLessThanOrEqual(state.faceConfigurations.count,Face.allCases.count)
    XCTAssertEqual(state.home.temperature,73)
    XCTAssertEqual(state.timers.map(\.title),["Owned pressure canary timer"])
  }
  func testUnknownProfilesCannotCrowdKnownPrivateProfileContent() throws {
    var object=try baseObject(),profiles:[String:Any]=[:]
    for i in 0..<Fixtures.profiles.count {profiles[String(format:"AA-unknown-%03d",i)]=try personal("UNUSED_SYNTHETIC_\(i)")}
    profiles["Alex"]=try personal("OWNED_ALEX_PRIVATE_CANARY")
    profiles["Jamie"]=try personal("OWNED_JAMIE_PRIVATE_CANARY")
    object["personal"]=profiles
    let state=try restore(object)
    XCTAssertEqual(state.personal["Alex"]?.messages,["OWNED_ALEX_PRIVATE_CANARY"])
    XCTAssertEqual(state.personal["Jamie"]?.messages,["OWNED_JAMIE_PRIVATE_CANARY"])
    XCTAssertLessThanOrEqual(state.personal.count,Fixtures.profiles.count)
    XCTAssertEqual(state.home.temperature,73)
  }
  func testNonObjectPhotoRecordsCannotConsumeHealthyAdjustmentBudget() throws {
    var object=try baseObject(),adjustments:[String:Any]=[:]
    for i in 0..<100 {adjustments[String(format:"AA-broken-%03d",i)]="not an adjustment object"}
    let key=String(repeating:"f",count:64)
    adjustments[key]=["clock":"bottom","automaticCrop":false,"horizontal":0.23,"vertical":0.77]
    object["photoAdjustments"]=adjustments
    let state=try restore(object)
    XCTAssertEqual(state.photoAdjustments.count,1)
    XCTAssertEqual(state.photoAdjustments[key]?.clock,.bottom)
    XCTAssertEqual(state.photoAdjustments[key]?.automaticCrop,false)
    XCTAssertEqual(state.photoAdjustments[key]?.horizontal,0.23)
    XCTAssertEqual(state.photoAdjustments[key]?.vertical,0.77)
    XCTAssertEqual(state.home.temperature,73)
  }
  func testOversizedTableNamesCannotHideHealthyPhotoAdjustment() throws {
    var object=try baseObject(),adjustments:[String:Any]=[:]
    for i in 0..<100 {adjustments[String(format:"AA-%03d-",i)+String(repeating:"x",count:129)]=["clock":"top"]}
    adjustments["synthetic"]=["clock":"bottom","horizontal":0.2]
    object["photoAdjustments"]=adjustments
    let state=try restore(object)
    XCTAssertEqual(state.photoAdjustments.count,1)
    XCTAssertEqual(state.photoAdjustments["synthetic"]?.clock,.bottom)
    XCTAssertEqual(state.photoAdjustments["synthetic"]?.horizontal,0.2)
  }
  func testMalformedSlotValuesCannotConsumeHealthyComplicationBudget() throws {
    var object=try baseObject(),slots:[String:Any]=[:]
    for i in 0..<64 {slots[String(format:"AA-broken-%03d",i)]=i.isMultiple(of:2) ? (17 as Any):("Future Radar" as Any)}
    slots["panel0"]="Weather";slots["panel1"]="Timer"
    object["faceConfigurations"]=["Modular":["complications":slots,"theme":1]]
    let c=try restore(object).configuration(for:.modular)
    XCTAssertEqual(c.complications["panel0"],.weather)
    XCTAssertEqual(c.complications["panel1"],.timer)
    XCTAssertEqual(c.complications.count,2)
    XCTAssertEqual(c.theme,1)
  }
  func testUnknownWellFormedSlotIDsCannotCrowdKnownSlots() throws {
    var object=try baseObject()
    var slots=Dictionary(uniqueKeysWithValues:(0..<64).map { (String(format:"AA-future-%03d",$0),"Clock") })
    slots["panel0"]="Weather";slots["panel1"]="Timer"
    object["faceConfigurations"]=["Modular":["complications":slots,"theme":1]]
    let c=try restore(object).configuration(for:.modular)
    XCTAssertEqual(c.complications["panel0"],.weather)
    XCTAssertEqual(c.complications["panel1"],.timer)
    XCTAssertEqual(c.complications.count,64)
  }
  func testLegacyUnknownRecordsBelowCapacityRemainPreserved() throws {
    var object=try baseObject()
    object["personal"]=["Future profile":try personal("OWNED_FUTURE_PROFILE")]
    object["faceConfigurations"]=["Future face":["theme":1]]
    object["photoAdjustments"]=["synthetic":["clock":"bottom"]]
    let state=try restore(object)
    XCTAssertEqual(state.personal["Future profile"]?.messages,["OWNED_FUTURE_PROFILE"])
    XCTAssertEqual(state.faceConfigurations["Future face"]?.theme,1)
    XCTAssertEqual(state.photoAdjustments["synthetic"]?.clock,.bottom)
  }
  func testOverflowRemainsBoundedAndCanonicalRoundTripIsIdempotent() throws {
    var object=try baseObject()
    object["photoAdjustments"]=Dictionary(uniqueKeysWithValues:(0..<140).map { (String(format:"own-%03d",$0),["clock":"bottom"]) })
    object["faceConfigurations"]=Dictionary(uniqueKeysWithValues:(0..<Face.allCases.count+20).map { (String(format:"future-%03d",$0),["theme":1]) })
    var profiles:[String:Any]=[:]
    for i in 0..<20 {profiles[String(format:"future-%03d",i)]=try personal("OWNED_SYNTHETIC_\(i)")}
    object["personal"]=profiles
    let state=try restore(object)
    XCTAssertEqual(state.photoAdjustments.count,100)
    XCTAssertEqual(state.faceConfigurations.count,Face.allCases.count)
    XCTAssertEqual(state.personal.count,6)
    let first=try JSONEncoder().encode(state),again=try Snapshot.decodeMigrating(first)
    XCTAssertEqual(try Snapshot.canonicalBytes(first),try Snapshot.canonicalBytes(JSONEncoder().encode(again)))
  }
  func testNativeServiceIDLimitsUseCanonicalStableOrder() throws {
    let ids=(1...80).map { UUID(uuidString:String(format:"00000000-0000-4000-8000-%012d",$0))! }
    var object=try baseObject()
    object["nativeTimerIDs"]=ids.reversed().map(\.uuidString)
    object["nativeAlarmIDs"]=ids.map(\.uuidString)
    let expected=Set(ids.sorted { $0.uuidString < $1.uuidString }.prefix(64))
    let state=try restore(object)
    XCTAssertEqual(state.nativeTimerIDs.count,64)
    XCTAssertEqual(state.nativeAlarmIDs.count,64)
    XCTAssertEqual(state.nativeTimerIDs,expected)
    XCTAssertEqual(state.nativeAlarmIDs,expected)
  }

}

final class PersonalFieldRecoveryTests: XCTestCase {
  private func restore(_ profiles:[String:Any]) throws -> Snapshot {
    var state=Snapshot();state.home.temperature=74;state.connectionConsent=[]
    var raw=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as? [String:Any])
    raw["personal"]=profiles
    return try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject:raw))
  }
  private func reminder(_ item:ReminderItem) throws -> Any {
    try JSONSerialization.jsonObject(with:JSONEncoder().encode(item))
  }
  func testBrokenRemindersPreserveMessagesAndOtherProfile() throws {
    let state=try restore([
      "Alex":["messages":["OWNED_ALEX_MESSAGE"],"reminders":"broken"],
      "Jamie":["messages":["OWNED_JAMIE_MESSAGE"],"reminders":[]]
    ])
    XCTAssertEqual(state.personal["Alex"]?.messages,["OWNED_ALEX_MESSAGE"])
    XCTAssertEqual(state.personal["Alex"]?.reminders,[])
    XCTAssertEqual(state.personal["Jamie"]?.messages,["OWNED_JAMIE_MESSAGE"])
    XCTAssertEqual(state.home.temperature,74)
  }
  func testBrokenMessagesPreserveReminders() throws {
    let item=ReminderItem(title:"OWNED_JAMIE_REMINDER")
    let state=try restore(["Jamie":["messages":19,"reminders":[try reminder(item)]]])
    XCTAssertEqual(state.personal["Jamie"]?.messages,[])
    XCTAssertEqual(state.personal["Jamie"]?.reminders,[item])
  }
  func testLegacyMissingOneListDoesNotDiscardTheOtherOrInventContent() throws {
    let item=ReminderItem(title:"OWNED_LEGACY_REMINDER")
    let state=try restore(["Alex":["messages":["OWNED_LEGACY_MESSAGE"]],
      "Jamie":["reminders":[try reminder(item)]]])
    XCTAssertEqual(state.personal["Alex"]?.messages,["OWNED_LEGACY_MESSAGE"])
    XCTAssertEqual(state.personal["Alex"]?.reminders,[])
    XCTAssertEqual(state.personal["Jamie"]?.messages,[])
    XCTAssertEqual(state.personal["Jamie"]?.reminders,[item])
  }
  func testMalformedArrayItemsDoNotDiscardValidSiblings() throws {
    let first=ReminderItem(title:"OWNED_FIRST_REMINDER"),last=ReminderItem(title:"OWNED_LAST_REMINDER")
    let state=try restore(["Alex":["messages":["OWNED_FIRST_MESSAGE",17,NSNull(),["not":"message"],"OWNED_LAST_MESSAGE"],
      "reminders":[try reminder(first),17,NSNull(),["bad":true],try reminder(last)]]])
    XCTAssertEqual(state.personal["Alex"]?.messages,["OWNED_FIRST_MESSAGE","OWNED_LAST_MESSAGE"])
    XCTAssertEqual(state.personal["Alex"]?.reminders,[first,last])
  }
  func testDuplicateReminderIdentityCannotReachTwoLocalActions() throws {
    let first=ReminderItem(title:"OWNED_FIRST_IDENTITY")
    var duplicate=first;duplicate.title="OWNED_DUPLICATE_IDENTITY"
    let last=ReminderItem(title:"OWNED_DISTINCT_IDENTITY")
    let state=try restore(["Alex":["messages":[],"reminders":[try reminder(first),try reminder(duplicate),try reminder(last)]]])
    XCTAssertEqual(state.personal["Alex"]?.reminders,[first,last])
  }
  func testNullOrMalformedListsRecoverEmptyNotDemoOrOtherProfileContent() throws {
    for bad:Any in [NSNull(),19,"bad",["not":"a list"]] {
      let state=try restore(["Alex":["messages":bad,"reminders":bad],
        "Jamie":["messages":["OWNED_OTHER_PROFILE"],"reminders":[]]])
      XCTAssertEqual(state.personal["Alex"]?.messages,[])
      XCTAssertEqual(state.personal["Alex"]?.reminders,[])
      XCTAssertEqual(state.personal["Jamie"]?.messages,["OWNED_OTHER_PROFILE"])
    }
  }
  func testExplicitEmptyListsStayEmptyControl() throws {
    let state=try restore(["Alex":["messages":[],"reminders":[]]])
    XCTAssertEqual(state.personal["Alex"]?.messages,[])
    XCTAssertEqual(state.personal["Alex"]?.reminders,[])
  }
  func testHealthyContentRoundTripsAndFreshDemoConstructorIsUnchangedControl() throws {
    let fresh=PersonalContent();XCTAssertEqual(fresh.messages.count,2);XCTAssertEqual(fresh.reminders.count,2)
    var content=PersonalContent();content.messages=["OWNED_HEALTHY_MESSAGE","OWNED_HEALTHY_MESSAGE"]
    content.reminders=[ReminderItem(title:"OWNED_HEALTHY_REMINDER")]
    let object=try JSONSerialization.jsonObject(with:JSONEncoder().encode(content))
    let state=try restore(["Alex":object]);XCTAssertEqual(state.personal["Alex"]?.messages,content.messages)
    XCTAssertEqual(state.personal["Alex"]?.reminders,content.reminders)
    let encoded=try JSONEncoder().encode(state)
    XCTAssertEqual(try Snapshot.canonicalBytes(encoded),try Snapshot.canonicalBytes(JSONEncoder().encode(Snapshot.decodeMigrating(encoded))))
  }
  func testNonObjectProfileRecordsRemainRejectedControl() throws {
    for bad:Any in [17,"bad",[],NSNull()] {
      let state=try restore(["Alex":bad]);XCTAssertNil(state.personal["Alex"])
    }
  }
}
