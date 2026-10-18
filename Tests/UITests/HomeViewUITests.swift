import CoreGraphics
import UIKit
import XCTest

@MainActor
final class HomeViewUITests: XCTestCase {
  var app = XCUIApplication()
  override func setUp() {
    continueAfterFailure = false
  }
  func launch(_ extra: [String] = []) {
    app.launchArguments = ["--uitesting", "--reference-clock"] + extra
    app.launch()
    XCTAssertTrue(app.staticTexts["mock.badge"].waitForExistence(timeout: 15))
  }
  func tap(_ id: String) {
    let button = app.buttons[id]
    XCTAssertTrue(button.waitForExistence(timeout: 5), "Missing \(id)")
    button.tap()
  }
  func scrollPhotoControlFullyIntoView(_ element:XCUIElement) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    let scroll=app.scrollViews.firstMatch,viewport=app.otherElements["reference.viewport"]
    for _ in 0..<24 {
      let safe=scroll.frame.intersection(viewport.frame).insetBy(dx:0,dy:40)
      let target=element.frame
      if element.isHittable && safe.contains(target) { break }
      // Full flicks overshoot a short phone viewport and oscillate around the
      // target. Drag only the measured gap, then hold to stop scroll inertia.
      // Use the content gutter: a central drag can be captured by a Slider.
      let gap:CGFloat
      if target.isEmpty { gap=safe.height*0.6 }
      else if target.minY<safe.minY { gap = -(safe.minY-target.minY+14) }
      else { gap=target.maxY-safe.maxY+14 }
      let distance=min(max(abs(gap),24),safe.height*0.6)*(gap<0 ? -1:1)
      let start=app.coordinate(withNormalizedOffset:.zero).withOffset(
        CGVector(dx:safe.minX+15,dy:safe.midY+distance/2))
      let end=app.coordinate(withNormalizedOffset:.zero).withOffset(
        CGVector(dx:safe.minX+15,dy:safe.midY-distance/2))
      start.press(forDuration:0.1,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.2)
    }
    XCTAssertTrue(scroll.frame.intersection(viewport.frame).insetBy(dx:0,dy:40).contains(element.frame))
  }
  func openSyntheticAlbumChoices() {
    let load=app.buttons["photos.shared.load"]
    scrollPhotoControlFullyIntoView(load)
    load.tap()
    if app.buttons["device.unlock"].waitForExistence(timeout:2) {
      tap("device.unlock")
      scrollPhotoControlFullyIntoView(load)
      load.tap()
    }
    XCTAssertTrue(app.buttons["photos.shared.fixture"].waitForExistence(timeout:6))
  }
  func linkSyntheticAlbum(_ id:String = "fixture") {
    let menu=app.buttons["photos.shared."+id]
    scrollPhotoControlFullyIntoView(menu)
    menu.press(forDuration:1.0)
    let identified=app.buttons["photos.shared.link."+id]
    let action=identified.exists ? identified:app.buttons["Keep updated on this display"]
    XCTAssertTrue(action.waitForExistence(timeout:5))
    action.tap()
    XCTAssertTrue(app.otherElements["face.Photos"].waitForExistence(timeout:8))
  }
  func waitForPhotoMetadata(_ value:String) {
    let layout=app.staticTexts["photo.layout.test"]
    expectation(for:NSPredicate(format:"label CONTAINS %@",value),evaluatedWith:layout)
    waitForExpectations(timeout:10)
  }
  func albumSettings() { tap("nav.controls");tap("controls.settings") }
  func albumFixtureReport() -> String {
    let report=app.staticTexts["photos.shared.fixture.report"]
    scrollPhotoControlFullyIntoView(report)
    return report.label
  }
  func shot(_ name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
  func drawer() {
    tap("nav.apps")
    tap("all.apps")
  }
  func testPersonalHomeUsesObservedFourAppArrangementAndNativeMarks() {
    launch()
    tap("nav.apps")
    let facetime=app.buttons["app.FaceTime"],home=app.buttons["app.Home"]
    let music=app.buttons["app.Music"],messages=app.buttons["app.Messages"]
    for button in [facetime,home,music,messages] { XCTAssertTrue(button.isHittable) }
    // Accessibility bounds can include a wider symbol/label. The observed grid
    // aligns column CENTERS, not the left ink edge of differently shaped marks.
    XCTAssertLessThan(facetime.frame.midX,home.frame.midX)
    XCTAssertEqual(facetime.frame.minY,home.frame.minY,accuracy:2)
    XCTAssertEqual(music.frame.midX,facetime.frame.midX,accuracy:2)
    XCTAssertEqual(messages.frame.midX,home.frame.midX,accuracy:2)
    XCTAssertGreaterThan(music.frame.minY,facetime.frame.maxY)
    let photo=app.buttons["personal.photos.open"]
    XCTAssertTrue(photo.isHittable)
    XCTAssertEqual(photo.label,"Photos")
    shot("personal-observed-favorites-and-icons")
    tap("all.apps")
    XCTAssertTrue(app.buttons["app.Calendar"].isHittable)
    shot("apps-native-marks-first-rows")
    app.scrollViews.firstMatch.swipeUp()
    shot("apps-native-marks-lower-rows")
  }
  func testPersonalMediaLayoutPersistsOnlyForItsProfile() {
    let id=UUID().uuidString
    launch(["--persistence-test",id,"--reset-test-store","--face","Home Modular Clock"])
    tap("nav.apps")
    app.buttons["personal.profile"].tap();tap("profile.Alex")
    app.buttons["personal.profile"].press(forDuration:1)
    tap("personal.edit");tap("personal.layout.media");tap("personal.editor.done")
    XCTAssertTrue(app.scrollViews["personal.media.layout"].waitForExistence(timeout:5))
    XCTAssertTrue(app.buttons["personal.podcast.play"].exists)
    XCTAssertTrue(app.buttons["app.Calendar"].exists)
    let artist=app.staticTexts["personal.music.artist"]
    XCTAssertTrue(artist.exists)
    XCTAssertEqual(artist.label,"Demo Artist")
    XCTAssertTrue(app.scrollViews["personal.media.layout"].frame.contains(artist.frame),
      "The full artist line must be visible without scrolling")
    shot("personal-ui42-media-layout-alex")
    app.terminate()
    launch(["--persistence-test",id])
    tap("nav.apps");app.buttons["personal.profile"].tap();tap("profile.Alex")
    XCTAssertTrue(app.scrollViews["personal.media.layout"].waitForExistence(timeout:5))
    app.buttons["personal.profile"].tap();tap("profile.Jamie")
    XCTAssertTrue(app.otherElements["personal.photos.layout"].waitForExistence(timeout:5))
    XCTAssertFalse(app.scrollViews["personal.media.layout"].exists)
    XCTAssertTrue(app.buttons["app.Home"].exists)
    shot("personal-ui16-other-profile-unchanged")
    app.buttons["personal.profile"].tap();tap("profile.guest")
    XCTAssertFalse(app.buttons["personal.edit"].exists)
    XCTAssertTrue(app.otherElements["personal.photos.layout"].exists)
  }
  func testPersonalMediaWidgetUsesExplicitDemoPlaybackAndNavigation() {
    launch()
    tap("nav.apps");app.buttons["personal.profile"].tap();tap("profile.Alex")
    app.buttons["personal.profile"].press(forDuration:1)
    tap("personal.edit");tap("personal.layout.media");tap("personal.editor.done")
    XCTAssertTrue(app.staticTexts["Demo episode"].exists)
    tap("personal.podcast.play")
    let play=app.buttons["personal.podcast.play"]
    expectation(for:NSPredicate(format:"label CONTAINS %@","Pause"),evaluatedWith:play)
    waitForExpectations(timeout:8)
    shot("personal-podcast-widget-playing")
    tap("personal.podcast.play")
    tap("personal.podcast.open")
    XCTAssertTrue(app.buttons["podcast.play"].waitForExistence(timeout:5))
  }
  func testPersonalWeatherGridScrollKeepsSourceLayoutAndOpensWeather() {
    launch(["--face","Home Camera"])
    tap("nav.apps");app.buttons["personal.profile"].tap();tap("profile.Alex")
    app.buttons["personal.profile"].press(forDuration:1)
    tap("personal.edit");tap("personal.layout.weather");tap("personal.editor.done")
    let grid=app.scrollViews["personal.weather.layout"]
    XCTAssertTrue(grid.waitForExistence(timeout:5))
    XCTAssertTrue(app.buttons["app.Music"].exists)
    XCTAssertTrue(app.buttons["app.Podcasts"].exists)
    XCTAssertTrue(app.buttons["app.Safari"].exists)
    XCTAssertTrue(app.buttons["app.FaceTime"].exists)
    XCTAssertEqual(app.staticTexts["personal.weather.temperature"].label,"54°")
    XCTAssertTrue(app.staticTexts["personal.weather.source"].label.hasPrefix("Demo"))
    viewportShot("personal-ui41-weather-grid-top")
    grid.swipeUp()
    XCTAssertTrue(grid.exists,"Scrolling content must not switch to the global app drawer")
    XCTAssertTrue(app.buttons["app.World Clock"].exists)
    viewportShot("personal-ui41-weather-grid-scrolled")
    grid.swipeDown()
    tap("personal.weather.open")
    XCTAssertTrue(app.staticTexts["weather.app.city"].waitForExistence(timeout:5))
  }
  func testViewportEdgeGesturesOpenTheirActualDestinations() {
    launch(["--face","Home Camera"])
    func drag(_ x:Double,_ y:Double,_ endX:Double,_ endY:Double) {
      let frame=app.otherElements["reference.viewport"].frame
      let origin=app.coordinate(withNormalizedOffset:.zero)
      origin.withOffset(CGVector(dx:frame.minX+frame.width*x,dy:frame.minY+frame.height*y))
        .press(forDuration:0.1,thenDragTo:origin.withOffset(CGVector(dx:frame.minX+frame.width*endX,dy:frame.minY+frame.height*endY)))
    }
    drag(0.5,0.985,0.5,0.3)
    viewportShot("gesture-bottom-opens-personal")
    XCTAssertTrue(app.otherElements["personal.photos.layout"].waitForExistence(timeout:5))
    tap("nav.faces")
    drag(0.4,0.06,0.4,0.5)
    viewportShot("gesture-top-left-opens-assistant")
    XCTAssertTrue(app.textFields["assistant.input"].waitForExistence(timeout:5))
    tap("nav.faces")
    drag(0.85,0.06,0.85,0.5)
    XCTAssertTrue(app.buttons["controls.night"].waitForExistence(timeout:5))
    tap("nav.faces")
    drag(0.85,0.5,0.15,0.5)
    XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
  }
  func testPersonalWeatherWidgetDoesNotInventUnavailableData() {
    launch(["--page","Settings","--weather-fail"])
    let connect=app.buttons["connect.Weather"]
    for _ in 0..<18 where !connect.isHittable { app.scrollViews.firstMatch.swipeUp() }
    connect.tap()
    expectation(for:NSPredicate(format:"label CONTAINS %@","Weather unavailable"),evaluatedWith:app.staticTexts["connection.status.Weather"])
    waitForExpectations(timeout:5)
    tap("nav.faces");tap("nav.apps")
    app.buttons["personal.profile"].tap();tap("profile.Alex")
    app.buttons["personal.profile"].press(forDuration:1)
    tap("personal.edit");tap("personal.layout.weather");tap("personal.editor.done")
    XCTAssertEqual(app.staticTexts["personal.weather.temperature"].label,"—")
    XCTAssertTrue(app.staticTexts["personal.weather.source"].label.contains("unavailable"))
    viewportShot("personal-weather-widget-unavailable-no-demo")
  }

  func testThermostatWritesAndScenePropagatesToDetail() {
    launch()
    tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "68°")
    tap("thermostat.up")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "69°")
    tap("thermostat.down")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "68°")
    shot("UI33-thermostat")
    tap("nav.faces")
    tap("scene.goodnight")
    tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "66°")
  }
  func testHomeGlassControlsRemainInteractive() {
    launch(["--face", "Home Modular"])
    shot("prism-home-modular-reference")
    let thermostat=app.buttons["home.thermostat"]
    XCTAssertTrue(thermostat.waitForExistence(timeout:5))
    let frame=thermostat.frame
    XCTAssertTrue(app.otherElements["reference.viewport"].frame.contains(frame))
    // XCTest's AX isHittable report is false even on the baseline.
    // Send a real screen touch instead of relying on that AX report,
    // then require the actual destination and resulting control values.
    app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:frame.midX,dy:frame.midY)).tap()
    XCTAssertTrue(app.staticTexts["thermostat.value"].waitForExistence(timeout:5))
    tap("thermostat.up")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "69°")
    tap("nav.faces")
    tap("scene.goodnight")
    tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "66°")
  }
  func testHomePrismMotionStopsWithReduceMotion() {
    launch(["--face","Home Modular","--animation-test"])
    let moving=viewportPixels(viewportBytes("home-prism-moving-start"))
    Thread.sleep(forTimeInterval:1.5)
    XCTAssertNotEqual(moving,viewportPixels(viewportBytes("home-prism-moving-later")))
    app.terminate()
    launch(["--face","Home Modular","--animation-test","--reduce-motion"])
    let frozen=viewportPixels(viewportBytes("home-prism-reduced-start"))
    Thread.sleep(forTimeInterval:1.5)
    XCTAssertEqual(frozen,viewportPixels(viewportBytes("home-prism-reduced-later")))
  }
  func testHomePrismNightHasNoBlueGlassLeak() {
    launch(["--face","Home Modular"])
    tap("nav.controls");tap("controls.night");tap("nav.faces")
    let pixels=viewportPixels(viewportBytes("home-prism-night"))
    var lit=0,wrongColor=0
    for i in stride(from:0,to:pixels.count,by:4) where pixels[i]>25 {
      lit+=1
      if Double(pixels[i+1])>Double(pixels[i])*0.4 || Double(pixels[i+2])>Double(pixels[i])*0.4 { wrongColor+=1 }
    }
    XCTAssertGreaterThan(lit,100)
    XCTAssertEqual(wrongColor,0,"Native glass must respect the monochrome night treatment")
  }
  private func viewportPixels(_ png:Data,inset:Double=0.1) -> Data {
    let image=UIImage(data:png)!.cgImage!
    // Prism motion samples the inner 80%; camera night checks the whole viewport,
    // including root-owned banners and toasts. Host chrome is never in this PNG.
    let crop=image.cropping(to:CGRect(x:Double(image.width)*inset,y:Double(image.height)*inset,
      width:Double(image.width)*(1-2*inset),height:Double(image.height)*(1-2*inset)).integral)!
    var bytes=[UInt8](repeating:0,count:crop.width*crop.height*4)
    bytes.withUnsafeMutableBytes {
      let context=CGContext(data:$0.baseAddress,width:crop.width,height:crop.height,
        bitsPerComponent:8,bytesPerRow:crop.width*4,space:CGColorSpaceCreateDeviceRGB(),
        bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
      context.draw(crop,in:CGRect(x:0,y:0,width:crop.width,height:crop.height))
    }
    return Data(bytes)
  }
  func testOfflineWriteFailsWithoutChangingTemperature() {
    launch()
    tap("nav.controls")
    tap("controls.online")
    tap("nav.faces")
    tap("home.thermostat")
    tap("thermostat.up")
    XCTAssertTrue(
      app.alerts.staticTexts["The mock home is offline. No changes were made."].waitForExistence(
        timeout: 3))
    app.alerts.buttons["OK"].tap()
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "68°")
    shot("offline-error-state")
  }
  func testGuestPersonalContentGateAndMockLockAuthentication() {
    launch()
    drawer()
    tap("app.Calendar")
    XCTAssertTrue(app.staticTexts["Recognizing…"].waitForExistence(timeout: 3))
    shot("UI31-profile-gate")
    tap("profile.Alex")
    XCTAssertTrue(app.staticTexts["Morning walk"].waitForExistence(timeout: 3))
    tap("nav.apps")
    tap("all.apps")
    tap("app.Home")
    tap("grid.lock")
    XCTAssertEqual(app.staticTexts["lock.state"].label, "Locked")
    tap("lock.action")
    XCTAssertEqual(app.staticTexts["lock.state"].label, "Unlocked")
  }
  func testRecipeIngredientsCookingAndInlineTimer() {
    launch(["--screen-recipe"])
    shot("UI15-recipe-cover")
    tap("recipe.ingredients")
    tap("ingredient.0")
    tap("close")
    tap("nav.faces")
    drawer()
    app.swipeUp()
    tap("app.Recipes")
    tap("recipe.start")
    XCTAssertTrue(app.staticTexts["cooking.text"].label.contains("olive oil"))
    tap("cooking.timer")
    tap("cooking.next")
    XCTAssertTrue(app.staticTexts["cooking.text"].label.contains("squash"))
    shot("UI25-cooking-step")
    tap("cooking.next")
    tap("cooking.next")
    XCTAssertTrue(app.buttons["recipe.start"].waitForExistence(timeout: 3))
    tap("nav.faces")
    drawer()
    tap("app.Timers")
    XCTAssertTrue(app.staticTexts["timer.countdown"].waitForExistence(timeout: 3))
  }
  func testTimerPauseResumeAndDelete() {
    launch(["--page", "Timers"])
    tap("timer.start")
    tap("timer.pause")
    let paused = app.staticTexts["timer.countdown"].label
    XCTAssertTrue(app.buttons["Resume timer"].exists)
    tap("timer.pause")
    XCTAssertTrue(app.buttons["Pause timer"].exists)
    XCTAssertFalse(paused.isEmpty)
    shot("UI14-timer")
    tap("timer.delete")
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout: 3))
  }
  func testLocalAssistantActuallyMutatesMockHome() {
    launch()
    tap("nav.assistant")
    let field = app.textFields["assistant.input"]
    field.tap()
    field.typeText("temperature 72")
    tap("assistant.send")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("72"))
    tap("nav.faces")
    tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "72°")
  }
  func testFaceEditorChangesFaceAndWidget() {
    launch(["--face", "Modular"])
    shot("UI01-modular")
    app.otherElements["face.Modular"].press(forDuration: 1)
    XCTAssertTrue(app.buttons["editor.done"].waitForExistence(timeout: 3))
    tap("widget.0")
    tap("complication.choose.Clock")
    tap("select.Modular")
    tap("editor.done")
    XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout: 3))
  }

  func testWatchModularPickerEnforcesSmallFamilyAndKeepsOtherFace() {
    launch(["--face", "Watch Modular"])
    shot("RE-watch-modular")
    app.otherElements["face.Watch Modular"].press(forDuration: 1)
    tap("widget.0")
    XCTAssertFalse(app.buttons["complication.choose.Calendar"].exists)
    tap("complication.choose.Weather")
    tap("Mint style")
    XCTAssertEqual(app.buttons["Mint style"].value as? String, "Selected")
    shot("RE-complication-editor")
    tap("editor.done")
    XCTAssertTrue(app.buttons["complication.slot.topLeft"].label.contains("Weather"))
    app.otherElements["face.Watch Modular"].press(forDuration: 1)
    tap("select.Modular")
    tap("editor.done")
    XCTAssertTrue(app.otherElements["face.Modular"].exists)
    XCTAssertTrue(app.staticTexts["Wed Apr"].exists)
  }
  func testSpatialEditorFiltersInlineSlotAndRestoresAfterRelaunch() {
    let id = UUID().uuidString
    launch(["--persistence-test", id, "--reset-test-store", "--face", "Infograph Modular"])
    XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "complication.slot.")).count, 6)
    shot("Editor-infograph-six-slots")
    app.otherElements["face.Infograph Modular"].press(forDuration: 1)
    tap("preview.slot.date")
    XCTAssertFalse(app.buttons["complication.choose.Music"].exists)
    XCTAssertFalse(app.buttons["complication.choose.Weather"].exists)
    tap("complication.choose.Off")
    XCTAssertTrue(app.buttons["preview.slot.date"].label.contains("Off"))
    shot("Editor-spatial-empty-slot")
    tap("preview.slot.date")
    tap("complication.choose.Clock")
    tap("editor.done")
    app.terminate()
    launch(["--persistence-test", id])
    XCTAssertTrue(app.otherElements["face.Infograph Modular"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.buttons["complication.slot.date"].label.contains("Clock"))
    tap("complication.slot.date")
    XCTAssertTrue(app.staticTexts["World Clock"].waitForExistence(timeout: 3))
    app.terminate()
    launch(["--persistence-test", id, "--reset-test-store"])
  }
  func testDuoAndCompactUseIndependentSlotsAndNavigableContent() {
    launch(["--face", "Modular Duo"])
    XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "complication.slot.")).count, 3)
    shot("Editor-duo-three-slots")
    app.otherElements["face.Modular Duo"].press(forDuration: 1)
    tap("preview.slot.topLeft")
    XCTAssertFalse(app.buttons["complication.choose.Calendar"].exists)
    tap("complication.choose.Timer")
    tap("preview.slot.center")
    tap("complication.choose.Music")
    tap("editor.done")
    XCTAssertTrue(app.buttons["complication.slot.center"].label.contains("Music"))
    tap("complication.slot.center")
    XCTAssertTrue(app.buttons["player.play"].waitForExistence(timeout: 3))
    launch(["--face", "Modular Compact"])
    XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "complication.slot.")).count, 3)
    XCTAssertTrue(app.buttons["complication.slot.center"].label.contains("Date"))
    shot("Editor-compact-three-slots")
    app.otherElements["face.Modular Compact"].press(forDuration: 1)
    tap("preview.slot.bottom")
    XCTAssertTrue(app.buttons["complication.choose.Calendar"].exists)
    tap("complication.choose.Weather")
    tap("editor.done")
    XCTAssertTrue(app.buttons["complication.slot.bottom"].label.contains("Weather"))
  }
  func flowAtlasHasInkInEveryCell(_ png: Data) -> Bool {
    let image = UIImage(data: png)!.cgImage!
    for row in 0..<2 { for col in 0..<5 {
      let scale = Double(image.width) / 600
      let rect = CGRect(x: Double(55 + col * 102) * scale,
                        y: Double(96 + row * 218) * scale,
                        width: 82 * scale, height: 190 * scale).integral
      guard let cell = image.cropping(to: rect) else { return false }
      var bytes = [UInt8](repeating: 0, count: cell.width * cell.height * 4)
      bytes.withUnsafeMutableBytes { buffer in
        let context = CGContext(data: buffer.baseAddress, width: cell.width, height: cell.height,
          bitsPerComponent: 8, bytesPerRow: cell.width * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
        context.draw(cell, in: CGRect(x: 0, y: 0, width: cell.width, height: cell.height))
      }
      let ink = stride(from: 0, to: bytes.count, by: 4).filter { bytes[$0] > 180 }.count
      if Double(ink) / Double(cell.width * cell.height) < 0.015 { return false }
    } }
    return true
  }
  func testFlowOwnGlyphAtlasCoversBothStylesAndAxisExtremes() {
    for stencil in [false, true] {
      for wide in [false, true] {
        var args = ["--face", "Flow", "--flow-glyph-atlas"]
        if stencil { args.append("--flow-atlas-stencil") }
        if wide { args.append("--flow-atlas-wide") }
        launch(args)
        let name = "flow-own-atlas-\(stencil ? "stencil" : "solid")-\(wide ? "wide-heavy" : "narrow-light")"
        var visible = false
        for _ in 0..<8 {
          if flowAtlasHasInkInEveryCell(viewportBytes(name)) { visible = true; break }
          Thread.sleep(forTimeInterval: 0.25)
        }
        XCTAssertTrue(visible, "Every digit must actually render, not merely exist in accessibility")
        for digit in 0...9 {
          XCTAssertTrue(app.otherElements["Digit \(digit)"].exists,
                        "Missing glyph \(digit)")
        }
        app.terminate()
      }
    }
  }
  func testWorldClockAddsFractionalZoneAndPersistsRemoval() {
    let id = UUID().uuidString
    launch(["--page", "World Clock", "--persistence-test", id, "--reset-test-store"])
    tap("world.add")
    let search = app.textFields["world.search"]
    search.tap(); search.typeText("Kathmandu")
    tap("world.choose.Asia/Kathmandu")
    app.swipeUp()
    shot("world-after-selection")
    print(app.debugDescription)
    XCTAssertTrue(app.staticTexts["world.time.Asia/Kathmandu"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["world.time.Asia/Kathmandu"].label.contains("3:54") || app.staticTexts["world.time.Asia/Kathmandu"].label.contains("15:54"))
    shot("world-kathmandu-fractional-zone")
    app.terminate()
    launch(["--page", "World Clock", "--persistence-test", id])
    app.swipeUp()
    tap("world.remove.Asia/Kathmandu")
    app.terminate()
    launch(["--page", "World Clock", "--persistence-test", id])
    app.swipeUp()
    XCTAssertFalse(app.buttons["world.remove.Asia/Kathmandu"].exists)
    app.terminate()
    launch(["--page", "World Clock", "--persistence-test", id, "--reset-test-store"])
  }
  func testBrowserRejectsInsecureAddressAndPageCannotOpenExternalScheme() {
    launch(["--page", "Safari", "--browser-policy-fixture"])
    XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 8))
    let blocked = app.links["Blocked scheme fixture"]
    for _ in 0..<4 where !blocked.isHittable { app.webViews.firstMatch.swipeUp() }
    XCTAssertTrue(blocked.waitForExistence(timeout: 5))
    blocked.tap()
    XCTAssertTrue(app.staticTexts["browser.status"].label.contains("Blocked"))
    let address = app.textFields["browser.address"]
    address.tap()
    if let value = address.value as? String {
      address.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
    }
    address.typeText("http://example.invalid")
    tap("browser.load")
    XCTAssertTrue(app.staticTexts["browser.status"].label.contains("HTTPS"))
    XCTAssertFalse(app.buttons["browser.stop"].exists)
    shot("browser-insecure-address-rejected")
  }
  func testBrowserLocalHistoryOfflineAndStopDoNotNeedNetwork() {
    launch(["--page", "Safari", "--browser-navigation-fixture"])
    XCTAssertTrue(app.webViews.staticTexts["First local page"].waitForExistence(timeout: 8))
    app.links["Next page"].tap()
    XCTAssertTrue(app.webViews.staticTexts["Second local page"].waitForExistence(timeout: 5))
    tap("browser.back")
    XCTAssertTrue(app.webViews.staticTexts["First local page"].waitForExistence(timeout: 5))
    tap("browser.forward")
    XCTAssertTrue(app.webViews.staticTexts["Second local page"].waitForExistence(timeout: 5))
    app.links["Offline page"].tap()
    expectation(for: NSPredicate(format: "label CONTAINS %@", "Could not load"),
      evaluatedWith: app.staticTexts["browser.status"])
    waitForExpectations(timeout: 5)
    XCTAssertFalse(app.buttons["browser.stop"].exists)
    app.links["Slow page"].tap()
    tap("browser.stop")
    XCTAssertEqual(app.staticTexts["browser.status"].label, "Loading stopped.")
    XCTAssertFalse(app.buttons["browser.stop"].exists)
    shot("browser-local-history-offline-and-stop")
  }
  func submitAssistant(_ request: String) {
    tap("nav.assistant")
    let field = app.textFields["assistant.input"]
    field.tap(); field.typeText(request); tap("assistant.send")
  }
  func testBilingualTimerCommandUsesSecondsAndAmbiguityDoesNotAddTimer() {
    launch()
    submitAssistant("Timer auf 90 Sekunden namens Tee")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("90 seconds"))
    tap("nav.faces"); drawer(); tap("app.Timers")
    XCTAssertTrue(app.staticTexts["TEE"].exists)
    XCTAssertTrue(app.staticTexts["timer.countdown"].label.hasPrefix("01:")
      || app.staticTexts["timer.countdown"].label.hasPrefix("00:"))
    tap("timer.pause")
    submitAssistant("set a timer")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("Specify"))
    tap("nav.faces"); drawer(); tap("app.Timers")
    tap("timer.delete")
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout: 5))
    shot("voice-timer-ambiguity-no-extra-timer")
  }
  func testCookingStepCommandsPreserveAnExplicitCookingSession() {
    launch(["--screen-recipe"])
    tap("recipe.start")
    XCTAssertTrue(app.staticTexts["cooking.text"].label.contains("olive oil"))
    submitAssistant("next step")
    XCTAssertTrue(app.staticTexts["cooking.text"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["cooking.text"].label.contains("squash"))
    submitAssistant("vorheriger schritt")
    XCTAssertTrue(app.staticTexts["cooking.text"].label.contains("olive oil"))
    submitAssistant("repeat this step")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("olive oil"))
    shot("voice-cooking-repeat-step")
  }
  func testFlowHasIndependentTypefaceAndBackgroundControls() {
    launch(["--face", "Flow"])
    shot("RE-flow-stencil")
    app.otherElements["face.Flow"].press(forDuration: 1)
    tap("flow.typeface.1")
    let background = app.switches["flow.background"]
    XCTAssertTrue(background.exists)
    background.tap()
    tap("editor.done")
    shot("RE-flow-numerals-only")
    app.otherElements["face.Flow"].press(forDuration: 1)
    XCTAssertEqual(app.switches["flow.background"].value as? String, "0")
    tap("editor.done")
  }
  func testCameraGridDetailAndTalkbackAreLocal() {
    launch(["--page", "Cameras"])
    viewportShot("camera-demo-four-stills")
    tap("camera.0")
    XCTAssertEqual(app.descendants(matching:.any)["camera.demo.status"].label,"Demo still")
    XCTAssertEqual(app.staticTexts["camera.time"].label,"10:09")
    viewportShot("camera-demo-front-door-still")
    shot("UI34-camera-detail")
    tap("camera.talk")
    XCTAssertTrue(
      app.staticTexts["Mock talkback active · No microphone used"].waitForExistence(timeout: 3))
    tap("camera.grid")
    XCTAssertTrue(app.buttons["camera.0"].waitForExistence(timeout: 3))
    tap("camera.grid.size")
    XCTAssertTrue(app.buttons["camera.8"].exists)
    viewportShot("camera-demo-nine-stills")
    tap("camera.2")
    XCTAssertEqual(app.descendants(matching:.any)["camera.demo.status"].label,"Demo still")
    viewportShot("camera-demo-living-room-still")
  }
  func testCameraDemoNightAndOfflineNeverBecomeLive() {
    launch(["--face","Home Camera"])
    viewportShot("camera-demo-face-four-stills")
    tap("nav.controls");tap("controls.night");tap("controls.online");tap("nav.faces")
    tap("camera.0")
    XCTAssertEqual(app.descendants(matching:.any)["camera.demo.status"].label,"Offline · Demo still")
    XCTAssertTrue(app.staticTexts["Mock camera unavailable"].exists)
    let pixels=viewportPixels(viewportBytes("camera-demo-night-offline"),inset:0)
    var lit=0,wrongColor=0
    for i in stride(from:0,to:pixels.count,by:4) where pixels[i]>25 {
      lit+=1
      if Double(pixels[i+1])>Double(pixels[i])*0.4 || Double(pixels[i+2])>Double(pixels[i])*0.4 { wrongColor+=1 }
    }
    XCTAssertGreaterThan(lit,100)
    XCTAssertEqual(wrongColor,0,"Generated stills must respect the same monochrome night treatment")
  }
  func testCallAcceptAndEndWithoutNetwork() {
    launch(["--page", "FaceTime"])
    tap("facetime.simulate")
    shot("UI27-incoming-demo-call")
    tap("call.accept")
    XCTAssertTrue(
      app.staticTexts["Local call simulation · No connection"].waitForExistence(timeout: 3))
    tap("call.end")
    XCTAssertTrue(app.buttons["all.apps"].waitForExistence(timeout: 3))
  }
  func testMusicPlaybackAndTrackNavigation() {
    launch(["--page", "Music"])
    tap("player.play")
    expectation(
      for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: app.buttons["player.play"])
    waitForExpectations(timeout: 8)
    tap("player.next")
    XCTAssertTrue(app.staticTexts["A Little Sunshine"].exists)
    shot("UI22-music")
    tap("player.play")
    XCTAssertEqual(app.buttons["player.play"].label, "Play")
  }
  func testRemindersCreateAndComplete() {
    launch()
    drawer()
    tap("app.Reminders")
    tap("profile.Alex")
    let field = app.textFields["reminder.input"]
    field.tap()
    field.typeText("Test groceries")
    tap("reminder.add")
    tap("reminder.Test groceries")
    XCTAssertTrue(app.buttons["reminder.Test groceries"].exists)
  }
  func testReferenceFacesAndHomeGridRender() {
    for name in ["Home Modular", "Weather", "Calendar", "Flow", "Photos"] {
      launch(["--face", name])
      shot("face-\(name)")
      app.terminate()
    }
    launch(["--page", "Home"])
    XCTAssertTrue(app.buttons["grid.entrylight"].exists)
    viewportShot("home-grid-clock-reference")
    tap("grid.entrylight")
    shot("UI13-home-grid")
    tap("grid.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
    tap("thermostat.up")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"69°")
    launch(["--page","Home"])
    tap("grid.camera")
    XCTAssertTrue(app.staticTexts["Living Room"].exists)
    XCTAssertEqual(app.descendants(matching:.any)["camera.demo.status"].label,"Demo still")
  }
  func testNativeSystemAlarmSchedulesAndCancelsOnSimulator() {
    launch(["--page", "Settings"])
    let native = app.buttons["native.alarm"]
    for _ in 0..<8 where !native.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(native.exists)
    addUIInterruptionMonitor(withDescription: "Alarm permission") { alert in
      for title in ["Allow", "OK"] where alert.buttons[title].exists {
        alert.buttons[title].tap()
        return true
      }
      return false
    }
    native.tap()
    let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    if springboard.alerts.firstMatch.waitForExistence(timeout: 4) {
      let allow = springboard.alerts.buttons["Allow"]
      if allow.exists { allow.tap() }
    }
    let cancel = app.buttons["Cancel system test alarm"]
    XCTAssertTrue(
      cancel.waitForExistence(timeout: 15),
      "AlarmKit must actually schedule, not report a mocked success")
    shot("native-AlarmKit-scheduled")
    cancel.tap()
    XCTAssertTrue(app.staticTexts["System test alarm cancelled."].waitForExistence(timeout: 5))
  }
  func testPersonalReminderDoesNotLeakToAnotherProfile() {
    launch()
    drawer()
    tap("app.Reminders")
    tap("profile.Alex")
    let field = app.textFields["reminder.input"]
    field.tap()
    field.typeText("Alex private test")
    tap("reminder.add")
    tap("nav.faces")
    tap("nav.apps")
    app.buttons["Choose profile"].tap()
    tap("profile.Jamie")
    tap("all.apps")
    tap("app.Reminders")
    XCTAssertFalse(app.buttons["reminder.Alex private test"].exists)
  }
  func testLandscapeAndReturnToPortrait() {
    launch()
    XCUIDevice.shared.orientation = .landscapeLeft
    XCTAssertTrue(app.buttons["home.thermostat"].waitForExistence(timeout: 5))
    shot("iPad-landscape-home")
    XCUIDevice.shared.orientation = .portrait
    XCTAssertTrue(app.buttons["home.thermostat"].waitForExistence(timeout: 5))
  }

  func testNativeRegularTimerPauseResumeAndCancel() {
    launch(["--page", "Timers", "--system-alarms"])
    addUIInterruptionMonitor(withDescription: "System alarm permission") { alert in
      if alert.buttons["Allow"].exists {
        alert.buttons["Allow"].tap()
        return true
      }
      return false
    }
    tap("timer.start")
    let os = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    if os.alerts.firstMatch.waitForExistence(timeout: 2), os.alerts.buttons["Allow"].exists {
      os.alerts.buttons["Allow"].tap()
    }
    let status = app.staticTexts["timer.systemStatus"]
    let enabled = NSPredicate(format: "label == %@", "System alert enabled")
    expectation(for: enabled, evaluatedWith: status)
    waitForExpectations(timeout: 15)
    tap("timer.pause")
    XCTAssertTrue(app.buttons["Resume timer"].exists)
    tap("timer.pause")
    XCTAssertTrue(app.buttons["Pause timer"].exists)
    tap("timer.delete")
    XCTAssertTrue(app.buttons["timer.start"].exists)
    XCTAssertFalse(app.alerts.firstMatch.exists)
  }
  func testNativeAlarmDeliversWhileAppIsInBackground() {
    launch(["--page", "Settings", "--alarm-test-seconds", "8"])
    let button = app.buttons["native.alarm"]
    for _ in 0..<8 where !button.isHittable { app.scrollViews.firstMatch.swipeUp() }
    button.tap()
    let os = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    if os.alerts.firstMatch.waitForExistence(timeout: 2), os.alerts.buttons["Allow"].exists {
      os.alerts.buttons["Allow"].tap()
    }
    XCTAssertTrue(app.buttons["Cancel system test alarm"].waitForExistence(timeout: 12))
    XCUIDevice.shared.press(.home)
    XCTAssertTrue(
      os.staticTexts["HomeView test timer"].waitForExistence(timeout: 20),
      "The OS must deliver the actual own-app alarm while HomeView is backgrounded")
    let screenshot = XCTAttachment(screenshot: os.screenshot())
    screenshot.name = "AlarmKit-background-delivery"
    screenshot.lifetime = .keepAlways
    add(screenshot)
    if os.buttons["Stop"].exists { os.buttons["Stop"].tap() }
    app.activate()
    if app.buttons["Cancel system test alarm"].exists {
      app.buttons["Cancel system test alarm"].tap()
    }
  }

  func testNativeDemoPhotoSelectionWithoutOpeningPhotoLibrary() {
    launch(["--page", "Settings"])
    let button = app.buttons["photos.demo"]
    scrollPhotoControlFullyIntoView(button)
    button.tap()
    XCTAssertTrue(app.otherElements["face.Photos"].waitForExistence(timeout: 8))
    XCTAssertTrue(app.staticTexts["PHOTOS"].exists)
    expectation(for:NSPredicate(format:"label CONTAINS %@","finished=true"),evaluatedWith:app.staticTexts["photo.layout.test"])
    waitForExpectations(timeout:20)
    let summary=app.staticTexts["photo.layout.test"].label
    let fields=Dictionary(uniqueKeysWithValues:summary.split(separator:";").map {
      let pair=$0.split(separator:"=",maxSplits:1)
      return (String(pair[0]),String(pair[1]))
    })
    let realDepth=fields["foreground"]=="true" && fields["depth"]=="true"
    let protectedWithoutDepth=(Int(fields["regions"] ?? "0") ?? 0)>0 && fields["protected"]=="0"
    XCTAssertTrue(realDepth || protectedWithoutDepth,
      "The actual demo portrait needs a real matte or an unobstructed protected-image layout: "+summary)
    if fields["foreground"]=="false" { XCTAssertEqual(fields["depth"],"false") }
    print("PHOTO_LAYOUT",summary)
    viewportShot("photo-demo-portrait-protected")
    shot("native-demo-photo-face")
  }
  func testPhotoGlassTransmitsTheSameBackdropInsteadOfOpaqueInk() {
    func pixels(_ data: Data) -> (values:[UInt8],width:Int,height:Int) {
      let image = UIImage(data:data)!.cgImage!
      var bytes = [UInt8](repeating:0,count:image.width*image.height*4)
      bytes.withUnsafeMutableBytes { buffer in
        let context = CGContext(data:buffer.baseAddress,width:image.width,height:image.height,
          bitsPerComponent:8,bytesPerRow:image.width*4,space:CGColorSpaceCreateDeviceRGB(),
          bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height))
      }
      return (bytes,image.width,image.height)
    }
    launch(["--face","Photos","--photo-clock-test-mode","background"])
    let backdrop = pixels(viewportBytes("photo-glass-background-control"))
    app.terminate()
    launch(["--face","Photos","--photo-clock-test-mode","stencil"])
    let stencil = pixels(viewportBytes("photo-glass-opaque-positive-control"))
    app.terminate()
    launch(["--face","Photos"])
    let glass = pixels(viewportBytes("photo-glass-same-backdrop"))
    XCTAssertEqual(backdrop.width,glass.width)
    XCTAssertEqual(stencil.height,glass.height)
    var samples=0,transmitted=0,opaqueMatches=0
    // Fixed upper clock ROI, excluding caption, round corners and host chrome.
    // The separate white-stencil launch identifies actual interior ink pixels.
    for y in Int(Double(glass.height)*0.06)..<Int(Double(glass.height)*0.43) {
      for x in Int(Double(glass.width)*0.05)..<Int(Double(glass.width)*0.95) {
        let i=(y*glass.width+x)*4
        let neighbors=[i,i-12,i+12,i-glass.width*12,i+glass.width*12]
        guard neighbors.allSatisfy({ j in (0..<3).allSatisfy { stencil.values[j+$0]>245 } }),
              (0..<3).contains(where:{ backdrop.values[i+$0]<190 }) else { continue }
        samples += 1
        let error=(0..<3).map { abs(Int(glass.values[i+$0])-Int(backdrop.values[i+$0])) }.max()!
        let opaqueError=(0..<3).map { abs(Int(stencil.values[i+$0])-Int(backdrop.values[i+$0])) }.max()!
        if error<=45 { transmitted += 1 }
        if opaqueError<=45 { opaqueMatches += 1 }
      }
    }
    XCTAssertGreaterThan(samples,500,"The positive control must expose actual glyph interiors")
    XCTAssertGreaterThan(Double(transmitted)/Double(max(1,samples)),0.8,
      "The photo must remain visible through clock bodies, not flat opaque ink")
    XCTAssertLessThan(Double(opaqueMatches)/Double(max(1,samples)),0.05)
    print("PHOTO_GLASS_PIXELS samples=\(samples) transmitted=\(transmitted) opaqueMatches=\(opaqueMatches)")
  }
  func testPhotoGlassNightUsesTheWholeViewportMonochrome() {
    launch(["--face","Photos"])
    tap("nav.controls"); tap("controls.night"); tap("nav.faces")
    let pixels=[UInt8](viewportPixels(viewportBytes("photo-glass-night-full-viewport"),inset:0))
    var lit=0,wrongColor=0
    for i in stride(from:0,to:pixels.count,by:4) where pixels[i]>25 {
      lit += 1
      if Double(pixels[i+1])>Double(pixels[i])*0.4 || Double(pixels[i+2])>Double(pixels[i])*0.4 {
        wrongColor += 1
      }
    }
    XCTAssertGreaterThan(lit,100)
    XCTAssertEqual(wrongColor,0,"Photo transmission and highlights must stay inside the night treatment")
    print("PHOTO_GLASS_NIGHT lit=\(lit) wrongColor=\(wrongColor)")
  }
  func testPhotoClockAvoidsTopSubjectAndKeepsBothEdgeSubjects() {
    launch(["--photo-layout-fixture", "top"])
    let layout = app.staticTexts["photo.layout.test"]
    XCTAssertTrue(layout.waitForExistence(timeout: 5))
    XCTAssertTrue(layout.label.contains("clock=bottom"), layout.label)
    XCTAssertTrue(layout.label.contains("depth=true"), layout.label)
    shot("photo-layout-top-subject-clock-bottom")
    app.terminate()
    launch(["--photo-layout-fixture", "edges"])
    XCTAssertTrue(layout.waitForExistence(timeout: 5))
    XCTAssertTrue(layout.label.contains("full=true"), layout.label)
    shot("photo-layout-two-edge-subjects-full-image")
  }
  func testDensePhotoMaskDoesNotHideClockBehindSubject() {
    launch(["--photo-layout-fixture", "dense"])
    let layout = app.staticTexts["photo.layout.test"]
    XCTAssertTrue(layout.waitForExistence(timeout: 5))
    XCTAssertTrue(layout.label.contains("depth=false"), layout.label)
    XCTAssertTrue(app.staticTexts["photo.clock"].exists)
    shot("photo-layout-dense-mask-depth-disabled")
  }
  func testPhotoManualClockPositionSurvivesRelaunchAndResetsToAuto() {
    let id = UUID().uuidString
    launch(["--persistence-test", id, "--reset-test-store", "--photo-layout-fixture", "top",
            "--photo-layout-settings"])
    let top = app.buttons["photos.clock.top"]
    for _ in 0..<18 where !top.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(top.isHittable)
    top.tap()
    tap("nav.faces")
    let layout = app.staticTexts["photo.layout.test"]
    XCTAssertTrue(layout.label.contains("clock=top"), layout.label)
    XCTAssertTrue(layout.label.contains("depth=false"), layout.label)
    app.terminate()
    launch(["--persistence-test", id, "--photo-layout-fixture", "top"])
    XCTAssertTrue(layout.waitForExistence(timeout: 5))
    XCTAssertTrue(layout.label.contains("clock=top"), layout.label)
    shot("photo-layout-manual-top-after-relaunch")
    // Re-open Settings and reset only this photo's correction.
    tap("nav.controls")
    tap("controls.settings")
    let reset = app.buttons["photos.layout.reset"]
    for _ in 0..<18 where !reset.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(reset.isHittable)
    reset.tap()
    tap("nav.faces")
    XCTAssertTrue(layout.label.contains("clock=bottom"), layout.label)
  }
  func testPhotoManualCropCanOverrideAndRestoreFullImageFraming() {
    launch(["--photo-layout-fixture", "edges", "--photo-layout-settings"])
    let automatic = app.switches["photos.crop.auto"]
    for _ in 0..<18 where !automatic.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(automatic.isHittable)
    automatic.tap()
    let horizontal = app.sliders["photos.crop.horizontal"]
    for _ in 0..<4 where !horizontal.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(horizontal.isHittable)
    horizontal.adjust(toNormalizedSliderPosition: 0.85)
    tap("nav.faces")
    let layout = app.staticTexts["photo.layout.test"]
    XCTAssertTrue(layout.label.contains("full=false"), layout.label)
    shot("photo-layout-manual-crop")
    tap("nav.controls")
    tap("controls.settings")
    let reset = app.buttons["photos.layout.reset"]
    for _ in 0..<18 where !reset.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(reset.isHittable)
    reset.tap()
    tap("nav.faces")
    XCTAssertTrue(layout.label.contains("full=true"), layout.label)
  }

  func testAlternateHomeClockSceneAndThermostat() {
    launch(["--face", "Home Modular Clock"])
    XCTAssertTrue(app.buttons["alternate.thermostat"].exists)
    shot("UI45-large-clock-modular")
    tap("scene.Dinner Time")
    tap("alternate.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "70°")
  }

  func testNativeAlarmEditorSchedulesAndDeletesOwnAlarm() {
    launch(["--page", "Alarms", "--system-alarms"])
    tap("alarm.add")
    let os = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    if os.alerts.firstMatch.waitForExistence(timeout: 2), os.alerts.buttons["Allow"].exists {
      os.alerts.buttons["Allow"].tap()
    }
    XCTAssertTrue(app.staticTexts["System alert enabled"].waitForExistence(timeout: 15))
    let buttons = app.buttons.matching(
      NSPredicate(format: "identifier BEGINSWITH %@", "alarm.delete."))
    XCTAssertEqual(buttons.count, 2)
    buttons.element(boundBy: 1).tap()
    XCTAssertFalse(app.staticTexts["System alert enabled"].exists)
    XCTAssertEqual(
      app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "alarm.delete.")).count,
      1)
  }

  func testPodcastTransportPersistsThroughNavigation() {
    launch(["--page", "Podcasts"])
    tap("podcast.play")
    expectation(
      for: NSPredicate(format: "label CONTAINS %@", "Pause"),
      evaluatedWith: app.buttons["podcast.play"])
    waitForExpectations(timeout: 8)
    tap("nav.apps")
    tap("activity.podcast")
    tap("podcast.play")
    XCTAssertTrue(app.buttons["podcast.play"].label.contains("Play Demo Episode"))
  }

  func testMultipleRecipesRequireSelectionAndDoNotInventMetadata() {
    launch(["--page", "Safari", "--browser-multiple-recipes"])
    XCTAssertTrue(app.webViews.firstMatch.staticTexts["Garden Tomato Pasta"].waitForExistence(timeout: 10))
    tap("browser.recipe")
    XCTAssertTrue(app.staticTexts["Choose a Recipe"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["Garden Tomato Pasta"].exists)
    app.buttons["Second local recipe"].tap()
    XCTAssertTrue(app.staticTexts["Second local recipe"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Duration not provided")).firstMatch.exists)
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Servings not provided")).firstMatch.exists)
    tap("recipe.start")
    XCTAssertEqual(app.staticTexts["cooking.text"].label, "Mix the second fixture.")
    XCTAssertFalse(app.buttons["cooking.timer"].exists)
    shot("recipe-multiple-choice-no-invented-duration")
  }
  func testNativeBrowserRecipeExtractionCookingAndPinning() {
    launch(["--page", "Safari"])
    XCTAssertTrue(
      app.webViews.firstMatch.staticTexts["Garden Tomato Pasta"].waitForExistence(timeout: 15))
    tap("browser.recipe")
    XCTAssertTrue(app.staticTexts["Garden Tomato Pasta"].waitForExistence(timeout: 5))
    tap("recipe.start")
    XCTAssertTrue(app.staticTexts["cooking.text"].label.contains("Simmer"))
    tap("cooking.timer")
    app.buttons["Pin recipe"].tap()
    tap("nav.faces")
    drawer()
    let safari = app.buttons["app.Safari"]
    if !safari.isHittable { app.scrollViews.firstMatch.swipeUp() }
    tap("app.Safari")
    tap("browser.saved")
    XCTAssertTrue(app.buttons["saved.Garden Tomato Pasta"].waitForExistence(timeout: 5))
    shot("native-browser-recipe-library")
  }
  func testMockMirrorZoomAndRingLightNeverOpenCamera() {
    launch(["--page", "Mirror"])
    XCTAssertEqual(app.staticTexts["mirror.mode"].label, "Mock camera")
    XCTAssertEqual(app.buttons["mirror.light"].value as? String, "On")
    tap("mirror.light")
    XCTAssertEqual(app.buttons["mirror.light"].value as? String, "Off")
    tap("mirror.zoom")
    XCTAssertEqual(app.buttons["mirror.zoom"].value as? String, "1.25")
    XCTAssertEqual(app.staticTexts["mirror.mode"].label, "Mock camera")
    shot("native-mock-mirror-zoom")
  }

  func testNightFaceActuallyRendersMonochromeRed() {
    launch()
    tap("nav.controls")
    tap("controls.night")
    tap("nav.faces")
    let screenshot = app.screenshot()
    let image = screenshot.image.cgImage!
    let crop = image.cropping(
      to: CGRect(x: CGFloat(image.width) / 2, y: CGFloat(image.height) / 2, width: 1, height: 1))!
    var pixel = [UInt8](repeating: 0, count: 4)
    let rendered = pixel.withUnsafeMutableBytes { buffer -> Bool in
      guard
        let context = CGContext(
          data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue)
      else { return false }
      context.draw(crop, in: CGRect(x: 0, y: 0, width: 1, height: 1))
      return true
    }
    XCTAssertTrue(rendered)
    XCTAssertGreaterThan(pixel[0], 25)
    XCTAssertGreaterThan(Double(pixel[0]), Double(pixel[1]) * 2.5)
    XCTAssertGreaterThan(Double(pixel[0]), Double(pixel[2]) * 2.5)
    shot("native-night-monochrome-face")
  }

  func testDemoGalleryAutomaticallyRotatesBundledPhotos() {
    launch(["--page", "Settings", "--fast-photo-rotation"])
    let button = app.buttons["photos.gallery"]
    let scroll = app.scrollViews.firstMatch
    let viewport = app.otherElements["reference.viewport"]
    // AX may report hittable while the round viewport clips this button.
    // Require the full control inside the visible scroll area before touching it.
    for _ in 0..<12 {
      let safe = scroll.frame.intersection(viewport.frame).insetBy(dx:0,dy:40)
      if button.isHittable && safe.contains(button.frame) { break }
      if button.frame.minY < safe.minY { scroll.swipeDown() } else { scroll.swipeUp() }
    }
    XCTAssertTrue(scroll.frame.intersection(viewport.frame).insetBy(dx:0,dy:40).contains(button.frame))
    shot("photo-gallery-control-fully-visible")
    button.tap()
    let caption = app.staticTexts["photo.index"]
    XCTAssertTrue(caption.waitForExistence(timeout: 8))
    let original = caption.label
    XCTAssertTrue(original.contains("OF 2"))
    expectation(for: NSPredicate(format: "label != %@", original), evaluatedWith: caption)
    waitForExpectations(timeout: 7)
    let layout = app.staticTexts["photo.layout.test"].label
    XCTAssertTrue(layout.contains("full=false"),
      "A completed no-face landscape analysis must not invent a full-image subject: " + layout)
    viewportShot("photo-demo-gallery")
    shot("native-demo-photo-gallery")
  }
  func testKeepDisplayOnUsesNativeIdleTimer() {
    launch(["--page", "Settings"])
    let button = app.buttons["settings.keepawake"]
    XCTAssertEqual(button.value as? String, "Off")
    button.tap()
    expectation(for: NSPredicate(format: "value == %@", "On"), evaluatedWith: button)
    waitForExpectations(timeout: 5)

    button.tap()
    expectation(for: NSPredicate(format: "value == %@", "Off"), evaluatedWith: button)
    waitForExpectations(timeout: 5)
  }
  func testMockStateSurvivesRelaunchInIsolatedStore() {
    let id = UUID().uuidString
    launch(["--persistence-test", id, "--reset-test-store"])
    tap("home.thermostat")
    tap("thermostat.up")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "69°")
    drawer()
    let settings = app.buttons["app.Settings"]
    for _ in 0..<8 where !settings.isHittable { app.scrollViews.firstMatch.swipeUp() }
    settings.tap()
    let gallery = app.buttons["photos.gallery"]
    for _ in 0..<10 where !gallery.isHittable { app.scrollViews.firstMatch.swipeUp() }
    gallery.tap()
    XCTAssertTrue(app.staticTexts["photo.index"].label.contains("OF 2"))
    app.terminate()
    launch(["--persistence-test", id, "--screen-thermostat"])
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "69°")
    tap("nav.faces")
    XCTAssertTrue(app.staticTexts["photo.index"].label.contains("OF 2"))
    app.terminate()
    launch(["--persistence-test", id, "--reset-test-store", "--screen-thermostat"])
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "68°")
  }

  func viewportShot(_ name: String) {
    let viewport = app.otherElements["reference.viewport"]
    XCTAssertTrue(viewport.waitForExistence(timeout: 5))
    let frame = viewport.frame
    let screenshot = app.screenshot()
    let pixels = screenshot.image.cgImage!
    let scale = CGFloat(pixels.width) / app.frame.width
    let rect = CGRect(
      x: frame.minX * scale, y: frame.minY * scale, width: frame.width * scale,
      height: frame.height * scale
    ).integral
    XCTAssertEqual(frame.width, frame.height, accuracy: 1)
    guard let cropped = pixels.cropping(to: rect) else {
      XCTFail("Viewport crop failed")
      return
    }
    let attachment = XCTAttachment(image: UIImage(cgImage: cropped))
    attachment.name = "viewport-" + name
    attachment.lifetime = .keepAlways
    add(attachment)
    let metadata: [String: Any] = [
      "reference": name, "viewport_points": [frame.minX, frame.minY, frame.width, frame.height],
      "crop_pixels": [rect.minX, rect.minY, rect.width, rect.height],
      "screenshot_pixels": [pixels.width, pixels.height],
    ]
    let geometry = XCTAttachment(
      data: try! JSONSerialization.data(withJSONObject: metadata, options: [.sortedKeys]),
      uniformTypeIdentifier: "public.json")
    geometry.name = "geometry-" + name
    geometry.lifetime = .keepAlways
    add(geometry)
    shot("screen-" + name)
  }
  func testNumeralsReferenceReadingAndSharedClockDefaults() {
    launch(["--face","Numerals"])
    XCTAssertTrue(app.otherElements["face.Numerals"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["WED 1"].exists)
    viewportShot("numerals-reference-time")
    launch(["--face","Fade"])
    XCTAssertTrue(app.otherElements["face.Fade"].waitForExistence(timeout:5))
    viewportShot("numerals-shared-fade-regression")
  }
  func testVisualReferenceAtlas() {
    for (reference, face) in [
      ("UI01", "Modular"), ("UI07", "Home Modular"), ("UI08", "Calendar"), ("UI10", "Numerals"),
      ("UI12", "Fade"), ("UI47", "Flow"), ("UI05", "Weather"), ("UI45", "Home Modular Clock"),
    ] {
      launch(["--face", face])
      if reference == "UI08" {
        XCTAssertEqual(app.staticTexts["calendar.face.selected"].label, "1")
      }
      viewportShot(reference)
      app.terminate()
    }
    launch(["--page", "Home"])
    viewportShot("UI13")
    app.terminate()
    launch(["--reference-timer", "--reference-resting"])
    XCTAssertEqual(app.staticTexts["timer.countdown"].label, "10:56")
    viewportShot("UI14")
    app.terminate()
    launch(["--page", "Calendar"])
    viewportShot("UI26")
    app.terminate()
    launch(["--screen-recipe"])
    tap("recipe.start")
    viewportShot("UI25")
  }

  func testCalendarWeekSelectionChangesMockAgenda() {
    launch(["--page", "Calendar"])
    let cancelled = app.staticTexts["CANCELED: Coffee with Jamie"]
    XCTAssertTrue(cancelled.exists)
    tap("calendar.day.0")
    XCTAssertFalse(cancelled.exists)
    XCTAssertTrue(app.staticTexts["Morning walk"].exists)
    tap("calendar.day.3")
    XCTAssertTrue(cancelled.exists)
  }

  func testCorruptRecipeMigrationPreservesHomeAndSubsequentWrites() {
    let id = UUID().uuidString
    print("MIGRATION_TEST_ID=" + id)
    launch(["--persistence-test", id, "--reset-test-store", "--state-corrupt-fixture", "--screen-thermostat"])
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"69°")
    tap("thermostat.up")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"70°")
    app.terminate()
    launch(["--persistence-test", id, "--screen-thermostat"])
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"70°")
    shot("store-corrupt-recipe-keeps-home-and-writes")
  }
  func testFutureStoreRemainsReadOnlyAfterAnAttemptedSaveAndRelaunch() {
    let id=UUID().uuidString
    print("FUTURE_TEST_ID=" + id)
    launch(["--persistence-test", id, "--reset-test-store", "--state-future-fixture", "--screen-thermostat"])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
    tap("thermostat.up")
    XCTAssertTrue(app.alerts.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Original saved data is unchanged")).firstMatch.waitForExistence(timeout:5))
    app.alerts.buttons["OK"].tap()
    app.terminate()
    launch(["--persistence-test", id, "--screen-thermostat"])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
    shot("store-future-version-readonly-after-relaunch")
  }
  func testAssistantDraftSurvivesNavigationButNeverBackgroundOrImplicitSend() {
    launch()
    tap("nav.assistant")
    let field = app.textFields["assistant.input"]
    field.tap(); field.typeText("temperature 73")
    tap("nav.faces"); tap("nav.assistant")
    XCTAssertEqual(field.value as? String, "temperature 73")
    tap("assistant.voice")
    tap("nav.faces"); tap("nav.assistant")
    XCTAssertEqual(field.value as? String, "temperature 73")
    tap("nav.faces"); tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "68°")
    tap("nav.assistant")
    XCUIDevice.shared.press(.home); app.activate()
    XCTAssertTrue(field.waitForExistence(timeout: 8))
    XCTAssertTrue(["", "Type a request"].contains(field.value as? String ?? "invalid"))
    XCTAssertFalse(app.buttons["assistant.send"].isEnabled)
    shot("assistant-draft-cleared-after-background")
  }
  func testVoicePreviewRequiresSendBeforeMockCommand() {
    launch()
    tap("nav.assistant")
    tap("assistant.voice")
    XCTAssertTrue(app.staticTexts["assistant.voice.status"].label.contains("Synthetic"))
    XCTAssertFalse(app.buttons["assistant.send"].isEnabled)
    tap("assistant.voice")
    XCTAssertEqual(app.textFields["assistant.input"].value as? String, "temperature 72")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("What can I help"))
    shot("native-voice-preview-mock")
    tap("assistant.send")
    tap("nav.faces")
    tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "72°")
  }
  func testVoiceCancelAndDeniedPermissionKeepTypingAvailable() {
    launch()
    tap("nav.assistant")
    tap("assistant.voice")
    tap("assistant.voice.cancel")
    XCTAssertTrue(
      ["", "Type a request"].contains(
        app.textFields["assistant.input"].value as? String ?? "invalid"))
    XCTAssertFalse(app.buttons["assistant.send"].isEnabled)
    tap("nav.faces")
    tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "68°")
    app.terminate()
    launch(["--voice-denied"])
    tap("nav.assistant")
    tap("assistant.voice")
    XCTAssertTrue(
      app.staticTexts["assistant.voice.status"].label.contains("permission was not granted"))
    let field = app.textFields["assistant.input"]
    field.tap()
    field.typeText("temperature 71")
    tap("assistant.send")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("71"))
  }

  func testVoiceStopsDemoAudioAndResetsOnNavigation() {
    launch(["--page", "Music"])
    tap("player.play")
    expectation(
      for: NSPredicate(format: "label == %@", "Pause"), evaluatedWith: app.buttons["player.play"])
    waitForExpectations(timeout: 8)
    tap("nav.assistant")
    tap("assistant.voice")
    tap("nav.faces")
    tap("nav.assistant")
    XCTAssertTrue(app.staticTexts["assistant.voice.status"].label.contains("Tap to speak"))
    XCTAssertFalse(app.buttons["assistant.send"].isEnabled)
    drawer()
    tap("app.Music")
    XCTAssertEqual(app.buttons["player.play"].label, "Play")
  }

  func connectService(_ name: String, success: Bool = true) {
    let button = app.buttons["connect." + name]
    XCTAssertTrue(button.waitForExistence(timeout: 8))
    for _ in 0..<18 where !button.isHittable { app.scrollViews.firstMatch.swipeUp() }
    button.tap()
    let status = app.staticTexts["connection.status." + name]
    expectation(
      for: NSPredicate(format: "label CONTAINS %@", success ? "Connected" : "Access unavailable"),
      evaluatedWith: status)
    waitForExpectations(timeout: 8)
  }
  func testCalendarAgendaShowsAllDayAndSourceWithoutPersonalData() {
    launch(["--page", "Settings", "--calendar-agenda-fixture"])
    connectService("Calendar")
    drawer(); tap("app.Calendar"); tap("device.unlock")
    XCTAssertTrue(app.staticTexts["Synthetic all-day event"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["All day"].exists)
    XCTAssertTrue(app.staticTexts["Synthetic calendar · Test room"].exists)
    shot("calendar-agenda-all-day-and-source")
    tap("calendar.refresh")
    XCTAssertTrue(app.staticTexts["Synthetic all-day event"].waitForExistence(timeout: 5))
  }
  func testDeniedCalendarDoesNotSilentlyFallBackToDemoAgenda() {
    launch(["--page", "Settings", "--connection-denied"])
    connectService("Calendar", success: false)
    drawer(); tap("app.Calendar"); tap("device.unlock")
    XCTAssertTrue(app.staticTexts["No events"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["Morning walk"].exists)
    XCTAssertFalse(app.staticTexts["Device fixture meeting"].exists)
    shot("calendar-denied-no-demo-fallback")
  }
  func testConnectedCalendarRequiresDeviceUnlockAndUsesNativeSourceContract() {
    launch(["--page", "Settings"])
    connectService("Calendar")
    drawer()
    tap("app.Calendar")
    XCTAssertFalse(app.staticTexts["Device fixture meeting"].exists)
    tap("device.unlock")
    XCTAssertTrue(app.staticTexts["Device fixture meeting"].waitForExistence(timeout: 5))
    shot("connected-calendar-fixture")
    tap("nav.assistant")
    let request = app.textFields["assistant.input"]
    request.tap()
    request.typeText("show calendar")
    tap("assistant.send")
    XCTAssertTrue(app.staticTexts["Device fixture meeting"].waitForExistence(timeout: 5))
  }
  func testConnectedReadOnlyReminderExposesListAndDisablesMutation() {
    launch(["--page", "Settings", "--reminder-readonly-fixture"])
    connectService("Reminders")
    drawer(); tap("app.Reminders"); tap("device.unlock")
    let item = app.buttons["device.reminder.Shared read-only reminder"]
    XCTAssertTrue(item.waitForExistence(timeout: 5))
    XCTAssertFalse(item.isEnabled)
    XCTAssertEqual(item.value as? String, "Read-only")
    XCTAssertFalse(app.buttons["Delete Shared read-only reminder"].isEnabled)
    shot("reminder-readonly-source")
  }
  func testConnectedReminderCRUDUsesProviderReadback() {
    launch(["--page", "Settings"])
    connectService("Reminders")
    drawer()
    tap("app.Reminders")
    tap("device.unlock")
    let item = app.buttons["device.reminder.Device fixture reminder"]
    XCTAssertTrue(item.waitForExistence(timeout: 5))
    item.tap()
    expectation(for: NSPredicate(format: "value == %@", "Completed"), evaluatedWith: item)
    waitForExpectations(timeout: 5)
    let field = app.textFields["device.reminder.input"]
    field.tap()
    field.typeText("Native test item")
    tap("device.reminder.add")
    XCTAssertTrue(app.buttons["device.reminder.Native test item"].waitForExistence(timeout: 5))
    app.buttons["Delete Native test item"].tap()
    expectation(
      for: NSPredicate(format: "exists == false"),
      evaluatedWith: app.buttons["device.reminder.Native test item"])
    waitForExpectations(timeout: 5)
    shot("connected-reminders-fixture")
  }
  func testBackgroundLocksConnectedCalendarAndRequiresFreshDeviceUnlock() {
    launch(["--page", "Settings"])
    connectService("Calendar")
    drawer()
    tap("app.Calendar")
    tap("device.unlock")
    XCTAssertTrue(app.staticTexts["Device fixture meeting"].waitForExistence(timeout: 5))
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.staticTexts["mock.badge"].waitForExistence(timeout: 8))
    XCTAssertFalse(app.staticTexts["Device fixture meeting"].exists)
    // Navigate from a new foreground session; selecting a demo profile is not device unlock.
    tap("nav.faces")
    drawer()
    tap("app.Calendar")
    XCTAssertTrue(app.buttons["device.unlock"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.staticTexts["Device fixture meeting"].exists)
    shot("privacy-calendar-locked-after-background")
    tap("device.unlock")
    XCTAssertTrue(app.staticTexts["Device fixture meeting"].waitForExistence(timeout: 5))
  }
  func testConnectedMusicAndWeatherDoNotUseHomeKit() {
    launch(["--page", "Settings"])
    connectService("Apple Music")
    connectService("Weather")
    XCTAssertTrue(app.descendants(matching: .any)["connections.home.locked"].exists)
    drawer()
    tap("app.Music")
    let field = app.textFields["music.search.input"]
    field.tap()
    field.typeText("sample")
    tap("music.search")
    tap("music.result.0")
    XCTAssertEqual(app.staticTexts["music.current.title"].label, "Connected fixture song")
    XCTAssertEqual(app.buttons["music.connected.play"].label, "Pause")
    tap("music.connected.play")
    XCTAssertEqual(app.buttons["music.connected.play"].label, "Play")
    shot("connected-music-fixture")
    tap("nav.assistant")
    let request = app.textFields["assistant.input"]
    request.tap()
    request.typeText("music")
    tap("assistant.send")
    XCTAssertEqual(app.staticTexts["assistant.reply"].label, "Playback requested.")
    tap("nav.faces")
    let pauseActivity = app.buttons["Pause music"]
    XCTAssertTrue(pauseActivity.waitForExistence(timeout: 5))
    pauseActivity.tap()
    expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: pauseActivity)
    waitForExpectations(timeout: 5)
    drawer()
    tap("app.Weather")
    XCTAssertTrue(app.staticTexts["55°"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.staticTexts["Fixture City"].exists)
    shot("connected-weather-fixture")
  }
  func testDeniedConnectionDoesNotBecomeConnected() {
    launch(["--page", "Settings", "--connection-denied"])
    connectService("Calendar", success: false)
    XCTAssertEqual(app.buttons["connect.Calendar"].label, "Connect")
    tap("nav.faces")
    tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "68°")
  }
  func openWeather() {
    drawer(); tap("app.Weather")
    XCTAssertTrue(app.staticTexts["weather.source"].waitForExistence(timeout:5))
    XCTAssertLessThan(app.staticTexts["weather.source"].frame.maxY,
      app.otherElements["reference.viewport"].frame.maxY - 8,"Weather source must be visibly inside the display")
  }
  func testWeatherMissingValuesRemainUnknownAndUnitsAreExplicit() {
    launch(["--page","Settings","--weather-missing"])
    connectService("Weather")
    let units = app.segmentedControls["weather.units"]
    let celsius = units.buttons["°C / km/h"]
    for _ in 0..<8 where !celsius.isHittable
      || celsius.frame.maxY > app.otherElements["reference.viewport"].frame.maxY - 45 {
      app.scrollViews.firstMatch.swipeUp()
    }
    celsius.tap()
    XCTAssertTrue(celsius.isSelected,"The visible Celsius segment must actually be selected")
    openWeather()
    XCTAssertEqual(app.staticTexts["weather.temperature"].label,"—")
    XCTAssertTrue(app.staticTexts["weather.source"].label.contains("°C / km/h"),app.staticTexts["weather.source"].label)
    XCTAssertTrue(app.staticTexts["Condition unavailable"].exists)
    XCTAssertTrue(app.staticTexts["Sunrise — · AQI not supplied"].exists)
    let sunrise = app.staticTexts["Sunrise — · AQI not supplied"].frame
    let viewport = app.otherElements["reference.viewport"].frame
    XCTAssertGreaterThan(sunrise.minX,viewport.minX + viewport.width * 0.07)
    XCTAssertLessThan(sunrise.maxY,viewport.maxY - 8)
    shot("weather-missing-metrics-no-fabricated-aqi")
  }
  func testWeatherAppUsesSeparateCenteredCityAndConditionsLayout() {
    launch(["--page","Weather"])
    let city=app.staticTexts["weather.app.city"],temperature=app.staticTexts["weather.temperature"]
    let viewport=app.otherElements["reference.viewport"].frame
    XCTAssertEqual(city.label,"San Francisco");XCTAssertEqual(temperature.label,"54°")
    XCTAssertEqual(city.frame.midX,viewport.midX,accuracy:2)
    XCTAssertEqual(temperature.frame.midX,viewport.midX,accuracy:2)
    let conditions=app.staticTexts["Conditions"].frame
    XCTAssertGreaterThan(conditions.minY,temperature.frame.maxY)
    XCTAssertLessThan(conditions.maxY,viewport.maxY)
    XCTAssertTrue(app.staticTexts["weather.source"].label.hasPrefix("Demo"))
    touchWeatherControl("weather.cities")
    XCTAssertTrue(app.textFields["weather.app.city.input"].waitForExistence(timeout:5))
    tap("weather.city.done")
    XCTAssertTrue(city.waitForExistence(timeout:5))
    shot("weather-app-ui20-centered-city-conditions")
  }
  private func touchWeatherControl(_ id:String) {
    let button=app.buttons[id]
    XCTAssertTrue(button.waitForExistence(timeout:5))
    let frame=button.frame,viewport=app.otherElements["reference.viewport"].frame
    XCTAssertTrue(viewport.contains(CGPoint(x:frame.midX,y:frame.midY)))
    // Verify actual screen-coordinate touches and their resulting destination.
    // AX isHittable is false for these scaled SwiftUI scroll-view controls even
    // when their decoded screenshot position agrees with the native anchor.
    app.coordinate(withNormalizedOffset:.zero)
      .withOffset(CGVector(dx:frame.midX-app.frame.minX,dy:frame.midY-app.frame.minY)).tap()
  }
  func testWeatherForecastModesAndCitySheetUseOnlyConnectedFixtureData() {
    launch(["--page","Settings","--weather-forecast-fixture"])
    connectService("Weather");openWeather()
    XCTAssertEqual(app.staticTexts["weather.app.city"].label,"Berlin")
    touchWeatherControl("weather.mode.Wind")
    XCTAssertEqual(app.staticTexts["weather.metric"].label,"Wind (mph)")
    XCTAssertTrue(app.staticTexts["9 mph"].exists)
    touchWeatherControl("weather.mode.Precipitation")
    XCTAssertTrue(app.staticTexts["15%"].exists)
    shot("weather-app-source-hourly-precipitation")
    touchWeatherControl("weather.cities")
    let field=app.textFields["weather.app.city.input"];field.tap()
    field.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:(field.value as? String)?.count ?? 0)+"Paris")
    XCTAssertEqual(field.value as? String,"Paris")
    tap("weather.app.city.update")
    expectation(for:NSPredicate(format:"label == %@","Paris"),evaluatedWith:app.staticTexts["weather.app.city"])
    waitForExpectations(timeout:8)
    touchWeatherControl("weather.cities")
    app.segmentedControls["weather.app.units"].buttons["°C / km/h"].tap()
    tap("weather.city.done")
    XCTAssertEqual(app.staticTexts["weather.temperature"].label,"13°")
    XCTAssertTrue(app.staticTexts["weather.source"].label.contains("°C / km/h"))
    shot("weather-app-city-changed-celsius")
  }
  func testWeatherLateCityResultCannotDismissReopenedEditor() {
    launch(["--page","Settings","--weather-forecast-fixture","--weather-city-delay"])
    connectService("Weather");openWeather()
    touchWeatherControl("weather.cities")
    let field=app.textFields["weather.app.city.input"];field.tap()
    field.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:(field.value as? String)?.count ?? 0)+"Paris")
    tap("weather.app.city.update")
    tap("weather.city.done")
    touchWeatherControl("weather.cities")
    XCTAssertTrue(field.waitForExistence(timeout:5))
    let status=app.staticTexts["weather.app.city.status"]
    expectation(for:NSPredicate(format:"label == %@","Connected · synthetic source"),evaluatedWith:status)
    waitForExpectations(timeout:18)
    XCTAssertTrue(field.exists,"Completion from the closed editor must not dismiss the new sheet")
    XCTAssertEqual(field.value as? String,"Paris")
    tap("weather.city.done")
    XCTAssertEqual(app.staticTexts["weather.app.city"].label,"Paris")
    shot("weather-app-late-result-new-editor-preserved")
  }
  func testWeatherCloudsMoveAndRespectReduceMotion() {
    launch(["--page","Weather","--animation-test"])
    let first=weatherSkyPixels(viewportBytes("weather-clouds-moving-start"))
    Thread.sleep(forTimeInterval:1.5)
    XCTAssertNotEqual(first,weatherSkyPixels(viewportBytes("weather-clouds-moving-later")))
    app.terminate()
    launch(["--page","Weather","--animation-test","--reduce-motion"])
    let frozen=weatherSkyPixels(viewportBytes("weather-clouds-reduced-start"))
    Thread.sleep(forTimeInterval:1.5)
    XCTAssertEqual(frozen,weatherSkyPixels(viewportBytes("weather-clouds-reduced-later")))
  }
  func testWeatherZeroCloudCoverDoesNotInventClouds() {
    launch(["--page","Settings","--weather-clear"])
    connectService("Weather");openWeather()
    XCTAssertTrue(app.staticTexts["Clear"].exists)
    let sky=weatherSkyPixels(viewportBytes("weather-clouds-zero-cover-clear-sky"))
    let red=stride(from:0,to:sky.count,by:4).map { sky[$0] }
    XCTAssertLessThan(red.max()!,100,"The predefined clear-sky region must contain blue sky, not white clouds")
  }
  func testWeatherFaceOpensDistinctCityScreen() {
    launch(["--face","Weather"])
    XCTAssertTrue(app.otherElements["face.Weather"].waitForExistence(timeout:5))
    shot("weather-clouds-face-before-opening-city")
    app.otherElements["face.Weather"].tap()
    XCTAssertTrue(app.staticTexts["weather.app.city"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["Conditions"].exists)
  }
  private func weatherSkyPixels(_ png:Data) -> Data {
    let image=UIImage(data:png)!.cgImage!
    // Predeclared sky-only ROI: no city, clock, buttons, corners or host chrome.
    // Compare decoded RGBA bytes, never PNG encoding/metadata differences.
    let rect=CGRect(x:Double(image.width)*0.20,y:Double(image.height)*0.035,
      width:Double(image.width)*0.55,height:Double(image.height)*0.135).integral
    let crop=image.cropping(to:rect)!
    var pixels=[UInt8](repeating:0,count:crop.width*crop.height*4)
    pixels.withUnsafeMutableBytes {
      let context=CGContext(data:$0.baseAddress,width:crop.width,height:crop.height,
        bitsPerComponent:8,bytesPerRow:crop.width*4,space:CGColorSpaceCreateDeviceRGB(),
        bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
      context.draw(crop,in:CGRect(x:0,y:0,width:crop.width,height:crop.height))
    }
    return Data(pixels)
  }
  func testWeatherGlassDemoAndUnavailableLiveAQIRemainDistinct() {
    launch(["--face","Weather"])
    XCTAssertEqual(app.staticTexts["weather.temperature"].label,"54°")
    XCTAssertEqual(app.staticTexts["weather.detail.AQI"].label,"21")
    XCTAssertTrue(app.staticTexts["weather.source"].label.hasPrefix("Demo"))
    shot("weather-glass-ui05-demo-known-example")
    app.terminate()
    launch(["--face","Weather","--page","Settings"])
    connectService("Weather");tap("nav.faces")
    XCTAssertEqual(app.staticTexts["weather.temperature"].label,"55°")
    XCTAssertEqual(app.staticTexts["weather.detail.AQI"].label,"—")
    XCTAssertFalse(app.staticTexts["weather.source"].label.hasPrefix("Demo"))
    shot("weather-glass-connected-no-invented-aqi")
  }
  func testWeatherGlassFaceMovesAndReducedMotionIsStable() {
    launch(["--face","Weather","--animation-test"])
    let first=weatherGlassPixels(viewportBytes("weather-glass-moving-start"))
    Thread.sleep(forTimeInterval:1.5)
    XCTAssertNotEqual(first,weatherGlassPixels(viewportBytes("weather-glass-moving-later")))
    app.terminate()
    launch(["--face","Weather","--animation-test","--reduce-motion"])
    let frozen=weatherGlassPixels(viewportBytes("weather-glass-reduced-start"))
    Thread.sleep(forTimeInterval:1.5)
    XCTAssertEqual(frozen,weatherGlassPixels(viewportBytes("weather-glass-reduced-later")))
  }
  private func weatherGlassPixels(_ png:Data) -> Data {
    let image=UIImage(data:png)!.cgImage!
    // Fixed glyph/sky ROI excludes all changing labels, clocks and host chrome.
    let rect=CGRect(x:Double(image.width)*0.05,y:Double(image.height)*0.20,
      width:Double(image.width)*0.60,height:Double(image.height)*0.42).integral
    let crop=image.cropping(to:rect)!
    var pixels=[UInt8](repeating:0,count:crop.width*crop.height*4)
    pixels.withUnsafeMutableBytes {
      let context=CGContext(data:$0.baseAddress,width:crop.width,height:crop.height,
        bitsPerComponent:8,bytesPerRow:crop.width*4,space:CGColorSpaceCreateDeviceRGB(),
        bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
      context.draw(crop,in:CGRect(x:0,y:0,width:crop.width,height:crop.height))
    }
    return Data(pixels)
  }
  func testWeatherFailedConnectionDoesNotShowDemoTemperature() {
    launch(["--page","Settings","--weather-fail"])
    let button = app.buttons["connect.Weather"]
    for _ in 0..<18 where !button.isHittable { app.scrollViews.firstMatch.swipeUp() }
    button.tap()
    let status = app.staticTexts["connection.status.Weather"]
    expectation(for:NSPredicate(format:"label CONTAINS %@","Weather unavailable"),evaluatedWith:status)
    waitForExpectations(timeout:5)
    openWeather()
    XCTAssertEqual(app.staticTexts["weather.temperature"].label,"—")
    XCTAssertTrue(app.staticTexts["weather.source"].label.contains("unavailable"))
    XCTAssertFalse(app.staticTexts["54°"].exists)
    shot("weather-offline-without-demo-fallback")
  }
  func testWeatherStaleNightAndCachedOfflineAreLabeled() {
    launch(["--page","Settings","--weather-stale-night"])
    connectService("Weather");openWeather()
    XCTAssertTrue(app.staticTexts["weather.source"].label.hasPrefix("Stale reading"))
    shot("weather-stale-night-source-time")
    launch(["--page","Settings","--weather-cached-failure"])
    connectService("Weather")
    let update=app.buttons["weather.update"]
    for _ in 0..<8 where !update.isHittable { app.scrollViews.firstMatch.swipeUp() }
    update.tap()
    let status = app.staticTexts["connection.status.Weather"]
    expectation(for:NSPredicate(format:"label CONTAINS %@","Weather unavailable"),evaluatedWith:status)
    waitForExpectations(timeout:5)
    openWeather()
    XCTAssertEqual(app.staticTexts["weather.temperature"].label,"55°")
    XCTAssertTrue(app.staticTexts["weather.source"].label.hasPrefix("Offline"))
    shot("weather-offline-last-reading-not-current")
  }
  func testWeatherRainSnowAndDemoHaveDistinctSources() {
    launch(["--page","Weather"])
    XCTAssertTrue(app.staticTexts["weather.source"].label.hasPrefix("Demo"))
    shot("weather-explicit-demo-source")
    for (flag,label) in [("--weather-rain","Rain"),("--weather-snow","Snow")] {
      launch(["--page","Settings",flag]); connectService("Weather");openWeather()
      XCTAssertTrue(app.staticTexts[label].exists)
      XCTAssertFalse(app.staticTexts["weather.source"].label.hasPrefix("Demo"))
      shot("weather-effect-"+label.lowercased())
    }
  }
  func viewportBytes(_ name: String) -> Data {
    let frame = app.otherElements["reference.viewport"].frame
    let screenshot = app.screenshot().image.cgImage!
    let scale = CGFloat(screenshot.width) / app.frame.width
    let rect = CGRect(
      x: frame.minX * scale, y: frame.minY * scale, width: frame.width * scale,
      height: frame.height * scale
    ).integral
    let image = UIImage(cgImage: screenshot.cropping(to: rect)!)
    let attachment = XCTAttachment(image: image)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
    return image.pngData()!
  }
  func testFlowMaterialRendersColoredGlyphsOnBlackWithoutBackground() {
    launch(["--face", "Flow"])
    app.otherElements["face.Flow"].press(forDuration: 1)
    tap("flow.typeface.1")
    app.switches["flow.background"].tap()
    tap("editor.done")
    let png = viewportBytes("flow-material-solid-black")
    let image = UIImage(data: png)!.cgImage!
    let width = image.width, height = image.height
    var bytes = [UInt8](repeating: 0, count: width * height * 4)
    bytes.withUnsafeMutableBytes { buffer in
      let context = CGContext(data: buffer.baseAddress, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
      context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    var black = 0, colored = 0
    for i in stride(from: 0, to: bytes.count, by: 4) {
      let rgb = [Int(bytes[i]), Int(bytes[i+1]), Int(bytes[i+2])]
      let high = rgb.max()!, low = rgb.min()!
      if high < 12 { black += 1 }
      if high > 70 && high - low > 35 { colored += 1 }
    }
    XCTAssertGreaterThan(Double(black) / Double(width * height), 0.2)
    XCTAssertGreaterThan(Double(colored) / Double(width * height), 0.12,
                         "A missing Metal function or opaque black glyph layer must not pass")
  }
  func testFadeConicStopsRenderDifferentPhasesAndKeepClockVisible() {
    launch(["--face", "Fade"])
    _ = viewportBytes("fade-conic-reference-time")
    app.terminate()
    launch(["--face", "Fade", "--fade-test-phase", "0"])
    let first = viewportBytes("fade-conic-phase-zero")
    app.terminate()
    launch(["--face", "Fade", "--fade-test-phase", "0.25"])
    XCTAssertNotEqual(fadeBackgroundPixels(first),
                      fadeBackgroundPixels(viewportBytes("fade-conic-phase-quarter")))
    XCTAssertTrue(app.otherElements["face.Fade"].exists)
  }
  func testFadeReducedMotionIgnoresGradientPhaseChanges() {
    launch(["--face", "Fade", "--reduce-motion", "--fade-test-phase", "0"])
    let first = viewportBytes("fade-conic-reduced-zero")
    app.terminate()
    launch(["--face", "Fade", "--reduce-motion", "--fade-test-phase", "0.75"])
    XCTAssertEqual(fadeBackgroundPixels(first),
                   fadeBackgroundPixels(viewportBytes("fade-conic-reduced-later")))
  }
  private func fadeBackgroundPixels(_ png: Data) -> Data {
    let image = UIImage(data: png)!.cgImage!
    // Compare only actual gradient pixels. Clock-edge antialiasing can differ by 1–2 levels
    // across process restarts; the lower-right background has no hands, hub or numerals.
    let rect = CGRect(x: Double(image.width)*0.6, y: Double(image.height)*0.6,
                      width: Double(image.width)*0.1, height: Double(image.height)*0.1).integral
    let crop = image.cropping(to: rect)!
    var pixels = [UInt8](repeating: 0, count: crop.width*crop.height*4)
    pixels.withUnsafeMutableBytes {
      let context = CGContext(data: $0.baseAddress, width: crop.width, height: crop.height,
        bitsPerComponent: 8, bytesPerRow: crop.width*4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
      context.draw(crop, in: CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
    }
    return Data(pixels)
  }
  func testFlowMaterialStillMovesAfterThirtySeconds() {
    launch(["--face", "Flow", "--animation-test"])
    Thread.sleep(forTimeInterval: 30)
    let late = viewportBytes("flow-material-after-thirty-seconds")
    Thread.sleep(forTimeInterval: 1.2)
    XCTAssertNotEqual(flowPixels(late), flowPixels(viewportBytes("flow-material-after-thirty-two-seconds")))
  }
  func testNativeFlowMovesAndReducedMotionStaysStill() {
    launch(["--face", "Flow", "--animation-test"])
    let first = viewportBytes("flow-moving-start")
    Thread.sleep(forTimeInterval: 1.2)
    XCTAssertNotEqual(flowPixels(first), flowPixels(viewportBytes("flow-moving-later")))
    app.terminate()
    launch(["--face", "Flow", "--animation-test", "--reduce-motion"])
    let frozen = viewportBytes("flow-reduced-start")
    Thread.sleep(forTimeInterval: 1.2)
    XCTAssertEqual(flowPixels(frozen), flowPixels(viewportBytes("flow-reduced-later")))
  }
  private func flowPixels(_ png: Data) -> Data {
    let image = UIImage(data: png)!.cgImage!
    // A predefined interior region contains only Flow glyphs/fluid. Fixed reference
    // time excludes clock changes; no host clock, chrome, PNG metadata or corners.
    let rect = CGRect(x: Double(image.width)*0.05,y: Double(image.height)*0.05,
      width: Double(image.width)*0.90,height: Double(image.height)*0.90).integral
    let crop = image.cropping(to: rect)!
    var pixels = [UInt8](repeating:0,count:crop.width*crop.height*4)
    pixels.withUnsafeMutableBytes {
      let context = CGContext(data:$0.baseAddress,width:crop.width,height:crop.height,
        bitsPerComponent:8,bytesPerRow:crop.width*4,space:CGColorSpaceCreateDeviceRGB(),
        bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
      context.draw(crop,in:CGRect(x:0,y:0,width:crop.width,height:crop.height))
    }
    return Data(pixels)
  }
  func testSystemCommunicationHandsOffOnlyAfterExplicitAction() {
    launch(["--page", "FaceTime"])
    let recipient = app.textFields["facetime.recipient"]
    recipient.tap()
    recipient.typeText("test@example.invalid")
    tap("facetime.system")
    XCTAssertTrue(app.staticTexts["FaceTime not opened in tests"].exists)
    app.terminate()
    launch(["--page", "Messages"])
    tap("messages.compose")
    XCTAssertTrue(app.staticTexts["System composer not opened in tests"].exists)
  }

  func testSharedAlbumImportUsesOnlySyntheticPhotos() {
    launch(["--page", "Settings"])
    openSyntheticAlbumChoices()
    scrollPhotoControlFullyIntoView(app.buttons["photos.shared.fixture"])
    tap("photos.shared.fixture")
    XCTAssertTrue(app.staticTexts["photo.index"].waitForExistence(timeout: 8))
    XCTAssertTrue(app.staticTexts["photo.index"].label.contains("OF 2"))
    shot("connected-shared-album-fixture")
  }

  func testAlbumLiveWindowDropsRemovedPhotosAndShowsEmptyWithoutDemoSubstitution() {
    launch(["--page","Settings"])
    openSyntheticAlbumChoices();linkSyntheticAlbum()
    waitForPhotoMetadata("assets=fixture-a,fixture-b")
    viewportShot("album-linked-initial-two")
    albumSettings()
    let change=app.buttons["photos.shared.fixture.change"]
    scrollPhotoControlFullyIntoView(change);change.tap()
    tap("nav.faces")
    waitForPhotoMetadata("assets=fixture-b,fixture-c")
    XCTAssertFalse(app.staticTexts["photo.layout.test"].label.contains("fixture-a"))
    viewportShot("album-new-window-old-photo-removed")
    albumSettings()
    scrollPhotoControlFullyIntoView(change);change.tap()
    tap("nav.faces")
    waitForPhotoMetadata("assets=none;picture=false")
    XCTAssertTrue(app.descendants(matching:.any)["photo.album.empty"].exists)
    XCTAssertFalse(app.staticTexts["LANDSCAPE · DEMO ALBUM"].exists)
    viewportShot("album-empty-is-not-demo-photo")
  }
  func testAlbumSourceSwitchAndPersonalPreviewUseOnlyTheSelectedAlbum() {
    launch(["--page","Settings"])
    openSyntheticAlbumChoices();linkSyntheticAlbum()
    waitForPhotoMetadata("assets=fixture-a,fixture-b")
    albumSettings();openSyntheticAlbumChoices();linkSyntheticAlbum("second")
    waitForPhotoMetadata("album=second;assets=fixture-c")
    XCTAssertTrue(app.staticTexts["photo.index"].label.contains("SECOND SYNTHETIC ALBUM"))
    tap("nav.apps")
    let preview=app.buttons["personal.photos.open"]
    XCTAssertTrue(preview.waitForExistence(timeout:5))
    shot("album-selected-personal-preview")
    preview.tap()
    waitForPhotoMetadata("album=second;assets=fixture-c")
    viewportShot("album-second-scope-after-preview-touch")
  }
  func testAlbumDisconnectStopsFurtherRefreshAndBackgroundLocksPrivateChoices() {
    launch(["--page","Settings"])
    openSyntheticAlbumChoices();linkSyntheticAlbum()
    waitForPhotoMetadata("assets=fixture-a,fixture-b")
    albumSettings()
    let stop=app.buttons["photos.shared.disconnect"]
    scrollPhotoControlFullyIntoView(stop);stop.tap()
    let before=albumFixtureReport()
    let change=app.buttons["photos.shared.fixture.change"]
    scrollPhotoControlFullyIntoView(change);change.tap()
    Thread.sleep(forTimeInterval:2.2)
    let after=albumFixtureReport()
    func reads(_ report:String)->String { report.split(separator:";").first { $0.hasPrefix("reads=") }.map(String.init) ?? "missing" }
    XCTAssertEqual(reads(before),reads(after))
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertTrue(app.buttons["photos.shared.load"].waitForExistence(timeout:5))
    XCTAssertEqual(app.buttons["photos.shared.load"].label,"Unlock shared albums")
    XCTAssertFalse(app.buttons["photos.shared.fixture"].exists)
    XCTAssertTrue(albumFixtureReport().contains("catalogue=1"))
    tap("nav.faces")
    waitForPhotoMetadata("selection=none;album=none")
    viewportShot("album-disconnected-no-old-copies")
  }
  func testAlbumWindowPersistsAndRestoresOnlyTheKnownScopeWithoutCatalogueReads() {
    let id=UUID().uuidString
    launch(["--page","Settings","--persistence-test",id,"--reset-test-store"])
    openSyntheticAlbumChoices();linkSyntheticAlbum()
    waitForPhotoMetadata("assets=fixture-a,fixture-b")
    albumSettings()
    let change=app.buttons["photos.shared.fixture.change"]
    scrollPhotoControlFullyIntoView(change);change.tap()
    tap("nav.faces");waitForPhotoMetadata("assets=fixture-b,fixture-c")
    app.terminate()
    launch(["--persistence-test",id,"--album-fixture-window","changed"])
    waitForPhotoMetadata("album=fixture;assets=fixture-b,fixture-c")
    albumSettings()
    let report=albumFixtureReport()
    XCTAssertTrue(report.contains("fixture-only;catalogue=0;permission=0"),report)
    XCTAssertTrue(report.contains("album=fixture"),report)
    tap("nav.faces")
    viewportShot("album-scoped-cache-after-relaunch")
  }
  func testAlbumRevocationAndRemovalCannotResurrectALegacySinglePhotoFile() {
    let id=UUID().uuidString
    launch(["--page","Settings","--persistence-test",id,"--reset-test-store"])
    openSyntheticAlbumChoices();linkSyntheticAlbum()
    waitForPhotoMetadata("assets=fixture-a,fixture-b")
    albumSettings()
    let revoke=app.buttons["photos.shared.fixture.revoke"]
    scrollPhotoControlFullyIntoView(revoke);revoke.tap()
    tap("nav.faces");waitForPhotoMetadata("selection=none;album=none;assets=none;picture=false")
    app.terminate()
    launch(["--persistence-test",id,"--album-fixture-denied","--legacy-photo-file-fixture","--face","Photos"])
    waitForPhotoMetadata("selection=none;album=none;assets=none;picture=false")
    XCTAssertTrue(app.staticTexts["LANDSCAPE · DEMO ALBUM"].exists)
    viewportShot("album-revoked-legacy-file-does-not-return")
  }
  func testEmptyLinkedAlbumSurvivesRestartWithoutAnOldPhotoOrInventedDemo() {
    let id=UUID().uuidString
    launch(["--page","Settings","--persistence-test",id,"--reset-test-store","--album-fixture-window","empty"])
    openSyntheticAlbumChoices();linkSyntheticAlbum()
    waitForPhotoMetadata("album=fixture;assets=none;picture=false")
    XCTAssertTrue(app.descendants(matching:.any)["photo.album.empty"].exists)
    app.terminate()
    launch(["--persistence-test",id,"--album-fixture-window","empty","--legacy-photo-file-fixture"])
    waitForPhotoMetadata("selection=album;album=fixture;assets=none;picture=false")
    XCTAssertFalse(app.staticTexts["LANDSCAPE · DEMO ALBUM"].exists)
    XCTAssertTrue(app.descendants(matching:.any)["photo.album.empty"].exists)
    viewportShot("album-empty-after-relaunch-no-legacy-resurrection")
  }
  func testAlbumCatalogueRequiresActualDeviceUnlockNotADemoProfile() {
    launch(["--page","Settings","--device-unlock-denied"])
    let load=app.buttons["photos.shared.load"]
    scrollPhotoControlFullyIntoView(load);load.tap()
    tap("device.unlock")
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout:5))
    app.alerts.buttons["OK"].tap()
    albumSettings()
    XCTAssertFalse(app.buttons["photos.shared.fixture"].exists)
    let report=albumFixtureReport()
    XCTAssertTrue(report.contains("catalogue=0;permission=0;reads=0"),report)
  }
  func testReadOnlyRecoveredSnapshotCannotBeOverwrittenByAlbumConnection() {
    let id=UUID().uuidString
    launch(["--page","Settings","--persistence-test",id,"--reset-test-store","--state-future-fixture"])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
    openSyntheticAlbumChoices()
    let menu=app.buttons["photos.shared.fixture"]
    scrollPhotoControlFullyIntoView(menu);menu.press(forDuration:1)
    let action=app.buttons["Keep updated on this display"]
    XCTAssertTrue(action.waitForExistence(timeout:5));action.tap()
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout:5))
    app.alerts.buttons["OK"].tap()
    XCTAssertTrue(albumFixtureReport().contains("reads=0"))
    app.terminate()
    launch(["--page","Settings","--persistence-test",id])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists,"The unsupported source must remain untouched")
  }

}

extension HomeViewUITests {
  @objc func testDemoDoorbellDismissReturnsToTheSameFaceAndARepeatedEventDoesNotReopen() {
    launch(["--face","Fade","--doorbell-fixture"])
    tap("fixture.doorbell.repeat")
    XCTAssertTrue(app.staticTexts["doorbell.demo.label"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["fixture.doorbell.route"].label,"face")
    // Prove interaction by the actual dismiss and resulting route below,
    // not by the unreliable hittable flag of the scaled camera button.
    app.otherElements["doorbell.overlay"].swipeLeft()
    XCTAssertTrue(app.staticTexts["doorbell.demo.label"].exists)
    viewportShot("doorbell-demo-over-face")
    tap("doorbell.dismiss")
    XCTAssertFalse(app.staticTexts["doorbell.demo.label"].exists)
    XCTAssertEqual(app.staticTexts["fixture.doorbell.route"].label,"face")
    XCTAssertTrue(app.otherElements["face.Fade"].waitForExistence(timeout:5))
    tap("fixture.doorbell.repeat")
    XCTAssertFalse(app.staticTexts["doorbell.demo.label"].exists)
    tap("fixture.doorbell.new")
    XCTAssertTrue(app.staticTexts["doorbell.demo.label"].waitForExistence(timeout:5))
    tap("doorbell.dismiss")
    XCTAssertTrue(app.otherElements["face.Fade"].exists)
  }
  @objc func testDemoDoorbellPreservesTheRunningTimerAndBlocksUnderlyingControls() {
    launch(["--page","Timers","--doorbell-fixture"])
    tap("timer.start")
    let before=app.staticTexts["timer.countdown"].label
    tap("fixture.doorbell.new")
    XCTAssertTrue(app.staticTexts["doorbell.demo.label"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["fixture.doorbell.route"].label,"app:Timers")
    XCTAssertFalse(app.buttons["timer.pause"].isHittable)
    tap("doorbell.dismiss")
    XCTAssertTrue(app.buttons["timer.pause"].waitForExistence(timeout:5))
    let after=app.staticTexts["timer.countdown"].label
    func seconds(_ value:String)->Int {
      let parts=value.split(separator:":").compactMap { Int($0) }
      XCTAssertEqual(parts.count,2)
      return parts.count == 2 ? parts[0]*60+parts[1]:Int.max
    }
    XCTAssertLessThan(seconds(after),seconds(before))
    XCTAssertTrue(app.buttons["timer.pause"].label.contains("Pause"))
    viewportShot("doorbell-dismiss-running-timer-preserved")
  }
  @objc func testDemoDoorbellKeepsTheCurrentCookingStep() {
    launch(["--screen-recipe","--doorbell-fixture"])
    tap("recipe.start");tap("cooking.next")
    let text=app.staticTexts["cooking.text"].label
    tap("fixture.doorbell.new")
    XCTAssertTrue(app.staticTexts["doorbell.demo.label"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["fixture.doorbell.route"].label,"cooking")
    XCTAssertFalse(app.buttons["cooking.next"].isHittable)
    tap("doorbell.dismiss")
    XCTAssertTrue(app.staticTexts["cooking.text"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["cooking.text"].label,text)
    viewportShot("doorbell-dismiss-cooking-step-preserved")
  }
  @objc func testDemoDoorbellDoesNotHideATimerCompletion() {
    launch(["--page","Timers","--doorbell-fixture"])
    tap("timer.start");tap("fixture.doorbell.new")
    XCTAssertTrue(app.staticTexts["doorbell.demo.label"].waitForExistence(timeout:5))
    tap("fixture.doorbell.finishTimer")
    XCTAssertTrue(app.staticTexts["15 min finished"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["doorbell.demo.label"].exists)
    viewportShot("doorbell-with-visible-timer-completion")
    tap("doorbell.dismiss")
    XCTAssertTrue(app.staticTexts["DONE"].waitForExistence(timeout:5))
  }
  @objc func testDemoDoorbellBackgroundDoesNotRestoreTheOldPersonalPage() {
    launch(["--page","Calendar","--doorbell-fixture"])
    tap("fixture.doorbell.new")
    XCTAssertTrue(app.staticTexts["doorbell.demo.label"].waitForExistence(timeout:5))
    XCUIDevice.shared.press(.home);app.activate()
    XCTAssertTrue(app.staticTexts["Recognizing…"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["doorbell.demo.label"].exists)
    XCTAssertFalse(app.buttons["calendar.day.3"].exists)
    viewportShot("doorbell-background-personal-page-stays-locked")
  }
  @objc func testDemoDoorbellOfflineAndIncomingCallDoNotOpenACamera() {
    launch(["--doorbell-fixture"])
    tap("fixture.doorbell.offline");tap("fixture.doorbell.new")
    XCTAssertFalse(app.staticTexts["doorbell.demo.label"].exists)
    XCTAssertTrue(app.staticTexts["Demo doorbell unavailable · Mock camera offline"].exists)
    launch(["--doorbell-fixture"])
    tap("fixture.doorbell.call");tap("fixture.doorbell.new")
    XCTAssertTrue(app.buttons["call.end"].exists)
    XCTAssertFalse(app.staticTexts["doorbell.demo.label"].exists)
    viewportShot("doorbell-does-not-cover-incoming-demo-call")
    tap("call.end")
    XCTAssertFalse(app.staticTexts["doorbell.demo.label"].exists)
  }
}

extension HomeViewUITests {
  func verifyCalendarFace(header:String,day:Int,selectedCell:Int,grid:[Int],name:String) {
    XCTAssertEqual(grid.count,42)
    XCTAssertTrue(app.staticTexts[header].waitForExistence(timeout:5))
    let selected=app.staticTexts["calendar.face.selected"]
    XCTAssertEqual(selected.label,String(day))
    XCTAssertEqual(selected.value as? String,"Today")
    let viewport=app.otherElements["reference.viewport"].frame.insetBy(dx:8,dy:8)
    for i in 0..<42 {
      let cell=i == selectedCell ? selected:app.staticTexts["calendar.face.cell.\(i)"]
      XCTAssertTrue(cell.exists,"Missing cell \(i)")
      XCTAssertEqual(cell.label,String(grid[i]),"Wrong date in cell \(i)")
      XCTAssertTrue(viewport.contains(cell.frame),"Clipped date in cell \(i)")
    }
    viewportShot(name)
  }
  @objc func testCalendarReferenceMonthKeepsTheObservedSixRowsAndToday() {
    launch(["--face","Calendar"])
    verifyCalendarFace(header:"April 2026",day:1,selectedCell:3,grid:[
      29,30,31,1,2,3,4, 5,6,7,8,9,10,11, 12,13,14,15,16,17,18,
      19,20,21,22,23,24,25, 26,27,28,29,30,1,2, 3,4,5,6,7,8,9],
      name:"calendar-reference-april2026")
  }
  @objc func testCalendarLeapDayAndSixWeekMonthKeepAllDatesVisible() {
    launch(["--face","Calendar","--reference-date","2024-02-29T12:00:00Z"])
    verifyCalendarFace(header:"February 2024",day:29,selectedCell:32,grid:[
      28,29,30,31,1,2,3, 4,5,6,7,8,9,10, 11,12,13,14,15,16,17,
      18,19,20,21,22,23,24, 25,26,27,28,29,1,2, 3,4,5,6,7,8,9],
      name:"calendar-leap-day-february2024")
    launch(["--face","Calendar","--reference-date","2026-08-31T12:00:00Z"])
    verifyCalendarFace(header:"August 2026",day:31,selectedCell:36,grid:[
      26,27,28,29,30,31,1, 2,3,4,5,6,7,8, 9,10,11,12,13,14,15,
      16,17,18,19,20,21,22, 23,24,25,26,27,28,29, 30,31,1,2,3,4,5],
      name:"calendar-six-week-august2026")
  }
  @objc func testCalendarYearBoundaryFollowsTheChosenTimeZoneNotUTC() {
    let instant="2026-12-31T23:30:00Z"
    launch(["--face","Calendar","--reference-date",instant,"--reference-zone","America/Los_Angeles"])
    verifyCalendarFace(header:"December 2026",day:31,selectedCell:32,grid:[
      29,30,1,2,3,4,5, 6,7,8,9,10,11,12, 13,14,15,16,17,18,19,
      20,21,22,23,24,25,26, 27,28,29,30,31,1,2, 3,4,5,6,7,8,9],
      name:"calendar-local-december31-los-angeles")
    launch(["--face","Calendar","--reference-date",instant,"--reference-zone","Pacific/Kiritimati"])
    verifyCalendarFace(header:"January 2027",day:1,selectedCell:5,grid:[
      27,28,29,30,31,1,2, 3,4,5,6,7,8,9, 10,11,12,13,14,15,16,
      17,18,19,20,21,22,23, 24,25,26,27,28,29,30, 31,1,2,3,4,5,6],
      name:"calendar-local-january1-kiritimati")
  }
  @objc func testCalendarAgendaSelectionDoesNotChangeTheFacesLocalToday() {
    launch(["--face","Calendar","--page","Calendar",
      "--reference-date","2026-12-31T23:30:00Z","--reference-zone","Pacific/Kiritimati"])
    XCTAssertTrue(app.staticTexts["January"].waitForExistence(timeout:5))
    XCTAssertEqual(app.buttons["calendar.day.5"].value as? String,"Selected")
    tap("calendar.day.0")
    XCTAssertEqual(app.buttons["calendar.day.0"].value as? String,"Selected")
    XCTAssertNotEqual(app.buttons["calendar.day.5"].value as? String,"Selected")
    viewportShot("calendar-agenda-local-year-boundary-selection")
    tap("nav.faces")
    XCTAssertEqual(app.staticTexts["calendar.face.selected"].label,"1")
    XCTAssertEqual(app.staticTexts["calendar.face.selected"].value as? String,"Today")
    XCTAssertTrue(app.staticTexts["January 2027"].exists)
    viewportShot("calendar-face-keeps-local-today-after-agenda-navigation")
  }
}

extension HomeViewUITests {
  private func verifyWeatherFaceBounds(temperature:String,wind:String,humidity:String,aqi:String,name:String) {
    let root=app.otherElements["reference.viewport"]
    XCTAssertTrue(root.waitForExistence(timeout:5))
    let safe=root.frame.insetBy(dx:8,dy:8)
    let clock=app.staticTexts["weather.face.clock"],number=app.staticTexts["weather.temperature"]
    XCTAssertTrue(clock.exists)
    XCTAssertEqual(number.label,temperature)
    XCTAssertTrue(safe.contains(clock.frame),"Clock must remain inside the native face")
    XCTAssertTrue(safe.contains(number.frame),"Temperature must remain inside the native face")
    XCTAssertLessThan(clock.frame.maxY,number.frame.minY,"Clock and temperature must not overlap")
    for (label,value) in [("Sunset",nil),("Wind",Optional(wind)),("Humidity",Optional(humidity)),("AQI",Optional(aqi))] {
      let detail=app.staticTexts["weather.detail."+label]
      XCTAssertTrue(detail.exists)
      if let value { XCTAssertEqual(detail.label,value) }
      XCTAssertTrue(safe.contains(detail.frame),"Clipped metric "+label)
      XCTAssertTrue(safe.contains(app.staticTexts[label].frame),"Clipped caption "+label)
    }
    viewportShot(name)
  }
  @objc func testWeatherFaceMetricsFitDemoCelsiusAndUnknownValues() {
    launch(["--face","Weather"])
    verifyWeatherFaceBounds(temperature:"54°",wind:"7 mph",humidity:"76%",aqi:"21",
      name:"weather-ui05-demo-bounds")
    launch(["--face","Weather","--page","Settings"])
    connectService("Weather")
    let celsius=app.segmentedControls["weather.units"].buttons["°C / km/h"]
    XCTAssertTrue(celsius.waitForExistence(timeout:5))
    for _ in 0..<8 where !celsius.isHittable
      || celsius.frame.maxY > app.otherElements["reference.viewport"].frame.maxY - 45 {
      app.scrollViews.firstMatch.swipeUp()
    }
    celsius.tap()
    XCTAssertTrue(celsius.isSelected)
    tap("nav.faces")
    XCTAssertTrue(app.staticTexts["weather.source"].label.contains("°C / km/h"))
    verifyWeatherFaceBounds(temperature:"13°",wind:"13 km/h",humidity:"70%",aqi:"—",
      name:"weather-ui05-connected-celsius-bounds")
    launch(["--face","Weather","--page","Settings","--weather-missing"])
    connectService("Weather");tap("nav.faces")
    XCTAssertFalse(app.staticTexts["weather.source"].label.hasPrefix("Demo"))
    verifyWeatherFaceBounds(temperature:"—",wind:"—",humidity:"—",aqi:"—",
      name:"weather-ui05-unknown-values-bounds")
  }
}

extension HomeViewUITests {

  private func assertTimerVisibleGlyphSeparation(_ data:Data) {
    let image=UIImage(data:data)!.cgImage!,width=imageWidth(data),height=imageHeight(data)
    var pixels=[UInt8](repeating:0,count:width*height*4)
    pixels.withUnsafeMutableBytes {
      let context=CGContext(data:$0.baseAddress,width:width,height:height,bitsPerComponent:8,
        bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),
        bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
      context.draw(image,in:CGRect(x:0,y:0,width:width,height:height))
    }
    // Fixed central readout ROI excludes the orange perimeter and hidden controls.
    // Test actual white/orange glyphs, not overlapping font-layout rectangles.
    var whiteMaxY = -1,orangeMinY = height,whiteCount=0,orangeCount=0
    for y in (height*28/100)..<(height*70/100) {
      for x in (width*12/100)..<(width*88/100) {
        let i=(y*width+x)*4,r=Int(pixels[i]),g=Int(pixels[i+1]),b=Int(pixels[i+2])
        if r>235 && g>235 && b>235 { whiteMaxY=max(whiteMaxY,y);whiteCount+=1 }
        if x>width/4 && x<width*3/4 && y>height*45/100
          && r>200 && g>55 && g<210 && b<110 {
          orangeMinY=min(orangeMinY,y);orangeCount+=1
        }
      }
    }
    XCTAssertGreaterThan(whiteCount,0)
    XCTAssertGreaterThan(orangeCount,0)
    XCTAssertLessThan(whiteMaxY,orangeMinY,"Rendered white countdown and orange title must be separated")
  }
  private func imageWidth(_ data:Data) -> Int { UIImage(data:data)!.cgImage!.width }
  private func imageHeight(_ data:Data) -> Int { UIImage(data:data)!.cgImage!.height }
  private func verifyTimerReadoutBounds(value:String,title:String,name:String) {
    let countdown=app.staticTexts["timer.countdown"],caption=app.staticTexts["timer.title"]
    XCTAssertTrue(countdown.waitForExistence(timeout:5))
    XCTAssertEqual(countdown.label,value)
    XCTAssertEqual(caption.label,title)
    viewportShot(name)
    let frame=app.otherElements["reference.viewport"].frame
    let inner=frame.insetBy(dx:frame.width*0.15,dy:12)
    XCTAssertTrue(inner.contains(countdown.frame),"Countdown must stay clear of perimeter ticks")
    XCTAssertTrue(inner.contains(caption.frame),"Timer caption must stay inside the dial")
    XCTAssertLessThan(countdown.frame.midY,caption.frame.midY,"Readout must precede the title")
    assertTimerVisibleGlyphSeparation(viewportBytes("glyph-proof-"+name))
  }
  @objc func testRestingTimerReferenceFitsAndTouchRevealsItsRealControls() {
    launch(["--reference-timer","--reference-resting"])
    XCTAssertFalse(app.buttons["timer.pause"].exists)
    verifyTimerReadoutBounds(value:"10:56",title:"15 MIN",name:"timer-ui14-reference-resting")
    let frame=app.staticTexts["timer.countdown"].frame
    app.coordinate(withNormalizedOffset:.zero)
      .withOffset(CGVector(dx:frame.midX-app.frame.minX,dy:frame.midY-app.frame.minY)).tap()
    XCTAssertTrue(app.buttons["Resume timer"].waitForExistence(timeout:3))
    XCTAssertEqual(app.staticTexts["timer.countdown"].label,"10:56")
    viewportShot("timer-ui14-reference-controls-revealed")
  }
  @objc func testLongTimerReadoutFitsWithoutChangingItsPausedValue() {
    launch(["--reference-timer","--reference-timer-long","--reference-resting"])
    verifyTimerReadoutBounds(value:"23:59:59",title:"24 HOURS",name:"timer-ui14-long-readout")
    XCTAssertFalse(app.buttons["timer.pause"].exists)
    let frame=app.staticTexts["timer.countdown"].frame
    app.coordinate(withNormalizedOffset:.zero)
      .withOffset(CGVector(dx:frame.midX-app.frame.minX,dy:frame.midY-app.frame.minY)).tap()
    XCTAssertTrue(app.buttons["Resume timer"].waitForExistence(timeout:3))
    XCTAssertEqual(app.staticTexts["timer.countdown"].label,"23:59:59")
    tap("timer.delete")
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5))
  }
}

extension HomeViewUITests {
  private func flowBodyRGBA(_ data:Data) -> ([UInt8],Int,Int) {
    let image=UIImage(data:data)!.cgImage!,width=image.width,height=image.height
    var pixels=[UInt8](repeating:0,count:width*height*4)
    pixels.withUnsafeMutableBytes {
      let context=CGContext(data:$0.baseAddress,width:width,height:height,bitsPerComponent:8,
        bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),
        bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
      context.draw(image,in:CGRect(x:0,y:0,width:width,height:height))
    }
    return (pixels,width,height)
  }
  private func fixedFlowBodyPixels(_ data:Data,mask:Data) -> Data {
    let (pixels,width,height)=flowBodyRGBA(data)
    let (m,mw,mh)=flowBodyRGBA(mask)
    XCTAssertEqual(width,mw);XCTAssertEqual(height,mh)
    guard width==mw && height==mh else { return Data() }
    let radius=max(1,width*2/100)
    let offsets=[(0,0),(-radius,0),(radius,0),(0,-radius),(0,radius),
      (-radius,-radius),(-radius,radius),(radius,-radius),(radius,radius)]
    var interior=[UInt8]()
    for y in stride(from:radius,to:height-radius,by:2) {
      for x in stride(from:radius,to:width-radius,by:2) {
        let inside=offsets.allSatisfy { dx,dy in
          let i=((y+dy)*width+x+dx)*4
          return m[i]>245 && m[i+1]>245 && m[i+2]>245
        }
        if inside {
          let i=(y*width+x)*4
          interior.append(contentsOf:pixels[i..<(i+4)])
        }
      }
    }
    XCTAssertGreaterThan(interior.count,1000,"The own eroded mask must contain actual glyph interiors")
    return Data(interior)
  }
  @objc func testFlowGlassBodyMovesAfterThirtySecondsWithFixedGlyphs() {
    launch(["--face","Flow","--animation-test","--flow-fixed-glyphs"])
    Thread.sleep(forTimeInterval:30)
    let late=viewportBytes("flow-fixed-body-after-thirty-seconds")
    Thread.sleep(forTimeInterval:1.2)
    let later=viewportBytes("flow-fixed-body-after-thirty-two-seconds")
    launch(["--face","Flow","--flow-fixed-glyphs","--reduce-motion"])
    let frozen=viewportBytes("flow-fixed-body-reduced-start")
    Thread.sleep(forTimeInterval:1.2)
    let frozenLater=viewportBytes("flow-fixed-body-reduced-later")
    launch(["--face","Flow","--flow-fixed-glyphs","--flow-mask"])
    let mask=viewportBytes("flow-fixed-body-own-mask")
    XCTAssertNotEqual(fixedFlowBodyPixels(late,mask:mask),fixedFlowBodyPixels(later,mask:mask),
      "Moving fluid must change pixels inside fixed glyph bodies, not merely the background")
    XCTAssertEqual(fixedFlowBodyPixels(frozen,mask:mask),fixedFlowBodyPixels(frozenLater,mask:mask))
  }
}

extension HomeViewUITests {
  @objc func testFlowNativeSolidStyleAndWholeViewportNightTreatment() {
    launch(["--face","Flow"])
    app.otherElements["face.Flow"].press(forDuration:1)
    tap("flow.typeface.1")
    XCTAssertEqual(app.switches["flow.background"].value as? String,"1")
    tap("editor.done")
    viewportShot("flow-native-solid-background-on")
    tap("nav.controls");tap("controls.night");tap("nav.faces")
    let pixels=[UInt8](viewportPixels(viewportBytes("flow-native-solid-night-whole-viewport"),inset:0))
    var lit=0,wrongColor=0
    for i in stride(from:0,to:pixels.count,by:4) {
      let r=Double(pixels[i]),g=Double(pixels[i+1]),b=Double(pixels[i+2])
      if max(r,max(g,b))>25 {
        lit+=1
        if g>r*0.4 || b>r*0.4 { wrongColor+=1 }
      }
    }
    XCTAssertGreaterThan(lit,100)
    XCTAssertEqual(wrongColor,0,"Native lenses and fluid must remain within the whole-viewport night treatment")
  }
}

extension HomeViewUITests {
  @objc func testTimerControlsHideAfterRealIdleAndTouchRestartsTheDeadline() {
    launch(["--reference-timer","--timer-idle-test"])
    let pause=app.buttons["timer.pause"],countdown=app.staticTexts["timer.countdown"]
    XCTAssertTrue(countdown.waitForExistence(timeout:5))
    XCTAssertEqual(countdown.label,"10:56")
    expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:pause)
    waitForExpectations(timeout:8)
    XCTAssertFalse(app.buttons["timer.delete"].exists)
    viewportShot("timer-idle-first-hidden")
    let frame=countdown.frame
    let timeTouch=app.coordinate(withNormalizedOffset:.zero).withOffset(
      CGVector(dx:frame.midX-app.frame.minX,dy:frame.midY-app.frame.minY))
    timeTouch.tap()
    XCTAssertTrue(pause.waitForExistence(timeout:3))
    XCTAssertEqual(pause.label,"Resume timer")
    Thread.sleep(forTimeInterval:2.8)
    XCTAssertTrue(pause.exists)
    timeTouch.tap()
    Thread.sleep(forTimeInterval:2.3)
    // More than five seconds after the first reveal, but fewer than four since
    // the second real touch: a mere one-shot show timer would already have hidden.
    XCTAssertTrue(pause.exists)
    XCTAssertEqual(countdown.label,"10:56")
    viewportShot("timer-idle-touch-reset-visible")
    expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:pause)
    waitForExpectations(timeout:8)
    XCTAssertEqual(countdown.label,"10:56")
    XCTAssertFalse(app.buttons["timer.delete"].exists)
    viewportShot("timer-idle-hidden-again")
    timeTouch.tap()
    XCTAssertTrue(pause.waitForExistence(timeout:3))
    tap("timer.delete")
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5))
    viewportShot("timer-idle-delete-returns-setup")
  }
}

extension HomeViewUITests {
  @objc func testRunningTimerContinuesWithHiddenControlsAndPausesAfterTouch() {
    launch(["--page","Timers","--timer-idle-test"])
    tap("timer.start")
    let countdown=app.staticTexts["timer.countdown"],pause=app.buttons["timer.pause"]
    XCTAssertTrue(countdown.waitForExistence(timeout:5))
    func seconds(_ text:String) -> Int {
      let fields=text.split(separator:":").compactMap { Int($0) }
      XCTAssertTrue(fields.count==2 || fields.count==3)
      return fields.reduce(0) { $0*60+$1 }
    }
    let before=seconds(countdown.label)
    expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:pause)
    waitForExpectations(timeout:8)
    let hidden=seconds(countdown.label)
    XCTAssertGreaterThan(hidden,0)
    XCTAssertLessThan(hidden,before,"The countdown must keep running while controls are hidden")
    viewportShot("timer-idle-running-hidden")
    let frame=countdown.frame
    app.coordinate(withNormalizedOffset:.zero).withOffset(
      CGVector(dx:frame.midX-app.frame.minX,dy:frame.midY-app.frame.minY)).tap()
    XCTAssertTrue(pause.waitForExistence(timeout:3))
    tap("timer.pause")
    XCTAssertTrue(app.buttons["Resume timer"].exists)
    let frozen=countdown.label
    Thread.sleep(forTimeInterval:1.5)
    XCTAssertEqual(countdown.label,frozen)
    viewportShot("timer-idle-running-then-paused")
    // A screenshot can consume most of the four-second visibility window.
    // Reveal again before the actual delete action, as a person would.
    let visibleFrame=countdown.frame
    app.coordinate(withNormalizedOffset:.zero).withOffset(
      CGVector(dx:visibleFrame.midX-app.frame.minX,dy:visibleFrame.midY-app.frame.minY)).tap()
    tap("timer.delete")
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5))
  }
}

