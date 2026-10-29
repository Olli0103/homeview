import XCTest

final class HomeViewTVUITests:XCTestCase {
  private func launch(_ page:String?=nil,extra:[String]=[])->XCUIApplication {
    continueAfterFailure=false
    let app=XCUIApplication(bundleIdentifier:"org.example.HomeViewReplica")
    app.launchArguments=["--uitesting","--reference-clock","--persistence-test",UUID().uuidString,"--reset-test-store"]
    if let page { app.launchArguments += ["--page",page] }
    app.launchArguments += extra
    app.launch();XCTAssertTrue(app.staticTexts["mock.badge"].waitForExistence(timeout:20));return app
  }
  private func capture(_ app:XCUIApplication,_ name:String) {
    let shot=XCTAttachment(screenshot:app.screenshot());shot.name=name;shot.lifetime = .keepAlways;add(shot)
    let tree=XCTAttachment(string:app.debugDescription);tree.name=name+"-tree";tree.lifetime = .keepAlways;add(tree)
  }
  private func select(_ target:XCUIElement,in app:XCUIApplication,maxMoves:Int=24) {
    XCTAssertTrue(target.waitForExistence(timeout:5))
    var trace:[String]=[]
    var attempted:[String:Set<Int>]=[:]
    for _ in 0..<maxMoves {
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
  func testNativeTVCameraGridAndDemoTalkback() {
    let app=launch("Cameras")
    select(app.buttons["camera.grid.size"],in:app)
    XCTAssertEqual(app.buttons["camera.grid.size"].label,"Show 4")
    let viewport=app.otherElements["reference.viewport"].frame
    capture(app,"tv-nine-demo-cameras")
    let geometry=(0..<9).map { index -> [String:Any] in
      let frame=app.buttons["camera.\(index)"].frame
      return ["index":index,"frame":[frame.minX,frame.minY,frame.width,frame.height]]
    }
    let bounds=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:[
      "viewport":[viewport.minX,viewport.minY,viewport.width,viewport.height],"tiles":geometry],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    bounds.name="tv-camera-AX-geometry";bounds.lifetime = .keepAlways;add(bounds)
    for index in 0..<9 {
      let tile=app.buttons["camera.\(index)"]
      // tvOS activation/focus bounds can exceed the clipped visible image.
      // Keep all centers inside the viewport, then prove actual focused actions.
      XCTAssertTrue(tile.exists);XCTAssertTrue(viewport.contains(CGPoint(x:tile.frame.midX,y:tile.frame.midY)))
    }
    select(app.buttons["camera.8"],in:app)
    capture(app,"tv-demo-camera-detail")
    let status=app.descendants(matching:.any)["camera.demo.status"]
    XCTAssertTrue(status.waitForExistence(timeout:5));XCTAssertEqual(status.label,"Demo still")
    select(app.buttons["camera.talk"],in:app)
    XCTAssertEqual(app.buttons["camera.talk"].value as? String,"On (demo)")
    capture(app,"tv-demo-talkback-on-no-microphone")
    select(app.buttons["camera.grid"],in:app)
    select(app.buttons["camera.0"],in:app)
    XCTAssertEqual(app.buttons["camera.talk"].value as? String,"Off (demo)")
    select(app.buttons["camera.close"],in:app)
    XCTAssertTrue(app.buttons["all.apps"].waitForExistence(timeout:5))
    capture(app,"tv-demo-camera-closed")
  }
  func testNativeTVPhotosDemoGalleryAndPickerBoundary() {
    let app=launch("Settings",extra:["--face","Photos"])
    XCTAssertFalse(app.buttons["Choose Photos"].exists)
    select(app.buttons["photos.gallery"],in:app,maxMoves:80)
    XCTAssertTrue(app.otherElements["face.Photos"].waitForExistence(timeout:10))
    let caption=app.staticTexts["photo.index"]
    XCTAssertTrue(caption.label.contains("1 OF 2"))
    XCTAssertTrue(app.staticTexts["photo.layout.test"].label.contains("picture=true"))
    capture(app,"tv-photo-demo-gallery-first")
    select(app.buttons["photo.next"],in:app)
    XCTAssertTrue(caption.label.contains("2 OF 2"));capture(app,"tv-photo-demo-gallery-next")
    select(app.buttons["photo.next"],in:app)
    XCTAssertTrue(caption.label.contains("1 OF 2"))
    XCUIRemote.shared.press(.menu)
    XCTAssertTrue(app.buttons["all.apps"].waitForExistence(timeout:5))
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
