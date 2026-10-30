import XCTest
@testable import HomeViewCore

final class FaceConfigurationMigrationTests: XCTestCase {
  func testAllOwnFlowPalettesRoundTripWithoutChangingSiblingState() throws {
    for palette in 0...7 {
      for font in 0...2 {
      var state=Snapshot()
      state.editConfiguration(for:.modular) {$0.theme=1;$0.complications["panel0"] = .timer}
      let sibling=state.configuration(for:.modular)
      state.editConfiguration(for:.flow) {$0.flowPalette=palette;$0.flowTypeface=font;$0.flowBackground=false}
      let restored=try Snapshot.decodeMigrating(JSONEncoder().encode(state))
      XCTAssertEqual(restored.configuration(for:.flow).flowPalette,palette)
      XCTAssertEqual(restored.configuration(for:.flow).flowTypeface,font)
      XCTAssertFalse(restored.configuration(for:.flow).flowBackground)
      XCTAssertEqual(restored.configuration(for:.modular),sibling)
      XCTAssertEqual(restored.theme,0)
      }
    }
  }
  func testLegacyFlowWithoutPaletteKeepsTypefaceAndBackground() throws {
    let state=try restore(["Flow":["theme":1,"flowTypeface":1,"flowBackground":false]])
    let c=state.configuration(for:.flow)
    XCTAssertEqual(c.flowPalette,0)
    XCTAssertEqual(c.theme,1)
    XCTAssertEqual(c.flowTypeface,1)
    XCTAssertFalse(c.flowBackground)
  }
  func testMalformedFlowPaletteFallsBackWithoutDiscardingOtherFields() throws {
    for invalid:Any in [-1,8,Int.max,"ice",true,NSNull()] {
      let state=try restore(["Flow":["flowPalette":invalid,"theme":1,"flowTypeface":1,"flowBackground":false]])
      let c=state.configuration(for:.flow)
      XCTAssertEqual(c.flowPalette,0)
      XCTAssertEqual(c.theme,1)
      XCTAssertEqual(c.flowTypeface,1)
      XCTAssertFalse(c.flowBackground)
    }
  }
  func testNumeralsPaletteSurvivesStorageWithoutChangingLegacyOrSiblingThemes() throws {
    XCTAssertEqual(Face.numerals.definition.options,[.color])
    var state=Snapshot()
    XCTAssertEqual(state.configuration(for:.numerals).theme,0)
    state.editConfiguration(for:.numerals) {$0.theme=1}
    let restored=try Snapshot.decodeMigrating(JSONEncoder().encode(state))
    XCTAssertEqual(restored.configuration(for:.numerals).theme,1)
    XCTAssertEqual(restored.theme,0)
    for face in [Face.modular,.home,.homeClock,.watchModular] {
      XCTAssertEqual(restored.configuration(for:face).theme,0)
      XCTAssertNil(restored.faceConfigurations[face.id])
    }
    XCTAssertEqual(restored.configuration(for:.numerals).complications,[:])
  }
  private func restore(_ configurations: [String:Any]) throws -> Snapshot {
    var state = Snapshot()
    state.home.temperature = 74
    state.timers = [Countdown(title:"Synthetic saved timer",seconds:90)]
    var raw = try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(state)) as? [String:Any])
    raw["faceConfigurations"] = configurations
    return try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject:raw))
  }
  func testLegacyFaceWithoutLaterFlowFieldsPreservesSlotsAndTheme() throws {
    let restored = try restore([
      "Modular":["complications":["panel0":"Weather","panel2":"Timer"],"theme":1],
      "Flow":["complications":[:],"theme":0,"flowTypeface":1,"flowBackground":false]
    ])
    XCTAssertEqual(restored.configuration(for:.modular).complications["panel0"],.weather)
    XCTAssertEqual(restored.configuration(for:.modular).complications["panel2"],.timer)
    XCTAssertEqual(restored.configuration(for:.modular).theme,1)
    XCTAssertEqual(restored.configuration(for:.modular).flowTypeface,0)
    XCTAssertTrue(restored.configuration(for:.modular).flowBackground)
    XCTAssertEqual(restored.configuration(for:.flow).flowTypeface,1)
    XCTAssertFalse(restored.configuration(for:.flow).flowBackground)
    XCTAssertEqual(restored.home.temperature,74)
    XCTAssertEqual(restored.timers.map(\.title),["Synthetic saved timer"])
  }
  func testUnknownWidgetCannotDiscardKnownSiblingChoicesOrStyle() throws {
    let restored = try restore([
      "Modular":["complications":["panel0":"Future Radar","panel1":"Clock","panel2":"Timer"],
        "theme":1,"flowTypeface":1,"flowBackground":false]
    ])
    let configuration = restored.configuration(for:.modular)
    XCTAssertNil(configuration.complications["panel0"])
    XCTAssertEqual(configuration.complications["panel1"],.clock)
    XCTAssertEqual(configuration.complications["panel2"],.timer)
    XCTAssertEqual(configuration.theme,1)
    XCTAssertEqual(configuration.flowTypeface,1)
    XCTAssertFalse(configuration.flowBackground)
    XCTAssertEqual(restored.complication(for:.modular,slot:Face.modular.slots[0]),.date)
    XCTAssertEqual(restored.home.temperature,74)
    XCTAssertEqual(restored.timers.map(\.title),["Synthetic saved timer"])
  }
  func testMissingFieldsDefaultIndependentlyInsteadOfRejectingTheObject() throws {
    let decoder = JSONDecoder()
    XCTAssertEqual(try decoder.decode(FaceConfiguration.self,from:Data("{}".utf8)),.init())
    let configuration = try decoder.decode(FaceConfiguration.self,
      from:Data("{\"flowBackground\":false}".utf8))
    XCTAssertFalse(configuration.flowBackground)
    XCTAssertEqual(configuration.theme,0)
    XCTAssertEqual(configuration.flowTypeface,0)
    XCTAssertTrue(configuration.complications.isEmpty)
    XCTAssertThrowsError(try decoder.decode(FaceConfiguration.self,from:Data("[]".utf8)))
  }
  func testMalformedSlotAndStyleDoNotDiscardIndependentHealthyFields() throws {
    let restored = try restore(["Modular":[
      "complications":["panel0":"Weather","panel1":17,"panel2":"Off"],
      "theme":"bad","flowTypeface":1,"flowBackground":false
    ]])
    let c = restored.configuration(for:.modular)
    XCTAssertEqual(c.complications["panel0"],.weather)
    XCTAssertNil(c.complications["panel1"])
    XCTAssertEqual(c.complications["panel2"],ComplicationKind.none)
    XCTAssertEqual(c.theme,0)
    XCTAssertEqual(c.flowTypeface,1)
    XCTAssertFalse(c.flowBackground)
  }
  func testInvalidComplicationContainerCannotEraseValidStyle() throws {
    for bad: Any in [[],"invalid",NSNull()] {
      let restored = try restore(["Flow":["complications":bad,"theme":1,
        "flowTypeface":1,"flowBackground":false]])
      let c = restored.configuration(for:.flow)
      XCTAssertTrue(c.complications.isEmpty)
      XCTAssertEqual(c.theme,1)
      XCTAssertEqual(c.flowTypeface,1)
      XCTAssertFalse(c.flowBackground)
    }
    let invalid = try restore(["Flow":["theme":99,"flowTypeface":-1,"flowBackground":1]])
    XCTAssertEqual(invalid.configuration(for:.flow),.init())
  }
  func testStoredSlotTableIsBoundedAndInvalidKeysAreSkipped() throws {
    var slots = Dictionary(uniqueKeysWithValues:(0..<100).map { (String(format:"slot%03d",$0),"Weather") })
    slots[""] = "Clock";slots[String(repeating:"x",count:129)] = "Timer"
    let restored = try restore(["Modular":["complications":slots,"theme":1]])
    let c = restored.configuration(for:.modular)
    XCTAssertEqual(c.complications.count,64)
    XCTAssertNil(c.complications[""])
    XCTAssertNil(c.complications[String(repeating:"x",count:129)])
    XCTAssertEqual(c.theme,1)
  }
  func testRecoveredConfigurationSurvivesCanonicalRoundTripAndFamilyValidation() throws {
    let restored = try restore([
      "Modular":["complications":["panel0":"Weather","panel2":"Timer"],"theme":1],
      "Watch Modular":["complications":["topLeft":"Music","center":"Timer"],"theme":1]
    ])
    let saved = try JSONEncoder().encode(restored)
    let again = try Snapshot.decodeMigrating(saved)
    XCTAssertEqual(again.faceConfigurations,restored.faceConfigurations)
    XCTAssertEqual(try Snapshot.canonicalBytes(JSONEncoder().encode(again)),try Snapshot.canonicalBytes(saved))
    // Recovery must not bypass the existing slot family's allowed choices.
    XCTAssertEqual(again.complication(for:.watchModular,slot:Face.watchModular.slots[0]),.none)
    XCTAssertEqual(again.complication(for:.watchModular,slot:Face.watchModular.slots[1]),.timer)
    XCTAssertEqual(again.configuration(for:.modular).complications["panel0"],.weather)
  }
}