extension HomeViewUITests {
  private func timerChoice(_ number:Int) -> XCUIElement {
    app.buttons[String(format:"timer.select.00000000-0000-0000-0000-%012d",number)]
  }
  private func verifyTimerChoice(_ number:Int,title:String,value:String?=nil) {
    XCTAssertEqual(app.staticTexts["timer.title"].label,title)
    if let value { XCTAssertEqual(app.staticTexts["timer.countdown"].label,value) }
    XCTAssertEqual(timerChoice(number).value as? String,"Selected")
    let choices=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","timer.select."))
    let selected=(0..<choices.count).filter { choices.element(boundBy:$0).value as? String == "Selected" }
    XCTAssertEqual(selected.count,1)
    let caption=app.staticTexts["timer.title"],status=app.staticTexts["timer.systemStatus"]
    XCTAssertGreaterThan(status.frame.minY,caption.frame.maxY,"Status must not cover the timer title")
    let viewport=app.otherElements["reference.viewport"].frame
    for i in 0..<choices.count {
      let frame=choices.element(boundBy:i).frame
      XCTAssertTrue(viewport.contains(frame))
      XCTAssertGreaterThan(frame.minY,viewport.minY+viewport.height*0.9,"Choices must stay below perimeter ticks")
    }
  }
  private func captureTimerChoices(_ state:String) {
    for number in [101,102,103] where timerChoice(number).exists {
      let attachment=XCTAttachment(data:timerChoice(number).screenshot().pngRepresentation,
        uniformTypeIdentifier:"public.png")
      attachment.name="timer-chip-"+state+"-"+String(number)
      attachment.lifetime = .keepAlways;add(attachment)
    }
  }
  private func timerSelectionSeconds() -> Int {
    let parts=app.staticTexts["timer.countdown"].label.split(separator:":").compactMap { Int($0) }
    XCTAssertTrue(parts.count==2 || parts.count==3)
    return parts.reduce(0) { $0*60+$1 }
  }
  @objc func testMultipleTimerFallbackAndDeletionKeepTheDisplayedChoice() {
    launch(["--multiple-timers-fixture"])
    verifyTimerChoice(103,title:"BREAD",value:"10:00")
    viewportShot("timer-selection-restored-fallback")
    captureTimerChoices("restored")
    timerChoice(101).tap()
    verifyTimerChoice(101,title:"TEA",value:"03:00")
    viewportShot("timer-selection-tea")
    captureTimerChoices("tea")
    tap("timer.delete")
    XCTAssertFalse(timerChoice(101).exists)
    verifyTimerChoice(103,title:"BREAD",value:"10:00")
    viewportShot("timer-selection-after-delete-fallback")
    captureTimerChoices("deleted")
    timerChoice(102).tap()
    verifyTimerChoice(102,title:"PASTA",value:"08:00")
    viewportShot("timer-selection-pasta-preserved")
    captureTimerChoices("pasta")
  }
  @objc func testMultipleTimersRunAndPauseIndependently() {
    launch(["--multiple-timers-fixture"])
    timerChoice(101).tap();tap("timer.pause")
    XCTAssertEqual(app.buttons["timer.pause"].label,"Pause timer")
    expectation(for:NSPredicate(format:"label != %@","03:00"),evaluatedWith:app.staticTexts["timer.countdown"])
    waitForExpectations(timeout:6)
    XCTAssertLessThan(timerSelectionSeconds(),180)
    XCTAssertGreaterThan(timerSelectionSeconds(),0)
    timerChoice(103).tap()
    verifyTimerChoice(103,title:"BREAD",value:"10:00")
    XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
    timerChoice(102).tap();tap("timer.pause")
    XCTAssertEqual(app.buttons["timer.pause"].label,"Pause timer")
    expectation(for:NSPredicate(format:"label != %@","08:00"),evaluatedWith:app.staticTexts["timer.countdown"])
    waitForExpectations(timeout:6)
    XCTAssertLessThan(timerSelectionSeconds(),480)
    viewportShot("timer-selection-pasta-running-with-tea")
    timerChoice(101).tap();tap("timer.pause")
    let tea=app.staticTexts["timer.countdown"].label
    XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
    viewportShot("timer-selection-tea-paused")
    timerChoice(102).tap()
    XCTAssertEqual(app.buttons["timer.pause"].label,"Pause timer")
    let pasta=timerSelectionSeconds()
    let pastaLabel=app.staticTexts["timer.countdown"].label
    expectation(for:NSPredicate(format:"label != %@",pastaLabel),evaluatedWith:app.staticTexts["timer.countdown"])
    waitForExpectations(timeout:6)
    XCTAssertLessThan(timerSelectionSeconds(),pasta)
    tap("timer.pause")
    timerChoice(103).tap()
    verifyTimerChoice(103,title:"BREAD",value:"10:00")
    timerChoice(101).tap()
    verifyTimerChoice(101,title:"TEA",value:tea)
    viewportShot("timer-selection-tea-still-paused")
  }
}

