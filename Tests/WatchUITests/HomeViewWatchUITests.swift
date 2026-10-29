import XCTest

final class HomeViewWatchUITests:XCTestCase {
  private func capture(_ app:XCUIApplication,_ name:String) {
    let tree=XCTAttachment(string:app.debugDescription);tree.name=name+"-tree";tree.lifetime = .keepAlways;add(tree)
    let shot=XCTAttachment(screenshot:app.screenshot());shot.name=name;shot.lifetime = .keepAlways;add(shot)
  }
  func testNativeWatchLaunchAndMockHomeControls() {
    continueAfterFailure=false
    let app=XCUIApplication(bundleIdentifier:"org.example.HomeViewWatch")
    app.launchArguments=["--uitesting","--reference-clock","--persistence-test",UUID().uuidString,"--reset-test-store"]
    app.launch()
    XCTAssertTrue(app.staticTexts["68°"].waitForExistence(timeout:20))
    let tree=XCTAttachment(string:app.debugDescription);tree.name="watch-initial-tree";tree.lifetime = .keepAlways;add(tree)
    let shot=XCTAttachment(screenshot:app.screenshot());shot.name="watch-native-initial";shot.lifetime = .keepAlways;add(shot)
    app.buttons["+"].tap();capture(app,"watch-after-increase")
    XCTAssertTrue(app.staticTexts["69°"].waitForExistence(timeout:5))
    XCTAssertGreaterThanOrEqual(app.buttons["+"].frame.width,44)
    XCTAssertGreaterThanOrEqual(app.buttons["+"].frame.height,44)
    app.buttons["−"].tap();XCTAssertTrue(app.staticTexts["68°"].waitForExistence(timeout:5))
    app.buttons["Lights On"].tap();XCTAssertTrue(app.buttons["Lights Off"].waitForExistence(timeout:5))
    capture(app,"watch-light-toggled")
    XCTAssertFalse(app.textFields["assistant.input"].exists)
    XCTAssertFalse(app.buttons["nav.apps"].exists)
  }
  func testNativeWatchTimerAndBackgroundReturn() {
    continueAfterFailure=false
    let app=XCUIApplication(bundleIdentifier:"org.example.HomeViewWatch")
    app.launchArguments=["--uitesting","--reference-clock","--persistence-test",UUID().uuidString,"--reset-test-store"]
    app.launch();XCTAssertTrue(app.staticTexts["68°"].waitForExistence(timeout:20))
    let start=app.buttons["5-minute timer"]
    for _ in 0..<6 {
      if start.exists && start.isHittable && app.frame.insetBy(dx:0,dy:40).contains(start.frame) { break }
      app.swipeUp()
    }
    XCTAssertTrue(start.isHittable);start.tap()
    let count=app.staticTexts.matching(NSPredicate(format:"label MATCHES %@","0[45]:[0-5][0-9]")).firstMatch
    for _ in 0..<4 {
      if count.exists && count.isHittable { break }
      app.swipeUp()
    }
    XCTAssertTrue(count.waitForExistence(timeout:5));capture(app,"watch-local-timer")
    XCUIDevice.shared.press(.home)
    XCTAssertTrue(app.wait(for:.runningBackground,timeout:5) || app.state == .runningBackgroundSuspended)
    app.activate();XCTAssertTrue(app.wait(for:.runningForeground,timeout:5))
    XCTAssertTrue(count.waitForExistence(timeout:5));capture(app,"watch-timer-returned")
  }
}
