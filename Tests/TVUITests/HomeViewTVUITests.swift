import XCTest
import UIKit

final class HomeViewTVUITests:XCTestCase {
  func testNativeTVMockDeviceAdvertisedRangeAndStep() {
    let app=launch("Settings",extra:["--mock-control-case","stepped","blinds"])
    let value=app.staticTexts["adjuster.value.Mock blinds"]
    XCTAssertEqual(value.label,"80%")
    select(app.buttons["Increase Mock blinds"],in:app,maxMoves:80)
    XCTAssertEqual(value.label,"85%")
    let indicator=app.descendants(matching:.any)["adjuster.progress.Mock blinds"]
    XCTAssertTrue(indicator.exists);XCTAssertEqual(indicator.value as? String,"85%")
    XCTAssertTrue(app.staticTexts["home.control.status.blinds"].label.contains("Confirmed by device state"))
    capture(app,"tv-device-advertised-range-step-confirmed")
  }
  func testReadOnlyTVAccessibilityMenuInventory() {
    continueAfterFailure=false
    let settings=XCUIApplication(bundleIdentifier:"com.apple.TVSettings")
    settings.launch();XCTAssertTrue(settings.wait(for:.runningForeground,timeout:30))
    let category=settings.cells.matching(NSPredicate(format:"label == %@","Accessibility")).firstMatch
    select(category,in:settings,maxMoves:20)
    XCTAssertTrue(settings.navigationBars.staticTexts["Accessibility"].waitForExistence(timeout:10))
    capture(settings,"tv-ossettings-accessibility-top")
    func focus()->String {
      guard let e=settings.descendants(matching:.any).allElementsBoundByIndex.first(where:{$0.hasFocus}) else {return "NONE"}
      return e.identifier+" | "+e.label+" | "+(e.value as? String ?? "")+" | "+String(describing:e.frame)
    }
    XCTAssertNotEqual(focus(),"NONE")
    var trace:[[String:Any]]=[],stable=0,reachedEnd=false
    for step in 1...32 {
      let before=focus()
      // Focus movement only: no Select after opening the category.
      XCUIRemote.shared.press(.down)
      let after=focus();XCTAssertNotEqual(after,"NONE")
      trace.append(["step":step,"before":before,"after":after,"action":"down"])
      if step%6==0 {capture(settings,"tv-ossettings-accessibility-page-\(step)")}
      stable=before==after ? stable+1:0
      if stable>=2 {reachedEnd=true;break}
    }
    capture(settings,"tv-ossettings-accessibility-end")
    let data:[String:Any]=["trace":trace,"stable_end_observed":reachedEnd,"bound":32,"feature_activation_actions":0]
    let receipt=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    receipt.name="tv-ossettings-focus-only-inventory";receipt.lifetime = .keepAlways;add(receipt)
  }
  func testReadOnlyTVSystemSettingsRootInventory() {
    continueAfterFailure=false
    let settings=XCUIApplication(bundleIdentifier:"com.apple.TVSettings")
    settings.launch()
    XCTAssertTrue(settings.wait(for:.runningForeground,timeout:30))
    capture(settings,"tv-ossettings-root")
  }
  @MainActor func testNativeTVSourceCaptionsActualCuesOffAndSourceChange() {
    continueAfterFailure=false;executionTimeAllowance=240
    let app=launch("Podcasts",extra:["--podcast-fixture","--podcast-caption-fixture","--mute-podcast-fixture"])
    func act(_ id:String) {
      var e=app.buttons[id]
      if id == "podcast.captions.option.0" || id == "podcast.captions.off" {
        // Native tvOS exposes each exact SwiftUI action identifier on an
        // Other inside a focusable Cell, not on a Button. Bind to that owner.
        capture(app,"TV-caption-native-menu-"+(id.hasSuffix("off") ? "off":"track"))
        let rows=app.cells.containing(.other,identifier:id)
        XCTAssertEqual(rows.count,1,"Exactly one native row must own the requested action identifier")
        e=rows.element(boundBy:0)
      }
      if !e.waitForExistence(timeout:8) {capture(app,"TV-caption-target-missing")}
      XCTAssertTrue(e.exists)
      select(e,in:app,maxMoves:80,allowFocusedDescendant:id.hasPrefix("podcast.captions"))
    }
    act("podcast.feeds");act("podcast.feed.fixture");act("podcast.episode.0")
    let captions=app.buttons["podcast.captions"]
    XCTAssertTrue(captions.exists);XCTAssertFalse(captions.isEnabled)
    XCTAssertTrue(app.staticTexts["podcast.status"].label.contains("Paused"))
    act("podcast.play")
    expectation(for:NSPredicate(format:"enabled == true"),evaluatedWith:captions);waitForExpectations(timeout:12)
    act("podcast.captions");act("podcast.captions.option.0")
    let cue=app.staticTexts["podcast.captions.current"]
    expectation(for:NSPredicate(format:"exists == true AND label CONTAINS %@","first marker"),evaluatedWith:cue);waitForExpectations(timeout:12)
    act("podcast.play");XCTAssertEqual(app.staticTexts["podcast.status"].label,"Paused")
    select(cue,in:app,maxMoves:80,activate:false)
    XCTAssertTrue(app.otherElements["reference.viewport"].frame.intersection(app.scrollViews.firstMatch.frame).contains(cue.frame))
    capture(app,"TV-source-captions-first-cue")
    act("podcast.captions");act("podcast.captions.off")
    XCTAssertFalse(cue.exists);XCTAssertEqual(captions.value as? String,"off")
    act("podcast.captions");act("podcast.captions.option.0")
    for _ in 0..<3 {act("podcast.back")}
    XCTAssertTrue(app.staticTexts["podcast.position"].label.hasPrefix("0:00 /"))
    for _ in 0..<3 {act("podcast.forward")}
    XCTAssertTrue(app.staticTexts["podcast.position"].label.hasPrefix("0:45 /"))
    act("podcast.play")
    expectation(for:NSPredicate(format:"exists == true AND label CONTAINS %@","final marker"),evaluatedWith:cue);waitForExpectations(timeout:12)
    act("podcast.play");XCTAssertEqual(app.staticTexts["podcast.status"].label,"Paused")
    select(cue,in:app,maxMoves:80,activate:false)
    XCTAssertTrue(app.otherElements["reference.viewport"].frame.intersection(app.scrollViews.firstMatch.frame).contains(cue.frame))
    capture(app,"TV-source-captions-final-cue")
    act("podcast.feeds");act("podcast.episode.1");XCTAssertFalse(cue.exists)
    act("podcast.play")
    let status=app.staticTexts["podcast.captions.status"]
    expectation(for:NSPredicate(format:"label == %@","No captions supplied by this episode."),evaluatedWith:status);waitForExpectations(timeout:12)
    XCTAssertFalse(captions.isEnabled);XCTAssertFalse(cue.exists)
    XCTAssertTrue(app.otherElements["reference.viewport"].frame.contains(status.frame))
    capture(app,"TV-source-no-invented-captions")
    act("podcast.play");XCTAssertEqual(app.staticTexts["podcast.status"].label,"Paused")
  }
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
  private func select(_ target:XCUIElement,in app:XCUIApplication,maxMoves:Int=24,allowFocusedDescendant:Bool=false,activate:Bool=true) {
    func intendedFocus()->Bool {
      target.hasFocus || (allowFocusedDescendant && target.descendants(matching:.any).allElementsBoundByIndex.contains(where:{$0.hasFocus}))
    }
    XCTAssertTrue(target.waitForExistence(timeout:5))
    var trace:[String]=[]
    var attempted:[String:Set<Int>]=[:]
    for _ in 0..<maxMoves {
      if intendedFocus() { break }
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
    XCTAssertTrue(intendedFocus(),"Select must only activate the intended control or its actually owned focused descendant")
    if activate {XCUIRemote.shared.press(.select)}
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

@MainActor extension HomeViewTVUITests {
  private func mutedTVDemoArtwork(_ reduced:Bool)->XCUIApplication {
    let app=launch("Music",extra:["--animation-test"]+(reduced ? ["--reduce-motion"]:[]))
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    select(app.buttons["nav.controls"],in:app,maxMoves:80)
    let volume=app.staticTexts["adjuster.value.Demo audio"]
    XCTAssertTrue(volume.waitForExistence(timeout:5))
    let decrease=app.buttons["Decrease Demo audio"]
    select(decrease,in:app,maxMoves:100,activate:false)
    for _ in 0..<10 {
      if volume.label == "0%" {break}
      XCTAssertTrue(decrease.hasFocus)
      XCUIRemote.shared.press(.select)
    }
    XCTAssertEqual(volume.label,"0%","Only the own demo audio must be muted before explicit playback")
    capture(app,"tv-artwork-own-audio-zero")
    select(app.buttons["nav.apps"],in:app,maxMoves:100)
    select(app.buttons["all.apps"],in:app,maxMoves:100)
    select(app.buttons["app.Music"],in:app,maxMoves:100)
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    return app
  }
  private func tvArtworkPixels(_ app:XCUIApplication,_ name:String)->Data {
    let viewport=app.otherElements["reference.viewport"].frame
    let button=app.buttons["music.artwork.info.demo"].frame
    XCTAssertGreaterThan(viewport.width,0)
    // Native tvOS AX buttons include additional activation padding, so their
    // width is not the source72-point overlay width. This fixed viewport ROI
    // was qualified in the unchanged paused native baseline before product edits.
    let area=CGRect(x:viewport.minX+viewport.width*0.40,y:viewport.minY+viewport.height*0.23,
      width:viewport.width*0.20,height:viewport.height*0.15)
    let image=app.screenshot().image.cgImage!,scale=CGFloat(image.width)/app.frame.width
    let crop=CGRect(x:(area.minX-app.frame.minX)*scale,y:(area.minY-app.frame.minY)*scale,
      width:area.width*scale,height:area.height*scale).integral
    XCTAssertTrue(CGRect(x:0,y:0,width:image.width,height:image.height).contains(crop))
    let extracted=image.cropping(to:crop)!,width=extracted.width,height=extracted.height
    let shot=XCTAttachment(image:UIImage(cgImage:extracted));shot.name=name+"-fixed-cover-roi";shot.lifetime = .keepAlways;add(shot)
    let rect:(CGRect)->[Double]={[Double($0.minX),Double($0.minY),Double($0.width),Double($0.height)]}
    let geometry=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:["viewport":rect(viewport),
      "info":rect(button),"global_roi":rect(area),"pixel_roi":rect(crop),
      "scope":"Fixed own viewport x40–60%,y23–38% ROI qualified against unchanged native paused baseline before product edit. Native TV AX padding is not rendered cover geometry. Excludes DEMO/info/focus/player/progress; requalify actual final captures."],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    geometry.name=name+"-geometry";geometry.lifetime = .keepAlways;add(geometry)
    var data=Data(count:width*height*4)
    data.withUnsafeMutableBytes { bytes in
      let context=CGContext(data:bytes.baseAddress,width:width,height:height,bitsPerComponent:8,
        bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
      context.draw(extracted,in:CGRect(x:0,y:0,width:width,height:height))
    }
    return data
  }
  private func tvArtworkChanged(_ a:Data,_ b:Data)->Int {
    XCTAssertEqual(a.count,b.count);return zip(a,b).reduce(0){$0+($1.0 == $1.1 ? 0:1)}
  }
  private func settleTVArtwork(_ seconds:Double=0.8) {RunLoop.current.run(until:Date().addingTimeInterval(seconds))}
  func testNativeTVDemoArtworkActualRemoteMotionPauseAndBackground() {
    continueAfterFailure=false;executionTimeAllowance=300
    let app=mutedTVDemoArtwork(false),play=app.buttons["player.play"]
    select(play,in:app,maxMoves:100)
    expectation(for:NSPredicate(format:"label == %@","Pause"),evaluatedWith:play);waitForExpectations(timeout:10)
    settleTVArtwork(1.5)
    let first=tvArtworkPixels(app,"tv-artwork-moving-a");settleTVArtwork()
    let second=tvArtworkPixels(app,"tv-artwork-moving-b");settleTVArtwork()
    XCTAssertGreaterThan(tvArtworkChanged(first,second),100)
    XCTAssertGreaterThan(tvArtworkChanged(second,tvArtworkPixels(app,"tv-artwork-moving-c")),100)
    capture(app,"tv-artwork-playing-native")
    select(play,in:app,maxMoves:100);XCTAssertEqual(play.label,"Play");settleTVArtwork()
    let paused=tvArtworkPixels(app,"tv-artwork-explicit-pause-a");settleTVArtwork()
    XCTAssertEqual(tvArtworkChanged(paused,tvArtworkPixels(app,"tv-artwork-explicit-pause-b")),0)
    select(play,in:app,maxMoves:100)
    expectation(for:NSPredicate(format:"label == %@","Pause"),evaluatedWith:play);waitForExpectations(timeout:10)
    XCUIRemote.shared.press(.home)
    XCTAssertTrue(app.wait(for:.runningBackground,timeout:10) || app.state == .runningBackgroundSuspended)
    app.activate();XCTAssertTrue(play.waitForExistence(timeout:10));settleTVArtwork(1.5)
    let resumed=play.label == "Pause",returned=tvArtworkPixels(app,"tv-artwork-background-a");settleTVArtwork()
    let changes=tvArtworkChanged(returned,tvArtworkPixels(app,"tv-artwork-background-b"))
    if resumed {XCTAssertGreaterThan(changes,100);select(play,in:app,maxMoves:100)}
    else {XCTAssertEqual(changes,0)}
    XCTAssertEqual(play.label,"Play");capture(app,"tv-artwork-paused-native")
    let state=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:["audio_observed_continued_after_return":resumed,
      "scope":"Actual Home/background return; cover must follow existing observed demo audio state. No new background audio promise."],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    state.name="tv-artwork-background-audio-state";state.lifetime = .keepAlways;add(state)
  }
  func testNativeTVDemoArtworkReducedMotionKeepsPlayingStatic() {
    continueAfterFailure=false;executionTimeAllowance=240
    let app=mutedTVDemoArtwork(true),play=app.buttons["player.play"]
    select(play,in:app,maxMoves:100)
    expectation(for:NSPredicate(format:"label == %@","Pause"),evaluatedWith:play);waitForExpectations(timeout:10)
    settleTVArtwork(1.5)
    let first=tvArtworkPixels(app,"tv-artwork-reduced-a");settleTVArtwork()
    XCTAssertEqual(tvArtworkChanged(first,tvArtworkPixels(app,"tv-artwork-reduced-b")),0)
    capture(app,"tv-artwork-playing-reduced-native")
    select(play,in:app,maxMoves:100);XCTAssertEqual(play.label,"Play")
  }
}

@MainActor extension HomeViewTVUITests {
  func testNativeTVMatchedCloseFocusedPausedMusicReference() {
    continueAfterFailure=false
    let app=launch("Music",extra:["--animation-test"])
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    XCTAssertTrue(app.buttons["close"].hasFocus,"Match the original native baseline focus, not a different focused footer state")
    capture(app,"tv-music-matched-close-paused-reference")
    let rect:(CGRect)->[Double]={[Double($0.minX),Double($0.minY),Double($0.width),Double($0.height)]}
    var bounds:[String:[Double]]=["viewport":rect(app.otherElements["reference.viewport"].frame)]
    for id in ["nav.faces","nav.apps","nav.assistant","nav.controls"] {bounds[id]=rect(app.buttons[id].frame)}
    let data=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:bounds,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    data.name="tv-music-matched-reference-geometry";data.lifetime = .keepAlways;add(data)
  }
}