extension HomeViewUITests {
  private var timerChoicesContainer:XCUIElement {
    app.descendants(matching:.any).matching(identifier:"timer.choices").firstMatch
  }
  private func axContains(_ outer:CGRect,_ inner:CGRect) -> Bool {
    // Observed AX target coordinates have Float32 rounding. Compare both
    // rectangles at that precision instead of inventing sub-AX differences.
    Float(inner.minX)>=Float(outer.minX) && Float(inner.minY)>=Float(outer.minY)
      && Float(inner.maxX)<=Float(outer.maxX) && Float(inner.maxY)<=Float(outer.maxY)
  }
  private func timerChoiceIsVisible(_ element:XCUIElement) -> Bool {
    guard element.exists,!element.frame.isEmpty else { return false }
    let viewport=app.otherElements["reference.viewport"].frame
    // Match the existing 40pt content padding, keeping the choice away from
    // the rounded display corner rather than accepting a merely clipped AX box.
    return axContains(viewport.insetBy(dx:viewport.width*40/600,dy:0),element.frame)
  }
  private func dragTimerChoices(left:Bool) {
    let row=timerChoicesContainer.frame
    let viewport=app.otherElements["reference.viewport"].frame
    let native=app.scrollViews.firstMatch.frame
    let report=XCTAttachment(string:"group=\(row) viewport=\(viewport) nativeScroll=\(native)")
    report.name="timer-overflow-scroll-frames";report.lifetime = .keepAlways;add(report)
    // This also normalizes the earlier x=11.999999999999991 vs x=12 report.
    XCTAssertTrue(axContains(viewport,row),
      "group=\(row), viewport=\(viewport), nativeScroll=\(native)")
    XCTAssertLessThan(row.height,viewport.height*0.12)
    let visibleRow=row.intersection(viewport)
    let x0=visibleRow.minX+visibleRow.width*(left ? 0.8:0.2)
    let x1=visibleRow.minX+visibleRow.width*(left ? 0.2:0.8)
    let origin=app.coordinate(withNormalizedOffset:.zero)
    origin.withOffset(CGVector(dx:x0-app.frame.minX,dy:visibleRow.midY-app.frame.minY))
      .press(forDuration:0.1,thenDragTo:origin.withOffset(
        CGVector(dx:x1-app.frame.minX,dy:visibleRow.midY-app.frame.minY)),withVelocity:.slow,thenHoldForDuration:0.2)
  }
  private func revealTimerChoice(_ element:XCUIElement,left:Bool) {
    for _ in 0..<8 where !timerChoiceIsVisible(element) { dragTimerChoices(left:left) }
    let viewport=app.otherElements["reference.viewport"].frame
    let report=XCTAttachment(string:"target=\(element.frame) viewport=\(viewport) safe=\(viewport.insetBy(dx:viewport.width*40/600,dy:0)) row=\(timerChoicesContainer.frame)")
    report.name="timer-overflow-target-frame";report.lifetime = .keepAlways;add(report)
    XCTAssertTrue(timerChoiceIsVisible(element),"target=\(element.frame), viewport=\(viewport), safe=\(viewport.insetBy(dx:viewport.width*40/600,dy:0))")
  }
  private func touchTimerChoice(_ element:XCUIElement) {
    XCTAssertTrue(timerChoiceIsVisible(element))
    let frame=element.frame
    app.coordinate(withNormalizedOffset:.zero).withOffset(
      CGVector(dx:frame.midX-app.frame.minX,dy:frame.midY-app.frame.minY)).tap()
  }
  private func verifyTimerLimitAlert() {
    tap("Add another timer")
    let alert=app.alerts["HomeView"]
    XCTAssertTrue(alert.waitForExistence(timeout:4))
    XCTAssertTrue(alert.staticTexts["Choose 1 second to 24 hours, up to 12 timers."].exists)
    alert.buttons["OK"].tap()
    XCTAssertEqual(timerChoicesContainer.value as? String,"12 timers")
  }
  private func captureVisibleTimerChoice(_ element:XCUIElement,state:String) {
    XCTAssertTrue(timerChoiceIsVisible(element))
    let attachment=XCTAttachment(data:element.screenshot().pngRepresentation,uniformTypeIdentifier:"public.png")
    attachment.name="timer-overflow-chip-"+state;attachment.lifetime = .keepAlways;add(attachment)
  }
  @objc func testTwelveTimerHorizontalSelectionDeletionAndLimit() {
    launch(["--timer-overflow-fixture"])
    XCTAssertTrue(timerChoicesContainer.waitForExistence(timeout:5))
    XCTAssertEqual(timerChoicesContainer.value as? String,"12 timers")
    XCTAssertEqual(app.staticTexts["timer.title"].label,"TIMER 12")
    XCTAssertEqual(app.staticTexts["timer.countdown"].label,"12:00")
    revealTimerChoice(timerChoice(212),left:true)
    XCTAssertEqual(timerChoice(212).value as? String,"Selected")
    viewportShot("timer-overflow-last-visible")
    captureVisibleTimerChoice(timerChoice(212),state:"last")
    revealTimerChoice(timerChoice(201),left:false)
    touchTimerChoice(timerChoice(201))
    XCTAssertEqual(app.staticTexts["timer.countdown"].label,"01:00")
    XCTAssertEqual(timerChoice(201).value as? String,"Selected")
    viewportShot("timer-overflow-first-selected")
    captureVisibleTimerChoice(timerChoice(201),state:"first")
    revealTimerChoice(timerChoice(206),left:true)
    touchTimerChoice(timerChoice(206))
    XCTAssertEqual(app.staticTexts["timer.countdown"].label,"06:00")
    verifyTimerLimitAlert()
    XCTAssertEqual(app.staticTexts["timer.countdown"].label,"06:00")
    XCTAssertEqual(timerChoice(206).value as? String,"Selected")
    viewportShot("timer-overflow-thirteenth-rejected")
    captureVisibleTimerChoice(timerChoice(206),state:"middle")
    revealTimerChoice(timerChoice(212),left:true)
    touchTimerChoice(timerChoice(212));tap("timer.delete")
    XCTAssertEqual(timerChoicesContainer.value as? String,"11 timers")
    XCTAssertFalse(timerChoice(212).exists)
    XCTAssertEqual(app.staticTexts["timer.countdown"].label,"11:00")
    revealTimerChoice(timerChoice(211),left:true)
    XCTAssertEqual(timerChoice(211).value as? String,"Selected")
    viewportShot("timer-overflow-delete-last-fallback")
    captureVisibleTimerChoice(timerChoice(211),state:"delete-fallback")
  }
  @objc func testNormalAddsReachTwelveAndRejectThirteen() {
    launch(["--page","Timers"])
    tap("timer.start")
    for _ in 0..<11 { tap("Add another timer") }
    XCTAssertEqual(timerChoicesContainer.value as? String,"12 timers")
    let choices=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@ AND value == %@","timer.select.","Selected"))
    let selected=choices.firstMatch
    revealTimerChoice(selected,left:true)
    XCTAssertEqual(choices.count,1)
    let id=selected.identifier
    viewportShot("timer-overflow-twelve-normal-adds")
    verifyTimerLimitAlert()
    XCTAssertEqual(choices.count,1)
    XCTAssertEqual(choices.firstMatch.identifier,id)
    XCTAssertEqual(app.staticTexts["timer.title"].label,"15 MIN")
    viewportShot("timer-overflow-normal-add-limit-preserved")
  }
}
