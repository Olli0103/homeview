import XCTest

@MainActor final class HomeViewVisionUITests:XCTestCase {
  func testReadOnlyVisionVisibleLiveSpeechAndRTTSearchInventory() {
    continueAfterFailure=false
    let settings=XCUIApplication(bundleIdentifier:"com.apple.Preferences")
    settings.launch();XCTAssertTrue(settings.wait(for:.runningForeground,timeout:30))
    let category=settings.buttons["ACCESSIBILITY"]
    XCTAssertTrue(category.waitForExistence(timeout:10));category.tap();XCTAssertTrue(category.isSelected)
    let table=settings.tables.firstMatch,window=settings.windows.containing(.button,identifier:"ACCESSIBILITY").firstMatch
    XCTAssertTrue(table.exists);XCTAssertTrue(window.exists)
    let live=settings.cells["LIVE_SPEECH_TITLE"]
    XCTAssertTrue(live.exists);let status=live.label;XCTAssertTrue(status.contains("Off"))
    var poses:[[Double]]=[],visible=false
    for step in 0..<8 {
      let f=live.frame,clip=table.frame.intersection(window.frame).insetBy(dx:20,dy:112)
      poses.append([Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)])
      if !f.isEmpty,clip.contains(f) {visible=true;break}
      // Use the table's native scene-bound scroll action, not the window gutter.
      let pose=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:[
        "target":[f.minX,f.minY,f.width,f.height],"window":[window.frame.minX,window.frame.minY,window.frame.width,window.frame.height],
        "direction":f.minY<clip.minY ? "down":"up","base":"main table semantic slow swipe"],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
      pose.name="vision-ossettings-scroll-before-\(step)";pose.lifetime = .keepAlways;add(pose)
      if f.minY<clip.minY {table.swipeDown(velocity:.slow)} else {table.swipeUp(velocity:.slow)}
    }
    XCTAssertTrue(visible);XCTAssertEqual(live.label,status)
    let report=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:["poses":poses,"status":status,"feature_row_taps":0],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    report.name="vision-ossettings-live-speech-scroll-only";report.lifetime = .keepAlways;add(report)
    capture(settings,"vision-ossettings-live-speech-visible")
    let field=settings.searchFields.firstMatch
    XCTAssertTrue(field.waitForExistence(timeout:5));field.tap();field.typeText("RTT")
    XCTAssertEqual(field.value as? String,"RTT");RunLoop.current.run(until:Date().addingTimeInterval(2))
    capture(settings,"vision-ossettings-query-rtt")
    field.tap();field.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:3));field.typeText("Live Speech")
    XCTAssertEqual(field.value as? String,"Live Speech");RunLoop.current.run(until:Date().addingTimeInterval(2))
    capture(settings,"vision-ossettings-query-live-speech")
    field.tap();field.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:11))
    XCTAssertTrue(["","Search"].contains(field.value as? String ?? "INVALID"))
  }
  func testReadOnlyVisionAccessibilityMenuInventory() {
    continueAfterFailure=false
    let settings=XCUIApplication(bundleIdentifier:"com.apple.Preferences")
    settings.launch();XCTAssertTrue(settings.wait(for:.runningForeground,timeout:30))
    let category=settings.buttons["ACCESSIBILITY"]
    XCTAssertTrue(category.waitForExistence(timeout:10));category.tap()
    XCTAssertTrue(category.isSelected)
    capture(settings,"vision-ossettings-accessibility-top")
  }
  func testReadOnlyVisionSystemSettingsRootInventory() {
    continueAfterFailure=false
    let settings=XCUIApplication(bundleIdentifier:"com.apple.Preferences")
    settings.launch()
    XCTAssertTrue(settings.wait(for:.runningForeground,timeout:30))
    capture(settings,"vision-ossettings-root")
  }
  private func launch(_ page:String?=nil)->XCUIApplication {
    continueAfterFailure=false
    let app=XCUIApplication(bundleIdentifier:"org.example.HomeViewReplica")
    app.launchArguments=["--uitesting","--reference-clock","--persistence-test",UUID().uuidString,"--reset-test-store"]
    if let page {app.launchArguments += ["--page",page]}
    app.launch();XCTAssertTrue(app.staticTexts["mock.badge"].waitForExistence(timeout:30));return app
  }
  private func capture(_ app:XCUIApplication,_ name:String) {
    let image=XCTAttachment(screenshot:app.screenshot());image.name=name;image.lifetime = .keepAlways;add(image)
    let tree=XCTAttachment(string:app.debugDescription);tree.name=name+"-tree";tree.lifetime = .keepAlways;add(tree)
    // visionOS app snapshots crop the render surface; the public simulator
    // camera can capture this held state without changing the app renderer.
    func marker(_ phase:String) {
      let data=try! JSONSerialization.data(withJSONObject:["name":name,"at":Date().timeIntervalSince1970],options:[.sortedKeys])
      FileHandle.standardOutput.write(Data(("NATIVE_QA_"+phase+":"+String(decoding:data,as:UTF8.self)+"\n").utf8))
    }
    marker("READY");RunLoop.current.run(until:Date().addingTimeInterval(10));marker("DONE")
  }
  func testNativeVisionWindowAndMockThermostat() {
    let app=launch();capture(app,"vision-native-window")
    let viewport=app.otherElements["reference.viewport"]
    XCTAssertTrue(viewport.exists);XCTAssertGreaterThan(viewport.frame.width,0);XCTAssertGreaterThan(viewport.frame.height,0)
    let window=app.windows.containing(.other,identifier:"reference.viewport").firstMatch
    XCTAssertTrue(window.exists);XCTAssertTrue(window.frame.contains(viewport.frame))
    for id in ["nav.faces","nav.apps","nav.assistant","nav.controls"] {
      XCTAssertTrue(window.frame.contains(app.buttons[id].frame));XCTAssertTrue(app.buttons[id].isHittable)
    }
    app.buttons["home.thermostat"].tap()
    XCTAssertTrue(app.staticTexts["thermostat.value"].waitForExistence(timeout:5));XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
    capture(app,"vision-mock-thermostat")
  }
  func testNativeVisionLocalTimer() {
    let app=launch("Timers");app.buttons["timer.start"].tap()
    XCTAssertTrue(app.staticTexts["timer.countdown"].waitForExistence(timeout:5))
    app.buttons["timer.pause"].tap();XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
    capture(app,"vision-timer-paused")
    app.buttons["timer.delete"].tap();XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5))
  }
  func testNativeVisionAssistantUnsentInput() {
    let app=launch();app.buttons["nav.assistant"].tap()
    let field=app.textFields["assistant.input"];XCTAssertTrue(field.waitForExistence(timeout:5))
    field.tap();field.typeText("OWNED VISION DRAFT")
    XCTAssertTrue((field.value as? String ?? "").contains("OWNED VISION DRAFT"));capture(app,"vision-unsent-draft")
  }
  func testNativeVisionBundledBrowser() {
    let app=launch("Safari")
    XCTAssertTrue(app.webViews.staticTexts["Garden Tomato Pasta"].waitForExistence(timeout:15));capture(app,"vision-local-browser")
  }
}
