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
    tap("camera.0")
    shot("UI34-camera-detail")
    tap("camera.talk")
    XCTAssertTrue(
      app.staticTexts["Mock talkback active · No microphone used"].waitForExistence(timeout: 3))
    tap("camera.grid")
    XCTAssertTrue(app.buttons["camera.0"].waitForExistence(timeout: 3))
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
    tap("grid.entrylight")
    shot("UI13-home-grid")
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
    for _ in 0..<8 where !button.isHittable { app.scrollViews.firstMatch.swipeUp() }
    button.tap()
    XCTAssertTrue(app.otherElements["face.Photos"].waitForExistence(timeout: 8))
    XCTAssertTrue(app.staticTexts["PHOTOS"].exists)
    shot("native-demo-photo-face")
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
    for _ in 0..<10 where !button.isHittable { app.scrollViews.firstMatch.swipeUp() }
    button.tap()
    let caption = app.staticTexts["photo.index"]
    XCTAssertTrue(caption.waitForExistence(timeout: 8))
    let original = caption.label
    XCTAssertTrue(original.contains("OF 2"))
    expectation(for: NSPredicate(format: "label != %@", original), evaluatedWith: caption)
    waitForExpectations(timeout: 7)
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
    XCTAssertNotEqual(late, viewportBytes("flow-material-after-thirty-two-seconds"))
  }
  func testNativeFlowMovesAndReducedMotionStaysStill() {
    launch(["--face", "Flow", "--animation-test"])
    let first = viewportBytes("flow-moving-start")
    Thread.sleep(forTimeInterval: 1.2)
    XCTAssertNotEqual(first, viewportBytes("flow-moving-later"))
    app.terminate()
    launch(["--face", "Flow", "--animation-test", "--reduce-motion"])
    let frozen = viewportBytes("flow-reduced-start")
    Thread.sleep(forTimeInterval: 1.2)
    XCTAssertEqual(frozen, viewportBytes("flow-reduced-later"))
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
    let load = app.buttons["photos.shared.load"]
    for _ in 0..<24 where !load.isHittable { app.scrollViews.firstMatch.swipeUp() }
    load.tap()
    tap("photos.shared.fixture")
    XCTAssertTrue(app.staticTexts["photo.index"].waitForExistence(timeout: 8))
    XCTAssertTrue(app.staticTexts["photo.index"].label.contains("OF 2"))
    shot("connected-shared-album-fixture")
  }

}
