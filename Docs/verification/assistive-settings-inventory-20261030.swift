// Archived read-only simulator diagnostic, not part of the normal App test target.
import UIKit
import XCTest

extension HomeViewUITests {
  func testReadOnlySimulatorAssistiveSettingsSurfaceInventory() {
    #if targetEnvironment(simulator)
    continueAfterFailure=false;executionTimeAllowance=180
    let original=UIAccessibility.isAssistiveTouchRunning
    let settings=XCUIApplication(bundleIdentifier:"com.apple.Preferences")
    var observations:[[String:Any]]=[]
    func capture(_ stage:String) {
      let text=settings.debugDescription
      let tree=XCTAttachment(string:text);tree.name="assistive-settings-"+stage+"-hierarchy";tree.lifetime = .keepAlways;add(tree)
      let shot=XCTAttachment(screenshot:XCUIScreen.main.screenshot());shot.name="assistive-settings-"+stage+"-screen";shot.lifetime = .keepAlways;add(shot)
      observations.append(["stage":stage,"native_assistive_touch":UIAccessibility.isAssistiveTouchRunning,
        "observed_routes": ["Touch","AssistiveTouch","Switch Control","Voice Control","Zoom"].map { name in
          ["name":name,"exact_button_exists":settings.buttons.matching(NSPredicate(format:"label == %@",name)).firstMatch.exists,
            "exact_cell_exists":settings.cells.matching(NSPredicate(format:"label == %@",name)).firstMatch.exists] as [String:Any]
        }])
    }
    settings.launch();XCTAssertTrue(settings.wait(for:.runningForeground,timeout:30))
    if !settings.otherElements["AccessibilitySettingsControllerView"].exists {
      let accessibility=settings.buttons["com.apple.settings.accessibility"]
      guard accessibility.waitForExistence(timeout:10) else {XCTFail("Observed Settings Accessibility target not reached");return}
      XCTAssertTrue(accessibility.isHittable);accessibility.tap()
    }
    let page=settings.otherElements["AccessibilitySettingsControllerView"]
    XCTAssertTrue(page.waitForExistence(timeout:10))
    let table=page.tables.firstMatch
    XCTAssertTrue(table.exists)
    capture("top")
    for step in 1...3 {table.swipeUp();capture("scroll-\(step)")}
    XCTAssertEqual(UIAccessibility.isAssistiveTouchRunning,original)
    let data:[String:Any]=["original_native_assistive_touch":original,"final_native_assistive_touch":UIAccessibility.isAssistiveTouchRunning,
      "observations":observations,"scope":"Read-only full bounded Accessibility menu inventory on an owned simulator. Three table-only scrolls; no switch, action, microphone, account, Nearby Device or personal store used. Inventory completion does not establish assistive activation, product usability, physical capability or universal API absence."]
    let report=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    report.name="assistive-settings-read-only-inventory";report.lifetime = .keepAlways;add(report)
    #else
    XCTFail("This read-only Settings inventory is simulator-only")
    #endif
  }
}
