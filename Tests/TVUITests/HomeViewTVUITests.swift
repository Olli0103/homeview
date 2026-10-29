import XCTest

final class HomeViewTVUITests:XCTestCase {
  private func launch(_ page:String?=nil)->XCUIApplication {
    continueAfterFailure=false
    let app=XCUIApplication(bundleIdentifier:"org.example.HomeViewReplica")
    app.launchArguments=["--uitesting","--reference-clock","--persistence-test",UUID().uuidString,"--reset-test-store"]
    if let page { app.launchArguments += ["--page",page] }
    app.launch();XCTAssertTrue(app.staticTexts["mock.badge"].waitForExistence(timeout:20));return app
  }
  private func capture(_ app:XCUIApplication,_ name:String) {
    let shot=XCTAttachment(screenshot:app.screenshot());shot.name=name;shot.lifetime = .keepAlways;add(shot)
    let tree=XCTAttachment(string:app.debugDescription);tree.name=name+"-tree";tree.lifetime = .keepAlways;add(tree)
  }
  private func select(_ target:XCUIElement,in app:XCUIApplication) {
    XCTAssertTrue(target.waitForExistence(timeout:5))
    var trace:[String]=[]
    var attempted:[String:Set<Int>]=[:]
    for _ in 0..<24 {
      if target.hasFocus { break }
      guard let current=app.descendants(matching:.any).allElementsBoundByIndex.first(where:{$0.hasFocus}) else {
        XCTFail("No current native focus");return
      }
      let dx=target.frame.midX-current.frame.midX,dy=target.frame.midY-current.frame.midY
      let vertical:XCUIRemote.Button = dy>0 ? .down:.up
      let horizontal:XCUIRemote.Button = dx>0 ? .right:.left
      let preferred:[XCUIRemote.Button] = abs(dy)>max(25,abs(dx)*0.6) ? [vertical,horizontal,.left,.right,.up,.down]:[horizontal,vertical,.down,.up,.right,.left]
      let state=current.identifier+"|"+current.label+"|"+String(describing:current.frame)
      let key=preferred.first { !(attempted[state] ?? []).contains(Int($0.rawValue)) } ?? preferred[0]
      attempted[state,default:[]].insert(Int(key.rawValue))
      trace.append(current.identifier+" -> "+String(describing:key))
      XCUIRemote.shared.press(key)
    }
    let receipt=XCTAttachment(string:trace.joined(separator:"\n"));receipt.name="remote-focus-"+target.identifier;receipt.lifetime = .keepAlways;add(receipt)
    capture(app,"before-select-"+target.identifier)
    XCTAssertTrue(target.hasFocus,"Select must only activate the intended focused control")
    XCUIRemote.shared.press(.select)
  }
  func testRemoteOpensAppsAndSelectsTimer() {
    let app=launch()
    select(app.buttons["nav.apps"],in:app)
    XCTAssertTrue(app.buttons["all.apps"].waitForExistence(timeout:5))
    select(app.buttons["all.apps"],in:app)
    XCTAssertTrue(app.buttons["app.Timers"].waitForExistence(timeout:5))
    capture(app,"tv-app-drawer")
    select(app.buttons["app.Timers"],in:app)
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5));capture(app,"tv-timer-setup")
  }
  func testRemoteStartsPausesAndDeletesLocalTimer() {
    let app=launch("Timers")
    select(app.buttons["timer.start"],in:app)
    XCTAssertTrue(app.staticTexts["timer.countdown"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["Foreground timer"].exists)
    select(app.buttons["timer.pause"],in:app)
    XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer");capture(app,"tv-timer-paused")
    select(app.buttons["timer.delete"],in:app)
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5));capture(app,"tv-timer-deleted")
  }
  func testNativeTVBrowserBoundaryAndMenuReturn() {
    let app=launch("Safari")
    XCTAssertFalse(app.textFields["browser.address"].exists)
    XCTAssertTrue(app.staticTexts["A bundled recipe for offline testing. No network requests are made."].exists)
    capture(app,"tv-browser-boundary")
    XCUIRemote.shared.press(.menu)
    XCTAssertTrue(app.buttons["nav.apps"].waitForExistence(timeout:5));capture(app,"tv-menu-return")
  }
  func testNativeTVLaunchAndRemoteFocusDiscovery() {
    continueAfterFailure=false
    let app=XCUIApplication(bundleIdentifier:"org.example.HomeViewReplica")
    app.launchArguments=["--uitesting","--reference-clock","--persistence-test",UUID().uuidString,"--reset-test-store"]
    app.launch()
    XCTAssertTrue(app.staticTexts["mock.badge"].waitForExistence(timeout:20))
    var rows:[[String:Any]]=[]
    func capture(_ state:String) {
      let focused=app.descendants(matching:.any).allElementsBoundByIndex.filter { $0.hasFocus }
      rows.append(["state":state,"focused":focused.map {["id":$0.identifier,"label":$0.label]}])
      let shot=XCTAttachment(screenshot:app.screenshot());shot.name="tv-"+state;shot.lifetime = .keepAlways;add(shot)
      let tree=XCTAttachment(string:app.debugDescription);tree.name="tv-"+state+"-tree";tree.lifetime = .keepAlways;add(tree)
    }
    capture("launch")
    for (i,key) in [XCUIRemote.Button.down,.right,.right,.left,.up,.down].enumerated() {
      XCUIRemote.shared.press(key);capture("remote-\(i)")
    }
    let receipt=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:rows,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    receipt.name="tv-native-focus-discovery";receipt.lifetime = .keepAlways;add(receipt)
    XCTAssertTrue(rows.contains { ($0["focused"] as? [[String:String]])?.isEmpty == false },"Native remote must reach an actual focusable control")
  }
}
