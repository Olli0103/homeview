import XCTest

@MainActor final class HomeViewVisionUITests:XCTestCase {
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
