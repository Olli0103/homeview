import CoreGraphics
import UIKit
import XCTest

extension HomeViewUITests {
  func testIsolatedSyntheticNativePhotosPickerPresentationInventory() throws {
    #if targetEnvironment(simulator)
    continueAfterFailure=false;executionTimeAllowance=180
    let environment=ProcessInfo.processInfo.environment
    let deviceName=environment["SIMULATOR_DEVICE_NAME"] ?? "",deviceID=environment["SIMULATOR_UDID"] ?? ""
    let identity=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:["device_name":deviceName,"device_id":deviceID,
      "scope":"Only a newly created named synthetic-photo simulator may open the native picker. No existing personal library."],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    identity.name="native-photos-isolated-runtime";identity.lifetime = .keepAlways;add(identity)
    try requireIsolatedSyntheticPhotoSimulator()
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    let choose=app.buttons.matching(NSPredicate(format:"label CONTAINS %@","Choose Photos")).firstMatch
    scrollPhotoControlFullyIntoView(choose)
    shot("native-photos-picker-before-opening")
    choose.tap()
    let cancel=app.buttons["Cancel"].firstMatch
    let found=cancel.waitForExistence(timeout:15)
    let loading=app.staticTexts["Loading…"].firstMatch
    let settled=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:loading)
    let settledResult=XCTWaiter.wait(for:[settled],timeout:45)
    let presented=XCUIScreen.main.screenshot()
    let pixels=[UInt8](viewportPixels(presented.pngRepresentation,inset:0));var magenta=0,cyan=0
    for i in stride(from:0,to:pixels.count,by:4) {
      let r=pixels[i],g=pixels[i+1],b=pixels[i+2]
      if r>180 && g<100 && b>160 {magenta+=1}
      if r<100 && g>150 && b>150 {cyan+=1}
    }
    let content=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:["magenta_pixels":magenta,"cyan_pixels":cyan,
      "minimum_each":1000,"loading_disappeared":settledResult == .completed,
      "scope":"Positive visibility of the owned magenta/cyan fixture; no selection made. Actual saved image review also required."],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    content.name="native-photos-presented-canary";content.lifetime = .keepAlways;add(content)
    let tree=XCTAttachment(string:app.debugDescription);tree.name="native-photos-picker-presented-hierarchy";tree.lifetime = .keepAlways;add(tree)
    shot("native-photos-picker-presented")
    guard found else {XCTFail("Native picker cancel target not identified; no system capability absence inferred");return}
    cancel.tap()
    let gone=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:cancel)
    XCTAssertEqual(XCTWaiter.wait(for:[gone],timeout:8),.completed)
    XCTAssertTrue(choose.exists);XCTAssertTrue(choose.isHittable)
    shot("native-photos-picker-cancelled-no-selection")
    XCTAssertEqual(settledResult,.completed,"Keep a loading-only presentation distinct from a populated picker")
    XCTAssertGreaterThan(magenta,1000,"Synthetic fixture must actually be visible before privacy acceptance")
    XCTAssertGreaterThan(cyan,1000,"Both checkerboard colors must actually be visible")
    #else
    XCTFail("Synthetic PhotosPicker probe is simulator-only")
    #endif
  }
}

extension HomeViewUITests {
  private func requireIsolatedSyntheticPhotoSimulator() throws {
    let e=ProcessInfo.processInfo.environment
    guard (e["SIMULATOR_DEVICE_NAME"] ?? "").hasPrefix("HomeView Photo Privacy ") else {
      throw XCTSkip("Opt-in probe requires a separately provisioned fresh synthetic-photo simulator; never open an existing personal library")
    }
  }
  private func syntheticPhotoCanary(_ png:Data,checkpoint:String,record:Bool=true)->Bool {
    let pixels=[UInt8](viewportPixels(png,inset:0));var magenta=0,cyan=0
    for i in stride(from:0,to:pixels.count,by:4) {
      let r=pixels[i],g=pixels[i+1],b=pixels[i+2]
      if r>180 && g<100 && b>160 {magenta+=1}
      if r<100 && g>150 && b>150 {cyan+=1}
    }
    if record {
      let data:[String:Any]=["magenta_pixels":magenta,"cyan_pixels":cyan,"minimum_each":1000,
        "scope":"Positive visibility of the owned synthetic checkerboard; actual image review also required."]
      let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
      a.name="native-photos-canary-"+checkpoint;a.lifetime = .keepAlways;add(a)
    }
    return magenta>1000 && cyan>1000
  }
  private func openIsolatedPopulatedNativePhotosPicker() throws->XCUIElement {
    try requireIsolatedSyntheticPhotoSimulator()
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    let choose=app.buttons.matching(NSPredicate(format:"label CONTAINS %@","Choose Photos")).firstMatch
    scrollPhotoControlFullyIntoView(choose);choose.tap()
    XCTAssertTrue(app.buttons["Cancel"].firstMatch.waitForExistence(timeout:15))
    let loading=app.staticTexts["Loading…"].firstMatch
    let wait=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:loading)
    XCTAssertEqual(XCTWaiter.wait(for:[wait],timeout:45),.completed)
    let fixture=app.images.matching(identifier:"PXGGridLayout-Info").firstMatch
    XCTAssertTrue(fixture.waitForExistence(timeout:10));XCTAssertTrue(fixture.isHittable)
    XCTAssertTrue(app.frame.contains(fixture.frame))
    XCTAssertTrue(syntheticPhotoCanary(fixture.screenshot().pngRepresentation,checkpoint:"grid-tile-before"),"Never interact with a tile until both owned fixture colors are visible")
    shot("native-photos-populated-grid-before")
    return fixture
  }
  func testIsolatedSyntheticNativePhotosPickerGridSwitcherPrivacy() throws {
    #if targetEnvironment(simulator)
    continueAfterFailure=false;executionTimeAllowance=180
    _=try openIsolatedPopulatedNativePhotosPicker()
    calendarSwitcherCard(from:app,bounds:app.frame,checkpoint:"photos-grid-inactive",preserveReturnOnPrivacyFailure:true).tap()
    XCTAssertTrue(app.buttons["Cancel"].firstMatch.waitForExistence(timeout:10))
    let fixture=app.images.matching(identifier:"PXGGridLayout-Info").firstMatch
    XCTAssertTrue(fixture.waitForExistence(timeout:10));XCTAssertTrue(syntheticPhotoCanary(fixture.screenshot().pngRepresentation,checkpoint:"grid-tile-return"))
    shot("native-photos-populated-grid-return")
    app.buttons["Cancel"].firstMatch.tap()
    XCTAssertTrue(app.buttons.matching(NSPredicate(format:"label CONTAINS %@","Choose Photos")).firstMatch.waitForExistence(timeout:10))
    shot("native-photos-grid-cancelled-no-selection")
    #else
    XCTFail("Isolated synthetic media only")
    #endif
  }
  private func assertSyntheticPhotoGridReturned(_ checkpoint:String) {
    XCTAssertTrue(app.buttons["Cancel"].firstMatch.waitForExistence(timeout:10))
    let fixture=app.images.matching(identifier:"PXGGridLayout-Info").firstMatch
    XCTAssertTrue(fixture.waitForExistence(timeout:10))
    XCTAssertTrue(syntheticPhotoCanary(fixture.screenshot().pngRepresentation,checkpoint:checkpoint))
    shot("native-photos-"+checkpoint)
  }
  private func cancelSyntheticPhotosWithoutImport() {
    app.buttons["Cancel"].firstMatch.tap()
    let choose=app.buttons.matching(NSPredicate(format:"label CONTAINS %@","Choose Photos")).firstMatch
    XCTAssertTrue(choose.waitForExistence(timeout:10));XCTAssertTrue(choose.isHittable)
    XCTAssertFalse(app.buttons["Remove Selected Photo"].exists,"Cancel must not import the pending synthetic selection")
  }
  func testIsolatedSyntheticNativePhotosPickerPendingSelectionSwitcherPrivacy() throws {
    #if targetEnvironment(simulator)
    continueAfterFailure=false;executionTimeAllowance=180
    let fixture=try openIsolatedPopulatedNativePhotosPicker(),done=app.buttons["Done"].firstMatch
    XCTAssertTrue(done.exists);XCTAssertFalse(done.isEnabled)
    fixture.tap()
    let selected=XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:done)
    XCTAssertEqual(XCTWaiter.wait(for:[selected],timeout:10),.completed)
    let before=XCTAttachment(string:app.debugDescription);before.name="native-photos-pending-selection-before-hierarchy";before.lifetime = .keepAlways;add(before)
    shot("native-photos-pending-selection-before")
    calendarSwitcherCard(from:app,bounds:app.frame,checkpoint:"photos-pending-selection",preserveReturnOnPrivacyFailure:true).tap()
    assertSyntheticPhotoGridReturned("pending-selection-return")
    XCTAssertTrue(done.isEnabled,"The pending selection must survive inactivity; never confirm it in this probe")
    let after=XCTAttachment(string:app.debugDescription);after.name="native-photos-pending-selection-return-hierarchy";after.lifetime = .keepAlways;add(after)
    cancelSyntheticPhotosWithoutImport()
    #else
    throw XCTSkip("Isolated simulator only")
    #endif
  }
  func testIsolatedSyntheticNativePhotosPickerPreviewSwitcherPrivacy() throws {
    #if targetEnvironment(simulator)
    continueAfterFailure=false;executionTimeAllowance=180
    let fixture=try openIsolatedPopulatedNativePhotosPicker()
    fixture.press(forDuration:1.2)
    let preview=app.otherElements.matching(NSPredicate(format:"label == %@","Preview")).firstMatch
    XCTAssertTrue(preview.waitForExistence(timeout:5));XCTAssertTrue(app.frame.contains(preview.frame))
    XCTAssertTrue(syntheticPhotoCanary(XCUIScreen.main.screenshot().pngRepresentation,checkpoint:"preview-before"))
    shot("native-photos-preview-before")
    calendarSwitcherCard(from:app,bounds:app.frame,checkpoint:"photos-preview",preserveReturnOnPrivacyFailure:true).tap()
    let returnStart=ProcessInfo.processInfo.systemUptime
    let immediate=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
    immediate.name="native-photos-preview-return-immediate";immediate.lifetime = .keepAlways;add(immediate)
    let state=app.state.rawValue
    let foreground=app.wait(for:.runningForeground,timeout:10)
    let returned=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:["state_observed_after_immediate_image":state,
      "running_foreground_after_wait":foreground,"return_observation_elapsed":ProcessInfo.processInfo.systemUptime-returnStart,
      "scope":"Separate the immediate card/activation transition from actual foreground picker restoration. Original canary, picker, selection and cancel conditions remain required."],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    returned.name="native-photos-preview-return-foreground";returned.lifetime = .keepAlways;add(returned)
    XCTAssertTrue(foreground)
    let visible=XCTNSPredicateExpectation(predicate:NSPredicate {_,_ in
      self.syntheticPhotoCanary(XCUIScreen.main.screenshot().pngRepresentation,checkpoint:"preview-return-poll",record:false)
    },object:nil)
    let visibility=XCTWaiter.wait(for:[visible],timeout:8)
    let readiness=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:["canary_visible_within_wait":visibility == .completed,
      "elapsed_after_card_tap_API_return":ProcessInfo.processInfo.systemUptime-returnStart,"requested_visibility_wait":8,
      "scope":"Bounded actual-image readiness after the OS card return, not instant presentation, scene-active, touch-latency or physical proof. Original canary thresholds unchanged."],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    readiness.name="native-photos-preview-return-canary-readiness";readiness.lifetime = .keepAlways;add(readiness)
    XCTAssertEqual(visibility,.completed)
    XCTAssertTrue(syntheticPhotoCanary(XCUIScreen.main.screenshot().pngRepresentation,checkpoint:"preview-return"))
    let restored=preview.exists
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:["native_preview_still_present":restored,
      "scope":"Native transient preview may close on deactivation; underlying picker and no-selection state must remain. No search or pending selection waiver."],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="native-photos-preview-return-state";a.lifetime = .keepAlways;add(a)
    shot("native-photos-preview-return")
    if restored {
      // Use the observed dimmed content above the preview, not the Home-indicator gutter.
      let point=CGPoint(x:app.frame.midX,y:preview.frame.minY-30)
      XCTAssertGreaterThan(point.y,app.frame.minY+60)
      XCTAssertTrue(app.frame.contains(point));XCTAssertFalse(preview.frame.contains(point))
      app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:point.x,dy:point.y)).tap()
      let gone=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:preview)
      XCTAssertEqual(XCTWaiter.wait(for:[gone],timeout:5),.completed)
    }
    assertSyntheticPhotoGridReturned("preview-grid-return")
    XCTAssertFalse(app.buttons["Done"].firstMatch.isEnabled)
    cancelSyntheticPhotosWithoutImport()
    #else
    throw XCTSkip("Isolated simulator only")
    #endif
  }
  func testIsolatedSyntheticNativePhotosPickerSearchKeyboardSwitcherPrivacy() throws {
    #if targetEnvironment(simulator)
    continueAfterFailure=false;executionTimeAllowance=180
    _=try openIsolatedPopulatedNativePhotosPicker()
    let bar=app.otherElements["photosSearchBar"].firstMatch
    if bar.exists {
      // The observed iPad control is an AX Other, not a SearchField or Search button.
      XCTAssertTrue(app.frame.contains(bar.frame));XCTAssertTrue(bar.isEnabled)
      bar.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5)).tap()
    } else {
      let search=app.buttons["Search"].firstMatch
      XCTAssertTrue(search.waitForExistence(timeout:5));XCTAssertTrue(search.isHittable);search.tap()
    }
    let field=app.otherElements["photosSearchBar"].textViews.firstMatch
    let found=field.waitForExistence(timeout:10)
    let tree=XCTAttachment(string:app.debugDescription);tree.name="native-photos-search-before-input-hierarchy";tree.lifetime = .keepAlways;add(tree)
    XCTAssertTrue(found)
    let keyboardIntro=app.otherElements["UIContinuousPathIntroductionView"].firstMatch
    if keyboardIntro.exists {
      let proceed=keyboardIntro.buttons["Continue"].firstMatch
      XCTAssertTrue(proceed.isHittable);proceed.tap()
      let gone=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:keyboardIntro)
      XCTAssertEqual(XCTWaiter.wait(for:[gone],timeout:5),.completed)
    }
    field.tap();field.typeText("HOMEVIEW67_PRIVATE_SEARCH")
    XCTAssertEqual(field.value as? String,"HOMEVIEW67_PRIVATE_SEARCH")
    XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout:5))
    shot("native-photos-search-keyboard-before")
    calendarSwitcherCard(from:app,bounds:app.frame,checkpoint:"photos-search-keyboard",preserveReturnOnPrivacyFailure:true).tap()
    XCTAssertTrue(field.waitForExistence(timeout:10));XCTAssertEqual(field.value as? String,"HOMEVIEW67_PRIVATE_SEARCH")
    XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout:5))
    shot("native-photos-search-keyboard-return")
    // Do not guess between search-cancel and picker-cancel targets or confirm media.
    app.terminate()
    #else
    throw XCTSkip("Isolated simulator only")
    #endif
  }
  func testIsolatedSyntheticNativePhotosPickerHomeBackgroundPrivacy() throws {
    #if targetEnvironment(simulator)
    continueAfterFailure=false;executionTimeAllowance=180
    _=try openIsolatedPopulatedNativePhotosPicker()
    let bounds=app.frame
    XCUIDevice.shared.press(.home)
    let background=XCTNSPredicateExpectation(predicate:NSPredicate {_,_ in
      self.app.state == .runningBackground || self.app.state == .runningBackgroundSuspended
    },object:nil)
    XCTAssertEqual(XCTWaiter.wait(for:[background],timeout:10),.completed)
    let system=XCUIApplication(bundleIdentifier:"com.apple.springboard")
    calendarSwitcherCard(from:system,bounds:bounds,checkpoint:"photos-home-background",preserveReturnOnPrivacyFailure:true).tap()
    assertSyntheticPhotoGridReturned("home-background-return")
    XCTAssertFalse(app.buttons["Done"].firstMatch.isEnabled)
    cancelSyntheticPhotosWithoutImport()
    #else
    throw XCTSkip("Isolated simulator only")
    #endif
  }
  func testIsolatedSyntheticNativePhotosPickerPreviewPresentationInventory() throws {
    #if targetEnvironment(simulator)
    continueAfterFailure=false;executionTimeAllowance=180
    let fixture=try openIsolatedPopulatedNativePhotosPicker()
    fixture.press(forDuration:1.2)
    let tree=XCTAttachment(string:app.debugDescription);tree.name="native-photos-long-press-hierarchy";tree.lifetime = .keepAlways;add(tree)
    shot("native-photos-long-press-presentation")
    XCTAssertTrue(syntheticPhotoCanary(XCUIScreen.main.screenshot().pngRepresentation,checkpoint:"long-press-visible"))
    // Exploratory presentation inventory only: terminate without selecting or confirming.
    app.terminate()
    #else
    XCTFail("Isolated synthetic media only")
    #endif
  }
}

extension HomeViewUITests {
  private func worldTypeLaunch() {
    launch(["--page","World Clock","--persistence-test",UUID().uuidString,"--reset-test-store",
      "--reference-date","2026-01-01T01:00:00Z","--reference-zone","UTC"])
  }
  private func worldTypeSheetContainer()->XCUIElement {
    let window=app.windows.firstMatch.frame
    let candidates=app.otherElements.containing(.button,identifier:"world.detail.done")
      .containing(.staticText,identifier:"world.detail.time").allElementsBoundByIndex.filter { e in
        let f=e.frame
        return [f.minX,f.minY,f.width,f.height].allSatisfy(\.isFinite)
          && f.width>0 && f.height>0 && axContains(window,f)
      }
    XCTAssertFalse(candidates.isEmpty,"Native detail must have a finite container bound to both unique sheet targets")
    return candidates.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height } ?? app.windows.firstMatch
  }
  private func worldTypeObserve(_ state:String,_ element:XCUIElement,control:Bool=false,sheet:Bool=false,excerpt:Bool=false) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    if !sheet {revealRecipeTypeElement(element,margin:0,horizontalMargin:0)}
    let surface=sheet ? worldTypeSheetContainer():app.otherElements["reference.viewport"]
    let scroll=sheet ? surface.scrollViews.firstMatch:app.scrollViews.firstMatch
    if sheet,recipeTypeScrollContains(element,scroll) {
      for _ in 0..<16 {
        let clip=surface.frame.intersection(scroll.frame),f=element.frame
        if axContains(clip,f) || (excerpt && f.height>clip.height && f.intersection(clip).height>=44) {break}
        let gap=f.minY<clip.minY ? f.minY-clip.minY-10:f.maxY-clip.maxY+10
        let distance=min(max(abs(gap),24),clip.height*0.6)*(gap<0 ? -1:1)
        let origin=app.coordinate(withNormalizedOffset:.zero)
        origin.withOffset(CGVector(dx:clip.minX+8,dy:clip.midY+distance/2))
          .press(forDuration:0.1,thenDragTo:origin.withOffset(CGVector(dx:clip.minX+8,dy:clip.midY-distance/2)),withVelocity:.slow,thenHoldForDuration:0.2)
      }
    }
    RunLoop.current.run(until:Date().addingTimeInterval(0.3))
    let viewport=surface.frame
    func box(_ r:CGRect)->[Double] {
      let values=[r.minX,r.minY,r.width,r.height]
      return values.allSatisfy(\.isFinite) ? values.map(Double.init):[0,0,0,0]
    }
    func row(_ e:XCUIElement)->[String:Any] {
      let inside=recipeTypeScrollContains(e,scroll)
      let clip=inside ? scroll.frame.intersection(viewport):viewport
      return ["id":e.identifier,"label":e.label,"frame":box(e.frame),"clip":box(clip),
        "inside_scroll":inside,"fully_in_clip":axContains(clip,e.frame),
        "geometry_finite":[e.frame.minX,e.frame.minY,e.frame.width,e.frame.height].allSatisfy(\.isFinite),
        "visible_intersection":box(e.frame.intersection(clip))]
    }
    var report:[String:Any]=["state":state,"control_envelope_not_font_metric":control,
      "reading_scope":excerpt ? "declared paragraph excerpt, not whole reading":"reported short-text extent; native pixels separately reviewed, no AX-only full-reading PASS",
      "coordinate_lane":sheet ? "smallest finite native container containing unique sheet Done and time, actual sheet scroll if present":"scaled root, actual scroll clip",
      "target":row(element)]
    if control {
      let child=element.staticTexts.firstMatch;report["text_child_exists"]=child.exists
      if child.exists {report["text_child"]=row(child)}
    }
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="photo-type-"+state+"-geometry";a.lifetime = .keepAlways;add(a)
    if sheet {
      let screen=app.screenshot(),pixels=screen.image.cgImage!,window=app.windows.firstMatch.frame
      let scale=CGFloat(pixels.width)/window.width
      let crop=CGRect(x:viewport.minX*scale,y:viewport.minY*scale,width:viewport.width*scale,height:viewport.height*scale).integral
      guard let own=pixels.cropping(to:crop) else {XCTFail("Native sheet crop failed");return}
      let image=XCTAttachment(image:UIImage(cgImage:own));image.name="viewport-photo-type-"+state;image.lifetime = .keepAlways;add(image)
      let g=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:["state":state,"native_container_points":box(viewport),"crop_pixels":box(crop),"screenshot_pixels":[pixels.width,pixels.height]],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
      g.name="world-sheet-crop-"+state;g.lifetime = .keepAlways;add(g)
      shot("world-type-"+state)
    } else {viewportShot("photo-type-"+state)}
  }
  func testWorldClockSelectedAndChooserSystemTextSizeInventory() {
    continueAfterFailure=false;worldTypeLaunch()
    worldTypeObserve("world-heading",app.staticTexts["World Clock"])
    worldTypeObserve("world-count",app.staticTexts["4 of 12 cities"])
    worldTypeObserve("world-add",app.buttons["world.add"],control:true)
    let first=app.buttons["world.detail.open.America/Los_Angeles"]
    worldTypeObserve("world-city",first.staticTexts["San Francisco"])
    worldTypeObserve("world-date-offset",first.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","UTC")).firstMatch)
    worldTypeObserve("world-day-relation",first.staticTexts["Previous day"])
    worldTypeObserve("world-time",app.staticTexts["world.time.America/Los_Angeles"])
    worldTypeObserve("world-policy",app.staticTexts["Tap a city for day and night. Sun position is an offline estimate."],excerpt:true)
    podcastTypeActivate(app.buttons["world.add"])
    worldTypeObserve("world-chooser-heading",app.staticTexts["Add City"])
    worldTypeObserve("world-chooser-policy",app.staticTexts["Choose a time zone"])
    worldTypeObserve("world-done",app.buttons["world.add"],control:true)
    worldTypeObserve("world-search",app.textFields["world.search"],control:true)
    let london=app.buttons["world.choose.Europe/London"]
    worldTypeObserve("world-choice-name",london.staticTexts["London"])
    worldTypeObserve("world-choice-zone",london.staticTexts["Europe/London"])
    podcastTypeActivate(london)
    XCTAssertEqual(app.buttons["world.add"].label,"Add City")
    XCTAssertTrue(app.staticTexts["5 of 12 cities"].exists)
    let remove=app.buttons["world.remove.Europe/London"]
    podcastTypeActivate(remove)
    XCTAssertFalse(remove.exists);XCTAssertTrue(app.staticTexts["4 of 12 cities"].exists)
    tap("close");XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    worldTypeObserve("positive-settings-heading",app.staticTexts["Settings"])
  }
  func testWorldClockNativeDetailSystemTextSizeInventory() {
    continueAfterFailure=false;worldTypeLaunch()
    podcastTypeActivate(app.buttons["world.detail.open.America/Los_Angeles"])
    XCTAssertTrue(app.staticTexts["world.detail.time"].waitForExistence(timeout:5))
    let surface=worldTypeSheetContainer()
    let hierarchy=XCTAttachment(string:app.debugDescription);hierarchy.name="world-detail-type-hierarchy";hierarchy.lifetime = .keepAlways;add(hierarchy)
    worldTypeObserve("world-detail-city",surface.staticTexts["San Francisco"],sheet:true)
    worldTypeObserve("world-detail-zone",surface.staticTexts["America/Los_Angeles"],sheet:true)
    worldTypeObserve("world-detail-done",surface.buttons["world.detail.done"],control:true,sheet:true)
    worldTypeObserve("world-detail-time",surface.staticTexts["world.detail.time"],sheet:true)
    worldTypeObserve("world-detail-date-offset",surface.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","UTC")).firstMatch,sheet:true)
    worldTypeObserve("world-detail-relation",surface.staticTexts["Previous day"],sheet:true)
    worldTypeObserve("world-detail-sun",surface.staticTexts.matching(NSPredicate(format:"label BEGINSWITH %@","Sunrise")).firstMatch,sheet:true)
    worldTypeObserve("world-detail-light",surface.staticTexts["Currently daylight"],sheet:true)
    worldTypeObserve("world-detail-policy",surface.staticTexts["Offline estimate from a low-order solar model, not an ephemeris."],sheet:true,excerpt:true)
    XCTAssertTrue(app.buttons["world.detail.done"].isHittable);tap("world.detail.done")
    XCTAssertFalse(app.staticTexts["world.detail.time"].exists)
    XCTAssertTrue(app.staticTexts["4 of 12 cities"].exists)
  }
  private func podcastTypeObserve(_ state:String,_ element:XCUIElement,control:Bool=false,excerpt:Bool=false) {
    revealRecipeTypeElement(element,margin:0,horizontalMargin:0)
    RunLoop.current.run(until:Date().addingTimeInterval(0.5))
    let viewport=app.otherElements["reference.viewport"].frame,scroll=app.scrollViews.firstMatch
    func box(_ f:CGRect)->[Double] {[f.minX,f.minY,f.width,f.height]}
    func row(_ e:XCUIElement)->[String:Any] {
      let clip=recipeTypeScrollContains(e,scroll) ? scroll.frame.intersection(viewport):viewport
      return ["id":e.identifier,"label":e.label,"frame":box(e.frame),"clip":box(clip),
        "fully_in_clip":axContains(clip,e.frame),"visible_intersection":box(e.frame.intersection(clip))]
    }
    let clip=recipeTypeScrollContains(element,scroll) ? scroll.frame.intersection(viewport):viewport
    if excerpt {XCTAssertGreaterThanOrEqual(element.frame.intersection(clip).height,min(44,element.frame.height))}
    else {XCTAssertTrue(axContains(clip,element.frame))}
    var report:[String:Any]=["state":state,"control_envelope_not_font_metric":control,
      "reading_scope":excerpt ? "declared paragraph excerpt, not whole reading":"whole short text or control",
      "target":row(element)]
    if control {
      let text=element.staticTexts.firstMatch;report["text_child_exists"]=text.exists
      if text.exists {report["text_child"]=row(text)}
    }
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="photo-type-"+state+"-geometry";a.lifetime = .keepAlways;add(a)
    viewportShot("photo-type-"+state)
  }
  private func pausedPodcastTypeLaunch() {
    launch(["--page","Podcasts","--podcast-fixture","--mute-podcast-fixture","--persistence-test",UUID().uuidString,"--reset-test-store"])
    XCTAssertEqual(app.buttons["podcast.play"].label,"Play Demo Episode")
  }
  private func podcastTypeActivate(_ element:XCUIElement) {
    revealRecipeTypeElement(element,margin:0,horizontalMargin:0)
    let viewport=app.otherElements["reference.viewport"].frame,scroll=app.scrollViews.firstMatch
    let clip=recipeTypeScrollContains(element,scroll) ? scroll.frame.intersection(viewport):viewport
    XCTAssertTrue(axContains(clip,element.frame));XCTAssertTrue(element.isHittable);element.tap()
  }
  func testPodcastDemoAndEmptyRSSSystemTextSizeInventoryWithoutPlayback() {
    continueAfterFailure=false;pausedPodcastTypeLaunch()
    podcastTypeObserve("podcast-heading",app.staticTexts["Podcasts"])
    podcastTypeObserve("podcast-demo-title",app.staticTexts["A Quiet Morning"])
    podcastTypeObserve("podcast-demo-source",app.staticTexts["Demo episode · Local audio"])
    podcastTypeObserve("podcast-demo-play",app.buttons["podcast.play"],control:true)
    podcastTypeObserve("podcast-navigation",app.buttons["podcast.feeds"],control:true)
    podcastTypeActivate(app.buttons["podcast.feeds"])
    podcastTypeObserve("podcast-feed-heading",app.staticTexts["Public RSS feeds"])
    podcastTypeObserve("podcast-feed-policy",app.staticTexts.matching(NSPredicate(format:"label == %@",
      "Add a feed URL yourself. No private subscriptions are imported. Selecting an episode never starts playback automatically.")).firstMatch,excerpt:true)
    podcastTypeObserve("podcast-feed-address",app.textFields["podcast.feed.url"],control:true)
    podcastTypeObserve("podcast-feed-load",app.buttons["podcast.feed.load"],control:true)
    podcastTypeObserve("podcast-empty-feed-status",app.staticTexts["podcast.feed.status"])
    podcastTypeActivate(app.buttons["podcast.feeds"])
    XCTAssertEqual(app.buttons["podcast.play"].label,"Play Demo Episode")
    tap("close");XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    podcastTypeObserve("positive-settings-heading",app.staticTexts["Settings"])
  }
  func testPodcastOwnedRSSSystemTextSizeInventoryNeverAutoplays() {
    continueAfterFailure=false;pausedPodcastTypeLaunch()
    podcastTypeActivate(app.buttons["podcast.feeds"])
    podcastTypeActivate(app.buttons["podcast.feed.fixture"])
    let first=app.buttons["podcast.episode.0"]
    XCTAssertTrue(first.waitForExistence(timeout:8))
    podcastTypeObserve("podcast-loaded-feed-status",app.staticTexts["podcast.feed.status"])
    podcastTypeObserve("podcast-owned-feed-title",app.staticTexts["HomeView Test Feed"])
    podcastTypeObserve("podcast-owned-feed-host",app.staticTexts["fixtures.invalid"])
    podcastTypeObserve("podcast-choice-title",app.staticTexts["Own Audio Episode One"])
    podcastTypeObserve("podcast-choice-duration",app.staticTexts.matching(NSPredicate(format:"label == %@","1:00")).firstMatch)
    podcastTypeActivate(first)
    XCTAssertEqual(app.staticTexts["podcast.title"].label,"Own Audio Episode One")
    XCTAssertTrue(app.staticTexts["podcast.status"].label.contains("Paused"))
    podcastTypeObserve("podcast-episode-title",app.staticTexts["podcast.title"])
    podcastTypeObserve("podcast-episode-source",app.staticTexts["HomeView Test Feed"])
    podcastTypeObserve("podcast-episode-disclosure",app.staticTexts["Public RSS · Not Apple Podcasts account sync"])
    podcastTypeObserve("podcast-episode-position",app.staticTexts["podcast.position"])
    podcastTypeObserve("podcast-episode-play",app.buttons["podcast.play"],control:true)
    podcastTypeObserve("podcast-episode-status",app.staticTexts["podcast.status"])
    podcastTypeObserve("podcast-captions-policy",app.staticTexts["podcast.captions.status"])
    podcastTypeObserve("podcast-captions-menu",app.buttons["podcast.captions"],control:true)
    XCTAssertFalse(app.buttons["podcast.captions"].isEnabled)
    XCTAssertEqual(app.buttons["podcast.play"].label,"Play")
    XCTAssertTrue(app.staticTexts["podcast.status"].label.contains("Paused"))
    podcastTypeActivate(app.buttons["podcast.demo"])
    XCTAssertEqual(app.buttons["podcast.play"].label,"Play Demo Episode")
    podcastTypeActivate(app.buttons["podcast.feeds"])
    let remove=app.buttons["podcast.feed.remove"]
    podcastTypeObserve("podcast-feed-remove",remove,control:true)
    podcastTypeActivate(remove)
    XCTAssertFalse(first.exists);XCTAssertTrue(app.staticTexts["podcast.feed.status"].label.contains("removed"))
    podcastTypeActivate(app.buttons["podcast.feeds"])
    XCTAssertEqual(app.buttons["podcast.play"].label,"Play Demo Episode")
    tap("close");XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
  }
}

extension HomeViewUITests {
  private func revealPhotoTypeElement(_ element:XCUIElement) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    let scroll=app.scrollViews.firstMatch,viewport=app.otherElements["reference.viewport"].frame
    let inside=recipeTypeScrollContains(element,scroll)
    var trace:[[String:Any]]=[]
    defer {
      let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:trace,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
      a.name="photo-type-scroll-trace-"+element.identifier;a.lifetime = .keepAlways;add(a)
    }
    for _ in 0..<72 {
      // Keep text and switches away from the rounded viewport corners. A long
      // paragraph is an excerpt probe, not simultaneous whole-text visibility.
      let clip=inside ? scroll.frame.intersection(viewport).insetBy(dx:0,dy:40):viewport
      let f=element.frame
      trace.append(["frame":[f.minX,f.minY,f.width,f.height],"clip":[clip.minX,clip.minY,clip.width,clip.height]])
      if axContains(clip,f) || (f.height>clip.height && f.intersection(clip).height>=min(44,clip.height)) {return}
      guard inside else {XCTFail("Photo target outside its containing viewport");return}
      let gap=f.minY<clip.minY ? f.minY-clip.minY-10:f.maxY-clip.maxY+10
      let distance=min(max(abs(gap),24),clip.height*0.8)*(gap<0 ? -1:1)
      let start=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:clip.minX+8,dy:clip.midY+distance/2))
      let end=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:clip.minX+8,dy:clip.midY-distance/2))
      start.press(forDuration:0.1,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.2)
    }
    viewportShot("photo-type-scroll-failure-"+element.identifier)
    XCTFail("Photo target not reached within the declared finite scroll budget")
  }
  private func photoTypeOpenSyntheticAlbumChoices() {
    let load=app.buttons["photos.shared.load"]
    revealPhotoTypeElement(load);load.tap()
    if app.buttons["device.unlock"].waitForExistence(timeout:2) {
      tap("device.unlock");revealPhotoTypeElement(load);load.tap()
    }
    XCTAssertTrue(app.buttons["photos.shared.fixture"].waitForExistence(timeout:6))
  }
  private func photoTypeObserve(_ state:String,_ element:XCUIElement,control:Bool=false) {
    revealPhotoTypeElement(element)
    RunLoop.current.run(until:Date().addingTimeInterval(0.5))
    let viewport=app.otherElements["reference.viewport"].frame,scroll=app.scrollViews.firstMatch
    func box(_ f:CGRect)->[Double] {[f.minX,f.minY,f.width,f.height]}
    func row(_ e:XCUIElement)->[String:Any] {
      let clip=recipeTypeScrollContains(e,scroll) ? scroll.frame.intersection(viewport):viewport
      return ["id":e.identifier,"label":e.label,"frame":box(e.frame),"clip":box(clip),
        "fully_in_clip":axContains(clip,e.frame),"visible_intersection":box(e.frame.intersection(clip))]
    }
    var report:[String:Any]=["state":state,"control_envelope_not_font_metric":control,"target":row(element)]
    if control {
      let text=element.staticTexts.firstMatch
      report["text_child_exists"]=text.exists
      if text.exists {report["text_child"]=row(text)}
    }
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="photo-type-"+state+"-geometry";a.lifetime = .keepAlways;add(a)
    viewportShot("photo-type-"+state)
  }
  private func revealPausedMusicTransport(_ element:XCUIElement) {
    // This is a functional midpoint probe, not a 44pt edge audit. The music
    // transport sits at the content end; a photo-specific extra 40pt scroll
    // clearance is not its clipping boundary. Keep full actual containment.
    revealRecipeTypeElement(element,margin:0,horizontalMargin:0)
    let viewport=app.otherElements["reference.viewport"].frame,scroll=app.scrollViews.firstMatch
    let clip=recipeTypeScrollContains(element,scroll) ? scroll.frame.intersection(viewport):viewport
    XCTAssertTrue(axContains(clip,element.frame));XCTAssertTrue(element.isHittable)
    let f=element.frame
    let report:[String:Any]=["id":element.identifier,"frame":[f.minX,f.minY,f.width,f.height],
      "actual_clip":[clip.minX,clip.minY,clip.width,clip.height],"hittable":element.isHittable,
      "scope":"Full actual scroll-clip containment plus original next/previous/paused callback; not a minimum hit rectangle or assistive-service test."]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="photo-type-music-transport-"+element.label;a.lifetime = .keepAlways;add(a)
  }
  private func musicTypeObserve(_ state:String,_ element:XCUIElement) {
    // Music rows can sit at either natural scroll end. Observe the actual
    // clip, not the photo-settings helper's ornamental 40pt clearance.
    revealRecipeTypeElement(element,margin:0,horizontalMargin:0)
    RunLoop.current.run(until:Date().addingTimeInterval(0.5))
    let viewport=app.otherElements["reference.viewport"].frame,scroll=app.scrollViews.firstMatch
    let clip=recipeTypeScrollContains(element,scroll) ? scroll.frame.intersection(viewport):viewport
    let f=element.frame
    // All declared music targets are short text, not paragraph excerpts.
    XCTAssertTrue(axContains(clip,f))
    func box(_ f:CGRect)->[Double] {[f.minX,f.minY,f.width,f.height]}
    let report:[String:Any]=["state":state,"control_envelope_not_font_metric":false,
      "target":["id":element.identifier,"label":element.label,"frame":box(f),"clip":box(clip),
        "fully_in_clip":axContains(clip,f),"visible_intersection":box(f.intersection(clip))]]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="photo-type-"+state+"-geometry";a.lifetime = .keepAlways;add(a)
    viewportShot("photo-type-"+state)
  }
  func testPausedDemoMusicSystemTextSizeInventoryWithoutPlayback() {
    continueAfterFailure=false
    launchPausedDemoMusicAudit()
    musicTypeObserve("music-player-title",app.staticTexts["FEVER DREAM"])
    musicTypeObserve("music-player-artist",app.staticTexts["Demo Artist"])
    let next=app.buttons["player.next"],previous=app.buttons["Previous track"]
    revealPausedMusicTransport(next);next.tap()
    XCTAssertTrue(app.staticTexts["A Little Sunshine"].exists)
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    revealPausedMusicTransport(previous);previous.tap()
    XCTAssertTrue(app.staticTexts["FEVER DREAM"].exists)
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    let info=app.buttons["music.artwork.info.demo"]
    revealPhotoTypeElement(info);info.tap()
    XCTAssertTrue(app.staticTexts["music.artwork.source"].waitForExistence(timeout:5))
    tap("music.artwork.done")
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    let library=app.buttons["Music library"]
    revealPhotoTypeElement(library);library.tap()
    musicTypeObserve("music-library-heading",app.staticTexts["Music"])
    for (i,title) in ["FEVER DREAM","A Little Sunshine","Evening Light"].enumerated() {
      musicTypeObserve("music-library-title-\(i)",app.staticTexts[title])
    }
    musicTypeObserve("music-library-policy",app.staticTexts["Bundled demo audio"].firstMatch)
    // A library selection would start audio. Do not activate any library row.
    tap("close")
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    musicTypeObserve("positive-settings-heading",app.staticTexts["Settings"])
  }
  func testPhotoSettingsSystemTextSizeInventoryWithoutLibrary() {
    continueAfterFailure=false
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    photoTypeObserve("positive-settings-heading",app.staticTexts["Settings"])
    photoTypeObserve("heading",app.staticTexts["Photos face"])
    photoTypeObserve("picker-policy",app.staticTexts.matching(NSPredicate(format:"label == %@",
      "The system photo picker shares only the image you choose. Mock tests never open your photo library.")).firstMatch)
    photoTypeObserve("choose-control",app.buttons.matching(NSPredicate(format:"label CONTAINS %@","Choose Photos")).firstMatch,control:true)
    photoTypeObserve("album-locked-control",app.buttons["photos.shared.load"],control:true)
    photoTypeObserve("demo-control",app.buttons["photos.demo"],control:true)
    let gallery=app.buttons["photos.gallery"]
    photoTypeObserve("gallery-control",gallery,control:true)
    activateRecipeTypeControl(gallery)
    XCTAssertTrue(app.staticTexts["photo.index"].waitForExistence(timeout:8))
    XCTAssertTrue(app.staticTexts["photo.index"].label.contains("OF 2"))
    albumSettings()
    let rotate=app.switches["photos.rotate"]
    photoTypeObserve("rotation-control",rotate,control:true)
    revealPhotoTypeElement(rotate);rotate.tap();XCTAssertEqual(rotate.value as? String,"0")
    let remove=app.buttons["Remove Selected Photo"]
    photoTypeObserve("remove-control",remove,control:true)
    activateRecipeTypeControl(remove)
    XCTAssertFalse(app.buttons["photos.layout.reset"].exists)
    XCTAssertFalse(app.switches["photos.rotate"].exists)
  }
  func testPhotoLayoutSystemTextSizeInventoryKeepsAdjustAndReset() {
    continueAfterFailure=false
    launch(["--photo-layout-fixture","edges","--photo-layout-settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    photoTypeObserve("position-heading",app.staticTexts["Clock position"])
    let top=app.buttons["photos.clock.top"],bottom=app.buttons["photos.clock.bottom"]
    photoTypeObserve("top-control",top,control:true)
    activateRecipeTypeControl(top);XCTAssertEqual(top.value as? String,"Selected")
    activateRecipeTypeControl(bottom);XCTAssertEqual(bottom.value as? String,"Selected")
    let automatic=app.switches["photos.crop.auto"]
    photoTypeObserve("automatic-control",automatic,control:true)
    revealPhotoTypeElement(automatic);automatic.tap();XCTAssertEqual(automatic.value as? String,"0")
    photoTypeObserve("crop-policy",app.staticTexts["Adjust the crop for this photo. Automatic framing preserves detected subjects."])
    let horizontal=app.sliders["photos.crop.horizontal"],vertical=app.sliders["photos.crop.vertical"]
    photoTypeObserve("horizontal-control",horizontal,control:true)
    revealRecipeTypeElement(horizontal,horizontalMargin:0);horizontal.adjust(toNormalizedSliderPosition:0.85)
    photoTypeObserve("vertical-control",vertical,control:true)
    revealRecipeTypeElement(vertical,horizontalMargin:0);vertical.adjust(toNormalizedSliderPosition:0.2)
    let reset=app.buttons["photos.layout.reset"]
    photoTypeObserve("reset-control",reset,control:true)
    activateRecipeTypeControl(reset)
    XCTAssertEqual(automatic.value as? String,"1")
    XCTAssertEqual(app.buttons["photos.clock.automatic"].value as? String,"Selected")
    tap("nav.faces")
    XCTAssertTrue(app.staticTexts["photo.layout.test"].label.contains("full=true"))
  }
  func testSharedAlbumSystemTextSizeInventoryKeepsExplicitLinkAndDisconnect() {
    continueAfterFailure=false
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    photoTypeOpenSyntheticAlbumChoices()
    photoTypeObserve("album-load-control",app.buttons["photos.shared.load"],control:true)
    photoTypeObserve("album-notice",app.staticTexts["photos.shared.display.notice"])
    photoTypeObserve("album-first-choice",app.buttons["photos.shared.fixture"],control:true)
    photoTypeObserve("album-second-choice",app.buttons["photos.shared.second"],control:true)
    linkSyntheticAlbum()
    waitForPhotoMetadata("assets=fixture-a,fixture-b")
    albumSettings()
    photoTypeObserve("album-linked-title",app.staticTexts["Synthetic shared album"])
    photoTypeObserve("album-linked-notice",app.staticTexts.matching(NSPredicate(format:"label == %@",
      "New photos from this album appear on this shared display while HomeView is active. Up to ten photos are kept.")).firstMatch)
    photoTypeObserve("album-status",app.staticTexts["photos.shared.status"])
    let refresh=app.buttons["photos.shared.refresh"]
    photoTypeObserve("album-refresh-control",refresh,control:true)
    activateRecipeTypeControl(refresh)
    let disconnect=app.buttons["photos.shared.disconnect"]
    photoTypeObserve("album-disconnect-control",disconnect,control:true)
    activateRecipeTypeControl(disconnect)
    XCTAssertFalse(refresh.exists)
    XCTAssertFalse(app.buttons["Remove Selected Photo"].exists)
  }
}

extension HomeViewUITests {
  private func verifyNativeMotionSurface(_ scene:String)throws->Int {
    guard app.wait(for:.runningForeground,timeout:10),app.otherElements["reference.viewport"].waitForExistence(timeout:5) else {throw NSError(domain:"HomeView.NativeMotionProbe",code:10)}
    let surface:XCUIElement
    switch scene {
    case "flow":surface=app.otherElements["face.Flow"]
    case "home-prism":surface=app.otherElements["face.Home Modular"]
    case "weather-face":surface=app.otherElements["face.Weather"]
    case "weather-app":surface=app.staticTexts["weather.app.city"]
    default:throw NSError(domain:"HomeView.NativeMotionProbe",code:11)
    }
    guard surface.waitForExistence(timeout:5) else {throw NSError(domain:"HomeView.NativeMotionProbe",code:12)}
    let line=String(app.debugDescription.split(separator:"\n").first ?? "")
    let expression=try NSRegularExpression(pattern:#"pid:\s*([0-9]+)"#)
    guard let match=expression.firstMatch(in:line,range:NSRange(line.startIndex..<line.endIndex,in:line)),
      let range=Range(match.range(at:1),in:line),let pid=Int(line[range]),pid>0 else {throw NSError(domain:"HomeView.NativeMotionProbe",code:13)}
    return pid
  }
  private func nativeMotionRegionHasContent(_ data:Data)->Bool {
    guard data.count>=400,data.count%4==0 else {return false}
    return data.withUnsafeBytes { (b:UnsafeRawBufferPointer)->Bool in
      var varied=0
      for i in stride(from:0,to:b.count,by:4) {
        if max(abs(Int(b[i])-Int(b[0])),max(abs(Int(b[i+1])-Int(b[1])),abs(Int(b[i+2])-Int(b[2]))))>16 {
          varied+=1;if varied>=100 {return true}
        }
      }
      return false
    }
  }
  private func nativeSystemMotionSwitch(_ settings:XCUIApplication)throws->XCUIElement {
    if settings.state == .notRunning {settings.launch()} else if settings.state != .runningForeground {settings.activate()}
    guard settings.wait(for:.runningForeground,timeout:15) else {throw NSError(domain:"HomeView.NativeMotionProbe",code:1)}
    let reduced=settings.switches["REDUCE_MOTION"].firstMatch
    if !reduced.waitForExistence(timeout:2) {
      let accessibility=settings.buttons["com.apple.settings.accessibility"].firstMatch
      if accessibility.exists {guard accessibility.isHittable else {throw NSError(domain:"HomeView.NativeMotionProbe",code:2)};accessibility.tap()}
      let motion=settings.buttons["Motion"].firstMatch.exists ? settings.buttons["Motion"].firstMatch
        : settings.cells["Motion"].firstMatch.exists ? settings.cells["Motion"].firstMatch:settings.staticTexts["Motion"].firstMatch
      guard motion.waitForExistence(timeout:8),motion.isHittable else {throw NSError(domain:"HomeView.NativeMotionProbe",code:3)}
      motion.tap()
    }
    guard reduced.waitForExistence(timeout:8) else {throw NSError(domain:"HomeView.NativeMotionProbe",code:4)}
    return reduced
  }
  private func setNativeSystemMotion(_ enabled:Bool,settings:XCUIApplication)throws->[String:Any] {
    let reduced=try nativeSystemMotionSwitch(settings),expected=enabled ? "1":"0"
    guard let before=reduced.value as? String,before=="0" || before=="1" else {throw NSError(domain:"HomeView.NativeMotionProbe",code:5)}
    var tapped=false
    if before != expected {
      // The observed named AX switch contains the actual physical switch, not the label button.
      let physical=reduced.switches.firstMatch
      guard physical.exists,physical.isHittable,settings.frame.contains(physical.frame) else {throw NSError(domain:"HomeView.NativeMotionProbe",code:6)}
      physical.tap();tapped=true
    }
    let value=XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@",expected),object:reduced)
    guard XCTWaiter.wait(for:[value],timeout:10) == .completed else {throw NSError(domain:"HomeView.NativeMotionProbe",code:7)}
    let native=XCTNSPredicateExpectation(predicate:NSPredicate {_,_ in UIAccessibility.isReduceMotionEnabled==enabled},object:nil)
    guard XCTWaiter.wait(for:[native],timeout:10) == .completed else {throw NSError(domain:"HomeView.NativeMotionProbe",code:8)}
    return ["switch_before":before,"switch_after":reduced.value as? String ?? "",
      "native_UIAccessibility_reduce_motion":UIAccessibility.isReduceMotionEnabled,"physical_switch_tapped":tapped]
  }
  private func verifyNativeSystemMotion(_ scene:String,arguments:[String],pixels:(Data)->Data)throws {
    #if targetEnvironment(simulator)
    continueAfterFailure=true;executionTimeAllowance=300
    let settings=XCUIApplication(bundleIdentifier:"com.apple.Preferences"),start=ProcessInfo.processInfo.systemUptime
    var original:Bool?,restored=false,events:[[String:Any]]=[]
    func record(_ event:String,_ fields:[String:Any]=[:]) {var row=fields;row["event"]=event;row["elapsed"]=ProcessInfo.processInfo.systemUptime-start;events.append(row)}
    func emit(_ phase:String) {
      var report:[String:Any]=["scene":scene,"phase":phase,
        "restored":restored,"events":events,
        "scope":"Actual owned-simulator OS Reduce Motion, same-app OFF moving/ON exact still/OFF moving return, expected foreground surface and nonblank region; no --reduce-motion argument. Not physical power, original motion, other assistive or full-flow acceptance."]
      if let original {report["original_enabled"]=original} else {report["original_enabled"]=NSNull()}
      let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
      a.name="native-motion-system-"+scene+"-"+phase;a.lifetime = .keepAlways;add(a)
    }
    defer {
      app.terminate()
      if let original {
        do {let state=try setNativeSystemMotion(original,settings:settings);restored=UIAccessibility.isReduceMotionEnabled==original;record("restored-original",state);XCTAssertTrue(restored)}
        catch {let e=error as NSError;record("restore-error",["domain":e.domain,"code":e.code]);XCTFail("Restore original real simulator Reduce Motion setting")}
      }
      emit("after")
    }
    do {
      let control=try nativeSystemMotionSwitch(settings)
      guard let raw=control.value as? String,raw=="0" || raw=="1" else {throw NSError(domain:"HomeView.NativeMotionProbe",code:9)}
      original=raw=="1";record("original-state",["switch_value":raw,"native_UIAccessibility_reduce_motion":UIAccessibility.isReduceMotionEnabled]);emit("before")
      record("OFF-readback",try setNativeSystemMotion(false,settings:settings))
      launch(arguments+["--animation-test","--persistence-test",UUID().uuidString,"--reset-test-store"])
      XCTAssertFalse(app.launchArguments.contains("--reduce-motion"));XCTAssertFalse(UIAccessibility.isReduceMotionEnabled)
      let initialPID=try verifyNativeMotionSurface(scene);record("application-PID-OFF",["pid":initialPID,"source":"Public XCUIApplication.debugDescription root attributes"])
      RunLoop.current.run(until:Date().addingTimeInterval(1))
      let offStart=ProcessInfo.processInfo.systemUptime,off=pixels(viewportBytes("native-system-motion-"+scene+"-off-first"))
      XCTAssertTrue(nativeMotionRegionHasContent(off),"Moving ROI must not be a uniform blank capture")
      Thread.sleep(forTimeInterval:1.5)
      let moving=off != pixels(viewportBytes("native-system-motion-"+scene+"-off-later"))
      record("OFF-moving-positive",["different_RGBA":moving,"sample_elapsed":ProcessInfo.processInfo.systemUptime-offStart,"no_reduce_motion_argument":true]);XCTAssertTrue(moving)
      record("ON-readback",try setNativeSystemMotion(true,settings:settings))
      app.activate();let onPID=try verifyNativeMotionSurface(scene);record("application-PID-ON",["pid":onPID,"matches_initial":onPID==initialPID]);XCTAssertEqual(onPID,initialPID,"Same actual app process across the OS preference change")
      XCTAssertTrue(UIAccessibility.isReduceMotionEnabled)
      let counter=app.staticTexts["flow.compute.test"]
      if scene=="flow" {
        guard counter.waitForExistence(timeout:5) else {XCTFail("Existing Flow compute diagnostic missing");return}
        let idle=XCTNSPredicateExpectation(predicate:NSPredicate(format:"value CONTAINS %@","pending=false"),object:counter)
        guard XCTWaiter.wait(for:[idle],timeout:10) == .completed else {XCTFail("Flow pending work did not quiesce");return}
      }
      RunLoop.current.run(until:Date().addingTimeInterval(0.7))
      let beforeCounter=scene=="flow" ? counter.value as? String ?? "":""
      let onStart=ProcessInfo.processInfo.systemUptime,frozen=pixels(viewportBytes("native-system-motion-"+scene+"-on-first"))
      XCTAssertTrue(nativeMotionRegionHasContent(frozen),"Still ROI must contain the expected nonuniform content, not a blank screen")
      Thread.sleep(forTimeInterval:1.5)
      let same=frozen==pixels(viewportBytes("native-system-motion-"+scene+"-on-later"))
      let afterCounter=scene=="flow" ? counter.value as? String ?? "":""
      record("ON-still-region",["equal_RGBA":same,"sample_elapsed":ProcessInfo.processInfo.systemUptime-onStart,
        "native_UIAccessibility_reduce_motion":UIAccessibility.isReduceMotionEnabled,"flow_counter_before":beforeCounter,"flow_counter_after":afterCounter]);XCTAssertTrue(same)
      if scene=="flow" {XCTAssertTrue(beforeCounter.contains("active=true"));XCTAssertTrue(beforeCounter.contains("pending=false"));XCTAssertEqual(beforeCounter,afterCounter,"No additional Flow revision after actual OS Reduce Motion")}
      record("OFF-again-readback",try setNativeSystemMotion(false,settings:settings))
      app.activate();let returnPID=try verifyNativeMotionSurface(scene);record("application-PID-OFF-return",["pid":returnPID,"matches_initial":returnPID==initialPID]);XCTAssertEqual(returnPID,initialPID,"Moving return must use the original process");XCTAssertFalse(UIAccessibility.isReduceMotionEnabled)
      RunLoop.current.run(until:Date().addingTimeInterval(0.7))
      let returnStart=ProcessInfo.processInfo.systemUptime,returned=pixels(viewportBytes("native-system-motion-"+scene+"-off-return-first"))
      XCTAssertTrue(nativeMotionRegionHasContent(returned))
      Thread.sleep(forTimeInterval:1.5)
      let resumed=returned != pixels(viewportBytes("native-system-motion-"+scene+"-off-return-later"))
      record("OFF-moving-return",["different_RGBA":resumed,"sample_elapsed":ProcessInfo.processInfo.systemUptime-returnStart,
        "native_UIAccessibility_reduce_motion":UIAccessibility.isReduceMotionEnabled,"same_app_lifetime":returnPID==initialPID && onPID==initialPID]);XCTAssertTrue(resumed)
    } catch {let e=error as NSError;record("probe-error",["domain":e.domain,"code":e.code]);XCTFail("Native OS Reduce Motion probe failed")}
    #else
    XCTFail("OS preference mutation is restricted to owned simulator tests")
    #endif
  }
  func testNativeSystemReduceMotionFlowAndRestore()throws {try verifyNativeSystemMotion("flow",arguments:["--face","Flow"],pixels:flowPixels)}
  func testNativeSystemReduceMotionWeatherAppAndRestore()throws {try verifyNativeSystemMotion("weather-app",arguments:["--page","Weather"],pixels:weatherSkyPixels)}
  func testNativeSystemReduceMotionWeatherFaceAndRestore()throws {try verifyNativeSystemMotion("weather-face",arguments:["--face","Weather"],pixels:weatherGlassPixels)}
  func testNativeSystemReduceMotionHomePrismAndRestore()throws {try verifyNativeSystemMotion("home-prism",arguments:["--face","Home Modular"],pixels:{self.viewportPixels($0)})}
}

extension HomeViewUITests {
  private func captureNativeMotionSettings(_ settings:XCUIApplication,_ stage:String) {
    let started=ProcessInfo.processInfo.systemUptime
    // One public XCTest snapshot string avoids live index queries into a changing Settings tree.
    let snapshot=settings.debugDescription
    let tree=XCTAttachment(string:snapshot);tree.name="native-motion-settings-"+stage+"-hierarchy";tree.lifetime = .keepAlways;add(tree)
    let report:[String:Any]=["stage":stage,"snapshot_start":started,
      "snapshot_return":ProcessInfo.processInfo.systemUptime,"public_snapshot_string_attached":true,
      "native_UIAccessibility_reduce_motion":UIAccessibility.isReduceMotionEnabled,
      "scope":"Read-only owned simulator Settings navigation/control inventory; no preference action or HomeView runtime acceptance. Public AX snapshot string and screenshot are separate observations, not a complete OS capability proof."]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="native-motion-settings-"+stage;a.lifetime = .keepAlways;add(a)
    let shot=XCTAttachment(screenshot:settings.screenshot());shot.name="native-motion-settings-"+stage+"-screen";shot.lifetime = .keepAlways;add(shot)
  }
  func testReadOnlySimulatorAccessibilityMotionSettingInventory() {
    #if targetEnvironment(simulator)
    continueAfterFailure=false;executionTimeAllowance=180
    let original=UIAccessibility.isReduceMotionEnabled
    let settings=XCUIApplication(bundleIdentifier:"com.apple.Preferences")
    settings.launch();XCTAssertTrue(settings.wait(for:.runningForeground,timeout:30))
    let accessibility=settings.buttons["com.apple.settings.accessibility"]
    guard accessibility.waitForExistence(timeout:10) else {captureNativeMotionSettings(settings,"missing-root-target");XCTFail("Observed Settings Accessibility button missing");return}
    XCTAssertTrue(accessibility.isHittable);accessibility.tap()
    captureNativeMotionSettings(settings,"accessibility")
    let motion=settings.buttons["Motion"].firstMatch.exists ? settings.buttons["Motion"].firstMatch
      : settings.cells["Motion"].firstMatch.exists ? settings.cells["Motion"].firstMatch:settings.staticTexts["Motion"].firstMatch
    guard motion.waitForExistence(timeout:10) else {XCTFail("Motion menu target not reached; no OS absence inference");return}
    XCTAssertTrue(motion.isHittable);motion.tap()
    let reduced=settings.switches["Reduce Motion"].firstMatch
    let found=reduced.waitForExistence(timeout:10)
    captureNativeMotionSettings(settings,"motion")
    guard found else {XCTFail("Reduce Motion switch not identified; no OS absence inference");return}
    let raw=reduced.value as? String
    XCTAssertTrue(raw=="0" || raw=="1","Record actual native switch format")
    XCTAssertEqual(UIAccessibility.isReduceMotionEnabled,raw=="1")
    XCTAssertEqual(UIAccessibility.isReduceMotionEnabled,original,"Read-only inventory must not change the preference")
    #else
    XCTFail("This diagnostic is restricted to the owned simulator environment")
    #endif
  }
}

extension HomeViewUITests {
  func testNativeVoiceOverServiceActionLabelsAndRestore() throws {
    continueAfterFailure=true;executionTimeAllowance=240
    guard #available(iOS 27.0,*) else {XCTFail("Native VoiceOver service requires iOS 27");return}
    let service=XCUIDevice.shared.voiceOverService,original=service.isEnabled
    let kinds=["Calendar","Reminders","Apple Music","Weather"],started=ProcessInfo.processInfo.systemUptime
    var events:[[String:Any]]=[],labels:[String:String]=[:],spoken:[String:String]=[:],restored=false
    func record(_ name:String,_ fields:[String:Any]=[:]) {
      var row=fields;row["event"]=name;row["elapsed"]=ProcessInfo.processInfo.systemUptime-started;events.append(row)
    }
    func normalized(_ text:String)->String {text.replacingOccurrences(of:"\u{00a0}",with:" ").lowercased()}
    defer {
      do {
        if service.isEnabled != original {if original {try service.enable()} else {try service.disable()}}
        restored=service.isEnabled==original
        record("restored-state",["enabled":service.isEnabled,"matches_original":restored]);XCTAssertTrue(restored)
      } catch {let e=error as NSError;record("restore-error",["domain":e.domain,"code":e.code]);XCTFail("Restore original simulator VoiceOver state")}
      let report:[String:Any]=["original_enabled":original,"restored":restored,"events":events,
        "AX_action_labels":labels,"native_action_utterances":spoken,
        "scope":"Four unconnected service button names. Native reported speech, no acoustic or raw-input acceptance; test-only viewport marker explicitly retained. No service action invoked."]
      let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
      a.name="native-voiceover-service-actions";a.lifetime = .keepAlways;add(a)
    }
    record("original-state",["enabled":original])
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    viewportShot("native-service-actions-before-voiceover")
    for kind in kinds {
      let button=app.buttons["connect."+kind]
      labels[kind]=button.label
      XCTAssertEqual(button.label,"Connect "+kind,"Action must identify its service without the neighbouring heading")
      XCTAssertEqual(app.staticTexts["connection.status."+kind].label,"Not connected")
    }
    do {
      if !service.isEnabled {try service.enable()}
      record("enabled-state",["enabled":service.isEnabled]);guard service.isEnabled else {XCTFail("Native VoiceOver not enabled");return}
      var heading:String?
      let deadline=ProcessInfo.processInfo.systemUptime+100
      if let initial=try? service.currentSpeech().utterance {record("initial-speech",["utterance":initial])}
      for _ in 0..<128 {
        guard spoken.count<kinds.count,ProcessInfo.processInfo.systemUptime<deadline else {break}
        let utterance=try service.moveForward().utterance;record("move-forward",["utterance":utterance])
        if let kind=kinds.first(where:{normalized(utterance)==normalized($0)}) {heading=kind}
        if let kind=heading,spoken[kind]==nil,normalized(utterance).hasPrefix("connect"),normalized(utterance).contains("button") {
          spoken[kind]=utterance;record("native-service-action",["service":kind,"utterance":utterance]);heading=nil
        }
      }
      XCTAssertEqual(spoken.count,kinds.count,"Native traversal must reach all four action buttons")
      for kind in kinds {XCTAssertTrue(normalized(spoken[kind] ?? "").contains(normalized("Connect "+kind+" Button")),"Native button utterance must identify "+kind)}
      let anchor=try service.currentSpeech().utterance
      record("move-backward",["utterance":try service.moveBackward().utterance])
      let returned=try service.moveForward().utterance;record("move-forward-return",["utterance":returned])
      XCTAssertEqual(normalized(returned),normalized(anchor))
      viewportShot("native-service-actions-focused")
      for kind in kinds {XCTAssertEqual(app.staticTexts["connection.status."+kind].label,"Not connected")}
    } catch {let e=error as NSError;record("native-service-error",["domain":e.domain,"code":e.code]);XCTFail("Native service action-label traversal failed")}
  }
}

extension HomeViewUITests {
  private func verifyNativeVoiceOverFocus(_ scene:String,arguments:[String],required:[String])throws {
    continueAfterFailure=true;executionTimeAllowance=180
    guard #available(iOS 27.0,*) else {XCTFail("Native VoiceOver service requires iOS 27");return}
    let service=XCUIDevice.shared.voiceOverService,original=service.isEnabled
    let started=ProcessInfo.processInfo.systemUptime
    var events:[[String:Any]]=[],seen=Set<String>(),restored=false
    func record(_ event:String,_ fields:[String:Any]=[:]) {
      var row=fields;row["event"]=event;row["elapsed"]=ProcessInfo.processInfo.systemUptime-started;events.append(row)
    }
    func normalized(_ text:String)->String {
      text.replacingOccurrences(of:"\u{00a0}",with:" ").replacingOccurrences(of:"&",with:"and").lowercased()
    }
    func observe(_ event:String,_ speech:String) {
      record(event,["utterance":speech])
      for value in required where normalized(speech).contains(normalized(value)) {seen.insert(value)}
    }
    func emit(_ phase:String) {
      let report:[String:Any]=["scene":scene,"required_spoken_values":required,"seen_required":seen.sorted(),
        "original_enabled":original,"restored":restored,"phase":phase,"events":events,
        "scope":"Native VoiceOver service focus/reported speech and backward-forward consistency only; no raw activation, acoustic, physical or original-order acceptance. Test-only reference-viewport marker remains in recorded stream."]
      let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
      a.name="native-voiceover-focus-"+scene+"-"+phase;a.lifetime = .keepAlways;add(a)
    }
    record("original-state",["enabled":original]);emit("before")
    defer {
      do {
        if service.isEnabled != original {if original {try service.enable()} else {try service.disable()}}
        restored=service.isEnabled==original
        record("restored-state",["enabled":service.isEnabled,"matches_original":restored]);XCTAssertTrue(restored)
      } catch {let e=error as NSError;record("restore-error",["domain":e.domain,"code":e.code]);XCTFail("Restore original simulator VoiceOver state")}
      emit("after")
    }
    launch(arguments+["--persistence-test",UUID().uuidString,"--reset-test-store"])
    if scene=="recipe" {
      guard app.buttons["saved.Butternut Squash Soup"].waitForExistence(timeout:5) else {XCTFail("Existing reset-store recipe fixture missing");return}
    }
    if scene=="lock" {tap("grid.lock");XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked")}
    if scene=="editor" {
      let edit=app.buttons["settings.faces"];scrollPhotoControlFullyIntoView(edit);edit.tap()
      guard app.buttons["editor.done"].waitForExistence(timeout:5) else {XCTFail("Editor fixture did not open");return}
    }
    guard app.otherElements["reference.viewport"].waitForExistence(timeout:5) else {XCTFail("Own reference viewport missing before VO");return}
    // Fixture routing above is ordinary XCTest setup, not VoiceOver activation.
    do {
      if !service.isEnabled {try service.enable()}
      record("enabled-state",["enabled":service.isEnabled])
      guard service.isEnabled else {XCTFail("Native VoiceOver service not enabled");return}
      if let initial=try? service.currentSpeech().utterance {observe("initial-speech",initial)}
      let deadline=ProcessInfo.processInfo.systemUptime+70
      for _ in 0..<96 {
        if seen.count==required.count {break}
        guard ProcessInfo.processInfo.systemUptime<deadline else {break}
        observe("move-forward",try service.moveForward().utterance)
      }
      record("required-values-result",["missing":required.filter {!seen.contains($0)},"found":seen.count])
      guard seen.count==required.count else {XCTFail("Native VoiceOver did not reach all declared spoken values for \(scene)");return}
      let anchor=try service.currentSpeech().utterance
      observe("move-backward",try service.moveBackward().utterance)
      let returned=try service.moveForward().utterance;observe("move-forward-return",returned)
      XCTAssertEqual(normalized(returned),normalized(anchor),"Return to the same native focused utterance")
      viewportShot("native-voiceover-focus-"+scene)
      switch scene {
      case "camera":XCTAssertEqual(app.buttons["camera.grid.size"].label,"Show 9");XCTAssertFalse(app.buttons["camera.8"].exists)
      case "lock":XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked");XCTAssertEqual(app.buttons["lock.action"].label,"Authenticate Device")
      case "timer":XCTAssertEqual(app.staticTexts["timer.countdown"].label,"10:56");XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
      case "recipe":XCTAssertTrue(app.buttons["saved.Butternut Squash Soup"].exists);XCTAssertFalse(app.buttons["cooking.next"].exists)
      case "settings":for kind in ["Calendar","Reminders","Apple Music","Weather"] {XCTAssertEqual(app.buttons["connect."+kind].label,"Connect "+kind);XCTAssertEqual(app.staticTexts["connection.status."+kind].label,"Not connected")}
      case "editor":XCTAssertEqual(app.buttons["select.Modular"].value as? String,"Selected");XCTAssertFalse(app.buttons["complications.done"].exists)
      default:XCTFail("Unknown native VO scene")
      }
    } catch {let e=error as NSError;record("native-service-error",["domain":e.domain,"code":e.code]);XCTFail("Native VoiceOver focus/speech call failed")}
  }
  func testNativeVoiceOverCameraFocusSpeechAndRestore()throws {
    try verifyNativeVoiceOverFocus("camera",arguments:["--page","Cameras"],required:["Cameras","Show 9","Front Door","Back Yard","Living Room","Driveway"])
  }
  func testNativeVoiceOverLockFocusSpeechAndRestore()throws {
    try verifyNativeVoiceOverFocus("lock",arguments:["--page","Home"],required:["Front Door","Locked","Mock lock","Authenticate Device"])
  }
  func testNativeVoiceOverTimerFocusSpeechAndRestore()throws {
    try verifyNativeVoiceOverFocus("timer",arguments:["--reference-timer"],required:["10:56","15 MIN","Foreground timer","Resume timer","Delete timer"])
  }
  func testNativeVoiceOverRecipeFocusSpeechAndRestore()throws {
    try verifyNativeVoiceOverFocus("recipe",arguments:["--page","Recipes"],required:["Recipes","Recent & Pinned","Butternut Squash Soup"])
  }
  func testNativeVoiceOverSettingsFocusSpeechAndRestore()throws {
    try verifyNativeVoiceOverFocus("settings",arguments:["--page","Settings"],required:["Settings","Mock home only","Native system features","Connected services","Apple Home stays disconnected","Calendar","Not connected"])
  }
  func testNativeVoiceOverEditorFocusSpeechAndRestore()throws {
    try verifyNativeVoiceOverFocus("editor",arguments:["--face","Modular","--page","Settings"],required:["Faces","Done","Complications","Top left"])
  }
}

extension HomeViewUITests {
  private func cameraTypeCapture(_ state:String,_ roles:[String:XCUIElement],controls:[String:XCUIElement]=[:]) {
    RunLoop.current.run(until:Date().addingTimeInterval(1))
    let viewport=app.otherElements["reference.viewport"].frame,scroll=app.scrollViews.firstMatch
    func box(_ f:CGRect)->[Double] {[f.minX,f.minY,f.width,f.height]}
    func row(_ e:XCUIElement)->[String:Any] {
      let f=e.frame,inside=recipeTypeScrollContains(e,scroll)
      let clip=inside ? scroll.frame.intersection(viewport):viewport
      return ["id":e.identifier,"label":e.label,"value":e.value as? String ?? "",
        "element_type":e.elementType.rawValue,"frame":box(f),"actual_clip":box(clip),
        "inside_scroll":inside,"fully_in_clip":axContains(clip,f)]
    }
    var selected:[[String:Any]]=[],missing:[String]=[]
    for name in roles.keys.sorted() {
      let e=roles[name]!
      if e.exists {var r=row(e);r["role"]=name;selected.append(r)} else {missing.append(name)}
    }
    var targets:[[String:Any]]=[]
    for name in controls.keys.sorted() {
      let e=controls[name]!;XCTAssertTrue(e.exists)
      var r=row(e);r["role"]=name;targets.append(r)
    }
    let report:[String:Any]=["viewport":box(viewport),"roles":selected,
      "missing_text_children_not_PASS":missing,"controls_not_font_metrics":targets,
      "all_static_text":app.staticTexts.allElementsBoundByIndex.map(row)]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="camera-type-"+state+"-geometry";a.lifetime = .keepAlways;add(a)
    viewportShot("camera-type-"+state)
  }
  private func cameraTypeDetailRoles(offline:Bool=false,doorbell:Bool=false,room:String="Front Door")->[String:XCUIElement] {
    let root:XCUIElement=doorbell ? app.otherElements["doorbell.overlay"]:app
    var roles:[String:XCUIElement]=["room":root.staticTexts[room],
      "status_static_label":root.descendants(matching:.any)["camera.demo.status"],"time":root.staticTexts["camera.time"]]
    if offline {roles["unavailable"]=root.staticTexts["Mock camera unavailable"]}
    if doorbell {roles["doorbell_demo"]=root.staticTexts["doorbell.demo.label"]}
    return roles
  }
  func testMockCameraToggleRenderedInkInventory() {
    continueAfterFailure=false
    launch(["--page","Cameras","--persistence-test",UUID().uuidString,"--reset-test-store"])
    let toggle=app.buttons["camera.grid.size"]
    XCTAssertEqual(toggle.label,"Show 9")
    cameraTypeCapture("toggle-four",[:],controls:["toggle":toggle])
    activateRecipeTypeControl(toggle)
    XCTAssertEqual(toggle.label,"Show 4");XCTAssertTrue(app.buttons["camera.8"].exists)
    cameraTypeCapture("toggle-nine",[:],controls:["toggle":toggle])
    activateRecipeTypeControl(toggle)
    XCTAssertEqual(toggle.label,"Show 9");XCTAssertFalse(app.buttons["camera.8"].exists)
  }
  func testMockCameraSystemTextSizeInventory() {
    continueAfterFailure=false
    launch(["--page","Cameras","--persistence-test",UUID().uuidString,"--reset-test-store"])
    func gridRoles()->[String:XCUIElement] {[
      "header":app.staticTexts["Cameras"],"clock":app.staticTexts["10:09"],
      "toggle_text":app.buttons["camera.grid.size"].staticTexts.firstMatch,
      "tile_text":app.buttons["camera.0"].staticTexts.matching(NSPredicate(format:"label == %@","Front Door")).firstMatch]}
    cameraTypeCapture("grid-four",gridRoles(),controls:["toggle":app.buttons["camera.grid.size"],"first_tile":app.buttons["camera.0"]])
    activateRecipeTypeControl(app.buttons["camera.grid.size"])
    XCTAssertTrue(app.buttons["camera.8"].exists)
    cameraTypeCapture("grid-nine",gridRoles(),controls:["last_tile":app.buttons["camera.8"]])
    activateRecipeTypeControl(app.buttons["camera.8"])
    XCTAssertEqual(app.descendants(matching:.any)["camera.demo.status"].label,"Demo still")
    XCTAssertEqual(app.staticTexts["camera.time"].label,"10:09")
    cameraTypeCapture("front-door",cameraTypeDetailRoles(),controls:["talk":app.buttons["camera.talk"],"grid":app.buttons["camera.grid"],"close":app.buttons["camera.close"]])
    activateRecipeTypeControl(app.buttons["camera.talk"])
    XCTAssertEqual(app.buttons["camera.talk"].value as? String,"On (demo)")
    activateRecipeTypeControl(app.buttons["camera.talk"])
    XCTAssertEqual(app.buttons["camera.talk"].value as? String,"Off (demo)")
    let gone=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:app.staticTexts["Mock talkback off"])
    XCTAssertEqual(XCTWaiter.wait(for:[gone],timeout:7),.completed)
    cameraTypeCapture("talk-off",cameraTypeDetailRoles())
    activateRecipeTypeControl(app.buttons["camera.grid"])
    XCTAssertTrue(app.buttons["camera.2"].waitForExistence(timeout:5))
    activateRecipeTypeControl(app.buttons["camera.2"])
    XCTAssertEqual(app.buttons["camera.talk"].value as? String,"Off (demo)")
    cameraTypeCapture("living-room",cameraTypeDetailRoles(room:"Living Room"))
    activateRecipeTypeControl(app.buttons["camera.close"])
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
    launch(["--face","Home Camera","--persistence-test",UUID().uuidString,"--reset-test-store"])
    XCTAssertTrue(app.buttons["camera.3"].exists)
    cameraTypeCapture("face-frozen",[:],controls:["first_tile":app.buttons["camera.0"],"last_tile":app.buttons["camera.3"]])
  }
  func testMockCameraOfflineAndDoorbellSystemTextSizeInventory() {
    continueAfterFailure=false
    launch(["--face","Home Camera","--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("nav.controls");tap("controls.online");tap("nav.faces");tap("camera.0")
    XCTAssertEqual(app.descendants(matching:.any)["camera.demo.status"].label,"Offline · Demo still")
    XCTAssertTrue(app.staticTexts["Mock camera unavailable"].exists)
    cameraTypeCapture("offline",cameraTypeDetailRoles(offline:true),controls:["close":app.buttons["camera.close"],"grid":app.buttons["camera.grid"],"talk":app.buttons["camera.talk"]])
    let warning=app.staticTexts["Mock camera unavailable"]
    revealRecipeTypeElement(warning,margin:10,horizontalMargin:0)
    let viewport=app.otherElements["reference.viewport"].frame,scroll=app.scrollViews.firstMatch
    let clip=recipeTypeScrollContains(warning,scroll) ? scroll.frame.intersection(viewport):viewport
    XCTAssertTrue(axContains(clip,warning.frame),"The complete short offline warning must be readable")
    cameraTypeCapture("offline-warning-visible",["unavailable":warning])
    activateRecipeTypeControl(app.buttons["camera.close"])
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
    launch(["--face","Home Camera","--doorbell-fixture","--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("fixture.doorbell.new")
    XCTAssertTrue(app.staticTexts["doorbell.demo.label"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["fixture.doorbell.route"].label,"face")
    cameraTypeCapture("doorbell",cameraTypeDetailRoles(doorbell:true),controls:["dismiss":app.buttons["doorbell.dismiss"],"talk":app.buttons["camera.talk"],"grid":app.buttons["camera.grid"]])
    activateRecipeTypeControl(app.buttons["doorbell.dismiss"])
    XCTAssertFalse(app.staticTexts["doorbell.demo.label"].exists)
    XCTAssertTrue(app.otherElements["face.Home Camera"].waitForExistence(timeout:5))
  }
}

extension HomeViewUITests {
  private func connectionsLockTypeCapture(_ state:String,_ roles:[String:XCUIElement],onlyVisibleNeighbors:Bool=false) {
    RunLoop.current.run(until:Date().addingTimeInterval(2))
    func box(_ f:CGRect)->[Double] {[f.minX,f.minY,f.width,f.height]}
    let viewport=app.otherElements["reference.viewport"].frame,scroll=app.scrollViews.firstMatch
    func row(_ e:XCUIElement,_ measuredFrame:CGRect?=nil)->[String:Any] {
      let frame=measuredFrame ?? e.frame
      let inside=recipeTypeScrollContains(e,scroll)
      let clip=inside ? scroll.frame.intersection(viewport):viewport
      let intersection=frame.intersection(clip)
      return ["id":e.identifier,"label":e.label,"frame":box(frame),"inside_scroll":inside,
        "effective_clip":box(clip),"fully_in_clip":axContains(clip,frame),
        "visible_intersection":intersection.isNull ? [0,0,0,0]:box(intersection)]
    }
    var selected:[[String:Any]]=[]
    for role in roles.keys.sorted() {
      let e=roles[role]!;XCTAssertTrue(e.exists);XCTAssertFalse(e.frame.isEmpty)
      var r=row(e);r["role"]=role;r["value"]=e.value as? String ?? "";selected.append(r)
    }
    // Retain visible neighbors and the predeclared offscreen font targets;
    // do not repeatedly query unrelated offscreen settings for every pose.
    var extraLabels:[String]=[]
    if !onlyVisibleNeighbors {
      if state=="native-features" {
        extraLabels=["Public system APIs can supply our own UI with calendars, reminders, photos, media and alarms. The original Clock/Home/FaceTime interfaces are not embeddable. Personal Siri, Messages history, HomePod Intercom and Find My are simulations here."]
      } else if state=="connections-home" {
        extraLabels=["Calendar and reminders are protected by your device authentication. Other Apple apps' private history is not imported."]
      } else if state=="shared-heading" {
        extraLabels=["Connecting or unlocking never publishes private contents. In Calendar, share one selected event per display label (up to four). Only title, time and calendar source are published as a snapshot. Demo labels are not household identities. Publications stay in memory until revoked, disconnected, backgrounded or restarted."]
      } else if state=="lock" {extraLabels=["Locked","Mock lock · Device authentication required","Authenticate Device"]}
      else if state=="unlock-gate" {extraLabels=["Unlock personal data","Use this device's authentication for connected personal content and shared album choices.","Unlock"]}
    }
    var extraFrames=roles.values.filter {$0.elementType == .staticText}.map(\.frame)
    for literal in extraLabels {
      let e=app.staticTexts.matching(NSPredicate(format:"label == %@",literal)).firstMatch
      if e.exists {extraFrames.append(e.frame)}
    }
    let texts=app.staticTexts.allElementsBoundByIndex.compactMap {e->[String:Any]? in
      let frame=e.frame
      guard frame.intersects(viewport) || (!onlyVisibleNeighbors && extraFrames.contains(frame)) else {return nil}
      return row(e,frame)
    }
    let report:[String:Any]=["viewport":box(viewport),"roles":selected,
      "static_text_scope":"Viewport intersections plus declared offscreen measurement targets; not an exhaustive AX tree.",
      "offscreen_measurement_labels":extraLabels,"all_static_text":texts]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="connections-lock-type-"+state+"-geometry";a.lifetime = .keepAlways;add(a)
    viewportShot("connections-lock-type-"+state)
  }
  private func revealConnectionsParagraphStart(_ element:XCUIElement) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    let scroll=app.scrollViews.firstMatch,viewport=app.otherElements["reference.viewport"].frame
    XCTAssertTrue(recipeTypeScrollContains(element,scroll))
    for _ in 0..<32 {
      let clip=scroll.frame.intersection(viewport).insetBy(dx:10,dy:10),f=element.frame
      // A declared visible excerpt for color measurement, not a claim that
      // the whole paragraph fits. Interaction probes retain full controls.
      let start=CGRect(x:f.minX,y:f.minY,width:f.width,height:min(64,f.height))
      if axContains(clip,start) {return}
      let gap=start.minY<clip.minY ? start.minY-clip.minY-10:start.maxY-clip.maxY+10
      let distance=min(max(abs(gap),24),clip.height*0.6)*(gap<0 ? -1:1)
      let a=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:clip.minX+8,dy:clip.midY+distance/2))
      let b=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:clip.minX+8,dy:clip.midY-distance/2))
      a.press(forDuration:0.1,thenDragTo:b,withVelocity:.slow,thenHoldForDuration:0.2)
    }
    XCTFail("Policy paragraph start was not visibly reachable")
  }
  func testConnectionsPolicyExcerptsWithoutConnectionOrAuthentication() {
    continueAfterFailure=false
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    let policies=[
      ("native-description-visible","Public system APIs can supply our own UI with calendars, reminders, photos, media and alarms. The original Clock/Home/FaceTime interfaces are not embeddable. Personal Siri, Messages history, HomePod Intercom and Find My are simulations here."),
      ("connections-privacy-visible","Calendar and reminders are protected by your device authentication. Other Apple apps' private history is not imported."),
      ("shared-policy-visible","Connecting or unlocking never publishes private contents. In Calendar, share one selected event per display label (up to four). Only title, time and calendar source are published as a snapshot. Demo labels are not household identities. Publications stay in memory until revoked, disconnected, backgrounded or restarted.")]
    for (state,literal) in policies {
      let text=app.staticTexts.matching(NSPredicate(format:"label == %@",literal)).firstMatch
      revealConnectionsParagraphStart(text)
      connectionsLockTypeCapture(state,["text":text],onlyVisibleNeighbors:true)
    }
    for name in ["Calendar","Reminders","Apple Music","Weather"] {
      let status=app.staticTexts["connection.status."+name]
      revealRecipeTypeElement(status,margin:10)
      XCTAssertEqual(status.label,"Not connected");XCTAssertEqual(app.buttons["connect."+name].label,"Connect "+name)
      connectionsLockTypeCapture("service-"+name.replacingOccurrences(of:" ",with:"-")+"-status-visible",["status":status],onlyVisibleNeighbors:true)
    }
    drawer();tap("app.Home");tap("grid.lock")
    XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked")
    let lockPolicy=app.staticTexts["Mock lock · Device authentication required"]
    revealRecipeTypeElement(lockPolicy,margin:10,horizontalMargin:0)
    connectionsLockTypeCapture("lock-policy-visible",["policy":lockPolicy],onlyVisibleNeighbors:true)
    activateRecipeTypeControl(app.buttons["lock.action"],horizontalMargin:0)
    XCTAssertTrue(app.buttons["device.unlock"].waitForExistence(timeout:5))
    let gatePolicy=app.staticTexts["Use this device's authentication for connected personal content and shared album choices."]
    revealRecipeTypeElement(gatePolicy,margin:10,horizontalMargin:0)
    connectionsLockTypeCapture("unlock-policy-visible",["policy":gatePolicy],onlyVisibleNeighbors:true)
    // Observe text only: never Connect, Update, publish, offer or Unlock.
    tap("close");XCTAssertTrue(app.buttons["all.apps"].waitForExistence(timeout:5))
    tap("all.apps");tap("app.Home");tap("grid.lock")
    XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked")
    XCTAssertEqual(app.buttons["lock.action"].label,"Authenticate Device")
  }

  func testConnectionsAndLockSystemTextSizeReadOnlyInventory() {
    continueAfterFailure=false
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    let warning=app.staticTexts.matching(NSPredicate(format:"label == %@",
      "Apple Home stays disconnected. Other services can be connected below. The system photo picker shares only chosen photos. Automated tests use synthetic data.")).firstMatch
    connectionsLockTypeCapture("settings-top",["title":app.staticTexts["Settings"],"scope":warning])
    for (state,e) in [
      ("native-features",app.staticTexts["Native system features"]),
      ("connections-heading",app.staticTexts["Connected services"]),
      ("connections-home",app.staticTexts["connections.home.locked"]),
      ("connections-guest",app.staticTexts["guest.policy.summary"]),
      ("shared-heading",app.staticTexts["Shared faces"]),
      ("shared-empty",app.staticTexts["shared.calendar.empty"])] {
      revealRecipeTypeElement(e,margin:10)
      connectionsLockTypeCapture(state,["text":e])
    }
    for name in ["Calendar","Reminders","Apple Music","Weather"] {
      let button=app.buttons["connect."+name],status=app.staticTexts["connection.status."+name]
      revealRecipeTypeElement(button,margin:10)
      XCTAssertEqual(button.label,"Connect "+name);XCTAssertEqual(status.label,"Not connected")
      connectionsLockTypeCapture("service-"+name.replacingOccurrences(of:" ",with:"-"),
        ["service":app.staticTexts[name],"connect_control":button,"status":status])
    }
    // Deliberately never press Connect, Update, links, sharing or authentication.
    drawer();tap("app.Home");tap("grid.lock")
    let locked=app.staticTexts["lock.state"],action=app.buttons["lock.action"]
    XCTAssertEqual(locked.label,"Locked");XCTAssertEqual(action.label,"Authenticate Device")
    connectionsLockTypeCapture("lock",["state":locked,"policy":app.staticTexts["Mock lock · Device authentication required"],"action_control":action])
    activateRecipeTypeControl(action,horizontalMargin:0)
    XCTAssertTrue(app.buttons["device.unlock"].waitForExistence(timeout:5))
    connectionsLockTypeCapture("unlock-gate",["title":app.staticTexts["Unlock personal data"],
      "policy":app.staticTexts["Use this device's authentication for connected personal content and shared album choices."],"unlock_control":app.buttons["device.unlock"]])
    let unlock=app.buttons["device.unlock"]
    revealRecipeTypeElement(unlock,margin:10,horizontalMargin:0)
    let gateScroll=app.scrollViews.firstMatch,gateViewport=app.otherElements["reference.viewport"].frame
    let gateClip=recipeTypeScrollContains(unlock,gateScroll) ? gateScroll.frame.intersection(gateViewport):gateViewport
    XCTAssertTrue(axContains(gateClip,unlock.frame),"Observe the full Unlock control without invoking authentication")
    connectionsLockTypeCapture("unlock-control-visible",["unlock_control":unlock],onlyVisibleNeighbors:true)
    // Leaving this local gate never invokes the Unlock callback or provider.
    tap("close")
    XCTAssertTrue(app.buttons["all.apps"].waitForExistence(timeout:5))
    connectionsLockTypeCapture("returned-personal",["all_apps_control":app.buttons["all.apps"]])
    tap("all.apps");tap("app.Home");tap("grid.lock")
    XCTAssertEqual(locked.label,"Locked");XCTAssertEqual(action.label,"Authenticate Device")
    tap("close");XCTAssertTrue(app.buttons["all.apps"].waitForExistence(timeout:5))
    tap("all.apps");tap("app.Home");tap("grid.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
  }
}

extension HomeViewUITests {
  private func recipeTypeScrollContains(_ element:XCUIElement,_ scroll:XCUIElement)->Bool {
    guard scroll.exists else {return false}
    let candidates=scroll.descendants(matching:element.elementType)
    return element.identifier.isEmpty
      ? candidates.matching(NSPredicate(format:"label == %@",element.label)).count>0
      : candidates.matching(identifier:element.identifier).count>0
  }
  private func revealRecipeTypeElement(_ element:XCUIElement,margin:CGFloat=2,horizontalMargin:CGFloat?=nil) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    let scroll=app.scrollViews.firstMatch,viewport=app.otherElements["reference.viewport"].frame
    let insideScroll=recipeTypeScrollContains(element,scroll)
    let recordCamera=element.identifier.hasPrefix("camera.")
    var cameraTrace:[[String:Any]]=[],cameraReached=false
    defer {
      if recordCamera {
        let report:[String:Any]=["id":element.identifier,"inside_scroll":insideScroll,"reached":cameraReached,"steps":cameraTrace]
        let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
        a.name="camera-scroll-trace-"+element.identifier;a.lifetime = .keepAlways;add(a)
        if !cameraReached {viewportShot("camera-scroll-failure-"+element.identifier)}
      }
    }
    for _ in 0..<16 {
      let clip=(insideScroll ? scroll.frame.intersection(viewport):viewport).insetBy(dx:horizontalMargin ?? margin,dy:margin),f=element.frame
      if recordCamera {cameraTrace.append(["frame":[f.minX,f.minY,f.width,f.height],"clip":[clip.minX,clip.minY,clip.width,clip.height]])}
      if axContains(clip,f) || (f.height>clip.height && f.intersection(clip).height>=min(44,clip.height)) {cameraReached=true;return}
      guard insideScroll else {XCTFail("Recipe target is outside its actual clip: "+element.identifier);return}
      let gap=f.minY<clip.minY ? f.minY-clip.minY-10:f.maxY-clip.maxY+10
      let distance=min(max(abs(gap),24),clip.height*0.6)*(gap<0 ? -1:1),y=clip.midY
      let start=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:clip.minX+8,dy:y+distance/2))
      let end=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:clip.minX+8,dy:y-distance/2))
      start.press(forDuration:0.1,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.2)
    }
    XCTFail("Recipe target was never visibly reachable: "+element.identifier)
  }
  private func activateRecipeTypeControl(_ element:XCUIElement,horizontalMargin:CGFloat?=nil) {
    revealRecipeTypeElement(element,horizontalMargin:horizontalMargin)
    let viewport=app.otherElements["reference.viewport"].frame,scroll=app.scrollViews.firstMatch
    let clip=recipeTypeScrollContains(element,scroll) ? scroll.frame.intersection(viewport):viewport
    let visible=element.frame.intersection(clip).insetBy(dx:2,dy:2)
    XCTAssertFalse(visible.isEmpty);XCTAssertTrue(element.isEnabled)
    // A functional center probe, not a minimum-hit-size/edge audit. A large
    // scrollable row need not fit wholly on screen to have a visible action.
    app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:visible.midX-app.frame.minX,dy:visible.midY-app.frame.minY)).tap()
  }
  private func recipeTypeCapture(_ state:String,_ elements:[String:XCUIElement]) {
    func box(_ f:CGRect)->[Double] {[f.minX,f.minY,f.width,f.height]}
    RunLoop.current.run(until:Date().addingTimeInterval(2))
    let viewport=app.otherElements["reference.viewport"].frame
    let scroll=app.scrollViews.firstMatch
    func effectiveClip(_ e:XCUIElement)->CGRect {
      recipeTypeScrollContains(e,scroll) ? scroll.frame.intersection(viewport):viewport
    }
    var rows:[[String:Any]]=[]
    for role in elements.keys.sorted() {
      let e=elements[role]!,f=e.frame;XCTAssertTrue(e.exists);XCTAssertFalse(f.isEmpty)
      let visible=f.intersects(viewport)
      rows.append(["role":role,"label":e.label,"frame":box(f),"fully_in_viewport":axContains(viewport,f),
        "effective_clip":box(effectiveClip(e)),"fully_in_clip":axContains(effectiveClip(e),f),
        "intersects_clip":visible,"visible_intersection":visible ? box(f.intersection(viewport)):[0,0,0,0],"AX_hittable":e.isHittable])
    }
    let texts=app.staticTexts.allElementsBoundByIndex.map {e->[String:Any] in
      ["id":e.identifier,"label":e.label,"frame":box(e.frame),"fully_in_viewport":axContains(viewport,e.frame),
        "effective_clip":box(effectiveClip(e)),"fully_in_clip":axContains(effectiveClip(e),e.frame)]
    }
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:["app":box(app.frame),"clip":box(viewport),"elements":rows,"all_static_text":texts],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="recipe-type-"+state+"-geometry";a.lifetime = .keepAlways;add(a)
    viewportShot("recipe-type-"+state)
  }
  func testRecipeSystemTextSizeInventoryKeepsChecksStepsAndNoTimer() {
    continueAfterFailure=false
    let owned=UUID().uuidString,title="Butternut Squash Soup"
    launch(["--page","Recipes","--persistence-test",owned,"--reset-test-store"])
    let row=app.buttons["saved."+title]
    XCTAssertTrue(row.waitForExistence(timeout:5))
    recipeTypeCapture("library",["heading":app.staticTexts["Recent & Pinned"],"recipe_control":row])
    revealRecipeTypeElement(row,margin:10)
    recipeTypeCapture("library-row-visible",["recipe_control":row])
    activateRecipeTypeControl(row)
    XCTAssertTrue(app.buttons["recipe.ingredients"].waitForExistence(timeout:5))
    recipeTypeCapture("cover",["title":app.staticTexts[title],"ingredients_control":app.buttons["recipe.ingredients"],"start_control":app.buttons["recipe.start"]])
    activateRecipeTypeControl(app.buttons["recipe.ingredients"])
    let first=app.buttons["ingredient.0"],last=app.buttons["ingredient.5"]
    XCTAssertEqual(first.value as? String,"Unchecked");activateRecipeTypeControl(first)
    XCTAssertEqual(first.value as? String,"Checked")
    recipeTypeCapture("ingredients-first",["title":app.staticTexts["Ingredients"],"first_control":first])
    activateRecipeTypeControl(first);XCTAssertEqual(first.value as? String,"Unchecked")
    activateRecipeTypeControl(last);XCTAssertEqual(last.value as? String,"Checked")
    recipeTypeCapture("ingredients-last",["last_control":last])
    app.terminate();launch(["--screen-recipe","--persistence-test",owned])
    activateRecipeTypeControl(app.buttons["recipe.start"])
    let step=app.staticTexts["cooking.step"],instruction=app.staticTexts["cooking.text"]
    XCTAssertEqual(step.label,"Step 1 of 3");XCTAssertTrue(instruction.label.contains("olive oil"))
    let original=instruction.label
    recipeTypeCapture("cooking-first",["step":step,"instruction":instruction,"next_control":app.buttons["cooking.next"],"handoff_control":app.buttons["cooking.handoff"]])
    revealRecipeTypeElement(app.buttons["cooking.timer"],margin:10)
    recipeTypeCapture("cooking-timer-control",["timer_control":app.buttons["cooking.timer"]])
    revealRecipeTypeElement(app.buttons["cooking.handoff"],margin:10)
    recipeTypeCapture("cooking-handoff-control",["handoff_control":app.buttons["cooking.handoff"]])
    activateRecipeTypeControl(app.buttons["cooking.handoff"])
    XCTAssertTrue(app.buttons["recipe.handoff.offer"].waitForExistence(timeout:5))
    recipeTypeCapture("handoff",["title":app.staticTexts["Recipe Handoff"],"done_control":app.buttons["recipe.handoff.done"]])
    let policy=app.staticTexts["Recipe text, ingredients and source URLs are not copied. Save the same recipe on both devices first."]
    revealRecipeTypeElement(policy,margin:10)
    recipeTypeCapture("handoff-policy-visible",["policy":policy])
    // No offer, transfer, authentication or system activity is invoked.
    activateRecipeTypeControl(app.buttons["recipe.handoff.done"])
    XCTAssertEqual(step.label,"Step 1 of 3");XCTAssertEqual(instruction.label,original)
    revealRecipeTypeElement(app.buttons["cooking.next"],margin:10)
    recipeTypeCapture("cooking-next-control",["next_control":app.buttons["cooking.next"]])
    activateRecipeTypeControl(app.buttons["cooking.next"])
    XCTAssertEqual(step.label,"Step 2 of 3");XCTAssertTrue(instruction.label.contains("squash"))
    recipeTypeCapture("cooking-second",["step":step,"instruction":instruction])
    activateRecipeTypeControl(app.buttons["Previous step"])
    XCTAssertEqual(step.label,"Step 1 of 3");XCTAssertEqual(instruction.label,original)
    for _ in 0..<3 {activateRecipeTypeControl(app.buttons["cooking.next"])}
    XCTAssertTrue(app.buttons["recipe.start"].waitForExistence(timeout:5))
    tap("nav.faces");drawer();tap("app.Timers")
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5));XCTAssertFalse(app.staticTexts["timer.countdown"].exists)
    drawer();tap("app.Home");tap("grid.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
  }
}

extension HomeViewUITests {
  private func faceEditorPresentationCapture(_ state:String,_ elements:[String:XCUIElement],sheet:Bool=false) {
    func box(_ f:CGRect)->[Double] {[f.minX,f.minY,f.width,f.height]}
    RunLoop.current.run(until:Date().addingTimeInterval(2))
    let before=elements.mapValues {box($0.frame)},began=ProcessInfo.processInfo.systemUptime
    RunLoop.current.run(until:Date().addingTimeInterval(2))
    let clip=sheet ? app.frame:app.otherElements["reference.viewport"].frame
    var rows:[[String:Any]]=[]
    for role in elements.keys.sorted() {
      let e=elements[role]!,f=e.frame,after=box(f)
      XCTAssertTrue(e.exists);XCTAssertFalse(f.isEmpty);XCTAssertTrue(axContains(clip,f))
      for i in after.indices {XCTAssertEqual(before[role]![i],after[i],accuracy:0.5)}
      rows.append(["role":role,"label":e.label,"frame":after,"before_wait_frame":before[role]!,"AX_hittable":e.isHittable])
    }
    let text=app.staticTexts.allElementsBoundByIndex.map {e->[String:Any] in
      ["identifier":e.identifier,"label":e.label,"frame":box(e.frame),"fully_in_clip":axContains(clip,e.frame)]
    }
    let payload:[String:Any]=["app":box(app.frame),"clip":box(clip),"elements":rows,"all_static_text":text,
      "declared_wait_seconds":2,"elapsed_seconds":ProcessInfo.processInfo.systemUptime-began]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:payload,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="face-editor-presentation-"+state+"-geometry";a.lifetime = .keepAlways;add(a)
    if sheet {shot("face-editor-presentation-"+state)} else {viewportShot("face-editor-presentation-"+state)}
  }
  func testFaceEditorPresentationInventoryKeepsSlotAndReadOnlyHome() {
    continueAfterFailure=false
    launchFaceEditorAudit("Modular")
    faceEditorPresentationCapture("root-top",["title":app.staticTexts["Faces"],"face_control":app.buttons["select.Modular"]])
    let slot=app.buttons["widget.0"]
    scrollEditorIntoView(slot)
    let original=slot.label
    XCTAssertTrue(original.contains("Top left"));XCTAssertTrue(original.contains("Date"))
    faceEditorPresentationCapture("root-list",["slot_control":slot])
    for opening in ["first","reopened"] {
      slot.tap()
      let done=app.buttons["complications.done"]
      XCTAssertTrue(done.waitForExistence(timeout:5));waitEditorFrameStable(done)
      let headers=app.staticTexts.matching(NSPredicate(format:"label == %@","Top left"))
      XCTAssertGreaterThan(headers.count,0)
      let nearest=(0..<headers.count).min {abs(headers.element(boundBy:$0).frame.midY-done.frame.midY)<abs(headers.element(boundBy:$1).frame.midY-done.frame.midY)}!
      // SwiftUI exposes this plain button as a combined AX node, not a
      // StaticText child. Keep its measured control bounds distinct from text.
      let header=headers.element(boundBy:nearest),off=app.buttons["complication.choose.Off"]
      XCTAssertLessThan(abs(header.frame.midY-done.frame.midY),1)
      faceEditorPresentationCapture("sheet-"+opening,["title":header,"off_control":off,"done_control":done],sheet:true)
      done.tap();XCTAssertTrue(slot.waitForExistence(timeout:5));XCTAssertEqual(slot.label,original)
    }
    tap("editor.done");drawer();tap("app.Home");tap("grid.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
  }
}

extension HomeViewUITests {
  private func timerSetupDuration(_ label:String)->XCUIElement {
    let items=app.staticTexts.matching(NSPredicate(format:"label == %@",label))
    XCTAssertGreaterThan(items.count,0)
    let index=(0..<items.count).max {items.element(boundBy:$0).frame.height<items.element(boundBy:$1).frame.height}!
    return items.element(boundBy:index)
  }
  private func launchEmptyTimerSetup() {
    launch(["--persistence-test",UUID().uuidString,"--reset-test-store","--page","Timers"])
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["timer.countdown"].exists)
  }
  func testTimerSetupSystemTextSizeKeepsDurationAndPresetControls() {
    launchEmptyTimerSetup()
    let duration=timerSetupDuration("15 min"),title=app.staticTexts["Timers"],start=app.buttons["timer.start"]
    revealAccessibleTimerElement(title);revealAccessibleTimerElement(duration);revealAccessibleTimerElement(start)
    systemTextSizeGeometry("timer-setup",["title":title,"duration":duration,"start_control":start,
      "viewport":app.otherElements["reference.viewport"]])
    viewportShot("system-text-size-timer-setup")
    let decrease=app.buttons["Decrease minutes"],increase=app.buttons["Increase minutes"]
    revealAccessibleTimerElement(decrease);decrease.tap();XCTAssertTrue(timerSetupDuration("14 min").exists)
    revealAccessibleTimerElement(increase);increase.tap();XCTAssertTrue(timerSetupDuration("15 min").exists)
    let preset=app.buttons["5 min"];revealAccessibleTimerElement(preset);preset.tap()
    XCTAssertTrue(timerSetupDuration("5 min").exists);XCTAssertFalse(app.staticTexts["timer.countdown"].exists)
  }
  private func verifyTimerSetupStartCorner(bottomRight:Bool) {
    launchEmptyTimerSetup()
    let start=app.buttons["timer.start"];revealAccessibleTimerElement(start)
    let f=start.frame,target=CGRect(x:f.midX-22,y:f.midY-22,width:44,height:44)
    XCTAssertTrue(axContains(app.otherElements["reference.viewport"].frame,target));XCTAssertTrue(start.isEnabled)
    systemTextSizeGeometry(bottomRight ? "timer-setup-start-bottom-right":"timer-setup-start-top-left",
      ["start_control":start,"viewport":app.otherElements["reference.viewport"]])
    viewportShot(bottomRight ? "timer-setup-start-bottom-right":"timer-setup-start-top-left")
    let offset:CGFloat=bottomRight ? 42:2
    app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:target.minX+offset-app.frame.minX,dy:target.minY+offset-app.frame.minY)).tap()
    XCTAssertTrue(app.staticTexts["timer.countdown"].waitForExistence(timeout:3))
    XCTAssertEqual(app.staticTexts["timer.title"].label,"15 MIN")
    revealAccessibleTimerElement(app.buttons["timer.pause"]);tap("timer.pause")
    XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
    let remaining=timerSelectionSeconds();XCTAssertGreaterThan(remaining,870);XCTAssertLessThanOrEqual(remaining,900)
    revealAccessibleTimerElement(app.buttons["timer.delete"]);tap("timer.delete")
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5))
  }
  func testTimerSetupStartTopLeftMinimum44PointAction() {verifyTimerSetupStartCorner(bottomRight:false)}
  func testTimerSetupStartBottomRightMinimum44PointAction() {verifyTimerSetupStartCorner(bottomRight:true)}
  private func revealAccessibleTimerElement(_ element:XCUIElement) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    let readout=app.scrollViews["timer.accessible.content"],setup=app.scrollViews["timer.setup.accessible.content"]
    let scroll=readout.exists ? readout:setup
    guard scroll.exists else {return}
    var poses:[[String:Any]]=[]
    defer {
      let data=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:poses,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
      data.name="timer-accessible-scroll-"+element.identifier;data.lifetime = .keepAlways;add(data)
      shot("timer-accessible-reached-"+element.identifier)
    }
    for step in 0..<12 {
      let safe=scroll.frame.intersection(app.otherElements["reference.viewport"].frame).insetBy(dx:16,dy:16)
      let f=element.frame
      func box(_ r:CGRect)->[Double] {[r.minX,r.minY,r.width,r.height]}
      poses.append(["step":step,"target":box(f),"scroll":box(scroll.frame),"safe":box(safe),"AX_hittable":element.isHittable])
      // Text need not be an AX hit target. Buttons are verified by their
      // enabled state, exact visible bounds and actual selection/delete result.
      if axContains(safe,f) {return}
      if f.minY<safe.minY {scroll.swipeDown(velocity:.slow)} else {scroll.swipeUp(velocity:.slow)}
    }
    XCTFail("Timer element never became fully visible: \(element.identifier) \(element.frame)")
  }
  private func verifyAccessibleTimerChoice(_ number:Int,title:String,value:String) {
    XCTAssertEqual(app.staticTexts["timer.title"].label,title)
    XCTAssertEqual(app.staticTexts["timer.countdown"].label,value)
    XCTAssertEqual(timerChoice(number).value as? String,"Selected")
    let choices=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","timer.select."))
    XCTAssertEqual((0..<choices.count).filter {choices.element(boundBy:$0).value as? String == "Selected"}.count,1)
  }
  func testTimerSystemTextSizeKeepsPausedValueAndDeleteAction() {
    launch(["--reference-timer"])
    let title=app.staticTexts["timer.title"],status=app.staticTexts["timer.systemStatus"],countdown=app.staticTexts["timer.countdown"]
    XCTAssertTrue(countdown.waitForExistence(timeout:5))
    XCTAssertEqual(countdown.label,"10:56");XCTAssertEqual(title.label,"15 MIN")
    XCTAssertEqual(status.label,"Foreground timer");XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
    let viewport=app.otherElements["reference.viewport"]
    revealAccessibleTimerElement(countdown);revealAccessibleTimerElement(title)
    XCTAssertTrue(axContains(viewport.frame,title.frame));viewportShot("system-text-size-timer-single-title")
    revealAccessibleTimerElement(status);XCTAssertTrue(axContains(viewport.frame,status.frame))
    systemTextSizeGeometry("timer-single",["title":title,"status":status,"countdown":countdown,
      "pause":app.buttons["timer.pause"],"delete":app.buttons["timer.delete"],"viewport":viewport])
    viewportShot("system-text-size-timer-single")
    revealAccessibleTimerElement(app.buttons["timer.pause"])
    revealAccessibleTimerElement(app.buttons["timer.delete"]);tap("timer.delete")
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5))
    XCTAssertFalse(countdown.exists)
  }
  func testTimerChoicesSystemTextSizeKeepsSelectionAndPeerValues() {
    launch(["--multiple-timers-fixture"])
    let choices=app.scrollViews["timer.choices"],tea=timerChoice(101),countdown=app.staticTexts["timer.countdown"]
    XCTAssertTrue(choices.waitForExistence(timeout:5))
    XCTAssertEqual(countdown.label,"10:00");XCTAssertEqual(app.staticTexts["timer.title"].label,"BREAD")
    XCTAssertEqual(tea.label,"Tea timer, 03:00");XCTAssertEqual(tea.value as? String,"Not selected")
    revealAccessibleTimerElement(tea)
    systemTextSizeGeometry("timer-choices",["choice":tea,"choices":choices,"title":app.staticTexts["timer.title"],
      "status":app.staticTexts["timer.systemStatus"],"countdown":countdown,"viewport":app.otherElements["reference.viewport"]])
    viewportShot("system-text-size-timer-choices")
    XCTAssertTrue(axContains(choices.frame,tea.frame),"choice=\(tea.frame), row=\(choices.frame)")
    XCTAssertTrue(tea.isEnabled)
    if app.scrollViews["timer.accessible.content"].exists {
      // This nested scroll's visible, enabled button can report false AX
      // hittability. Deliver real pointer input, then require exact read-back.
      let f=tea.frame
      app.coordinate(withNormalizedOffset:.zero)
        .withOffset(CGVector(dx:f.midX-app.frame.minX,dy:f.midY-app.frame.minY)).tap()
    } else {tea.tap()}
    verifyAccessibleTimerChoice(101,title:"TEA",value:"03:00")
    revealAccessibleTimerElement(app.staticTexts["timer.title"])
    revealAccessibleTimerElement(app.buttons["timer.delete"]);tap("timer.delete")
    XCTAssertFalse(timerChoice(101).exists)
    verifyAccessibleTimerChoice(103,title:"BREAD",value:"10:00")
    revealAccessibleTimerElement(countdown)
    XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
  }
}

extension HomeViewUITests {
  private func personalEditorContrastCapture(_ state:String,_ elements:[String:XCUIElement]) {
    func box(_ f:CGRect)->[Double] {[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)]}
    let before=elements.mapValues {box($0.frame)},began=ProcessInfo.processInfo.systemUptime
    RunLoop.current.run(until:Date().addingTimeInterval(2))
    var rows:[[String:Any]]=[]
    for role in elements.keys.sorted() {
      let e=elements[role]!,frame=e.frame
      XCTAssertTrue(e.exists);XCTAssertFalse(frame.isEmpty);XCTAssertTrue(app.frame.contains(frame))
      let after=box(frame)
      for i in after.indices {XCTAssertEqual(before[role]![i],after[i],accuracy:0.5)}
      rows.append(["role":role,"label":e.label,"frame":after,"before_wait_frame":before[role]!,"AX_hittable":e.isHittable])
    }
    let data:[String:Any]=["app":box(app.frame),"elements":rows,"declared_wait_seconds":2,
      "elapsed_seconds":ProcessInfo.processInfo.systemUptime-began]
    let attachment=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    attachment.name="personal-editor-contrast-"+state+"-geometry";attachment.lifetime = .keepAlways;add(attachment)
    shot("personal-editor-contrast-"+state)
  }
  func testPersonalEditorSettledTextContrastKeepsConfigurationAndRootPixels() {
    continueAfterFailure=false
    let owned=UUID().uuidString
    print("PERSONAL_EDITOR_CONTRAST_OWNED_STORE "+owned)
    launch(["--persistence-test",owned,"--reset-test-store","--face","Modular","--reduce-motion"])
    tap("nav.apps");tap("personal.profile");tap("profile.Alex")
    XCTAssertTrue(app.otherElements["personal.photos.layout"].waitForExistence(timeout:5))
    RunLoop.current.run(until:Date().addingTimeInterval(2))
    let root=viewportBytes("personal-editor-contrast-root-before")
    func configuration()->[String:String] {
      var value:[String:String]=[:]
      for key in ["personal.layout.photos","personal.layout.media","personal.layout.weather"]+(0..<4).map({"personal.favorite.\($0)"}) {
        let e=responseElement(key);XCTAssertTrue(e.exists)
        value[key]=e.label+" | "+(e.value as? String ?? "")
      }
      return value
    }
    func openEditor() {
      app.buttons["personal.profile"].press(forDuration:1);tap("personal.edit")
      XCTAssertTrue(app.staticTexts["Home Screen · Alex"].waitForExistence(timeout:5))
    }
    func labels()->[String:XCUIElement] {
      ["title":app.staticTexts["Home Screen · Alex"],"layout":app.staticTexts["Layout"],
        "favorites":app.staticTexts["Favorite apps"],
        "disclosure":app.staticTexts["Layout choices are saved for this demo profile. They do not unlock personal accounts."]]
    }
    openEditor();let before=configuration()
    personalEditorContrastCapture("personal-first",labels())
    tap("personal.editor.done");XCTAssertTrue(app.buttons["personal.profile"].waitForExistence(timeout:5))
    openEditor();XCTAssertEqual(configuration(),before)
    personalEditorContrastCapture("personal-reopened",labels())
    tap("personal.editor.done");XCTAssertTrue(app.buttons["personal.profile"].waitForExistence(timeout:5))
    RunLoop.current.run(until:Date().addingTimeInterval(2))
    XCTAssertEqual(viewportPixels(root,inset:0),viewportPixels(viewportBytes("personal-editor-contrast-root-returned"),inset:0))
    tap("nav.assistant");tap("assistant.capabilities")
    XCTAssertTrue(app.staticTexts["Assistant capabilities"].waitForExistence(timeout:5))
    personalEditorContrastCapture("capabilities-positive",["positive_title":app.staticTexts["Assistant capabilities"]])
    tap("assistant.capabilities.done");drawer();tap("app.Home");tap("grid.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
  }
}

extension HomeViewUITests {
  private enum SecondaryHitTarget:String {
    case capabilities,personalEditor,recipeHandoff,musicArtwork,resetCancel,power,notices,timerActivity,voiceCancel
    var identifier:String {
      switch self {
      case .capabilities:return "assistant.capabilities.done"
      case .personalEditor:return "personal.editor.done"
      case .recipeHandoff:return "recipe.handoff.done"
      case .musicArtwork:return "music.artwork.done"
      case .resetCancel:return "reset.cancel"
      case .power:return "power.capabilities.done"
      case .notices:return "notices.done"
      case .timerActivity:return "timer.activity.done"
      case .voiceCancel:return "assistant.voice.cancel"
      }
    }
  }
  private func verifySecondaryHitTarget(_ target:SecondaryHitTarget,bottomRight:Bool) {
    continueAfterFailure=false
    let owned=UUID().uuidString,draft="OWNED_HIT_DRAFT",edge=bottomRight ? "bottom-right":"top-left"
    print("SECONDARY_HIT_OWNED_STORE "+owned+" target="+target.rawValue+" edge="+edge)
    var args=["--persistence-test",owned,"--reset-test-store"]
    switch target {
    case .recipeHandoff:args += ["--screen-recipe"]
    case .musicArtwork:args += ["--page","Music"]
    case .resetCancel,.power:args += ["--page","Settings"]
    case .timerActivity:args += ["--page","Settings","--timer-activity-fixture"]
    case .capabilities,.voiceCancel:args += ["--answer-speech-fixture"]
    default:break
    }
    launch(args)
    var retained=""
    switch target {
    case .capabilities:
      tap("nav.assistant")
      let input=app.textFields["assistant.input"];input.tap();input.typeText(draft)
      tap("assistant.capabilities")
    case .personalEditor:
      tap("nav.apps");tap("personal.profile");tap("profile.Alex")
      app.buttons["personal.profile"].press(forDuration:1);tap("personal.edit")
      XCTAssertTrue(app.staticTexts["Home Screen · Alex"].waitForExistence(timeout:5))
    case .recipeHandoff:
      tap("recipe.start")
      XCTAssertTrue(app.staticTexts["cooking.text"].waitForExistence(timeout:5))
      retained=app.staticTexts["cooking.text"].label;tap("cooking.handoff")
      XCTAssertFalse(app.buttons["recipe.handoff.stop"].exists)
    case .musicArtwork:
      XCTAssertEqual(app.buttons["player.play"].label,"Play");tap("music.artwork.info.demo")
      XCTAssertEqual(app.staticTexts["music.artwork.source"].label,"Bundled demo player")
    case .resetCancel:
      openResetReview();XCTAssertFalse(app.buttons["reset.confirm"].exists)
    case .power:
      let power=app.buttons["settings.power"];scrollPhotoControlFullyIntoView(power);power.tap()
      XCTAssertTrue(app.staticTexts["power.assessment"].waitForExistence(timeout:5))
      XCTAssertEqual(app.staticTexts["power.assessment"].label,"Adapter adequacy: Not available")
    case .notices:
      openMockNotices();XCTAssertTrue(app.staticTexts["notices.empty"].exists)
      XCTAssertEqual(app.staticTexts["notices.count"].label,"0 groups · 0 visible events")
    case .timerActivity:
      openTimerActivitySettings();XCTAssertEqual(app.switches["timer.activity.enabled"].value as? String,"0")
    case .voiceCancel:
      tap("nav.assistant")
      let input=app.textFields["assistant.input"];input.tap();input.typeText(draft)
      retained=app.staticTexts["assistant.reply"].label;tap("assistant.voice")
      XCTAssertTrue(app.staticTexts["assistant.voice.status"].label.contains("Synthetic"))
      revealPlanControl(app.buttons[target.identifier])
    }
    let button=app.buttons[target.identifier]
    XCTAssertTrue(button.waitForExistence(timeout:5));XCTAssertTrue(button.isEnabled)
    // The visible synthetic voice Cancel can report false AX hittability.
    // Its full scroll-clip containment and real corner action remain required.
    if target != .voiceCancel {XCTAssertTrue(button.isHittable)}
    let frame=button.frame,bounds=app.frame
    XCTAssertFalse(frame.isEmpty);XCTAssertTrue(bounds.contains(frame))
    let nativeToolbar=target == .musicArtwork || target == .timerActivity
    // UIKit's reported toolbar frame is not its hit-test bounds. Probe the
    // actual corners of a centered >=44-point rectangle, including outside
    // the reported 36-point height, instead of restyling a system button.
    let touchFrame=nativeToolbar
      ? CGRect(x:frame.midX-max(44,frame.width)/2,y:frame.midY-max(44,frame.height)/2,
        width:max(44,frame.width),height:max(44,frame.height)):frame
    XCTAssertTrue(bounds.contains(touchFrame))
    let point=CGPoint(x:bottomRight ? touchFrame.maxX-2:touchFrame.minX+2,y:bottomRight ? touchFrame.maxY-2:touchFrame.minY+2)
    func box(_ f:CGRect)->[Double] {[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)]}
    let data:[String:Any]=["target":target.rawValue,"identifier":target.identifier,"edge":edge,
      "frame":box(frame),"app":box(bounds),"point":[Double(point.x),Double(point.y)],"owned_store":owned,
      "AX_hittable":button.isHittable,"enabled":button.isEnabled,"native_toolbar":nativeToolbar,"touch_frame":box(touchFrame)]
    let attachment=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    attachment.name="secondary-hit-"+target.rawValue+"-"+edge+"-geometry";attachment.lifetime = .keepAlways;add(attachment)
    shot("secondary-hit-"+target.rawValue+"-"+edge+"-before")
    continueAfterFailure=true
    if !nativeToolbar {
      XCTAssertGreaterThanOrEqual(frame.width,44-0.000_001,"minimum hit width: "+target.rawValue)
      XCTAssertGreaterThanOrEqual(frame.height,44-0.000_001,"minimum hit height: "+target.rawValue)
    }
    continueAfterFailure=false
    app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:point.x-bounds.minX,dy:point.y-bounds.minY)).tap()
    expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:button);waitForExpectations(timeout:5)
    switch target {
    case .capabilities:
      XCTAssertTrue(app.buttons["assistant.capabilities"].waitForExistence(timeout:5))
      XCTAssertEqual(app.textFields["assistant.input"].value as? String,draft)
    case .personalEditor:
      XCTAssertTrue(app.buttons["personal.profile"].waitForExistence(timeout:5))
      app.buttons["personal.profile"].press(forDuration:1);tap("personal.edit")
      XCTAssertTrue(app.staticTexts["Home Screen · Alex"].waitForExistence(timeout:5));tap("personal.editor.done")
    case .recipeHandoff:
      XCTAssertTrue(app.staticTexts["cooking.text"].waitForExistence(timeout:5))
      XCTAssertEqual(app.staticTexts["cooking.text"].label,retained);XCTAssertFalse(app.buttons["timer.pause"].exists)
    case .musicArtwork:
      XCTAssertTrue(app.buttons["music.artwork.info.demo"].waitForExistence(timeout:5))
      XCTAssertEqual(app.buttons["player.play"].label,"Play")
    case .resetCancel:
      XCTAssertTrue(app.buttons["settings.reset"].waitForExistence(timeout:5))
      openResetReview();XCTAssertFalse(app.textFields["reset.confirmation"].exists)
      XCTAssertFalse(app.buttons["reset.confirm"].exists);tap("reset.cancel")
    case .power:XCTAssertTrue(app.buttons["settings.power"].waitForExistence(timeout:5))
    case .notices:
      XCTAssertTrue(app.buttons["controls.notices"].waitForExistence(timeout:5))
      openMockNotices();XCTAssertEqual(app.staticTexts["notices.count"].label,"0 groups · 0 visible events");tap("notices.done")
    case .timerActivity:
      XCTAssertTrue(app.buttons["settings.timer-activity"].waitForExistence(timeout:5))
      openTimerActivitySettings();XCTAssertEqual(app.switches["timer.activity.enabled"].value as? String,"0");tap("timer.activity.done")
    case .voiceCancel:
      XCTAssertEqual(app.textFields["assistant.input"].value as? String,draft)
      XCTAssertEqual(app.staticTexts["assistant.reply"].label,retained)
    }
    shot("secondary-hit-"+target.rawValue+"-"+edge+"-returned")
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
  }
  func testSecondaryCapabilitiesTopLeft() {verifySecondaryHitTarget(.capabilities,bottomRight:false)}
  func testSecondaryCapabilitiesBottomRight() {verifySecondaryHitTarget(.capabilities,bottomRight:true)}
  func testSecondaryPersonalEditorTopLeft() {verifySecondaryHitTarget(.personalEditor,bottomRight:false)}
  func testSecondaryPersonalEditorBottomRight() {verifySecondaryHitTarget(.personalEditor,bottomRight:true)}
  func testSecondaryRecipeHandoffTopLeft() {verifySecondaryHitTarget(.recipeHandoff,bottomRight:false)}
  func testSecondaryRecipeHandoffBottomRight() {verifySecondaryHitTarget(.recipeHandoff,bottomRight:true)}
  func testSecondaryMusicArtworkTopLeft() {verifySecondaryHitTarget(.musicArtwork,bottomRight:false)}
  func testSecondaryMusicArtworkBottomRight() {verifySecondaryHitTarget(.musicArtwork,bottomRight:true)}
  func testSecondaryResetCancelTopLeft() {verifySecondaryHitTarget(.resetCancel,bottomRight:false)}
  func testSecondaryResetCancelBottomRight() {verifySecondaryHitTarget(.resetCancel,bottomRight:true)}
  func testSecondaryPowerTopLeft() {verifySecondaryHitTarget(.power,bottomRight:false)}
  func testSecondaryPowerBottomRight() {verifySecondaryHitTarget(.power,bottomRight:true)}
  func testSecondaryNoticesTopLeft() {verifySecondaryHitTarget(.notices,bottomRight:false)}
  func testSecondaryNoticesBottomRight() {verifySecondaryHitTarget(.notices,bottomRight:true)}
  func testSecondaryTimerActivityTopLeft() {verifySecondaryHitTarget(.timerActivity,bottomRight:false)}
  func testSecondaryTimerActivityBottomRight() {verifySecondaryHitTarget(.timerActivity,bottomRight:true)}
  func testSecondaryVoiceCancelTopLeft() {verifySecondaryHitTarget(.voiceCancel,bottomRight:false)}
  func testSecondaryVoiceCancelBottomRight() {verifySecondaryHitTarget(.voiceCancel,bottomRight:true)}
}

extension HomeViewUITests {
  private func systemTextSizeGeometry(_ name:String,_ elements:[String:XCUIElement]) {
    var rows:[[String:Any]]=[]
    for key in elements.keys.sorted() {
      let item=elements[key]!,f=item.frame
      rows.append(["id":key,"exists":item.exists,"hittable":item.isHittable,"label":item.label,
        "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)]])
    }
    let attachment=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:rows,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    attachment.name="system-text-size-"+name+"-geometry";attachment.lifetime = .keepAlways;add(attachment)
  }
  func testAssistantSystemTextSizePreservesLiteralCardAndUnsentInput() {
    launch(["--answer-speech-fixture"]);tap("nav.assistant")
    let input=app.textFields["assistant.input"],draft="UNSENT_FONT_FIXTURE"
    input.tap();input.typeText(draft);selectAnswerExample("message")
    let reply=app.staticTexts["assistant.reply"],scope=app.staticTexts["assistant.card.scope"],message=responseElement("assistant.card.message")
    XCTAssertTrue(message.waitForExistence(timeout:5));XCTAssertTrue(scope.exists)
    XCTAssertTrue(reply.label.contains("fictional"));XCTAssertTrue(message.label.contains("Avery Morgan"))
    XCTAssertTrue(message.label.contains("6:30 PM"));XCTAssertEqual(input.value as? String,draft)
    systemTextSizeGeometry("message",["reply":reply,"semantic_scope":scope,"message":message,
      "read":app.buttons["answer.speech.read"],"input":input,"content":app.scrollViews["assistant.content"],"viewport":app.otherElements["reference.viewport"]])
    viewportShot("system-text-size-message",assistantRectangle:true)
    XCTAssertEqual(app.buttons["answer.speech.read"].label,"Unlock readout")
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
  }
  func testAnswerReadoutSettingsSystemTextSizeKeepsDoneAtMinimumHitSize() {
    launch(["--answer-speech-fixture"]);tap("nav.assistant");tap("answer.speech.settings")
    let done=app.buttons["answer.speech.settings.done"],title=app.staticTexts["Answer readout"]
    XCTAssertTrue(done.waitForExistence(timeout:5));XCTAssertTrue(title.exists)
    systemTextSizeGeometry("readout-settings",["done":done,"title":title,"rate":app.staticTexts["answer.speech.rate.label"],"window":app.windows.firstMatch])
    shot("system-text-size-readout-settings")
    let previous=continueAfterFailure;continueAfterFailure=true
    XCTAssertGreaterThanOrEqual(done.frame.width,44-0.000_001)
    XCTAssertGreaterThanOrEqual(done.frame.height,44-0.000_001)
    continueAfterFailure=previous
    XCTAssertTrue(done.isHittable);done.tap()
    XCTAssertTrue(app.buttons["answer.speech.read"].waitForExistence(timeout:5))
    XCTAssertEqual(app.buttons["answer.speech.read"].label,"Unlock readout")
  }
  func testOnDeviceAnswerSystemTextSizeKeepsLiteralQuestionAndAnswer() {
    launch(["--assistant-ai-fixture","normal"]);chooseSyntheticOnDeviceAnswers()
    let prompt="Fictional recipe title, please."
    askSyntheticQuestion(prompt)
    let question=app.staticTexts["assistant.ai.question.0"],answer=app.staticTexts["assistant.ai.answer.0"]
    XCTAssertTrue(answer.waitForExistence(timeout:5));XCTAssertEqual(question.label,prompt)
    XCTAssertTrue(answer.label.contains("Moon Soup"));XCTAssertTrue(answer.label.contains("No action was taken"))
    if app.buttons["assistant.keyboard.dismiss"].exists {tap("assistant.keyboard.dismiss")}
    systemTextSizeGeometry("ondevice",["question":question,"answer":answer,
      "input":app.textFields["assistant.input"],"content":app.scrollViews["assistant.content"],"viewport":app.otherElements["reference.viewport"]])
    viewportShot("system-text-size-ondevice",assistantRectangle:true)
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
  }
}

extension HomeViewUITests {
  func testAnimatedFaceRoundTripPreservesRestingPixels() throws {
    try faceRoundTrip(animated:true)
  }
  func testReducedFaceRoundTripPreservesRestingPixels() throws {
    try faceRoundTrip(animated:false)
  }
  private func faceRoundTrip(animated:Bool) throws {
    launch(["--face","Modular",animated ? "--animation-test":"--reduce-motion"])
    if animated {
      XCTAssertFalse(UIAccessibility.isReduceMotionEnabled,"Record a real animated transition, not a reduced-motion substitute")
    }
    let viewport=app.otherElements["reference.viewport"].frame
    let geometry:[String:Any]=["viewport":[Double(viewport.minX),Double(viewport.minY),Double(viewport.width),Double(viewport.height)],
      "app":[Double(app.frame.minX),Double(app.frame.minY),Double(app.frame.width),Double(app.frame.height)],"reduce_motion":UIAccessibility.isReduceMotionEnabled]
    let receipt=XCTAttachment(data:try JSONSerialization.data(withJSONObject:geometry,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    receipt.name="replica-transition-capture-geometry";receipt.lifetime = .keepAlways;add(receipt)
    shot("replica-transition-modular-start")
    let before=viewportBytes("face-roundtrip-modular-before")
    app.otherElements["face.Modular"].swipeLeft()
    XCTAssertTrue(app.otherElements["face.Watch Modular"].waitForExistence(timeout:5))
    shot("replica-transition-watch-middle")
    app.otherElements["face.Watch Modular"].swipeRight()
    XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
    shot("replica-transition-modular-return")
    XCTAssertEqual(viewportPixels(before,inset:0),viewportPixels(viewportBytes("face-roundtrip-modular-return"),inset:0))
    // Reversal must keep working after both identities have been removed once.
    app.otherElements["face.Modular"].swipeLeft()
    XCTAssertTrue(app.otherElements["face.Watch Modular"].waitForExistence(timeout:5))
    app.otherElements["face.Watch Modular"].swipeRight()
    XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
    XCTAssertEqual(viewportPixels(before,inset:0),viewportPixels(viewportBytes("face-roundtrip-modular-second-return"),inset:0))
  }
}

extension HomeViewUITests {
  func testFlowComputeReducedFrameStopsAndNightDoesNotSubmitFluidWork() {
    launch(["--face","Flow","--animation-test","--reduce-motion"])
    let report=app.staticTexts["flow.compute.test"]
    XCTAssertTrue(report.waitForExistence(timeout:8))
    expectation(for:NSPredicate(format:"value CONTAINS %@","revision=1;pending=false"),evaluatedWith:report)
    waitForExpectations(timeout:8)
    let before=viewportBytes("flow-compute-reduced-accepted")
    Thread.sleep(forTimeInterval:1.2)
    XCTAssertTrue((report.value as? String ?? "").contains("revision=1;pending=false"))
    let after=viewportBytes("flow-compute-reduced-no-extra-step")
    XCTAssertEqual(viewportPixels(before,inset:0),viewportPixels(after,inset:0))
    tap("nav.controls");tap("controls.night");tap("nav.faces")
    let night=app.staticTexts["flow.compute.test"]
    XCTAssertTrue(night.waitForExistence(timeout:5))
    XCTAssertTrue((night.value as? String ?? "").contains("active=false"));XCTAssertTrue((night.value as? String ?? "").contains("pending=false"))
    viewportShot("flow-compute-night-no-work")
  }
}

extension HomeViewUITests {
  func testNightFaceMatrixUsesFullViewportAndExplicitTimeZones() {
    let faces=["Modular","Watch Modular","Infograph Modular","Modular Duo","Modular Compact",
      "Home Modular","Home Modular Clock","Photos","Weather","Calendar","Flow","Fade","Numerals","Home Camera"]
    let times=[("2026-12-31T23:30:00Z","Pacific/Kiritimati"),("2026-03-29T01:30:00Z","Europe/Berlin"),("2026-10-25T01:30:00Z","Europe/Berlin")]
    for (index,face) in faces.enumerated() {
      let (time,zone)=times[index%times.count]
      var args=["--face",face,"--reduce-motion","--reference-date",time,"--reference-zone",zone]
      if face=="Photos" {args += ["--photo-layout-fixture","top"]}
      launch(args)
      XCTAssertTrue(app.otherElements["face."+face].waitForExistence(timeout:5))
      tap("nav.controls");tap("controls.night")
      XCTAssertEqual(app.buttons["controls.night"].value as? String,"On")
      tap("nav.faces")
      if face=="Calendar" {XCTAssertEqual(app.staticTexts["calendar.face.selected"].label,"1")}
      let bytes=viewportBytes("night-matrix-"+face.replacingOccurrences(of:" ",with:"-"))
      let pixels=[UInt8](viewportPixels(bytes,inset:0));var lit=0,wrong=0
      for i in stride(from:0,to:pixels.count,by:4) where pixels[i]>25 {
        lit+=1
        if Double(pixels[i+1])>Double(pixels[i])*0.4 || Double(pixels[i+2])>Double(pixels[i])*0.4 {wrong+=1}
      }
      XCTAssertGreaterThan(lit,100,face);XCTAssertEqual(wrong,0,face+" full viewport hue leak")
      app.terminate()
    }
  }
  func testManualNightChoicePersistsThroughDSTAndReturnsToDay() {
    let id=UUID().uuidString
    print("NIGHT_MODE_OWNED_STORE "+id)
    launch(["--face","Calendar","--persistence-test",id,"--reset-test-store","--reduce-motion"])
    tap("nav.controls");tap("controls.night");tap("nav.faces")
    viewportShot("night-calendar-manual-before-restart")
    app.terminate()
    launch(["--persistence-test",id,"--reference-date","2026-10-25T01:30:00Z","--reference-zone","Europe/Berlin","--reduce-motion"])
    XCTAssertEqual(app.staticTexts["calendar.face.selected"].label,"25")
    tap("nav.controls")
    XCTAssertEqual(app.buttons["controls.night"].value as? String,"On")
    tap("controls.night")
    XCTAssertEqual(app.buttons["controls.night"].value as? String,"Off")
    tap("nav.faces")
    viewportShot("night-calendar-manual-off-after-DST-restart")
    app.terminate()
    launch(["--persistence-test",id])
    tap("nav.controls")
    XCTAssertEqual(app.buttons["controls.night"].value as? String,"Off")
  }
}

extension HomeViewUITests {
  func testCalendarNightContrastUsesRenderedGlyphControls() {
    for mode in ["positive","hidden","white"] {
      var args=["--face","Calendar","--reduce-motion"]
      if mode=="hidden" {args.append("--calendar-ink-hidden")}
      if mode=="white" {args.append("--calendar-ink-white")}
      launch(args)
      tap("nav.controls");tap("controls.night")
      XCTAssertEqual(app.buttons["controls.night"].value as? String,"On")
      tap("nav.faces")
      XCTAssertTrue(app.otherElements["face.Calendar"].waitForExistence(timeout:5))
      if mode=="positive" {
        func box(_ f:CGRect)->[String:Double] {["x":f.minX,"y":f.minY,"width":f.width,"height":f.height]}
        var cells:[[String:Any]]=[]
        for i in 0..<42 {
          let e=i==3 ? app.staticTexts["calendar.face.selected"]:app.staticTexts["calendar.face.cell.\(i)"]
          XCTAssertTrue(e.exists);cells.append(["index":i,"label":e.label,"frame":box(e.frame)])
        }
        let report:[String:Any]=["viewport":box(app.otherElements["reference.viewport"].frame),"cells":cells]
        let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys]),uniformTypeIdentifier:"public.json")
        a.name="night-calendar-ink-geometry";a.lifetime = .keepAlways;add(a)
      }
      viewportShot("night-calendar-ink-"+mode)
      app.terminate()
    }
  }
}

extension HomeViewUITests {
  func testCalendarLocalesKeepAllDatesVisibleAndMirrorOnlyRTLPresentation() {
    let cases:[(String,String,String,String,Int,[String])]=[
      ("de_DE","2024-02-29T12:00:00Z","Februar 2024","29",31,["29","30","31","1","2","3","4"]),
      ("ar_EG","2026-04-01T10:09:00Z","أبريل ٢٠٢٦","١",4,["٢٨","٢٩","٣٠","٣١","١","٢","٣"]),
      ("ja_JP","2026-08-31T12:00:00Z","2026年8月","31",36,["26","27","28","29","30","31","1"])]
    for (locale,date,title,day,selectedCell,firstWeek) in cases {
      launch(["--face","Calendar","--reference-locale",locale,"--reference-date",date])
      XCTAssertTrue(app.staticTexts["calendar.face.month"].waitForExistence(timeout:5))
      XCTAssertEqual(app.staticTexts["calendar.face.month"].label,title)
      let selected=app.staticTexts["calendar.face.selected"]
      XCTAssertEqual(selected.label,day)
      let viewport=app.otherElements["reference.viewport"].frame.insetBy(dx:8,dy:8)
      for i in 0..<42 {
        let cell=i==selectedCell ? selected:app.staticTexts["calendar.face.cell.\(i)"]
        XCTAssertTrue(cell.exists,"\(locale) missing \(i)")
        XCTAssertFalse(cell.label.isEmpty);XCTAssertTrue(viewport.contains(cell.frame),"\(locale) clipped \(i)")
        if i<7 {XCTAssertEqual(cell.label,firstWeek[i])}
      }
      let first=app.staticTexts["calendar.face.weekday.0"].frame
      let last=app.staticTexts["calendar.face.weekday.6"].frame
      if locale=="ar_EG" {XCTAssertGreaterThan(first.minX,last.maxX)}
      else {XCTAssertLessThan(first.maxX,last.minX)}
      viewportShot("calendar-locale-"+locale+"-all-dates")
      app.terminate()
    }
  }
  func testCalendarLocaleAgendaWeekSelectionCannotChangeFaceToday() {
    for (locale,index,day) in [("de_DE",2,"1"),("ar_EG",4,"١")] {
      launch(["--face","Calendar","--page","Calendar","--reference-locale",locale])
      XCTAssertEqual(app.buttons["calendar.day.\(index)"].value as? String,"Selected")
      tap("calendar.day.0")
      XCTAssertEqual(app.buttons["calendar.day.0"].value as? String,"Selected")
      XCTAssertNotEqual(app.buttons["calendar.day.\(index)"].value as? String,"Selected")
      viewportShot("calendar-locale-"+locale+"-agenda-selected")
      tap("nav.faces")
      XCTAssertEqual(app.staticTexts["calendar.face.selected"].label,day)
      XCTAssertFalse((app.staticTexts["calendar.face.selected"].value as? String ?? "").isEmpty)
      viewportShot("calendar-locale-"+locale+"-today-independent")
      app.terminate()
    }
  }
}

extension HomeViewUITests {
  private func openMockNotices() {
    tap("nav.controls")
    let b=app.buttons["controls.notices"];scrollPhotoControlFullyIntoView(b);b.tap()
    XCTAssertTrue(app.buttons["notices.load"].waitForExistence(timeout:5))
  }
  func testHouseNoticesGroupReplayRedactAndOpenOnlyMockView() {
    launch();openMockNotices()
    XCTAssertTrue(app.staticTexts["notices.empty"].exists)
    tap("notices.load")
    XCTAssertEqual(app.staticTexts["notices.count"].label,"3 groups · 5 visible events")
    XCTAssertEqual(app.otherElements.matching(NSPredicate(format:"identifier BEGINSWITH %@","notice.group.")).count,3)
    XCTAssertEqual(app.staticTexts["notice.title.arrival"].label,"Arrival")
    XCTAssertFalse(app.staticTexts["Synthetic Alex arrived"].exists)
    XCTAssertFalse(app.staticTexts["Withheld cabin detail"].exists)
    XCTAssertFalse(app.buttons["notice.open.other-house"].exists)
    XCTAssertFalse(app.buttons["notice.open.old"].isEnabled)
    shot("notices-grouped-guest-redacted")
    tap("notices.load")
    XCTAssertEqual(app.staticTexts["notices.count"].label,"3 groups · 5 visible events")
    tap("notices.authenticate")
    expectation(for:NSPredicate(format:"label == %@","Synthetic Alex arrived"),evaluatedWith:app.staticTexts["notice.title.arrival"])
    waitForExpectations(timeout:5)
    shot("notices-authenticated-private-demo-detail")
    tap("notices.lock")
    XCTAssertEqual(app.staticTexts["notice.title.arrival"].label,"Arrival")
    XCTAssertFalse(app.staticTexts["Synthetic Alex arrived"].exists)
    shot("notices-locked-detail-cleared")
    let open=app.buttons["notice.open.door"]
    for _ in 0..<4 where !open.isHittable {app.scrollViews["notices.list"].swipeUp()}
    XCTAssertTrue(open.isHittable);open.tap()
    XCTAssertTrue(app.staticTexts["lock.state"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked")
    XCTAssertEqual(app.buttons["lock.action"].label,"Authenticate Device")
    viewportShot("notices-door-target-no-unlock")
  }
  func testHouseNoticesOfflineDisablesTargetsAndClearHasNoDeviceEffect() {
    launch();tap("nav.controls");tap("controls.online")
    let b=app.buttons["controls.notices"];scrollPhotoControlFullyIntoView(b);b.tap()
    tap("notices.load")
    for id in ["arrival","door","alarm","unrelated","old"] {
      XCTAssertFalse(app.buttons["notice.open."+id].isEnabled,id)
    }
    shot("notices-offline-actions-disabled")
    tap("notices.clear")
    XCTAssertTrue(app.staticTexts["notices.empty"].exists)
    XCTAssertEqual(app.staticTexts["notices.count"].label,"0 groups · 0 visible events")
    tap("notices.done");tap("controls.online");tap("nav.faces")
    drawer();tap("app.Home");tap("grid.lock")
    XCTAssertTrue(app.staticTexts["lock.state"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked")
  }
}

extension HomeViewUITests {
  private func choosePanelProfile(_ name:String) {
    tap("nav.apps");tap("personal.profile");tap("profile."+name)
  }
  private func panelSettings() { drawer();tap("app.Settings") }
  func testSharedCalendarRequiresTwoExplicitPublicationsAndRevokesPanelsAndPreview() {
    let id=UUID().uuidString
    launch(["--face","Watch Modular","--page","Settings","--shared-panel-fixture",
      "--persistence-test",id,"--reset-test-store"])
    connectService("Calendar")
    choosePanelProfile("Alex");tap("all.apps");tap("app.Calendar");tap("device.unlock")
    XCTAssertTrue(app.staticTexts["Alex selected event"].waitForExistence(timeout:5))
    tap("nav.faces")
    XCTAssertTrue(app.staticTexts["Calendar not shared"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["Alex selected event"].exists)
    viewportShot("panels-calendar-private-even-unlocked")
    drawer();tap("app.Calendar")
    let alex=app.buttons["calendar.share.panel-0"];scrollPhotoControlFullyIntoView(alex);alex.tap()
    tap("nav.faces")
    XCTAssertTrue(app.staticTexts["shared.calendar.title.Alex"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["Jamie selected event"].exists)
    XCTAssertFalse(app.staticTexts["Never shared private event"].exists)
    choosePanelProfile("Jamie");tap("all.apps");tap("app.Calendar");tap("device.unlock")
    let jamie=app.buttons["calendar.share.panel-1"];scrollPhotoControlFullyIntoView(jamie);jamie.tap()
    tap("nav.faces")
    XCTAssertTrue(app.staticTexts["shared.calendar.title.Alex"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["shared.calendar.title.Jamie"].exists)
    XCTAssertTrue(app.staticTexts["shared.calendar.source.Jamie"].label.contains("Synthetic calendar"))
    XCTAssertFalse(app.staticTexts["Never shared private event"].exists)
    viewportShot("panels-two-explicit-labels")
    choosePanelProfile("guest");tap("nav.faces")
    XCTAssertTrue(app.staticTexts["shared.calendar.title.Alex"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["shared.calendar.title.Jamie"].exists)
    panelSettings()
    let revokeAlex=app.buttons["shared.calendar.revoke.Alex"]
    scrollPhotoControlFullyIntoView(revokeAlex);revokeAlex.tap()
    let revokeJamie=app.buttons["shared.calendar.revoke.Jamie"]
    scrollPhotoControlFullyIntoView(revokeJamie);revokeJamie.tap()
    tap("nav.faces")
    XCTAssertTrue(app.staticTexts["Calendar not shared"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["Alex selected event"].exists)
    XCTAssertFalse(app.staticTexts["Jamie selected event"].exists)
    viewportShot("panels-calendar-revoked")
    panelSettings()
    let editor=app.buttons["settings.faces"];scrollPhotoControlFullyIntoView(editor);editor.tap()
    XCTAssertTrue(app.buttons["editor.done"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["Alex selected event"].exists)
    XCTAssertFalse(app.staticTexts["Jamie selected event"].exists)
    viewportShot("panels-revoked-editor-preview")
    app.terminate();launch(["--face","Watch Modular","--persistence-test",id])
    XCTAssertFalse(app.staticTexts["Alex selected event"].exists)
    XCTAssertFalse(app.staticTexts["Jamie selected event"].exists)
  }
  func testSharedMusicFaceHidesAuthenticatedPrivateQueueUntilExplicitGrantAndBackground() {
    launch(["--face","Modular","--page","Settings"]);connectService("Apple Music")
    drawer();tap("app.Music")
    let field=app.textFields["music.search.input"];XCTAssertTrue(field.waitForExistence(timeout:5))
    field.tap();field.typeText("fixture");tap("music.search");tap("music.result.0")
    XCTAssertTrue(app.staticTexts["music.current.title"].waitForExistence(timeout:5))
    tap("nav.faces")
    XCTAssertTrue(app.staticTexts["Music not shared"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["Connected fixture song"].exists)
    XCTAssertFalse(app.buttons["Pause music"].exists)
    viewportShot("panels-music-private-even-unlocked")
    panelSettings();let share=app.buttons["guest.music.share"]
    scrollPhotoControlFullyIntoView(share);share.tap();tap("nav.faces")
    XCTAssertTrue(app.staticTexts["Connected fixture song"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["Shared · Apple Music"].exists)
    viewportShot("panels-music-explicitly-shared")
    XCUIDevice.shared.press(.home);app.activate()
    tap("nav.faces")
    XCTAssertTrue(app.staticTexts["Music not shared"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["Connected fixture song"].exists)
    viewportShot("panels-music-background-revoked")
  }
}

extension HomeViewUITests {
  func testFaceCatalogueEveryCurrentIdentityRendersWithoutLiveServices() {
    let faces=["Modular","Watch Modular","Infograph Modular","Modular Duo","Modular Compact",
      "Home Modular","Home Modular Clock","Photos","Weather","Calendar","Flow","Fade","Numerals","Home Camera"]
    for face in faces {
      var arguments=["--face",face,"--reduce-motion"]
      if face=="Photos" {arguments += ["--photo-layout-fixture","top"]}
      launch(arguments)
      XCTAssertTrue(app.otherElements["face."+face].waitForExistence(timeout:5),face)
      XCTAssertFalse(app.staticTexts["store.readOnly"].exists)
      viewportShot("catalogue-"+face.replacingOccurrences(of:" ",with:"-"))
      app.terminate()
    }
  }
}

extension HomeViewUITests {
  private func openRecoveredProfile(_ name:String,page:String) {
    tap("nav.apps");tap("personal.profile");tap("profile."+name)
    tap("all.apps");tap("app."+page)
  }
  private func checkRecoveredAlexMessages() {
    openRecoveredProfile("Alex",page:"Messages")
    XCTAssertTrue(app.staticTexts["OWNED_ALEX_FIRST_MESSAGE"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["OWNED_ALEX_LAST_MESSAGE"].exists)
    XCTAssertFalse(app.staticTexts["OWNED_JAMIE_FIRST_REMINDER"].exists)
    XCTAssertFalse(app.staticTexts["Hey! Are we still on for dinner?"].exists)
  }
  private func runPersonalFieldRecovery(legacy:Bool) {
    let id=UUID().uuidString,kind=legacy ? "legacy":"damaged"
    print("PERSONAL_FIELD_RECOVERY_STORE kind="+kind+" id="+id)
    var args=["--persistence-test",id,"--reset-test-store","--personal-field-recovery-fixture","--page","Settings"]
    if legacy {args.append("--personal-field-legacy")}
    launch(args)
    XCTAssertTrue(app.staticTexts.matching(identifier:"store.recovery").firstMatch.waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["store.readOnly"].exists)
    checkRecoveredAlexMessages();viewportShot("personal-fields-"+kind+"-alex-recovered")
    openRecoveredProfile("Jamie",page:"Messages")
    XCTAssertFalse(app.staticTexts["OWNED_ALEX_FIRST_MESSAGE"].exists)
    XCTAssertFalse(app.staticTexts["OWNED_ALEX_LAST_MESSAGE"].exists)
    XCTAssertFalse(app.staticTexts["Hey! Are we still on for dinner?"].exists)
    openRecoveredProfile("Jamie",page:"Reminders")
    let first=app.buttons["reminder.OWNED_JAMIE_FIRST_REMINDER"]
    let last=app.buttons["reminder.OWNED_JAMIE_LAST_REMINDER"]
    XCTAssertTrue(first.waitForExistence(timeout:5));XCTAssertTrue(last.exists)
    XCTAssertEqual(app.buttons.matching(identifier:"reminder.OWNED_JAMIE_FIRST_REMINDER").count,1)
    XCTAssertFalse(app.buttons["reminder.OWNED_DUPLICATE_REMINDER"].exists)
    XCTAssertEqual(first.value as? String,"Not completed")
    first.tap();XCTAssertEqual(first.value as? String,"Completed")
    viewportShot("personal-fields-"+kind+"-jamie-normal-write")
    app.terminate()
    launch(["--persistence-test",id,"--page","Settings"])
    XCTAssertFalse(app.staticTexts["store.readOnly"].exists)
    checkRecoveredAlexMessages()
    openRecoveredProfile("Jamie",page:"Reminders")
    XCTAssertTrue(first.waitForExistence(timeout:5));XCTAssertTrue(last.exists)
    XCTAssertEqual(first.value as? String,"Completed")
    XCTAssertEqual(last.value as? String,"Not completed")
    XCTAssertFalse(app.buttons["reminder.OWNED_DUPLICATE_REMINDER"].exists)
    viewportShot("personal-fields-"+kind+"-after-process-restart")
  }
  func testDamagedPersonalListsPreserveSiblingsAndNormalWriteAfterRestart() {
    runPersonalFieldRecovery(legacy:false)
  }
  func testLegacyPersonalListsPreserveSiblingsAndNormalWriteAfterRestart() {
    runPersonalFieldRecovery(legacy:true)
  }
}

extension HomeViewUITests {
  private func openPressureEditor() {
    let edit=app.buttons["settings.faces"]
    scrollPhotoControlFullyIntoView(edit);edit.tap()
    XCTAssertTrue(app.buttons["editor.done"].waitForExistence(timeout:5))
  }
  private func verifyPressureProfile(_ name:String,own:String,other:String) {
    tap("nav.apps");tap("personal.profile");tap("profile."+name)
    tap("all.apps");tap("app.Messages")
    XCTAssertTrue(app.staticTexts[own].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts[other].exists)
  }
  private func verifyPressureFace(_ expectedRight:String,write:Bool=false) {
    openPressureEditor()
    XCTAssertEqual(app.buttons["Sage style"].value as? String,"Selected")
    XCTAssertTrue(app.buttons["widget.0"].label.contains("Weather"))
    XCTAssertTrue(app.buttons["widget.1"].label.contains(expectedRight))
    if write {
      scrollEditorIntoView(app.buttons["widget.1"]);tap("widget.1")
      tap("complication.choose.Date")
      XCTAssertTrue(app.buttons["widget.1"].waitForExistence(timeout:5))
      XCTAssertTrue(app.buttons["widget.1"].label.contains("Date"))
    }
    tap("editor.done")
    XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
  }
  func testCrowdedMigrationPreservesFaceSlotsProfilesNormalWriteAndRestart() {
    let id=UUID().uuidString
    print("STATE_TABLE_PRESSURE_STORE kind=face id="+id)
    launch(["--persistence-test",id,"--reset-test-store","--state-table-pressure-fixture","--page","Settings"])
    XCTAssertTrue(app.staticTexts.matching(identifier:"store.recovery").firstMatch.waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["store.readOnly"].exists)
    verifyPressureFace("Clock",write:true)
    viewportShot("table-pressure-face-known-slots-saved")
    verifyPressureProfile("Alex",own:"OWNED_ALEX_PRIVATE_CANARY",other:"OWNED_JAMIE_PRIVATE_CANARY")
    viewportShot("table-pressure-alex-isolated")
    verifyPressureProfile("Jamie",own:"OWNED_JAMIE_PRIVATE_CANARY",other:"OWNED_ALEX_PRIVATE_CANARY")
    viewportShot("table-pressure-jamie-isolated")
    app.terminate()
    // No reset or fixture flag: normal reader must load the ordinary write.
    launch(["--persistence-test",id,"--page","Settings"])
    XCTAssertFalse(app.staticTexts["store.readOnly"].exists)
    verifyPressureFace("Date")
    verifyPressureProfile("Alex",own:"OWNED_ALEX_PRIVATE_CANARY",other:"OWNED_JAMIE_PRIVATE_CANARY")
    verifyPressureProfile("Jamie",own:"OWNED_JAMIE_PRIVATE_CANARY",other:"OWNED_ALEX_PRIVATE_CANARY")
    viewportShot("table-pressure-profiles-after-process-restart")
  }
  func testCrowdedPhotoCorrectionLoadsAndSurvivesNormalWriteAndRestart() {
    let id=UUID().uuidString
    print("STATE_TABLE_PRESSURE_STORE kind=photo id="+id)
    launch(["--persistence-test",id,"--reset-test-store","--state-table-pressure-fixture","--page","Settings"])
    let bottom=app.buttons["photos.clock.bottom"]
    scrollPhotoControlFullyIntoView(bottom)
    XCTAssertEqual(bottom.value as? String,"Selected")
    let automatic=app.switches["photos.crop.auto"]
    XCTAssertEqual(automatic.value as? String,"0")
    XCTAssertTrue(app.sliders["photos.crop.horizontal"].exists)
    XCTAssertTrue(app.sliders["photos.crop.vertical"].exists)
    viewportShot("table-pressure-photo-bottom-recovered")
    tap("photos.clock.top")
    XCTAssertEqual(app.buttons["photos.clock.top"].value as? String,"Selected")
    app.terminate()
    launch(["--persistence-test",id,"--page","Settings"])
    let top=app.buttons["photos.clock.top"]
    scrollPhotoControlFullyIntoView(top)
    XCTAssertEqual(top.value as? String,"Selected")
    XCTAssertEqual(app.switches["photos.crop.auto"].value as? String,"0")
    XCTAssertTrue(app.sliders["photos.crop.horizontal"].exists)
    XCTAssertTrue(app.sliders["photos.crop.vertical"].exists)
    viewportShot("table-pressure-photo-top-after-process-restart")
  }
}

extension HomeViewUITests {
  private func launchFaceEditorAudit(_ face:String) {
    launch(["--face",face,"--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    let edit=app.buttons["settings.faces"]
    scrollPhotoControlFullyIntoView(edit);edit.tap()
    XCTAssertTrue(app.buttons["editor.done"].waitForExistence(timeout:5))
  }
  private func auditFaceEditorHitRegions(_ state:String,sheet:Bool=false) throws {
    if sheet {shot("editor-hit-region-"+state)} else {viewportShot("editor-hit-region-"+state)}
    let viewport=sheet ? app.frame:app.otherElements["reference.viewport"].frame
    let controls=app.buttons.allElementsBoundByIndex+app.switches.allElementsBoundByIndex
      + app.sliders.allElementsBoundByIndex+app.segmentedControls.allElementsBoundByIndex
    let rows:[[String:Any]]=controls.compactMap { e in
      let f=e.frame
      guard !f.isEmpty,f.intersects(viewport) else {return nil}
      return ["identifier":e.identifier,"label":e.label,"value":String(describing:e.value),
        "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
        "hittable":e.isHittable,"enabled":e.isEnabled,"fullyInViewport":viewport.contains(f),
        "coordinateLane":sheet ? "native-sheet":"scaled-root"]
    }
    let g=XCTAttachment(data:try JSONSerialization.data(withJSONObject:rows,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    g.name="editor-"+state+"-geometry";g.lifetime = .keepAlways;add(g)
    var findings:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let e=issue.element,f=e?.frame ?? .zero
      findings.append(["identifier":e?.identifier ?? "","label":e?.label ?? "",
        "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
        "description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let a=XCTAttachment(data:try JSONSerialization.data(withJSONObject:findings,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="editor-"+state+"-all-findings";a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(findings.isEmpty,"Unfiltered editor findings: \(findings)")
  }
  func testFaceEditorModularTopUnfilteredHitRegionAudit() throws {
    launchFaceEditorAudit("Modular");try auditFaceEditorHitRegions("modular-top")
  }
  func testFaceEditorModularListUnfilteredHitRegionAudit() throws {
    launchFaceEditorAudit("Modular");scrollEditorIntoView(app.buttons["widget.2"])
    try auditFaceEditorHitRegions("modular-list")
  }
  func testFaceEditorFlowTopUnfilteredHitRegionAudit() throws {
    launchFaceEditorAudit("Flow");try auditFaceEditorHitRegions("flow-top")
  }
  func testFaceEditorFlowOptionsUnfilteredHitRegionAudit() throws {
    launchFaceEditorAudit("Flow");scrollEditorIntoView(app.switches["flow.background"])
    try auditFaceEditorHitRegions("flow-options")
  }
  func testFaceEditorWatchModularTopUnfilteredHitRegionAudit() throws {
    launchFaceEditorAudit("Watch Modular");try auditFaceEditorHitRegions("watch-modular-top")
  }
  func testFaceEditorInfographTopUnfilteredHitRegionAudit() throws {
    launchFaceEditorAudit("Infograph Modular");try auditFaceEditorHitRegions("infograph-top")
  }
  func testFaceEditorComplicationSheetUnfilteredHitRegionAudit() throws {
    launchFaceEditorAudit("Modular")
    let first=app.buttons["widget.0"];scrollEditorIntoView(first);first.tap()
    XCTAssertTrue(app.buttons["complications.done"].waitForExistence(timeout:5))
    waitEditorFrameStable(app.buttons["complications.done"])
    try auditFaceEditorHitRegions("complication-sheet",sheet:true)
  }
  private func waitEditorFrameStable(_ e:XCUIElement) {
    XCTAssertTrue(e.waitForExistence(timeout:5))
    var previous=CGRect.null,stable=0
    let until=Date().addingTimeInterval(5)
    while Date()<until {
      let frame=e.frame
      stable = frame==previous && e.isHittable ? stable+1:0
      if stable>=3 {return}
      previous=frame;Thread.sleep(forTimeInterval:0.15)
    }
    XCTFail("Editor control never reached a stable hittable frame: "+e.identifier)
  }
  private func scrollEditorIntoView(_ e:XCUIElement) {
    let v=app.otherElements["reference.viewport"].frame,scroll=app.scrollViews["editor.content"]
    let top=floor(max(v.minY,scroll.frame.minY)*2)/2,bottom=v.maxY-24
    for _ in 0..<16 {
      let f=e.frame
      if e.isHittable,v.contains(f),f.minY>=top,f.maxY<=bottom {return}
      let gap=f.isEmpty ? (bottom-top)*0.5 : f.minY<top ? -(top-f.minY+12):f.maxY-bottom+12
      let distance=min(max(abs(gap),24),(bottom-top)*0.6)*(gap<0 ? -1:1)
      let y=(top+bottom)/2
      let start=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:v.minX+15,dy:y+distance/2))
      let end=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:v.minX+15,dy:y-distance/2))
      start.press(forDuration:0.1,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.2)
    }
    XCTFail("Could not show editor control in the actual viewport: "+e.identifier)
  }
  private func tapEditorNativeEdge(_ e:XCUIElement,bottom:Bool=false,sheet:Bool=false) {
    if !sheet,e.identifier != "editor.done" {scrollEditorIntoView(e)}
    waitEditorFrameStable(e)
    let f=e.frame,v=sheet ? app.frame:app.otherElements["reference.viewport"].frame
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:[
      "identifier":e.identifier,"label":e.label,"value":String(describing:e.value),
      "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
      "hittable":e.isHittable,"viewport":[Double(v.minX),Double(v.minY),Double(v.width),Double(v.height)],
      "edge":bottom ? "bottom":"top","lane":sheet ? "native-sheet":"scaled-root"],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="editor-native-edge-"+(e.identifier.isEmpty ? e.label:e.identifier)+"-"+(bottom ? "bottom":"top")
    a.lifetime = .keepAlways;add(a)
    XCTAssertGreaterThanOrEqual(f.width,44);XCTAssertGreaterThanOrEqual(f.height,44)
    XCTAssertTrue(v.contains(f));XCTAssertTrue(e.isHittable)
    app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:f.midX,dy:bottom ? f.maxY-2:f.minY+2)).tap()
  }
  func testFaceEditorPaletteListAndCarouselNativeEdges() {
    launchFaceEditorAudit("Modular")
    tapEditorNativeEdge(app.buttons["Sage style"])
    XCTAssertEqual(app.buttons["Sage style"].value as? String,"Selected")
    tapEditorNativeEdge(app.buttons["Mist style"],bottom:true)
    XCTAssertEqual(app.buttons["Mist style"].value as? String,"Selected")
    tapEditorNativeEdge(app.buttons["widget.0"])
    tapEditorNativeEdge(app.buttons["complication.choose.Clock"],sheet:true)
    XCTAssertTrue(app.buttons["widget.0"].waitForExistence(timeout:5))
    XCTAssertTrue(app.buttons["widget.0"].label.contains("Clock"))
    tapEditorNativeEdge(app.buttons["select.Watch Modular"])
    XCTAssertEqual(app.buttons["select.Watch Modular"].value as? String,"Selected")
    tapEditorNativeEdge(app.buttons["select.Modular"],bottom:true)
    XCTAssertEqual(app.buttons["select.Modular"].value as? String,"Selected")
    XCTAssertTrue(app.buttons["widget.0"].label.contains("Clock"))
    tapEditorNativeEdge(app.buttons["editor.done"],bottom:true)
    XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
    viewportShot("editor-native-modular-controls-complete")
  }
  func testFaceEditorFlowTypefaceAndBackgroundNativeEdges() {
    launchFaceEditorAudit("Flow")
    tapEditorNativeEdge(app.buttons["flow.typeface.1"])
    XCTAssertEqual(app.buttons["flow.typeface.1"].value as? String,"Selected")
    tapEditorNativeEdge(app.buttons["flow.typeface.0"],bottom:true)
    XCTAssertEqual(app.buttons["flow.typeface.0"].value as? String,"Selected")
    let background=app.switches["flow.background"]
    XCTAssertEqual(background.value as? String,"1")
    tapEditorNativeEdge(background)
    XCTAssertEqual(background.value as? String,"0")
    tapEditorNativeEdge(background,bottom:true)
    XCTAssertEqual(background.value as? String,"1")
    tapEditorNativeEdge(app.buttons["editor.done"])
    XCTAssertTrue(app.otherElements["face.Flow"].waitForExistence(timeout:5))
    viewportShot("editor-native-flow-controls-complete")
  }
  func testFaceEditorInlineHitRegionKeepsSiblingSlotsAndCorrectPicker() {
    launchFaceEditorAudit("Infograph Modular")
    let date=app.buttons["preview.slot.date"]
    let siblings=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","preview.slot."))
    let rect=date.frame
    for other in siblings.allElementsBoundByIndex where other.identifier != date.identifier {
      XCTAssertTrue(rect.intersection(other.frame).isEmpty,"Date hit region overlaps "+other.identifier)
    }
    tapEditorNativeEdge(date)
    XCTAssertTrue(app.buttons["complication.choose.Off"].waitForExistence(timeout:5))
    XCTAssertFalse(app.buttons["complication.choose.Music"].exists)
    XCTAssertFalse(app.buttons["complication.choose.Weather"].exists)
    tapEditorNativeEdge(app.buttons["complications.done"],sheet:true)
    tapEditorNativeEdge(date,bottom:true)
    tapEditorNativeEdge(app.buttons["complication.choose.Off"],bottom:true,sheet:true)
    XCTAssertTrue(date.waitForExistence(timeout:5));XCTAssertTrue(date.label.contains("Off"))
    tapEditorNativeEdge(date)
    tapEditorNativeEdge(app.buttons["complication.choose.Clock"],sheet:true)
    XCTAssertTrue(date.waitForExistence(timeout:5));XCTAssertTrue(date.label.contains("Clock"))
    tapEditorNativeEdge(app.buttons["editor.done"],bottom:true)
    XCTAssertTrue(app.buttons["complication.slot.date"].waitForExistence(timeout:5))
    XCTAssertTrue(app.buttons["complication.slot.date"].label.contains("Clock"))
    viewportShot("editor-native-inline-correct-slot-complete")
  }

}

extension HomeViewUITests {
  private func launchLocalControlCenter() {
    launch(["--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("nav.controls")
    XCTAssertTrue(app.buttons["controls.online"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["controls.scope"].exists)
  }
  private func auditLocalControlCenter(_ state:String) throws {
    viewportShot("control-center-hit-region-"+state)
    let v=app.otherElements["reference.viewport"].frame
    let controls=app.buttons.allElementsBoundByIndex+app.sliders.allElementsBoundByIndex
    let rows:[[String:Any]]=controls.compactMap { e in
      let f=e.frame
      guard !f.isEmpty,f.intersects(v) else {return nil}
      return ["identifier":e.identifier,"label":e.label,"value":String(describing:e.value),
        "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
        "hittable":e.isHittable,"fullyInViewport":v.contains(f)]
    }
    let g=XCTAttachment(data:try JSONSerialization.data(withJSONObject:rows,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    g.name="control-center-"+state+"-geometry";g.lifetime = .keepAlways;add(g)
    var findings:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let e=issue.element,f=e?.frame ?? .zero
      findings.append(["identifier":e?.identifier ?? "","label":e?.label ?? "",
        "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
        "description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let a=XCTAttachment(data:try JSONSerialization.data(withJSONObject:findings,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="control-center-"+state+"-all-findings";a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(findings.isEmpty,"Unfiltered control-center findings: \(findings)")
  }
  private func tapLocalControlCenterEdge(_ e:XCUIElement,bottom:Bool=false) {
    bringLocalControlCenterIntoView(e)
    XCTAssertTrue(e.waitForExistence(timeout:5))
    let f=e.frame,v=app.otherElements["reference.viewport"].frame
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:[
      "identifier":e.identifier,"label":e.label,"edge":bottom ? "bottom":"top",
      "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
      "hittable":e.isHittable,"viewport":[Double(v.minX),Double(v.minY),Double(v.width),Double(v.height)]],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="control-center-edge-"+e.identifier+"-"+e.label+"-"+(bottom ? "bottom":"top");a.lifetime = .keepAlways;add(a)
    XCTAssertGreaterThanOrEqual(f.width,44);XCTAssertGreaterThanOrEqual(f.height,44)
    XCTAssertTrue(v.contains(f));XCTAssertTrue(e.isHittable)
    app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:f.midX,dy:bottom ? f.maxY-2:f.minY+2)).tap()
  }
  private func bringLocalControlCenterIntoView(_ e:XCUIElement) {
    let scroll=app.scrollViews["controls.content"]
    guard e.identifier != "close",scroll.exists else {return}
    let viewport=app.otherElements["reference.viewport"].frame
    var visible=viewport
    // The first row can sit at the actual scroll-content top. It cannot be
    // scrolled down to create the generic photo helper's 40-point top inset.
    visible.size.height=max(0,visible.height-40)
    if e.isHittable,visible.contains(e.frame) {return}
    scrollPhotoControlFullyIntoView(e)
  }
  func testLocalControlCenterDefaultUnfilteredHitRegionAudit() throws {
    launchLocalControlCenter();try auditLocalControlCenter("default")
  }
  func testLocalControlCenterNightUnfilteredHitRegionAudit() throws {
    launchLocalControlCenter();tap("controls.night");try auditLocalControlCenter("night")
  }
  func testLocalControlCenterCardsCloseAndSettingsActualEdges() {
    continueAfterFailure=true
    launchLocalControlCenter()
    for (identifier,before,after) in [("controls.online","On","Off"),
      ("controls.night","Off","On"),("controls.distance","Off","On")] {
      let e=app.buttons[identifier];XCTAssertEqual(e.value as? String,before)
      tapLocalControlCenterEdge(e)
      XCTAssertEqual(e.value as? String,after)
      tapLocalControlCenterEdge(e,bottom:true)
      XCTAssertEqual(e.value as? String,before)
    }
    tapLocalControlCenterEdge(app.buttons["close"])
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
    tap("nav.controls");tapLocalControlCenterEdge(app.buttons["controls.settings"])
    XCTAssertTrue(app.buttons["settings.reset"].waitForExistence(timeout:5))
    viewportShot("control-center-settings-destination")
  }
  func testLocalControlCenterAppOnlyAdjusterActualEdges() {
    continueAfterFailure=true
    launchLocalControlCenter()
    for label in ["Display dimming","Demo audio"] {
      let status=app.staticTexts["adjuster.value."+label],before=status.label
      tapLocalControlCenterEdge(app.buttons["Decrease "+label],bottom:true)
      XCTAssertNotEqual(status.label,before)
      tapLocalControlCenterEdge(app.buttons["Increase "+label])
      XCTAssertEqual(status.label,before)
    }
    viewportShot("control-center-app-only-adjusters-returned")
  }
  func testLocalControlCenterNativeSlidersKeepModelValues() {
    continueAfterFailure=true
    launchLocalControlCenter()
    for label in ["Display dimming","Demo audio"] {
      let slider=app.sliders[label],status=app.staticTexts["adjuster.value."+label]
      bringLocalControlCenterIntoView(slider)
      let f=slider.frame,v=app.otherElements["reference.viewport"].frame
      XCTAssertGreaterThanOrEqual(f.height,44);XCTAssertGreaterThanOrEqual(f.width,44)
      XCTAssertTrue(v.contains(f));XCTAssertTrue(slider.isHittable)
      for target in [CGFloat(0.25),CGFloat(0.75)] {
        slider.adjust(toNormalizedSliderPosition:target)
        let number=Double(status.label.replacingOccurrences(of:"%",with:""))
        XCTAssertNotNil(number,"Visible model value: \(status.label), native: \(String(describing:slider.value))")
        XCTAssertEqual(number ?? -100,Double(target)*100,accuracy:10)
      }
    }
    viewportShot("control-center-native-sliders-adjusted")
  }
}

extension HomeViewUITests {
  private func weatherSurfaceGeometry(_ element:XCUIElement,_ state:String,sheet:Bool=false) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    let f=element.frame,v=sheet ? app.frame:app.otherElements["reference.viewport"].frame
    let keyboard=app.keyboards.firstMatch
    let data:[String:Any] = ["identifier":element.identifier,"label":element.label,
      "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
      "containingFrame":[Double(v.minX),Double(v.minY),Double(v.width),Double(v.height)],
      "hittable":element.isHittable,"value":String(describing:element.value),"sheet":sheet,
      "keyboardVisible":keyboard.exists]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="weather-surface-native-"+state;a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(v.contains(f));XCTAssertGreaterThanOrEqual(f.width,44);XCTAssertGreaterThanOrEqual(f.height,44)
    // These scaled weather buttons historically report isHittable=false even
    // when their actual screen-coordinate touches work. Assert the outcome.
  }
  private func weatherSurfaceEdge(_ element:XCUIElement,bottom:Bool=false) {
    let f=element.frame
    app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:f.midX,dy:bottom ? f.maxY-2:f.minY+2)).tap()
  }
  private func weatherSurfaceAudit(_ state:String) throws {
    var findings:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let f=issue.element?.frame ?? .zero
      findings.append(["identifier":issue.element?.identifier ?? "","label":issue.element?.label ?? "",
        "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
        "description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let a=XCTAttachment(data:try JSONSerialization.data(withJSONObject:findings,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="weather-surface-"+state+"-all-findings";a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(findings.isEmpty,"Unfiltered weather audit: \(findings)")
  }
  private func launchWeatherSurfaceFixture() {
    launch(["--page","Settings","--weather-forecast-fixture","--persistence-test",UUID().uuidString,"--reset-test-store"])
    connectService("Weather");openWeather()
    XCTAssertEqual(app.staticTexts["weather.app.city"].label,"Berlin")
  }
  func testWeatherAttributionNativeEdgesOpenExpectedPublicWebsite() {
    continueAfterFailure=false
    let safari=XCUIApplication(bundleIdentifier:"com.apple.mobilesafari")
    for bottom in [false,true] {
      launchWeatherSurfaceFixture()
      XCTAssertEqual(app.state,.runningForeground)
      let safariBefore=safari.state
      XCTAssertNotEqual(safariBefore,.runningForeground,"OS target must not already be in front before the edge touch")
      let source=app.links["Open-Meteo"]
      scrollPhotoControlFullyIntoView(source,requireHittable:false)
      weatherSurfaceGeometry(source,bottom ? "link-actual-bottom":"link-actual-top")
      let f=source.frame
      let point=[Double(f.midX),Double(bottom ? f.maxY-2:f.minY+2)]
      weatherSurfaceEdge(source,bottom:bottom)
      let switched=safari.wait(for:.runningForeground,timeout:10)
      var report:[String:Any] = ["edge":bottom ? "bottom":"top","point":point,
        "linkFrame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
        "expectedURL":"https://open-meteo.com/","safariBeforeState":safariBefore.rawValue,
        "safariForeground":switched]
      if !switched {
        let tree=XCTAttachment(string:app.debugDescription);tree.name="weather-link-no-os-transition";tree.lifetime = .keepAlways;add(tree)
        shot("weather-link-edge-no-os-transition")
      } else {
        // Observed native Safari address fields differ between phone and pad;
        // neither is a web-page input or the older "URL" identifier.
        let address=safari.textFields.matching(NSPredicate(format:
          "identifier == %@ OR identifier == %@","TabBarItemTitle","TabBarItemTitleContainer")).firstMatch
        let found=address.waitForExistence(timeout:8)
        report["URLFieldFound"]=found
        if found {
          let value=address.value as? String ?? ""
          // Safari prepends a presentation-only LRM to the displayed address.
          let clean=value.replacingOccurrences(of:"\u{200E}",with:"")
            .replacingOccurrences(of:"\u{200F}",with:"").trimmingCharacters(in:.whitespacesAndNewlines)
          let normalized=clean.contains("://") ? clean:"https://"+clean
          report["nativeURLFieldIdentifier"]=address.identifier
          report["nativeURLValue"]=value
          report["nativeURLHost"]=URL(string:normalized)?.host?.lowercased() ?? ""
        }
        let tree=XCTAttachment(string:safari.debugDescription);tree.name="weather-link-native-safari-tree";tree.lifetime = .keepAlways;add(tree)
        let screen=XCTAttachment(screenshot:safari.screenshot());screen.name=bottom ? "weather-link-safari-bottom":"weather-link-safari-top";screen.lifetime = .keepAlways;add(screen)
      }
      let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
      a.name=bottom ? "weather-link-bottom-os-receipt":"weather-link-top-os-receipt";a.lifetime = .keepAlways;add(a)
      XCTAssertTrue(switched,"Actual attribution edge did not open the OS browser")
      XCTAssertEqual(report["nativeURLHost"] as? String,"open-meteo.com",
        "Native browser address must prove the expected public destination")
      safari.terminate()
    }
  }
  func testWeatherAppNativeHitRegionsAndActualModeEdges() throws {
    continueAfterFailure=true
    launchWeatherSurfaceFixture()
    for (name,legend,bottom) in [("Wind","Wind (mph)",false),("Precipitation","Precipitation (%)",true),("Temperature","Temperature (°F)",false)] {
      let button=app.buttons["weather.mode."+name]
      scrollPhotoControlFullyIntoView(button,requireHittable:false)
      weatherSurfaceGeometry(button,"mode-"+name);weatherSurfaceEdge(button,bottom:bottom)
      XCTAssertEqual(app.staticTexts["weather.metric"].label,legend)
      XCTAssertEqual(button.value as? String,"Selected")
    }
    let source=app.links["Open-Meteo"]
    scrollPhotoControlFullyIntoView(source,requireHittable:false)
    weatherSurfaceGeometry(source,"attribution-not-invoked")
    for name in ["Temperature","Precipitation","Wind"] {
      XCTAssertFalse(source.frame.intersects(app.buttons["weather.mode."+name].frame),
        "Expanded attribution target must not steal touches from "+name)
    }
    viewportShot("weather-surface-app-modes-and-attribution")
    try weatherSurfaceAudit("app")
    for bottom in [false,true] {
      let cities=app.buttons["weather.cities"]
      // The visible first header cannot be scrolled forty points below its
      // natural top inset. Its complete native rectangle is already visible.
      for _ in 0..<8 {
        if app.otherElements["reference.viewport"].frame.contains(cities.frame) {break}
        app.scrollViews.firstMatch.swipeDown()
      }
      weatherSurfaceGeometry(cities,bottom ? "cities-bottom":"cities-top")
      weatherSurfaceEdge(cities,bottom:bottom)
      XCTAssertTrue(app.textFields["weather.app.city.input"].waitForExistence(timeout:5))
      tap("weather.city.done")
    }
    viewportShot("weather-surface-app-returned-from-cities")
  }
  func testWeatherCitySheetNativeHitRegionsAndEditableEdges() throws {
    continueAfterFailure=true
    launchWeatherSurfaceFixture()
    for bottom in [false,true] {
      touchWeatherControl("weather.cities")
      let field=app.textFields["weather.app.city.input"],done=app.buttons["weather.city.done"]
      let update=app.buttons["weather.app.city.update"],units=app.segmentedControls["weather.app.units"]
      for (element,name) in [(field,"city"),(done,"done"),(update,"update"),
        (units.buttons["°F / mph"],"fahrenheit"),(units.buttons["°C / km/h"],"celsius")] {
        weatherSurfaceGeometry(element,"sheet-"+name,sheet:true)
      }
      shot(bottom ? "weather-surface-sheet-bottom-before":"weather-surface-sheet-top-before")
      if !bottom {try weatherSurfaceAudit("sheet")}
      let choice=units.buttons[bottom ? "°F / mph":"°C / km/h"]
      weatherSurfaceEdge(choice,bottom:bottom);XCTAssertTrue(choice.isSelected)
      weatherSurfaceEdge(update,bottom:bottom)
      expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:field);waitForExpectations(timeout:5)
      touchWeatherControl("weather.cities")
      XCTAssertTrue(field.waitForExistence(timeout:5));XCTAssertEqual(field.value as? String,"Berlin")
      weatherSurfaceEdge(field,bottom:bottom)
      XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout:5));field.typeText("X")
      XCTAssertTrue((field.value as? String ?? "").hasSuffix("X"))
      weatherSurfaceGeometry(field,"sheet-focused-city",sheet:true)
      let available=CGRect(x:app.frame.minX,y:app.frame.minY,width:app.frame.width,
        height:app.keyboards.firstMatch.frame.minY-app.frame.minY).insetBy(dx:12,dy:12)
      XCTAssertTrue(available.contains(field.frame),"Sheet city field must stay fully above the keyboard")
      shot(bottom ? "weather-surface-sheet-bottom-edited":"weather-surface-sheet-top-edited")
      weatherSurfaceEdge(done,bottom:bottom)
      expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:field);waitForExpectations(timeout:5)
      XCTAssertEqual(app.staticTexts["weather.app.city"].label,"Berlin","Done must not implicitly update the edited city")
    }
  }
  private func weatherSettingsGeometry(_ element:XCUIElement,_ state:String) {
    let f=element.frame,v=app.otherElements["reference.viewport"].frame
    let data:[String:Any] = ["identifier":element.identifier,"label":element.label,
      "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
      "viewport":[Double(v.minX),Double(v.minY),Double(v.width),Double(v.height)],
      "hittable":element.isHittable,"value":String(describing:element.value)]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="weather-settings-native-"+state;a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(v.contains(f));XCTAssertTrue(element.isHittable)
    XCTAssertGreaterThanOrEqual(f.width,44);XCTAssertGreaterThanOrEqual(f.height,44)
  }
  func testSettingsWeatherUnitsNativeHeightAndActualEdges() {
    continueAfterFailure=true
    launchUnconnectedSettingsAudit()
    let units=app.segmentedControls["weather.units"]
    scrollPhotoControlFullyIntoView(units)
    viewportShot("weather-settings-units-before")
    for (index,title) in ["°C / km/h","°F / mph","°C / km/h"].enumerated() {
      let choice=units.buttons[title]
      weatherSettingsGeometry(choice,"units-"+String(index))
      let f=choice.frame
      app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:f.midX,dy:index==1 ? f.maxY-2:f.minY+2)).tap()
      XCTAssertTrue(choice.isSelected,"Actual segment edge did not select "+title)
    }
    viewportShot("weather-settings-units-celsius-selected")
  }
  func testSettingsWeatherCityNativeHeightAndEditableEdges() {
    continueAfterFailure=true
    for bottom in [false,true] {
      launchUnconnectedSettingsAudit()
      let city=app.textFields["weather.city"]
      scrollPhotoControlFullyIntoView(city)
      weatherSettingsGeometry(city,bottom ? "city-bottom":"city-top")
      viewportShot(bottom ? "weather-settings-city-bottom-before":"weather-settings-city-top-before")
      let f=city.frame
      app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:f.midX,dy:bottom ? f.maxY-2:f.minY+2)).tap()
      XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout:5))
      city.typeText("X")
      XCTAssertTrue((city.value as? String ?? "").hasSuffix("X"),"Native city entry was not edited")
      weatherSettingsGeometry(city,bottom ? "city-focused-bottom":"city-focused-top")
      let editingSafeArea=app.scrollViews.firstMatch.frame.intersection(
        app.otherElements["reference.viewport"].frame).insetBy(dx:0,dy:40)
      XCTAssertTrue(editingSafeArea.contains(city.frame),"Focused city field must remain fully inside the same safe scroll area used before editing")
      shot(bottom ? "weather-settings-city-bottom-edited":"weather-settings-city-top-edited")
      app.terminate()
    }
  }
  private func launchUnconnectedSettingsAudit() {
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    XCTAssertTrue(app.buttons["settings.reset"].waitForExistence(timeout:5))
  }
  private func auditSettingsHitRegions(_ state:String) throws {
    viewportShot("settings-hit-region-"+state)
    let viewport=app.otherElements["reference.viewport"].frame
    let controls=app.buttons.allElementsBoundByIndex+app.textFields.allElementsBoundByIndex
      + app.switches.allElementsBoundByIndex+app.segmentedControls.allElementsBoundByIndex
      + app.sliders.allElementsBoundByIndex+app.links.allElementsBoundByIndex
    let geometry:[[String:Any]]=controls.compactMap { e in
      let f=e.frame
      guard !f.isEmpty,f.intersects(viewport) else {return nil}
      return ["identifier":e.identifier,"label":e.label,"type":e.elementType.rawValue,
        "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
        "hittable":e.isHittable,"enabled":e.isEnabled,"fullyInViewport":viewport.contains(f)]
    }
    let g=XCTAttachment(data:try JSONSerialization.data(withJSONObject:geometry,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    g.name="settings-hit-region-"+state+"-visible-control-geometry";g.lifetime = .keepAlways;add(g)
    var reports:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let e=issue.element,f=e?.frame ?? .zero
      reports.append(["identifier":e?.identifier ?? "","label":e?.label ?? "",
        "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
        "auditType":issue.auditType.rawValue,"description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let a=XCTAttachment(data:try JSONSerialization.data(withJSONObject:reports,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="settings-hit-region-"+state+"-all-findings";a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(reports.isEmpty,"Unfiltered Settings audit found \(reports.count) issues: \(reports)")
  }
  func testSettingsTopUnconnectedAutomaticHitRegionAudit() throws {
    launchUnconnectedSettingsAudit();try auditSettingsHitRegions("top")
  }
  func testSettingsControlsUnconnectedAutomaticHitRegionAudit() throws {
    launchUnconnectedSettingsAudit();scrollPhotoControlFullyIntoView(app.buttons["settings.faces"])
    try auditSettingsHitRegions("controls")
  }
  func testSettingsServicesUnconnectedAutomaticHitRegionAudit() throws {
    launchUnconnectedSettingsAudit();scrollPhotoControlFullyIntoView(app.buttons["connect.Calendar"])
    try auditSettingsHitRegions("services")
  }
  func testSettingsWeatherUnconnectedAutomaticHitRegionAudit() throws {
    launchUnconnectedSettingsAudit();scrollPhotoControlFullyIntoView(app.textFields["weather.city"])
    try auditSettingsHitRegions("weather")
  }
  func testSettingsPhotoChoicesUnconnectedAutomaticHitRegionAudit() throws {
    launchUnconnectedSettingsAudit();scrollPhotoControlFullyIntoView(app.buttons["photos.demo"])
    try auditSettingsHitRegions("photos")
  }
  func testSettingsMockMiddleAutomaticHitRegionAudit() throws {
    launchUnconnectedSettingsAudit();scrollPhotoControlFullyIntoView(app.buttons["settings.doorbell"])
    try auditSettingsHitRegions("mock-middle")
  }
  func testSettingsAdditionalVisibleChoicesAutomaticHitRegionAudit() throws {
    launchUnconnectedSettingsAudit()
    for (anchor,state) in [(app.buttons["Light & brightness"],"light-row"),
      (app.buttons["native.alarm"],"native-alarm-row"),
      (app.buttons["photos.gallery"],"gallery-row"),
      (app.links["Weather data by Open-Meteo"],"weather-attribution")] {
      scrollPhotoControlFullyIntoView(anchor)
      try auditSettingsHitRegions(state)
    }
  }
  func testSettingsMockSlidersKeepNativeAdjustmentAndValue() {
    launchUnconnectedSettingsAudit()
    for label in ["Mock blinds","Mock fan speed"] {
      let slider=app.sliders[label]
      scrollPhotoControlFullyIntoView(slider)
      let f=slider.frame,v=app.otherElements["reference.viewport"].frame
      XCTAssertGreaterThanOrEqual(f.width,44);XCTAssertGreaterThanOrEqual(f.height,44)
      XCTAssertTrue(v.contains(f));XCTAssertTrue(slider.isHittable)
      for target in [CGFloat(0.25),CGFloat(0.75)] {
        slider.adjust(toNormalizedSliderPosition:target)
        let number=Double((slider.value as? String ?? "").replacingOccurrences(of:"%",with:""))
        XCTAssertNotNil(number,"Native value: \(String(describing:slider.value))")
        XCTAssertEqual(number ?? -100,Double(target)*100,accuracy:10)
        let displayed=app.staticTexts["adjuster.value."+label]
        XCTAssertEqual(displayed.label,slider.value as? String)
      }
    }
    viewportShot("settings-native-sliders-adjusted")
  }
  private func tapSettingsNativeEdge(_ e:XCUIElement,bottom:Bool=false) {
    XCTAssertTrue(e.waitForExistence(timeout:5))
    let f=e.frame,v=app.otherElements["reference.viewport"].frame
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:[
      "identifier":e.identifier,"label":e.label,"frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
      "hittable":e.isHittable,"viewport":[Double(v.minX),Double(v.minY),Double(v.width),Double(v.height)],
      "edge":bottom ? "bottom":"top"],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="settings-native-edge-"+(e.identifier.isEmpty ? e.label:e.identifier).replacingOccurrences(of:" ",with:"-")+"-"+(bottom ? "bottom":"top")
    a.lifetime = .keepAlways;add(a)
    XCTAssertGreaterThanOrEqual(f.width,44);XCTAssertGreaterThanOrEqual(f.height,44)
    XCTAssertTrue(v.contains(f));XCTAssertTrue(e.isHittable)
    app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:f.midX,dy:bottom ? f.maxY-2:f.minY+2)).tap()
  }
  func testSettingsNightValueAndCloseActualNativeEdges() {
    continueAfterFailure=true
    launchUnconnectedSettingsAudit()
    let night=app.buttons["Night mode"]
    scrollPhotoControlFullyIntoView(night)
    XCTAssertEqual(night.value as? String,"Off")
    tapSettingsNativeEdge(night)
    expectation(for:NSPredicate(format:"value == %@","On"),evaluatedWith:night);waitForExpectations(timeout:5)
    tapSettingsNativeEdge(night,bottom:true)
    expectation(for:NSPredicate(format:"value == %@","Off"),evaluatedWith:night);waitForExpectations(timeout:5)
    tapSettingsNativeEdge(app.buttons["close"])
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
    viewportShot("settings-native-edges-returned-personal-home")
  }
  func testSettingsMockStepperAndSyntheticConnectionActualEdges() {
    continueAfterFailure=true
    launchUnconnectedSettingsAudit()
    let slider=app.sliders["Mock blinds"],increase=app.buttons["Increase Mock blinds"]
    scrollPhotoControlFullyIntoView(increase)
    let before=slider.value as? String;XCTAssertNotNil(before)
    tapSettingsNativeEdge(increase)
    expectation(for:NSPredicate(format:"value != %@",before ?? ""),evaluatedWith:slider);waitForExpectations(timeout:5)
    tapSettingsNativeEdge(app.buttons["Decrease Mock blinds"],bottom:true)
    expectation(for:NSPredicate(format:"value == %@",before ?? ""),evaluatedWith:slider);waitForExpectations(timeout:5)
    let calendar=app.buttons["connect.Calendar"]
    scrollPhotoControlFullyIntoView(calendar);tapSettingsNativeEdge(calendar)
    let status=app.staticTexts["connection.status.Calendar"]
    expectation(for:NSPredicate(format:"label CONTAINS %@","Connected"),evaluatedWith:status);waitForExpectations(timeout:5)
    XCTAssertEqual(calendar.label,"Disconnect Calendar")
    tapSettingsNativeEdge(calendar,bottom:true)
    expectation(for:NSPredicate(format:"label == %@","Disconnected"),evaluatedWith:status);waitForExpectations(timeout:5)
    XCTAssertEqual(calendar.label,"Connect Calendar")
    viewportShot("settings-native-edges-synthetic-calendar-disconnected")
  }
}

extension HomeViewUITests {
  private func verifyGuestRevokesConnectedSession(_ service:String) {
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    connectService(service)
    tap("nav.apps");tap("personal.profile");tap("profile.Alex")
    tap("all.apps");tap("app."+service);tap("device.unlock")
    let content:XCUIElement = service == "Calendar"
      ? app.staticTexts["Device fixture meeting"] : app.buttons["device.reminder.Device fixture reminder"]
    XCTAssertTrue(content.waitForExistence(timeout:5))
    viewportShot("guest-session-"+service.lowercased()+"-authenticated")
    tap("nav.apps");tap("personal.profile");tap("profile.guest")
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
    tap("all.apps");tap("app."+service)
    XCTAssertTrue(app.buttons["device.unlock"].waitForExistence(timeout:5))
    XCTAssertFalse(content.exists)
    viewportShot("guest-session-"+service.lowercased()+"-requires-new-unlock")
    tap("device.unlock")
    XCTAssertTrue(content.waitForExistence(timeout:5))
    viewportShot("guest-session-"+service.lowercased()+"-explicit-new-unlock")
  }
  func testGuestProfilePathRequiresFreshCalendarUnlock() {verifyGuestRevokesConnectedSession("Calendar")}
  func testGuestProfilePathRequiresFreshReminderUnlock() {verifyGuestRevokesConnectedSession("Reminders")}
}

extension HomeViewUITests {
  private func launchMockCameraAudit(nine:Bool=false,detail:Bool=false,talking:Bool=false) {
    launch(["--page","Cameras"])
    if nine {tap("camera.grid.size");XCTAssertTrue(app.buttons["camera.8"].exists)}
    if detail {tap("camera.0");XCTAssertEqual(app.descendants(matching:.any)["camera.demo.status"].label,"Demo still")}
    if talking {tap("camera.talk");XCTAssertTrue(app.staticTexts["Mock talkback active · No microphone used"].exists)}
  }
  private func auditMockCameraHitRegions(_ state:String) throws {
    viewportShot("mock-camera-hit-region-"+state)
    var reports:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let e=issue.element,f=e?.frame ?? .zero
      reports.append(["identifier":e?.identifier ?? "","label":e?.label ?? "",
        "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
        "auditType":issue.auditType.rawValue,"description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let a=XCTAttachment(data:try JSONSerialization.data(withJSONObject:reports,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="mock-camera-hit-region-"+state+"-all-findings";a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(reports.isEmpty,"Unfiltered mock camera audit found \(reports.count) issues: \(reports)")
  }
  func testMockCameraFourAutomaticHitRegionAudit() throws {launchMockCameraAudit();try auditMockCameraHitRegions("four")}
  func testMockCameraNineAutomaticHitRegionAudit() throws {launchMockCameraAudit(nine:true);try auditMockCameraHitRegions("nine")}
  func testMockCameraDetailAutomaticHitRegionAudit() throws {launchMockCameraAudit(detail:true);try auditMockCameraHitRegions("detail")}
  func testMockCameraTalkingAutomaticHitRegionAudit() throws {launchMockCameraAudit(detail:true,talking:true);try auditMockCameraHitRegions("talking")}
  private func tapMockCameraEdge(_ e:XCUIElement,bottom:Bool=false) {
    XCTAssertTrue(e.waitForExistence(timeout:5))
    let f=e.frame,v=app.otherElements["reference.viewport"].frame
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:[
      "identifier":e.identifier,"label":e.label,"frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
      "viewport":[Double(v.minX),Double(v.minY),Double(v.width),Double(v.height)],
      "hittable":e.isHittable,"edge":bottom ? "bottom":"top"],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="mock-camera-edge-"+e.identifier.replacingOccurrences(of:".",with:"-")+"-"+(bottom ? "bottom":"top")
    a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(v.contains(f));tapRecipeTargetEdge(e,bottom:bottom)
  }
  func testMockCameraGridSizeLastSlotAndHeaderCloseActualEdges() {
    launchMockCameraAudit()
    tapMockCameraEdge(app.buttons["camera.grid.size"])
    XCTAssertTrue(app.buttons["camera.8"].exists)
    let tiles=(0..<9).map {app.buttons["camera.\($0)"].frame}
    for i in 0..<tiles.count {for j in (i+1)..<tiles.count {XCTAssertTrue(tiles[i].intersection(tiles[j]).isNull)}}
    tapMockCameraEdge(app.buttons["camera.8"],bottom:true)
    XCTAssertEqual(app.descendants(matching:.any)["camera.demo.status"].label,"Demo still")
    XCTAssertTrue(app.staticTexts["Front Door"].exists)
    tapMockCameraEdge(app.buttons["camera.grid"])
    XCTAssertTrue(app.buttons["camera.0"].exists)
    tapMockCameraEdge(app.buttons["close"],bottom:true)
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
  }
  func testMockCameraTalkAndDetailCloseActualEdges() {
    launchMockCameraAudit(detail:true)
    tapMockCameraEdge(app.buttons["camera.talk"])
    XCTAssertTrue(app.staticTexts["Mock talkback active · No microphone used"].exists)
    tapMockCameraEdge(app.buttons["camera.talk"],bottom:true)
    XCTAssertTrue(app.staticTexts["Mock talkback off"].exists)
    tapMockCameraEdge(app.buttons["camera.close"],bottom:true)
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
  }
  func testMockCameraTalkValueAndNavigationResetAreReadable() {
    launchMockCameraAudit(detail:true)
    XCTAssertEqual(app.buttons["camera.talk"].value as? String,"Off (demo)")
    tap("camera.talk");XCTAssertEqual(app.buttons["camera.talk"].value as? String,"On (demo)")
    tap("camera.grid");tap("camera.1")
    XCTAssertEqual(app.buttons["camera.talk"].value as? String,"Off (demo)")
    tap("camera.talk");XCTAssertEqual(app.buttons["camera.talk"].value as? String,"On (demo)")
    tap("camera.close");tap("nav.apps");tap("app.Cameras");tap("camera.0")
    XCTAssertEqual(app.buttons["camera.talk"].value as? String,"Off (demo)")
    viewportShot("mock-camera-talk-off-after-navigation")
  }
  func testMockCameraFaceFrozenViewportWithoutCapture() {
    launch(["--face","Home Camera"])
    XCTAssertTrue(app.buttons["camera.3"].exists)
    viewportShot("mock-camera-face-preserved")
  }
}

extension HomeViewUITests {
  private func launchLocalBrowserAudit(history:Bool=false,multiple:Bool=false) {
    var args=["--page","Safari"]
    if history {args.append("--browser-navigation-fixture")}
    if multiple {args.append("--browser-multiple-recipes")}
    launch(args)
    XCTAssertTrue(app.webViews.staticTexts[history ? "First local page":"Garden Tomato Pasta"].waitForExistence(timeout:10))
  }
  private func auditBrowserHitRegions(_ state:String) throws {
    viewportShot("browser-hit-region-"+state)
    var reports:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let e=issue.element,f=e?.frame ?? .zero
      reports.append(["identifier":e?.identifier ?? "","label":e?.label ?? "",
        "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
        "auditType":issue.auditType.rawValue,"description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let a=XCTAttachment(data:try JSONSerialization.data(withJSONObject:reports,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="browser-hit-region-"+state+"-all-findings";a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(reports.isEmpty,"Unfiltered browser audit found \(reports.count) issues: \(reports)")
  }
  func testBrowserBundledAutomaticHitRegionAudit() throws {
    launchLocalBrowserAudit();try auditBrowserHitRegions("bundled")
  }
  func testBrowserHistoryAutomaticHitRegionAudit() throws {
    launchLocalBrowserAudit(history:true);app.links["Next page"].tap()
    XCTAssertTrue(app.webViews.staticTexts["Second local page"].waitForExistence(timeout:5))
    try auditBrowserHitRegions("history")
  }
  func testBrowserPendingAutomaticHitRegionAudit() throws {
    launchLocalBrowserAudit(history:true);app.links["Slow page"].tap()
    XCTAssertTrue(app.buttons["browser.stop"].waitForExistence(timeout:5))
    try auditBrowserHitRegions("pending")
  }
  func testBrowserRecipeChoicesAutomaticHitRegionAudit() throws {
    launchLocalBrowserAudit(multiple:true);tap("browser.recipe")
    XCTAssertTrue(app.buttons["Second local recipe"].waitForExistence(timeout:5))
    try auditBrowserHitRegions("recipe-choices")
  }
  private func tapBrowserEdge(_ e:XCUIElement,bottom:Bool=false) {
    XCTAssertTrue(e.waitForExistence(timeout:5))
    let f=e.frame,v=app.otherElements["reference.viewport"].frame
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:[
      "identifier":e.identifier,"label":e.label,"frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
      "viewport":[Double(v.minX),Double(v.minY),Double(v.width),Double(v.height)],
      "hittable":e.isHittable,"edge":bottom ? "bottom":"top"],options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="browser-edge-"+e.identifier.replacingOccurrences(of:".",with:"-")+"-"+(bottom ? "bottom":"top")
    a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(v.contains(f));tapRecipeTargetEdge(e,bottom:bottom)
  }
  func testBrowserHistoryStopSavedAndCloseActualEdges() {
    launchLocalBrowserAudit(history:true);app.links["Next page"].tap()
    XCTAssertTrue(app.webViews.staticTexts["Second local page"].waitForExistence(timeout:5))
    tapBrowserEdge(app.buttons["browser.back"])
    XCTAssertTrue(app.webViews.staticTexts["First local page"].waitForExistence(timeout:5))
    tapBrowserEdge(app.buttons["browser.forward"],bottom:true)
    XCTAssertTrue(app.webViews.staticTexts["Second local page"].waitForExistence(timeout:5))
    app.links["Slow page"].tap()
    tapBrowserEdge(app.buttons["browser.stop"])
    XCTAssertEqual(app.staticTexts["browser.status"].label,"Loading stopped.")
    XCTAssertFalse(app.buttons["browser.stop"].exists)
    viewportShot("browser-hit-region-stopped-after-edge")
    tapBrowserEdge(app.buttons["browser.saved"],bottom:true)
    XCTAssertTrue(app.staticTexts["Recent & Pinned"].waitForExistence(timeout:5))
    app.terminate();launchLocalBrowserAudit()
    tapBrowserEdge(app.buttons["close"],bottom:true)
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
  }
  func testBrowserAddressReadCancelAndRecipeChoiceActualEdges() {
    launchLocalBrowserAudit(multiple:true)
    let address=app.textFields["browser.address"]
    tapBrowserEdge(address)
    XCTAssertTrue(app.keyboards.firstMatch.exists)
    let old=address.value as? String ?? ""
    address.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:old.count)+"http://example.invalid")
    tapBrowserEdge(app.buttons["browser.load"],bottom:true)
    XCTAssertTrue(app.staticTexts["browser.status"].label.contains("HTTPS"))
    XCTAssertFalse(app.buttons["browser.stop"].exists)
    tapBrowserEdge(app.buttons["browser.recipe"])
    XCTAssertTrue(app.buttons["Second local recipe"].waitForExistence(timeout:5))
    tapBrowserEdge(app.buttons["browser.cancelRecipes"],bottom:true)
    XCTAssertTrue(address.waitForExistence(timeout:5))
    tapBrowserEdge(app.buttons["browser.recipe"],bottom:true)
    let second=app.buttons["Second local recipe"]
    tapBrowserEdge(second)
    XCTAssertTrue(app.staticTexts["Second local recipe"].waitForExistence(timeout:5))
    XCTAssertTrue(app.buttons["recipe.start"].exists)
    viewportShot("browser-hit-region-selected-second-recipe-after-edge")
  }
}

extension HomeViewUITests {
  func testReadOnlyWorldCityKeepsPickerAndSearchUntilExplicitDone() {
    let id=UUID().uuidString
    print("WORLD_WRITE_BOUNDARY_STORE_ID="+id)
    launch(["--page","World Clock","--persistence-test",id,"--state-future-fixture"])
    XCTAssertTrue(app.staticTexts["4 of 12 cities"].exists)
    tap("world.add")
    let search=app.textFields["world.search"]
    search.tap();search.typeText("Kathmandu")
    tap("world.choose.Asia/Kathmandu")
    dismissLocalWriteError()
    viewportShot("world-write-readonly-after-rejection")
    XCTAssertTrue(search.waitForExistence(timeout:3),"Rejected city save must retain its picker")
    XCTAssertEqual(search.value as? String,"Kathmandu","Rejected city save must retain its search")
    XCTAssertTrue(app.buttons["world.choose.Asia/Kathmandu"].exists)
    tap("world.add") // Explicit Done is still available after a rejected save.
    XCTAssertFalse(search.exists)
    XCTAssertTrue(app.staticTexts["4 of 12 cities"].exists)
    XCTAssertFalse(app.buttons["world.remove.Asia/Kathmandu"].exists)
    viewportShot("world-write-explicit-done-no-city-added")
    app.terminate()
    launch(["--page","World Clock","--persistence-test",id])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
    XCTAssertTrue(app.staticTexts["4 of 12 cities"].exists)
    tap("world.add")
    XCTAssertTrue(app.buttons["world.choose.Asia/Kathmandu"].exists)
    viewportShot("world-write-restart-original-data-preserved")
    let receipt=XCTAttachment(data:Data(id.utf8),uniformTypeIdentifier:"public.plain-text")
    receipt.name="world-write-owned-store-id";receipt.lifetime = .keepAlways;add(receipt)
  }
}

@MainActor
final class HomeViewUITests: XCTestCase {
  var app = XCUIApplication()
  override func setUp() {
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .portrait
  }
  override func tearDown() {
    // XCTest failures can abort before a Swift defer executes. Always restore
    // device orientation so one failed landscape case cannot taint later cases.
    XCUIDevice.shared.orientation = .portrait
    super.tearDown()
  }
  func rotateAssistantDevice(_ orientation:UIDeviceOrientation) {
    XCUIDevice.shared.orientation=orientation
    let until=Date().addingTimeInterval(8)
    var stable=0
    while Date()<until {
      let f=app.frame
      stable = (orientation.isLandscape ? f.width>f.height:f.height>f.width) ? stable+1:0
      if stable>=3 { break }
      RunLoop.current.run(until:Date().addingTimeInterval(0.2))
    }
    XCTAssertGreaterThanOrEqual(stable,3)
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
  func scrollPhotoControlFullyIntoView(_ element:XCUIElement,requireHittable:Bool=true) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    let scroll=app.scrollViews.firstMatch,viewport=app.otherElements["reference.viewport"]
    for _ in 0..<24 {
      let safe=scroll.frame.intersection(viewport.frame).insetBy(dx:0,dy:40)
      let target=element.frame
      if (!requireHittable || element.isHittable) && safe.contains(target) { break }
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
    XCTAssertEqual(app.buttons["personal.podcast.open"].label,"A Quiet Morning")
    XCTAssertTrue(app.staticTexts["Demo episode · Local audio"].exists)
    XCTAssertEqual(app.buttons["personal.podcast.play"].label,"Play")
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
  func testHorizontalDominantTopDiagonalChangesFaceInsteadOfOpeningAssistant() {
    launch(["--face","Home Camera"])
    let frame=app.otherElements["reference.viewport"].frame
    let origin=app.coordinate(withNormalizedOffset:.zero)
    let start=origin.withOffset(CGVector(dx:frame.minX+frame.width*0.25,dy:frame.minY+frame.height*0.08))
    let end=origin.withOffset(CGVector(dx:frame.minX+frame.width*0.83,dy:frame.minY+frame.height*0.32))
    viewportShot("navigation-diagonal-horizontal-before")
    start.press(forDuration:0.1,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.2)
    viewportShot("navigation-diagonal-horizontal-after")
    XCTAssertFalse(app.textFields["assistant.input"].exists)
    XCTAssertTrue(app.otherElements["face.Numerals"].waitForExistence(timeout:5))
  }
  func testVerticalDominantInteriorDiagonalDoesNotAdvanceFace() {
    launch(["--face","Home Camera"])
    let frame=app.otherElements["reference.viewport"].frame
    let origin=app.coordinate(withNormalizedOffset:.zero)
    let start=origin.withOffset(CGVector(dx:frame.minX+frame.width*0.45,dy:frame.minY+frame.height*0.45))
    let end=origin.withOffset(CGVector(dx:frame.minX+frame.width*0.70,dy:frame.minY+frame.height*0.90))
    let before=viewportBytes("navigation-diagonal-vertical-before")
    start.press(forDuration:0.1,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.2)
    let after=viewportBytes("navigation-diagonal-vertical-after")
    XCTAssertTrue(app.otherElements["face.Home Camera"].waitForExistence(timeout:5))
    XCTAssertFalse(app.otherElements["face.Numerals"].exists)
    XCTAssertEqual(viewportPixels(before,inset:0),viewportPixels(after,inset:0),
      "An ignored interior vertical gesture must preserve the actual displayed face")
  }
  func testShortFaceDragKeepsActualFaceAndDoesNotOpenAnOverlay() {
    launch(["--face","Numerals"])
    let frame=app.otherElements["reference.viewport"].frame
    let origin=app.coordinate(withNormalizedOffset:.zero)
    let before=viewportBytes("navigation-short-before")
    origin.withOffset(CGVector(dx:frame.minX+frame.width*0.5,dy:frame.minY+frame.height*0.5))
      .press(forDuration:0.1,thenDragTo:origin.withOffset(
        CGVector(dx:frame.minX+frame.width*0.58,dy:frame.minY+frame.height*0.57)),
        withVelocity:.slow,thenHoldForDuration:0.2)
    let after=viewportBytes("navigation-short-after")
    XCTAssertTrue(app.otherElements["face.Numerals"].exists)
    XCTAssertFalse(app.textFields["assistant.input"].exists)
    XCTAssertFalse(app.buttons["controls.night"].exists)
    XCTAssertEqual(viewportPixels(before,inset:0),viewportPixels(after,inset:0))
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
    viewportShot("gesture-top-left-opens-assistant",assistantRectangle:true)
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
    scrollPhotoControlFullyIntoView(connect)
    viewportShot("personal-weather-source-before-explicit-connect")
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
  func testHomeModularThermostatArrowDrawingKeepsControlFramesAndState() {
    launch(["--face","Home Modular"])
    let viewport=app.otherElements["reference.viewport"]
    let thermostat=app.buttons["home.thermostat"]
    XCTAssertTrue(thermostat.waitForExistence(timeout:5))
    XCTAssertEqual(thermostat.label,"68")
    let frame=viewport.frame
    for id in ["temperature.increase","temperature.decrease"] {
      let control=app.buttons[id]
      XCTAssertTrue(control.waitForExistence(timeout:5))
      XCTAssertTrue(frame.contains(control.frame))
      XCTAssertEqual(control.frame.width,frame.width*62/600,accuracy:1)
      XCTAssertEqual(control.frame.height,frame.height*62/600,accuracy:1)
    }
    viewportShot("home-modular-thermostat-arrows-initial")
    // Tap the visible symbol, not just the old control's centre.
    let origin=app.coordinate(withNormalizedOffset:.zero)
    origin.withOffset(CGVector(dx:frame.minX+frame.width*0.5645,
      dy:frame.minY+frame.height*0.5603)).tap()
    XCTAssertEqual(thermostat.label,"69")
    viewportShot("home-modular-thermostat-arrows-increased")
    origin.withOffset(CGVector(dx:frame.minX+frame.width*0.1105,
      dy:frame.minY+frame.height*0.5603)).tap()
    XCTAssertEqual(thermostat.label,"68")
    viewportShot("home-modular-thermostat-arrows-restored")
    // Padding is a real hit target, not just a visual/AX frame assertion.
    let increase=app.buttons["temperature.increase"].frame
    origin.withOffset(CGVector(dx:increase.minX+2,dy:increase.midY)).tap()
    XCTAssertEqual(thermostat.label,"69")
    let decrease=app.buttons["temperature.decrease"].frame
    origin.withOffset(CGVector(dx:decrease.minX+2,dy:decrease.midY)).tap()
    XCTAssertEqual(thermostat.label,"68")
  }
  // Regression for material-composition drift: retain exact equality, including
  // across independent cold launches. No retry or RGB tolerance.
  func testHomePrismColdLaunchesKeepFrozenPixelsExact() {
    defer { app.terminate() }
    var first:Data?
    for cycle in 0..<4 {
      launch(["--face","Home Modular","--animation-test","--reduce-motion"])
      for frame in 0..<8 {
        if frame>0 { Thread.sleep(forTimeInterval:1.5) }
        let pixels=viewportPixels(viewportBytes("home-prism-cold-c\(cycle)-frozen-\(frame)"))
        if let first { XCTAssertEqual(pixels,first,"Frozen viewport changed at cold launch \(cycle), frame \(frame)") }
        else { first=pixels }
      }
      app.terminate()
    }
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
    XCTAssertEqual(app.staticTexts["mock.badge"].label, "MOCK OFFLINE")
    tap("nav.faces")
    tap("home.thermostat")
    tap("thermostat.up")
    XCTAssertTrue(
      app.alerts.staticTexts["The mock home is offline. No changes were made."].waitForExistence(
        timeout: 3))
    app.alerts.buttons["OK"].tap()
    XCTAssertEqual(app.staticTexts["thermostat.value"].label, "68°")
    XCTAssertFalse(app.staticTexts["Mock home offline"].exists,
      "Offline status belongs in the shared status row, not over the thermostat title")
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
    XCTAssertEqual(app.buttons["lock.action"].label,"Authenticate Device","A demo profile cannot authorize a security action")
    tap("lock.action")
    XCTAssertTrue(app.buttons["device.unlock"].waitForExistence(timeout:5))
    shot("guest-policy-demo-profile-not-device-auth")
    tap("device.unlock")
    tap("grid.lock")
    XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked","Authentication never performs the security action automatically")
    tap("lock.action")
    XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked","A proposal is not a sent command")
    tap("lock.confirm")
    XCTAssertEqual(app.staticTexts["lock.state"].label, "Unlocked")
    viewportShot("guest-policy-explicit-authenticated-mock-lock")
  }
  func testMockLockProposalAndCancelNeverSendACommand() {
    continueAfterFailure=false
    launch(["--page","Home","--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("grid.lock")
    tap("lock.action")
    tap("device.unlock")
    tap("grid.lock")
    XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked")
    tap("lock.action")
    XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked","Preparing a security action must not send it")
    XCTAssertTrue(app.buttons["lock.confirm"].waitForExistence(timeout:5))
    viewportShot("mock-lock-proposal-no-command")
    tap("lock.cancel")
    XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked")
    XCTAssertFalse(app.buttons["lock.confirm"].exists)
    viewportShot("mock-lock-cancel-no-command")
  }
  func testMockThermostatModeChoiceRequiresObservedHeatingState() {
    continueAfterFailure=false
    launch(["--screen-thermostat","--persistence-test",UUID().uuidString,"--reset-test-store"])
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
    app.buttons["Cooling mode"].tap()
    viewportShot("home-controls-mode-picker-or-placeholder")
    let heat=app.buttons["Heat"]
    XCTAssertTrue(heat.waitForExistence(timeout:5),"Thermostat mode selection must be an actual supported control, not only a mock banner")
    heat.tap()
    XCTAssertTrue(app.staticTexts["Heating to"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°","A mode change does not fabricate a new target temperature")
    viewportShot("home-controls-heating-confirmed")
  }
  private func waitForMockLockState(_ expected:String) {
    let condition=XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@",expected),object:app.staticTexts["lock.state"])
    XCTAssertEqual(XCTWaiter.wait(for:[condition],timeout:5),.completed)
  }
  private func openMockDeviceControl(_ slot:String,store:String,scenario:String?=nil,reset:Bool=true) {
    var args=["--persistence-test",store]
    if reset {args.append("--reset-test-store")}
    if slot == "temperature" {args.append("--screen-thermostat")}
    else {args += ["--page","Settings"]}
    if let scenario {args += ["--mock-control-case",scenario,slot]}
    launch(args)
    if slot == "brightness" {activateRecipeTypeControl(app.buttons["Light & brightness"],horizontalMargin:0)}
    else if slot != "temperature" {revealRecipeTypeElement(mockDeviceIncrease(slot),horizontalMargin:0)}
  }
  private func mockDeviceIncrease(_ slot:String)->XCUIElement {
    switch slot {
    case "temperature":app.buttons["thermostat.up"]
    case "brightness":app.buttons["Increase Brightness"]
    case "fanSpeed":app.buttons["Increase Mock fan speed"]
    default:app.buttons["Increase Mock blinds"]
    }
  }
  private func mockDeviceValue(_ slot:String)->XCUIElement {
    app.staticTexts[slot == "temperature" ? "thermostat.value":"adjuster.value."+(slot == "brightness" ? "Brightness":slot == "fanSpeed" ? "Mock fan speed":"Mock blinds")]
  }
  private func exerciseMockDeviceContract(_ slot:String,initial:String,success:String,foreign:String) {
    continueAfterFailure=false;executionTimeAllowance=240
    for scenario in ["delayed","timeout","denied","foreign"] {
      let store=UUID().uuidString
      openMockDeviceControl(slot,store:store,scenario:scenario)
      XCTAssertEqual(mockDeviceValue(slot).label,initial)
      activateRecipeTypeControl(mockDeviceIncrease(slot),horizontalMargin:0)
      let status=app.staticTexts["home.control.status."+slot]
      if scenario == "delayed" {
        XCTAssertTrue(status.label.contains("pending"),"An outstanding callback must not report success")
        XCTAssertEqual(mockDeviceValue(slot).label,initial,"No optimistic value while the mock device has not applied the command")
        viewportShot("device-"+slot+"-pending")
        let done=XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Confirmed by device state"),object:status)
        XCTAssertEqual(XCTWaiter.wait(for:[done],timeout:12),.completed)
        XCTAssertEqual(mockDeviceValue(slot).label,success)
      } else {
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout:15))
        app.alerts.buttons["OK"].tap()
        if scenario == "timeout" {XCTAssertTrue(status.label.contains("timed out"))}
        if scenario == "denied" {XCTAssertTrue(status.label.contains("unverified"))}
        if scenario == "foreign" {XCTAssertTrue(status.label.contains("changed"))}
        XCTAssertEqual(mockDeviceValue(slot).label,scenario == "foreign" ? foreign:initial)
      }
      revealRecipeTypeElement(status,horizontalMargin:0)
      viewportShot("device-"+slot+"-"+scenario+"-terminal")
      print("DEVICE_CONTRACT slot=\(slot) scenario=\(scenario) value=\(mockDeviceValue(slot).label) status=\(status.label) store=\(store)")
      app.terminate()
      openMockDeviceControl(slot,store:store,reset:false)
      XCTAssertEqual(mockDeviceValue(slot).label,scenario == "delayed" ? success:scenario == "foreign" ? foreign:initial)
      XCTAssertFalse(app.staticTexts["home.control.status."+slot].label.contains("pending"),"No command is automatically replayed after restart")
    }
  }
  func testMockThermostatSuccessTimeoutDenialAndForeignChange() {
    exerciseMockDeviceContract("temperature",initial:"68°",success:"69°",foreign:"74°")
  }
  func testMockLightBrightnessSuccessTimeoutDenialAndForeignChange() {
    exerciseMockDeviceContract("brightness",initial:"75%",success:"85%",foreign:"40%")
  }
  func testMockFanSpeedSuccessTimeoutDenialAndForeignChange() {
    exerciseMockDeviceContract("fanSpeed",initial:"45%",success:"55%",foreign:"65%")
  }
  func testMockBlindsSuccessTimeoutDenialAndForeignChange() {
    exerciseMockDeviceContract("blinds",initial:"80%",success:"90%",foreign:"35%")
  }
  func testMockDeviceAdvertisedStepAndReadOnlyControls() {
    continueAfterFailure=false;executionTimeAllowance=240
    for (slot,expected) in [("temperature","70°"),("brightness","80%"),("fanSpeed","50%"),("blinds","85%")] {
      openMockDeviceControl(slot,store:UUID().uuidString,scenario:"stepped")
      activateRecipeTypeControl(mockDeviceIncrease(slot),horizontalMargin:0)
      XCTAssertEqual(mockDeviceValue(slot).label,expected,"Use the advertised five-unit step, not the normal increment")
      viewportShot("device-"+slot+"-advertised-step")
      openMockDeviceControl(slot,store:UUID().uuidString,scenario:"read-only")
      XCTAssertFalse(mockDeviceIncrease(slot).isEnabled)
      XCTAssertTrue(app.staticTexts["home.control.status."+slot].label.contains("Read-only"))
      viewportShot("device-"+slot+"-read-only")
    }
  }
  func testAllMockThermostatModesPersistWithoutChangingSetpoint() {
    continueAfterFailure=false
    let store=UUID().uuidString
    openMockDeviceControl("temperature",store:store)
    for (mode,state) in [("Off","System off"),("Auto","Auto target"),("Heat","Heating to"),("Cool","Cooling to")] {
      tap("thermostat.mode");app.buttons[mode].tap()
      XCTAssertTrue(app.staticTexts[state].waitForExistence(timeout:5))
      XCTAssertEqual(mockDeviceValue("temperature").label,"68°")
      XCTAssertTrue(app.staticTexts["home.control.status.thermostatMode"].label.contains("Confirmed"))
      app.terminate();openMockDeviceControl("temperature",store:store,reset:false)
      XCTAssertTrue(app.staticTexts[state].exists)
    }
    viewportShot("device-all-modes-persisted-cool")
  }
  func testAssistantShowsLiveDeviceReadbackWithoutPrematureSuccess() {
    continueAfterFailure=false
    launch(["--persistence-test",UUID().uuidString,"--reset-test-store","--mock-control-case","delayed","temperature"])
    tap("nav.assistant")
    let field=app.textFields["assistant.input"]
    field.tap();field.typeText("temperature 72");tap("assistant.send")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("requested"))
    XCTAssertFalse(app.staticTexts["assistant.reply"].label.contains("is set"))
    let status=app.staticTexts["home.control.status.temperature"]
    XCTAssertTrue(status.label.contains("pending"))
    let done=XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Confirmed by device state"),object:status)
    XCTAssertEqual(XCTWaiter.wait(for:[done],timeout:12),.completed)
    if app.buttons["assistant.keyboard.dismiss"].exists {tap("assistant.keyboard.dismiss")}
    revealRecipeTypeElement(status,horizontalMargin:0)
    viewportShot("device-assistant-live-confirmed-status",assistantRectangle:true)
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(mockDeviceValue("temperature").label,"72°")
  }
  func testMockDeviceForeignErrorCanBeAcknowledgedAndControlReused() {
    continueAfterFailure=false
    openMockDeviceControl("fanSpeed",store:UUID().uuidString,scenario:"foreign")
    activateRecipeTypeControl(mockDeviceIncrease("fanSpeed"),horizontalMargin:0)
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout:8));app.alerts.buttons["OK"].tap()
    let gone=XCTNSPredicateExpectation(predicate:NSPredicate(format:"exists == false"),object:app.alerts.firstMatch)
    XCTAssertEqual(XCTWaiter.wait(for:[gone],timeout:5),.completed,"The actually visible error must be dismissible")
    XCTAssertEqual(mockDeviceValue("fanSpeed").label,"65%")
    activateRecipeTypeControl(mockDeviceIncrease("fanSpeed"),horizontalMargin:0)
    XCTAssertEqual(mockDeviceValue("fanSpeed").label,"75%")
    let status=app.staticTexts["home.control.status.fanSpeed"]
    XCTAssertTrue(status.label.contains("Confirmed by device state"))
    revealRecipeTypeElement(status,horizontalMargin:0)
    viewportShot("device-foreign-error-acknowledged-and-explicit-retry-confirmed")
  }
  func testMockLockLargestSystemTextKeepsConfirmationReachable() {
    continueAfterFailure=false
    XCTAssertEqual(UIApplication.shared.preferredContentSizeCategory,.accessibilityExtraExtraExtraLarge)
    launch(["--page","Home","--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("grid.lock")
    let auth=app.buttons["lock.action"]
    activateRecipeTypeControl(auth,horizontalMargin:0)
    let unlock=app.buttons["device.unlock"]
    activateRecipeTypeControl(unlock,horizontalMargin:0);tap("grid.lock")
    let action=app.buttons["lock.action"]
    activateRecipeTypeControl(action,horizontalMargin:0)
    let confirm=app.buttons["lock.confirm"],cancel=app.buttons["lock.cancel"]
    revealRecipeTypeElement(cancel,horizontalMargin:0)
    XCTAssertGreaterThanOrEqual(cancel.frame.width,43.5)
    XCTAssertGreaterThanOrEqual(cancel.frame.height,43.5)
    systemTextSizeGeometry("mock-lock-cancel",["cancel":cancel,"clip_scroll":app.scrollViews.firstMatch,"viewport":app.otherElements["reference.viewport"]])
    activateRecipeTypeControl(cancel,horizontalMargin:0)
    XCTAssertFalse(confirm.exists)
    activateRecipeTypeControl(action,horizontalMargin:0)
    revealRecipeTypeElement(confirm,horizontalMargin:0)
    systemTextSizeGeometry("mock-lock-confirmation",["confirm":confirm,"clip_scroll":app.scrollViews.firstMatch,"viewport":app.otherElements["reference.viewport"]])
    viewportShot("mock-lock-largest-confirmation-before-action")
    XCTAssertGreaterThanOrEqual(confirm.frame.width,43.5)
    XCTAssertGreaterThanOrEqual(confirm.frame.height,43.5)
    activateRecipeTypeControl(confirm,horizontalMargin:0);waitForMockLockState("Unlocked")
    let state=app.staticTexts["lock.state"]
    revealRecipeTypeElement(state)
    let scroll=app.scrollViews.firstMatch,viewport=app.otherElements["reference.viewport"].frame
    let clip=recipeTypeScrollContains(state,scroll) ? scroll.frame.intersection(viewport):viewport
    XCTAssertTrue(axContains(clip,state.frame),"The confirmed state must actually fit in its own visible clip")
    viewportShot("mock-lock-largest-confirmed")
  }
  func testMockLockLargestInitialGeometryOnly() {
    continueAfterFailure=false
    XCTAssertEqual(UIApplication.shared.preferredContentSizeCategory,.accessibilityExtraExtraExtraLarge)
    launch(["--page","Home","--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("grid.lock")
    systemTextSizeGeometry("mock-lock-initial",["action":app.buttons["lock.action"],"scroll":app.scrollViews.firstMatch,
      "viewport":app.otherElements["reference.viewport"]])
    let a=XCTAttachment(string:app.debugDescription);a.name="mock-lock-largest-initial-hierarchy";a.lifetime = .keepAlways;add(a)
    viewportShot("mock-lock-largest-initial-diagnostic")
  }
  func testMockLockConfirmedReadbackPersistsWithoutPersistingAuthorization() {
    continueAfterFailure=false
    let id=UUID().uuidString
    launch(["--page","Home","--persistence-test",id,"--reset-test-store","--mock-lock-state","low-battery"])
    tap("grid.lock");tap("lock.action");tap("device.unlock");tap("grid.lock")
    waitForMockLockState("Locked")
    XCTAssertEqual(app.staticTexts["lock.battery"].label,"Low battery · 15%")
    tap("lock.action");XCTAssertEqual(app.staticTexts["lock.state"].label,"Locked")
    tap("lock.confirm");waitForMockLockState("Unlocked")
    XCTAssertTrue(app.staticTexts["lock.status"].label.contains("confirmed by state read-back"))
    viewportShot("mock-lock-confirmed-low-battery")
    tap("lock.action")
    XCTAssertEqual(app.staticTexts["lock.state"].label,"Unlocked")
    XCTAssertEqual(app.buttons["lock.confirm"].label,"Confirm Lock")
    tap("lock.cancel")
    app.terminate()
    launch(["--page","Home","--persistence-test",id])
    tap("grid.lock");waitForMockLockState("Unlocked")
    XCTAssertEqual(app.buttons["lock.action"].label,"Authenticate Device")
    XCTAssertFalse(app.buttons["lock.confirm"].exists)
    viewportShot("mock-lock-restart-observed-state-no-grant")
  }
  func testMockLockBackgroundDiscardsPendingConfirmation() {
    continueAfterFailure=false
    launch(["--page","Home","--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("grid.lock");tap("lock.action");tap("device.unlock");tap("grid.lock")
    waitForMockLockState("Locked");tap("lock.action")
    XCTAssertTrue(app.buttons["lock.confirm"].waitForExistence(timeout:5))
    XCUIDevice.shared.press(.home)
    XCTAssertTrue(app.wait(for:.runningBackground,timeout:5))
    app.activate()
    XCTAssertTrue(app.buttons["lock.action"].waitForExistence(timeout:5))
    XCTAssertEqual(app.buttons["lock.action"].label,"Authenticate Device")
    XCTAssertFalse(app.buttons["lock.confirm"].exists)
    tap("lock.refresh");waitForMockLockState("Locked")
    viewportShot("mock-lock-background-no-approval-no-command")
  }
  func testMockLockUnknownJammedAndBatteryFaultNeverOfferACommand() {
    continueAfterFailure=false
    for (fixture,state,battery) in [("unknown","Unknown","Battery level unavailable"),("jammed","Jammed","Low battery · 15%"),("battery-fault","Locked","Battery fault · Control unavailable")] {
      launch(["--page","Home","--persistence-test",UUID().uuidString,"--reset-test-store","--mock-lock-state",fixture])
      tap("grid.lock");tap("lock.action");tap("device.unlock");tap("grid.lock")
      waitForMockLockState(state)
      XCTAssertEqual(app.staticTexts["lock.battery"].label,battery)
      XCTAssertFalse(app.buttons["lock.action"].isEnabled)
      XCTAssertFalse(app.buttons["lock.confirm"].exists)
      XCTAssertTrue(app.buttons["lock.refresh"].isEnabled)
      viewportShot("mock-lock-unavailable-"+fixture)
      app.terminate()
    }
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
  private func exerciseFaceConfigurationRecovery(_ mode:String) {
    let id=UUID().uuidString
    print("FACE_CONFIGURATION_STORE mode=\(mode) id=\(id)")
    launch(["--persistence-test",id,"--face-configuration-fixture",mode])
    XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["store.readOnly"].exists)
    let initial=viewportBytes("face-recovery-"+mode+"-loaded")
    let image=UIImage(data:initial)!.cgImage!,w=image.width,h=image.height
    let pixels=[UInt8](viewportPixels(initial,inset:0))
    var sage=0,samples=0
    // Blank top-center paint, above all complications and away from corners.
    for y in Int(Double(h)*0.025)..<Int(Double(h)*0.055) {
      for x in Int(Double(w)*0.45)..<Int(Double(w)*0.55) {
        let i=(y*w+x)*4;samples += 1
        if Int(pixels[i])-Int(pixels[i+2])>15 &&
           Int(pixels[i+1])-Int(pixels[i+2])>20 { sage += 1 }
      }
    }
    XCTAssertGreaterThan(samples,100)
    XCTAssertEqual(sage,samples,"Recovered per-face Sage paint must actually render, not the default Mist paint")
    func checkEditor() {
      app.otherElements["face.Modular"].press(forDuration:1)
      XCTAssertTrue(app.buttons["editor.done"].waitForExistence(timeout:5))
      XCTAssertEqual(app.buttons["Sage style"].value as? String,"Selected")
      XCTAssertTrue(app.buttons["widget.0"].label.contains(mode=="legacy" ? "Weather":"Date"))
      XCTAssertTrue(app.buttons["widget.1"].label.contains("Clock"))
      XCTAssertTrue(app.buttons["widget.2"].label.contains("Timer"))
    }
    checkEditor()
    viewportShot("face-recovery-"+mode+"-editor")
    // A real editor action persists the recovered state through the normal writer.
    app.buttons["Sage style"].tap()
    tap("editor.done")
    app.terminate()
    // No fixture and no reset flag. The second process must read stored choices.
    launch(["--persistence-test",id])
    XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
    let reloaded=viewportBytes("face-recovery-"+mode+"-after-process-restart")
    XCTAssertEqual(viewportPixels(initial,inset:0),viewportPixels(reloaded,inset:0))
    checkEditor()
    tap("editor.done")
    print("FACE_CONFIGURATION_RESTART mode=\(mode) whole_viewport_identical=true")
  }
  func testLegacyFaceConfigurationRecoversAndSurvivesProcessRestart() {
    exerciseFaceConfigurationRecovery("legacy")
  }
  func testUnknownFaceWidgetPreservesSiblingChoicesAndStyleAcrossRestart() {
    exerciseFaceConfigurationRecovery("future-widget")
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
  func testHomeColorChangesOnlyHomeAndPersistsWithoutChangingModular() {
    let id=UUID().uuidString
    let receipt=XCTAttachment(string:id);receipt.name="face-color-owned-store-id";receipt.lifetime = .keepAlways;add(receipt)
    launch(["--persistence-test",id,"--reset-test-store","--face","Modular","--reduce-motion"])
    let modularBefore=viewportBytes("face-color-modular-before")
    app.otherElements["face.Modular"].press(forDuration:1)
    XCTAssertEqual(app.buttons["Mist style"].value as? String,"Selected")
    tap("select.Home Modular");tap("editor.done")
    let homeBefore=viewportBytes("face-color-home-before")
    app.otherElements["face.Home Modular"].press(forDuration:1)
    tap("Teal style");tap("editor.done")
    let homeAfter=viewportBytes("face-color-home-teal")
    XCTAssertNotEqual(viewportPixels(homeBefore,inset:0),viewportPixels(homeAfter,inset:0),
      "Selecting Home's color must actually change its own renderer")
    app.otherElements["face.Home Modular"].press(forDuration:1)
    tap("select.Modular")
    shot("face-color-modular-selection-after-home-edit")
    XCTAssertEqual(app.buttons["Mist style"].value as? String,"Selected",
      "Editing Home must not mutate an unconfigured Modular sibling through the legacy theme")
    tap("editor.done")
    let modularAfter=viewportBytes("face-color-modular-after-home-edit")
    XCTAssertEqual(viewportPixels(modularBefore,inset:0),viewportPixels(modularAfter,inset:0))
    app.terminate();launch(["--persistence-test",id,"--reduce-motion"])
    XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
    XCTAssertEqual(viewportPixels(modularBefore,inset:0),viewportPixels(viewportBytes("face-color-modular-after-restart"),inset:0))
    app.otherElements["face.Modular"].press(forDuration:1)
    tap("select.Home Modular")
    XCTAssertEqual(app.buttons["Teal style"].value as? String,"Selected")
    tap("editor.done")
    XCTAssertEqual(viewportPixels(homeAfter,inset:0),viewportPixels(viewportBytes("face-color-home-teal-after-restart"),inset:0))
  }
  func testHomeClockDoesNotOfferAnUnrenderedColorChoice() {
    launch(["--persistence-test",UUID().uuidString,"--reset-test-store","--face","Home Modular Clock","--reduce-motion"])
    app.otherElements["face.Home Modular Clock"].press(forDuration:1)
    shot("face-color-home-clock-options")
    XCTAssertFalse(app.buttons["Purple style"].exists,
      "The fixed-palette renderer must not advertise a color choice it does not render")
    XCTAssertFalse(app.buttons["Teal style"].exists)
    tap("editor.done")
    XCTAssertTrue(app.otherElements["face.Home Modular Clock"].exists)
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
  func testWorldClockDaylightRendersOnBothSidesOfMidnight() {
    launch(["--page","World Clock","--persistence-test",UUID().uuidString,"--reset-test-store",
      "--reference-date","2026-06-21T12:00:00Z","--reference-zone","UTC"])
    tap("world.add")
    let search=app.textFields["world.search"]
    search.tap();search.typeText("Reykjavik");tap("world.choose.Atlantic/Reykjavik")
    let detail=app.buttons["world.detail.open.Atlantic/Reykjavik"]
    if !detail.isHittable { app.swipeUp() }
    detail.tap()
    let bar=app.otherElements["world.daylight.bar"]
    XCTAssertTrue(bar.waitForExistence(timeout:5))
    XCTAssertTrue((bar.value as? String ?? "").contains("Sunrise"))
    let screenshot=bar.screenshot()
    let attachment=XCTAttachment(screenshot:screenshot)
    attachment.name="world-reykjavik-midnight-bar";attachment.lifetime = .keepAlways;add(attachment)
    let image=screenshot.image.cgImage!,width=image.width,height=image.height
    var pixels=[UInt8](repeating:0,count:width*height*4)
    let rendered=pixels.withUnsafeMutableBytes { buffer -> Bool in
      guard let context=CGContext(data:buffer.baseAddress,width:width,height:height,bitsPerComponent:8,
        bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else {return false}
      context.draw(image,in:CGRect(x:0,y:0,width:width,height:height));return true
    }
    XCTAssertTrue(rendered);XCTAssertGreaterThan(width,100);XCTAssertGreaterThan(height,5)
    func orange(_ fraction:Double)->Bool {
      let index=((height/2)*width+Int(Double(width-1)*fraction))*4
      return pixels[index]>200 && pixels[index+1]>80 && pixels[index+2]<100
    }
    XCTAssertFalse(orange(0.05),"Night between the early sunset and sunrise must remain dark")
    XCTAssertTrue(orange(0.5),"Daylight after sunrise must not be clamped to zero when sunset is earlier")
    shot("world-reykjavik-midnight-detail")
    tap("world.detail.done")
  }
  func testWorldClockOffersEveryZoneAndExplainsMissingSunPosition() {
    let id = UUID().uuidString
    launch(["--page", "World Clock", "--persistence-test", id, "--reset-test-store"])
    tap("world.add")
    let search = app.textFields["world.search"]
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    search.tap(); search.typeText("Asia/Shanghai")
    tap("world.choose.Asia/Shanghai")
    XCTAssertTrue(app.staticTexts["world.time.Asia/Shanghai"].waitForExistence(timeout: 3))
    shot("world-derived-zone")
    tap("world.detail.open.Asia/Shanghai")
    XCTAssertTrue(app.staticTexts["world.detail.time"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["No sun position for this time zone."].exists)
    XCTAssertTrue(app.staticTexts["Current light unknown"].exists)
    let unknownBar=app.otherElements["world.daylight.bar"].screenshot().image.cgImage!
    var sample=[UInt8](repeating:0,count:4)
    sample.withUnsafeMutableBytes { buffer in
      let context=CGContext(data:buffer.baseAddress,width:1,height:1,bitsPerComponent:8,bytesPerRow:4,
        space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
      context.draw(unknownBar,in:CGRect(x:0,y:0,width:1,height:1))
    }
    XCTAssertLessThanOrEqual(Int(sample.prefix(3).max()!)-Int(sample.prefix(3).min()!),3,
      "Unknown light must be neutral, not a translucent overlay on the purple night bar")
    shot("world-detail-derived-zone")
    tap("world.detail.done")
    XCTAssertFalse(app.staticTexts["world.detail.time"].waitForExistence(timeout: 2))
    tap("world.add")
    let second = app.textFields["world.search"]
    second.tap(); second.typeText("Sydney")
    tap("world.choose.Australia/Sydney")
    XCTAssertTrue(app.staticTexts["world.time.Australia/Sydney"].waitForExistence(timeout: 3))
    tap("world.detail.open.Australia/Sydney")
    XCTAssertTrue(app.staticTexts["world.detail.time"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.otherElements["world.daylight.bar"].exists)
    let sunrise = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Sunrise'")).firstMatch
    XCTAssertTrue(sunrise.waitForExistence(timeout: 3))
    XCTAssertTrue(sunrise.label.contains("Sunset"))
    shot("world-detail-computed-course")
    tap("world.detail.done")
    app.terminate()
    launch(["--page", "World Clock", "--persistence-test", id])
    XCTAssertTrue(app.staticTexts["world.time.Australia/Sydney"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["world.time.Asia/Shanghai"].exists)
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
    XCTAssertFalse(app.buttons["facetime.simulate"].exists)
    XCTAssertFalse(app.buttons["call.accept"].exists)
    tap("facetime.demo.preview")
    XCTAssertTrue(app.staticTexts["facetime.demo.scope"].exists)
    tap("facetime.simulate")
    XCTAssertTrue(app.staticTexts["Incoming local demo · No connection"].exists)
    XCTAssertFalse(app.buttons["call.demo.microphone"].exists)
    shot("UI27-incoming-demo-call")
    tap("call.accept")
    XCTAssertTrue(
      app.staticTexts["Local call simulation · No connection"].waitForExistence(timeout: 3))
    XCTAssertEqual(app.buttons["call.demo.microphone"].value as? String,"On (demo)")
    tap("call.demo.microphone")
    XCTAssertEqual(app.buttons["call.demo.microphone"].value as? String,"Muted (demo)")
    XCTAssertEqual(app.buttons["call.demo.video"].value as? String,"On (demo)")
    tap("call.demo.video")
    XCTAssertEqual(app.buttons["call.demo.video"].value as? String,"Off (demo)")
    shot("facetime-boundary-active-local-demo")
    tap("call.end")
    XCTAssertTrue(app.buttons["all.apps"].waitForExistence(timeout: 3))
  }
  func testFaceTimeLocalPreviewCanCloseOrDeclineWithoutAConnection() {
    launch(["--page","FaceTime"])
    XCTAssertFalse(app.buttons["facetime.system"].isEnabled)
    XCTAssertFalse(app.buttons["facetime.simulate"].exists)
    shot("facetime-boundary-normal-system-handoff")
    tap("facetime.demo.preview");XCTAssertTrue(app.buttons["facetime.simulate"].exists)
    tap("facetime.demo.preview");XCTAssertFalse(app.buttons["facetime.simulate"].exists)
    tap("facetime.demo.preview");tap("facetime.simulate")
    XCTAssertTrue(app.staticTexts["Jamie · Demo"].exists)
    tap("call.end")
    XCTAssertTrue(app.buttons["all.apps"].waitForExistence(timeout:3))
    XCTAssertFalse(app.buttons["call.accept"].exists)
    XCTAssertFalse(app.buttons["call.demo.microphone"].exists)
  }
  func testFindMySchematicDemoNeverClaimsALiveLocation() {
    launch(["--page","Find My"])
    XCTAssertEqual(app.staticTexts["findmy.demo.scope"].label,"Local demo · No Apple location data")
    let map=app.descendants(matching:.any)["findmy.demo.map"]
    XCTAssertTrue(map.exists);XCTAssertEqual(map.label,"Schematic demo map. No live location.")
    XCTAssertTrue(app.staticTexts["Demo Keys"].exists)
    XCTAssertTrue(app.staticTexts["Simulated item · Living Room"].exists)
    XCTAssertFalse(app.staticTexts["findmy.website.status"].exists)
    shot("findmy-boundary-schematic-not-live")
  }
  func testFindMyAppleWebsiteIsAnExplicitGuardedHandoffNotDataImport() {
    launch(["--page","Find My"])
    XCTAssertFalse(app.staticTexts["findmy.website.status"].exists)
    let button=app.buttons["findmy.apple.website"]
    scrollPhotoControlFullyIntoView(button);XCTAssertTrue(button.isHittable);button.tap()
    let status=app.staticTexts["findmy.website.status"]
    XCTAssertTrue(status.waitForExistence(timeout:3))
    XCTAssertEqual(status.label,"Find Devices website not opened in tests")
    let viewport=app.otherElements["reference.viewport"].frame
    XCTAssertGreaterThan(status.frame.minY,viewport.minY)
    XCTAssertLessThan(status.frame.maxY,viewport.maxY)
    XCTAssertTrue(app.staticTexts["findmy.website.scope"].label.contains("no locations are imported"))
    XCTAssertEqual(app.staticTexts["findmy.demo.scope"].label,"Local demo · No Apple location data")
    shot("findmy-boundary-website-handoff-guard")
  }
  func testFindMyToneReportsOnlyALocalRequestNotRemotePlayback() {
    launch(["--page","Find My"])
    let button=app.buttons["findmy.demo.sound"];scrollPhotoControlFullyIntoView(button);button.tap()
    XCTAssertTrue(app.staticTexts["Local demo tone requested · No remote item contacted"].waitForExistence(timeout:3))
    XCTAssertEqual(app.staticTexts["findmy.demo.scope"].label,"Local demo · No Apple location data")
    shot("findmy-boundary-local-tone-request-only")
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
  func testHomeModularIntercomReferenceMarkAndLocalDestination() {
    XCUIDevice.shared.orientation = .portrait
    launch(["--face","Home Modular"])
    viewportShot("home-modular-intercom-reference")
    let intercom=app.buttons.matching(NSPredicate(format:"label CONTAINS %@","Intercom")).firstMatch
    XCTAssertTrue(intercom.waitForExistence(timeout:5))
    let f=intercom.frame
    XCTAssertTrue(app.otherElements["reference.viewport"].frame.contains(f))
    app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:f.midX,dy:f.midY)).tap()
    XCTAssertTrue(app.textFields["intercom.input"].waitForExistence(timeout:5))
    viewportShot("home-modular-intercom-local-destination-no-send")
    // Do not send/record; only verify the local synthetic destination.
    tap("nav.controls");tap("controls.night");tap("nav.faces")
    let pixels=viewportPixels(viewportBytes("home-modular-intercom-night-primary"))
    var lit=0,wrong=0
    for i in stride(from:0,to:pixels.count,by:4) where pixels[i]>25 {
      lit+=1
      if Double(pixels[i+1])>Double(pixels[i])*0.4 || Double(pixels[i+2])>Double(pixels[i])*0.4 { wrong+=1 }
    }
    XCTAssertGreaterThan(lit,100)
    XCTAssertEqual(wrong,0)
  }

  func testHomeGridIntercomReferenceMarkAndMatchedState() {
    XCUIDevice.shared.orientation = .portrait
    launch(["--page","Home"])
    XCTAssertTrue(app.buttons["grid.entrylight"].waitForExistence(timeout:5))
    viewportShot("grid-intercom-entry-on")
    tap("grid.entrylight")
    viewportShot("grid-intercom-entry-off")
    tap("grid.entrylight")
    viewportShot("grid-intercom-entry-on-return")
    let intercom=app.buttons.matching(NSPredicate(format:"label CONTAINS %@","Intercom")).firstMatch
    XCTAssertTrue(intercom.waitForExistence(timeout:5))
    intercom.tap()
    XCTAssertTrue(app.textFields["intercom.input"].waitForExistence(timeout:5))
    XCTAssertTrue(app.buttons["intercom.send"].exists)
    viewportShot("grid-intercom-local-destination-no-send")
    // No announcement, microphone or system communication is invoked.
    tap("nav.controls");tap("controls.night");tap("nav.faces")
    drawer();tap("app.Home")
    XCTAssertTrue(app.buttons["grid.entrylight"].waitForExistence(timeout:5))
    let pixels=viewportPixels(viewportBytes("grid-intercom-night-primary"))
    var lit=0,wrong=0
    for i in stride(from:0,to:pixels.count,by:4) where pixels[i]>25 {
      lit+=1
      if Double(pixels[i+1])>Double(pixels[i])*0.4 || Double(pixels[i+2])>Double(pixels[i])*0.4 { wrong+=1 }
    }
    XCTAssertGreaterThan(lit,100)
    XCTAssertEqual(wrong,0)
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
  func testLandscapeAndReturnToPortrait() throws {
    XCUIDevice.shared.orientation = .portrait
    defer { XCUIDevice.shared.orientation = .portrait }
    launch()
    for (name,orientation) in [("landscape-left",UIDeviceOrientation.landscapeLeft),
      ("portrait-return",.portrait),("landscape-right",.landscapeRight),("portrait-final",.portrait)] {
      XCUIDevice.shared.orientation=orientation
      let until=Date().addingTimeInterval(12)
      var previous=CGRect.null,stable=0,settled=false
      while Date()<until {
        let a=app.frame,v=app.otherElements["reference.viewport"].frame
        let expectedAspect=orientation.isLandscape ? a.width>a.height:a.height>a.width
        let valid=expectedAspect && !v.isEmpty && a.contains(v) && v.width==v.height
          && v.contains(app.buttons["home.thermostat"].frame) && app.buttons["nav.faces"].isHittable
        stable = valid && v==previous ? stable+1:0
        previous=v
        if stable>=2 { settled=true;break }
        Thread.sleep(forTimeInterval:0.2)
      }
      XCTAssertTrue(settled,"Expected stable orientation and a contained square viewport: "+name)
      // app.screenshot() crops using inconsistent rotation coordinates on the
      // tested simulator runtime. Whole-screen capture preserves the actual
      // display; require its oriented point dimensions to match the app frame.
      let screen=XCUIScreen.main.screenshot()
      XCTAssertEqual(screen.image.size.width,app.frame.width)
      XCTAssertEqual(screen.image.size.height,app.frame.height)
      let picture=XCTAttachment(screenshot:screen)
      picture.name="rotation-"+name+"-screen";picture.lifetime = .keepAlways;add(picture)
      let frame=app.buttons["home.thermostat"].frame
      // Baseline AX hittability is false for this glass button even in portrait.
      // A real coordinate tap plus resulting values verifies actual interaction.
      app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:frame.midX,dy:frame.midY)).tap()
      XCTAssertTrue(app.staticTexts["thermostat.value"].waitForExistence(timeout:5))
      XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
      tap("thermostat.up")
      XCTAssertEqual(app.staticTexts["thermostat.value"].label,"69°")
      tap("thermostat.down")
      XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
      tap("nav.faces")
    }
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
  func testPhotoClockVisibleInkUsesButDoesNotExceedTheProtectedBand() {
    launch(["--face","Photos","--photo-clock-test-mode","background"])
    let background=viewportBytes("photo-type-protected-band-background")
    let backdrop=[UInt8](viewportPixels(background,inset:0))
    app.terminate()
    launch(["--face","Photos","--photo-clock-test-mode","stencil"])
    let data=viewportBytes("photo-type-protected-band-stencil")
    let image=UIImage(data:data)!.cgImage!
    let pixels=[UInt8](viewportPixels(data,inset:0))
    XCTAssertEqual(pixels.count,backdrop.count)
    var rows:[Int]=[]
    // White runtime ink against the own dark landscape, not accessibility bounds.
    // Caption and rounded viewport corners are outside this fixed clock ROI.
    for y in Int(Double(image.height)*0.04)..<Int(Double(image.height)*0.44) {
      var white=0
      for x in Int(Double(image.width)*0.05)..<Int(Double(image.width)*0.95) {
        let i=(y*image.width+x)*4
        if (0..<3).allSatisfy({pixels[i+$0]>245}) &&
           (0..<3).contains(where:{backdrop[i+$0]<190}) { white += 1 }
      }
      if white>10 { rows.append(y) }
    }
    XCTAssertFalse(rows.isEmpty)
    let top=Double(rows.first ?? 0)/Double(image.height)
    let bottom=Double((rows.last ?? 0)+1)/Double(image.height)
    XCTAssertGreaterThanOrEqual(bottom-top,0.27,"Ink should visibly use the taller available band")
    XCTAssertGreaterThanOrEqual(top,0.07,"Ink must remain inside the existing protected layout")
    XCTAssertLessThanOrEqual(bottom,0.39,"No glyph may exceed the existing protected layout")
    print("PHOTO_TYPE_INK top=\(top) bottom=\(bottom) height=\(bottom-top)")
  }
  func testAllTenOwnedPhotoGlyphsRenderInsideTheirNativeTiles() {
    launch(["--face","Photos","--photo-glyph-atlas"])
    for digit in 0..<10 {
      let tile=app.descendants(matching:.any).matching(identifier:"photo.glyph.\(digit)").firstMatch
      XCTAssertTrue(tile.waitForExistence(timeout:5))
      let data=tile.screenshot().pngRepresentation
      let attachment=XCTAttachment(data:data,uniformTypeIdentifier:"public.png")
      attachment.name="photo-glyph-tile-\(digit)";attachment.lifetime = .keepAlways;add(attachment)
      let image=UIImage(data:data)!.cgImage!,w=image.width,h=image.height
      let pixels=[UInt8](viewportPixels(data,inset:0))
      var count=0,left=w,right=0,top=h,bottom=0
      for y in 0..<h {
        for x in 0..<w {
          let i=(y*w+x)*4
          if (0..<3).allSatisfy({pixels[i+$0]>245}) {
            count += 1;left=min(left,x);right=max(right,x+1)
            top=min(top,y);bottom=max(bottom,y+1)
          }
        }
      }
      XCTAssertGreaterThan(count,100)
      XCTAssertGreaterThanOrEqual(left,2);XCTAssertLessThanOrEqual(right,w-2)
      XCTAssertGreaterThanOrEqual(top,2);XCTAssertLessThanOrEqual(bottom,h-2)
      let counters:[Double]=digit==0 ? [0.5]:digit==8 ? [0.25,0.75]:digit==9 ? [0.25]:digit==6 ? [0.75]:[]
      for y in counters {
        let i=(Int(Double(h)*y)*w+w/2)*4
        XCTAssertTrue((0..<3).allSatisfy { pixels[i+$0]<20 },"Counter must remain visibly open in glyph \(digit)")
      }
      if digit==9 || digit==6 {
        for y in [0.36,0.46,0.56] {
          let px=digit==9 ? 0.82:0.18,py=digit==9 ? y:1-y
          let i=(Int(Double(h)*py)*w+Int(Double(w)*px))*4
          XCTAssertTrue((0..<3).allSatisfy { pixels[i+$0]>230 },
            "Bowl and shaft must be visibly united in glyph \(digit)")
        }
      }
      print("PHOTO_OWN_GLYPH digit=\(digit) white=\(count) bounds=\(left),\(top),\(right),\(bottom)")
    }
    viewportShot("photo-owned-glyph-atlas")
  }
  func testPhotoInkRasterMatchesRenderedOwnPathsWithoutMirroring() {
    for fixture in ["sparse-depth","top"] {
      let args = ["--photo-layout-fixture",fixture,"--photo-depth-unoccluded-control"]
      launch(args+["--photo-clock-test-mode","stencil"])
      let vectorData = viewportBytes("photo-ink-vector-"+fixture)
      let image = UIImage(data:vectorData)!.cgImage!,w=image.width,h=image.height
      let vector = [UInt8](viewportPixels(vectorData,inset:0))
      app.terminate()
      launch(args+["--photo-ink-raster-control"])
      let raster = [UInt8](viewportPixels(viewportBytes("photo-ink-raster-"+fixture),inset:0))
      var white = [Int](repeating:0,count:128*128)
      var counts = white
      for y in 0..<h {
        for x in 0..<w {
          let cell = min(127,y*128/h)*128+min(127,x*128/w),i=(y*w+x)*4
          counts[cell] += 1
          if (0..<3).allSatisfy({vector[i+$0]>245}) { white[cell] += 1 }
        }
      }
      var intersection=0,union=0
      var digitIntersection=[Int](repeating:0,count:4),digitUnion=digitIntersection
      // Fixed independent regions of the reference-clock 10 09. In particular,
      // mirrored 1/9 must not hide behind the almost symmetric zero bodies.
      let columns=[0.05..<0.19,0.19..<0.40,0.55..<0.77,0.77..<0.95]
      for y in 0..<128 {
        for x in 0..<128 {
          let cell=y*128+x
          let vectorInk=white[cell]*2>counts[cell]
          let px=min(w-1,Int((Double(x)+0.5)/128*Double(w)))
          let py=min(h-1,Int((Double(y)+0.5)/128*Double(h)))
          let rasterInk=raster[(py*w+px)*4]>127
          if vectorInk && rasterInk { intersection += 1 }
          if vectorInk || rasterInk { union += 1 }
          for digit in 0..<4 where columns[digit].contains((Double(x)+0.5)/128) {
            if vectorInk && rasterInk { digitIntersection[digit] += 1 }
            if vectorInk || rasterInk { digitUnion[digit] += 1 }
          }
        }
      }
      let iou=Double(intersection)/Double(max(1,union))
      print("PHOTO_INK_ALIGNMENT fixture=\(fixture) intersection=\(intersection) union=\(union) iou=\(iou)")
      XCTAssertGreaterThan(union,100)
      XCTAssertGreaterThanOrEqual(iou,0.90,"Measured matrix and visible own glyphs must align, without a display flip")
      for digit in 0..<4 {
        let fraction=Double(digitIntersection[digit])/Double(max(1,digitUnion[digit]))
        print("PHOTO_INK_DIGIT_ALIGNMENT fixture=\(fixture) digit=\(digit) iou=\(fraction)")
        XCTAssertGreaterThanOrEqual(fraction,0.90)
      }
      app.terminate()
    }
  }
  func testPhotoNativeAlphaReplayUsesReadableMediumTopAndActuallyOccludesInk() {
    let args=["--photo-layout-fixture","native-alpha-replay"]
    launch(args+["--photo-clock-test-mode","background"])
    let bgData=viewportBytes("photo-ink-replay-background")
    let bg=[UInt8](viewportPixels(bgData,inset:0))
    app.terminate()
    launch(args+["--photo-clock-test-mode","stencil","--photo-depth-unoccluded-control"])
    let unoccluded=viewportBytes("photo-ink-replay-unoccluded")
    let image=UIImage(data:unoccluded)!.cgImage!,w=image.width,h=image.height
    let stencil=[UInt8](viewportPixels(unoccluded,inset:0))
    app.terminate()
    launch(args+["--photo-clock-test-mode","stencil"])
    let geometry=app.staticTexts["photo.clock.geometry.test"].label
    XCTAssertTrue(geometry.contains("height=0.56;y=0.05;"),geometry)
    let layout=app.staticTexts["photo.layout.test"].label
    XCTAssertTrue(layout.contains("fixture_mac_native_alpha_replay"),layout)
    XCTAssertTrue(layout.contains("depth=true;foreground=true;"),layout)
    let meta=app.staticTexts["photo.clock.ink.test"].label
    print("PHOTO_INK_REPLAY \(geometry) \(meta)")
    let actual=[UInt8](viewportPixels(viewportBytes("photo-ink-replay-occluded-stencil"),inset:0))
    var crossed=0,restored=0
    // Fixed interior of this own portrait's opaque head, not its soft edge.
    for y in Int(Double(h)*0.29)..<Int(Double(h)*0.38) {
      for x in Int(Double(w)*0.585)..<Int(Double(w)*0.595) {
        let i=(y*w+x)*4
        if (0..<3).allSatisfy({stencil[i+$0]>245}) &&
           (0..<3).contains(where:{bg[i+$0]<190}) {
          crossed += 1
          if (0..<3).allSatisfy({abs(Int(actual[i+$0])-Int(bg[i+$0]))<=2}) { restored += 1 }
        }
      }
    }
    print("PHOTO_INK_REPLAY_ALPHA crossed=\(crossed) restored=\(restored)")
    XCTAssertGreaterThan(crossed,100)
    XCTAssertEqual(restored,crossed)
    app.terminate()
    launch(args)
    viewportShot("photo-ink-replay-glass")
  }
  func testPhotoInkIsRecomputedWhenTheDisplayedMinuteChanges() {
    launch(["--photo-layout-fixture","native-alpha-replay","--fast-photo-clock"])
    let initial=app.staticTexts["photo.clock.ink.test"].label
    XCTAssertFalse(initial.contains("ink=-1"),initial)
    let first=viewportBytes("photo-ink-clock-before")
    let changed=NSPredicate { _,_ in self.app.staticTexts["photo.clock.ink.test"].label != initial }
    expectation(for:changed,evaluatedWith:nil)
    waitForExpectations(timeout:6)
    let next=app.staticTexts["photo.clock.ink.test"].label
    XCTAssertFalse(next.contains("ink=-1"),next)
    XCTAssertNotEqual(initial.components(separatedBy:";")[0],next.components(separatedBy:";")[0])
    XCTAssertNotEqual(initial.components(separatedBy:";")[1],next.components(separatedBy:";")[1])
    let second=viewportBytes("photo-ink-clock-after")
    XCTAssertNotEqual(viewportPixels(first,inset:0),viewportPixels(second,inset:0))
    print("PHOTO_INK_CLOCK before=\(initial) after=\(next)")
  }
  func testPhotoFullHeightMatteActuallyOccludesClockInkWithoutMirroring() {
    let fixture=["--photo-layout-fixture","sparse-depth"]
    launch(fixture+["--photo-clock-test-mode","background"])
    let background=viewportBytes("photo-adaptive-full-background")
    let bg=[UInt8](viewportPixels(background,inset:0))
    app.terminate()
    launch(fixture+["--photo-clock-test-mode","stencil","--photo-depth-unoccluded-control"])
    let stencilData=viewportBytes("photo-adaptive-full-unoccluded-stencil")
    let image=UIImage(data:stencilData)!.cgImage!,w=image.width,h=image.height
    let stencil=[UInt8](viewportPixels(stencilData,inset:0))
    XCTAssertEqual(stencil.count,bg.count)
    app.terminate()
    launch(fixture)
    let geometry=app.staticTexts["photo.clock.geometry.test"].label
    XCTAssertTrue(geometry.contains("height=0.9;"),geometry)
    let actual=[UInt8](viewportPixels(viewportBytes("photo-adaptive-full-alpha-occlusion"),inset:0))
    XCTAssertEqual(actual.count,bg.count)
    var covered=0,coveredChanges=0,outsideChanges=0
    var glassSamples=0,glassTransmitted=0,opaqueMatches=0
    var inkRows:[Int]=[]
    var left=w,right=0
    for y in Int(Double(h)*0.02)..<Int(Double(h)*0.98) {
      var rowInk=0
      for x in Int(Double(w)*0.02)..<Int(Double(w)*0.98) {
        let i=(y*w+x)*4
        let ink=(0..<3).allSatisfy { stencil[i+$0]>245 } &&
          (0..<3).contains { bg[i+$0]<190 }
        if ink { rowInk += 1;left=min(left,x);right=max(right,x+1) }
        let nx=Double(x)/Double(w),ny=Double(y)/Double(h)
        // Fixed interior of the asymmetric top-left alpha fixture, away from edges.
        let subject=nx>=0.13 && nx<=0.24 && ny>=0.17 && ny<=0.43
        if ink && subject {
          covered += 1
          if (0..<3).contains(where:{actual[i+$0] != bg[i+$0]}) { coveredChanges += 1 }
        } else if ink && !subject &&
                  (0..<3).contains(where:{abs(Int(actual[i+$0])-Int(bg[i+$0]))>3}) {
          outsideChanges += 1
        }
        let nearSubject=nx>=0.11 && nx<=0.26 && ny>=0.15 && ny<=0.45
        let neighbors=[i,i-12,i+12,i-w*12,i+w*12]
        if ink && !nearSubject &&
           neighbors.allSatisfy({j in (0..<3).allSatisfy {stencil[j+$0]>245}}) {
          glassSamples += 1
          let error=(0..<3).map {abs(Int(actual[i+$0])-Int(bg[i+$0]))}.max()!
          let opaqueError=(0..<3).map {abs(Int(stencil[i+$0])-Int(bg[i+$0]))}.max()!
          if error<=45 { glassTransmitted += 1 }
          if opaqueError<=45 { opaqueMatches += 1 }
        }
      }
      if rowInk>10 { inkRows.append(y) }
    }
    XCTAssertFalse(inkRows.isEmpty)
    let top=Double(inkRows.first ?? 0)/Double(h),bottom=Double((inkRows.last ?? 0)+1)/Double(h)
    XCTAssertGreaterThan(bottom-top,0.75)
    XCTAssertGreaterThanOrEqual(top,0.05)
    XCTAssertLessThanOrEqual(bottom,0.95)
    XCTAssertGreaterThanOrEqual(Double(left)/Double(w),0.05)
    XCTAssertLessThanOrEqual(Double(right)/Double(w),0.95)
    XCTAssertGreaterThan(covered,100,"The independent stencil must prove ink exists behind the subject")
    XCTAssertEqual(coveredChanges,0,"Actual foreground must occlude every sampled covered ink pixel")
    XCTAssertGreaterThan(outsideChanges,1000,"The unoccluded glass clock must remain visibly rendered")
    XCTAssertGreaterThan(glassSamples,500)
    XCTAssertGreaterThan(Double(glassTransmitted)/Double(max(1,glassSamples)),0.8,
      "Own large glyph bodies must transmit the correctly registered patterned backdrop")
    XCTAssertLessThan(Double(opaqueMatches)/Double(max(1,glassSamples)),0.05)
    print("PHOTO_OWN_GLASS samples=\(glassSamples) transmitted=\(glassTransmitted) opaqueMatches=\(opaqueMatches)")
    print("PHOTO_ADAPTIVE_ALPHA covered=\(covered) coveredChanges=\(coveredChanges) outsideChanges=\(outsideChanges) top=\(top) bottom=\(bottom) left=\(Double(left)/Double(w)) right=\(Double(right)/Double(w))")
  }
  func testPhotoMediumMatteBandHasVisibleInkWithinItsOwnGeometry() {
    launch(["--photo-layout-fixture","top","--photo-clock-test-mode","stencil",
            "--photo-depth-unoccluded-control"])
    let data=viewportBytes("photo-adaptive-medium-unoccluded-stencil")
    let image=UIImage(data:data)!.cgImage!,w=image.width,h=image.height
    let pixels=[UInt8](viewportPixels(data,inset:0))
    var rows:[Int]=[]
    var left=w,right=0
    for y in 0..<h {
      var white=0
      for x in 0..<w {
        let i=(y*w+x)*4
        if (0..<3).allSatisfy({pixels[i+$0]>245}) {
          white += 1;left=min(left,x);right=max(right,x+1)
        }
      }
      if white>10 { rows.append(y) }
    }
    let geometry=app.staticTexts["photo.clock.geometry.test"].label
    XCTAssertTrue(geometry.contains("height=0.56;"),geometry)
    XCTAssertFalse(rows.isEmpty)
    let top=Double(rows.first ?? 0)/Double(h),bottom=Double((rows.last ?? 0)+1)/Double(h)
    XCTAssertGreaterThan(bottom-top,0.45)
    XCTAssertGreaterThanOrEqual(top,0.39)
    XCTAssertLessThanOrEqual(bottom,0.95)
    XCTAssertGreaterThanOrEqual(Double(left)/Double(w),0.05)
    XCTAssertLessThanOrEqual(Double(right)/Double(w),0.95)
    print("PHOTO_ADAPTIVE_MEDIUM top=\(top) bottom=\(bottom) left=\(Double(left)/Double(w)) right=\(Double(right)/Double(w))")
    app.terminate()
    launch(["--photo-layout-fixture","top"])
    viewportShot("photo-adaptive-medium-glass")
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
    scrollPhotoControlFullyIntoView(automatic)
    automatic.tap()
    XCTAssertEqual(automatic.value as? String,"0","The actual framing switch must be off before a manual slider can appear")
    let horizontal = app.sliders["photos.crop.horizontal"]
    viewportShot("photo-write-crop-after-automatic-toggle")
    print("PHOTO_CROP_STATE auto=\(String(describing:automatic.value)) horizontal_exists=\(horizontal.exists) horizontal_frame=\(horizontal.exists ? horizontal.frame:.zero) viewport=\(app.otherElements["reference.viewport"].frame)")
    scrollPhotoControlFullyIntoView(horizontal)
    if !horizontal.isHittable {
      viewportShot("photo-write-crop-slider-not-hittable")
      print("PHOTO_CROP_ACTUAL_UI="+app.debugDescription)
    }
    XCTAssertTrue(horizontal.isHittable)
    horizontal.adjust(toNormalizedSliderPosition: 0.85)
    tap("nav.faces")
    let layout = app.staticTexts["photo.layout.test"]
    XCTAssertTrue(layout.label.contains("full=false"), layout.label)
    shot("photo-layout-manual-crop")
    tap("nav.controls")
    tap("controls.settings")
    let reset = app.buttons["photos.layout.reset"]
    scrollPhotoControlFullyIntoView(reset)
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

  func viewportShot(_ name: String, assistantRectangle:Bool=false) {
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
    if assistantRectangle {
      XCTAssertTrue(app.scrollViews["assistant.content"].exists)
      XCTAssertTrue(app.frame.contains(frame))
      XCTAssertTrue(frame.contains(app.buttons["assistant.send"].frame))
      XCTAssertGreaterThanOrEqual(frame.width,150)
      XCTAssertGreaterThanOrEqual(frame.height,150)
    } else {
      XCTAssertEqual(frame.width, frame.height, accuracy: 1)
    }
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
    let previous=app.staticTexts["thermostat.value"].label
    tap("thermostat.up")
    XCTAssertTrue(app.alerts.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Original saved data is unchanged")).firstMatch.waitForExistence(timeout:5))
    app.alerts.buttons["OK"].tap()
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,previous,"A rejected write must not change the displayed mock value")
    viewportShot("mock-write-readonly-value-unchanged")
    app.terminate()
    launch(["--persistence-test", id, "--screen-thermostat"])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
    shot("store-future-version-readonly-after-relaunch")
  }
  func testAssistantKeyboardGeometryAndUnsentRotation() {
    XCUIDevice.shared.orientation = .portrait
    defer { XCUIDevice.shared.orientation = .portrait }
    launch()
    tap("nav.assistant")
    let field=app.textFields["assistant.input"]
    field.tap();field.typeText("temperature 73")
    var reports:[[String:Any]]=[]
    for (name,orientation) in [("portrait",UIDeviceOrientation.portrait),("landscape",.landscapeLeft)] {
      XCUIDevice.shared.orientation=orientation
      let keyboard=app.keyboards.firstMatch
      XCTAssertTrue(keyboard.waitForExistence(timeout:5))
      let deadline=Date().addingTimeInterval(5)
      var previous=CGRect.null,stable=0
      while Date()<deadline {
        let f=app.frame,v=app.otherElements["reference.viewport"].frame
        let valid=(orientation.isLandscape ? f.width>f.height:f.height>f.width) && app.frame.contains(v)
        stable = valid && v==previous ? stable+1:0;previous=v
        if stable>=3 { break }
        RunLoop.current.run(until:Date().addingTimeInterval(0.2))
      }
      XCTAssertGreaterThanOrEqual(stable,3)
      let send=app.buttons["assistant.send"]
      let screen=XCUIScreen.main.screenshot()
      XCTAssertEqual(screen.image.size.width,app.frame.width)
      XCTAssertEqual(screen.image.size.height,app.frame.height)
      let picture=XCTAttachment(screenshot:screen);picture.name="assistant-keyboard-"+name+"-screen";picture.lifetime = .keepAlways;add(picture)
      func box(_ f:CGRect)->[String:Double] { ["x":f.minX,"y":f.minY,"width":f.width,"height":f.height] }
      reports.append(["orientation":name,"app":box(app.frame),"input":box(field.frame),"send":box(send.frame),"keyboard":box(keyboard.frame),"viewport":box(app.otherElements["reference.viewport"].frame)])
      let attachment=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:reports,options:[.prettyPrinted,.sortedKeys]),uniformTypeIdentifier:"public.json")
      attachment.name="assistant-keyboard-geometry-"+name;attachment.lifetime = .keepAlways;add(attachment)
      XCTAssertEqual(field.value as? String,"temperature 73")
      XCTAssertTrue(field.isHittable);XCTAssertTrue(send.isHittable)
      XCTAssertGreaterThanOrEqual(send.frame.height,44)
      XCTAssertGreaterThanOrEqual(send.frame.width,44)
      XCTAssertTrue(app.frame.contains(field.frame));XCTAssertTrue(app.frame.contains(send.frame))
      XCTAssertLessThanOrEqual(field.frame.maxY,keyboard.frame.minY)
      XCTAssertLessThanOrEqual(send.frame.maxY,keyboard.frame.minY)
      XCTAssertEqual(app.staticTexts["assistant.reply"].label,"What can I help you with?")
    }
    tap("assistant.keyboard.dismiss")
    XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout:1))
    XCTAssertEqual(field.value as? String,"temperature 73")
    XCTAssertEqual(app.staticTexts["assistant.reply"].label,"What can I help you with?")
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
    tap("nav.assistant");XCTAssertEqual(field.value as? String,"temperature 73")
  }

  func testAssistantShortcutDismissalAndSoftwareKeyboardSend() {
    launch()
    rotateAssistantDevice(.landscapeLeft)
    app.typeKey("s",modifierFlags:[.command,.shift])
    let field=app.textFields["assistant.input"]
    XCTAssertTrue(field.waitForExistence(timeout:5))
    field.typeText("temperature 73")
    tap("assistant.keyboard.dismiss")
    expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:app.buttons["assistant.keyboard.dismiss"])
    waitForExpectations(timeout:5)
    XCTAssertEqual(field.value as? String,"temperature 73")
    XCTAssertEqual(app.staticTexts["assistant.reply"].label,"What can I help you with?")
    app.typeKey("s",modifierFlags:[.command,.shift])
    XCTAssertTrue(app.buttons["assistant.keyboard.dismiss"].waitForExistence(timeout:5))
    // Return is explicitly labelled Send; dismissal, focus and route changes never send.
    field.typeText("\n")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("73"))
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"73°")
    shot("assistant-keyboard-explicit-send-only")
  }
  func testAssistantViewportGesturesAndContentScrollDoNotSend() {
    XCUIDevice.shared.orientation = .portrait
    defer { XCUIDevice.shared.orientation = .portrait }
    for orientation in [UIDeviceOrientation.portrait,.landscapeLeft] {
      launch()
      rotateAssistantDevice(orientation)
      tap("nav.faces")
      func drag(_ x:Double,_ y:Double,_ dx:Double,_ dy:Double) {
        let viewport=app.otherElements["reference.viewport"]
        var f=viewport.frame,previous=CGRect.null,stable=0
        let until=Date().addingTimeInterval(6)
        while Date()<until {
          f=viewport.frame
          stable = app.frame.contains(f) && f==previous ? stable+1:0;previous=f
          if stable>=3 { break }
          RunLoop.current.run(until:Date().addingTimeInterval(0.2))
        }
        XCTAssertGreaterThanOrEqual(stable,3,"Gesture coordinates need a settled, on-screen viewport")
        let origin=app.coordinate(withNormalizedOffset:.zero)
        origin.withOffset(CGVector(dx:f.minX+x*f.width,dy:f.minY+y*f.height))
          .press(forDuration:0.1,thenDragTo:origin.withOffset(CGVector(dx:f.minX+dx*f.width,dy:f.minY+dy*f.height)),withVelocity:.slow,thenHoldForDuration:0.2)
      }
      drag(0.4,0.06,0.4,0.65)
      let field=app.textFields["assistant.input"]
      XCTAssertTrue(field.waitForExistence(timeout:5))
      field.tap();field.typeText("temperature 73")
      let scroll=app.scrollViews["assistant.content"]
      XCTAssertTrue(scroll.exists)
      // A phone's compact landscape keyboard prioritizes its composer. Expose
      // the document with the same explicit dismissal offered to the user.
      if scroll.frame.isEmpty { tap("assistant.keyboard.dismiss") }
      XCTAssertGreaterThan(scroll.frame.height,0)
      scroll.swipeUp();scroll.swipeDown()
      XCTAssertTrue(field.exists)
      XCTAssertEqual(field.value as? String,"temperature 73")
      XCTAssertFalse(app.buttons["controls.night"].exists)
      drag(0.85,0.06,0.85,0.75)
      XCTAssertTrue(app.buttons["controls.night"].waitForExistence(timeout:5))
      XCTAssertFalse(field.exists)
      tap("nav.assistant")
      XCTAssertEqual(field.value as? String,"temperature 73")
      tap("assistant.keyboard.dismiss")
      tap("nav.faces");tap("home.thermostat")
      XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
    }
  }

  func testAssistantSystemControlCenterDoesNotSubmitDraft() {
    launch();tap("nav.assistant")
    let field=app.textFields["assistant.input"]
    field.tap();field.typeText("temperature 73")
    tap("assistant.keyboard.dismiss")
    let origin=app.coordinate(withNormalizedOffset:.zero),frame=app.frame
    origin.withOffset(CGVector(dx:frame.width*0.98,dy:1))
      .press(forDuration:0.1,thenDragTo:origin.withOffset(CGVector(dx:frame.width*0.8,dy:frame.height*0.65)),withVelocity:.slow,thenHoldForDuration:0.3)
    let system=XCUIApplication(bundleIdentifier:"com.apple.springboard")
    let screenshot=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
    screenshot.name="assistant-real-system-control-center";screenshot.lifetime = .keepAlways;add(screenshot)
    XCTAssertTrue(system.otherElements["cc-root-folder-view"].waitForExistence(timeout:5),
      "The actual OS Control Center must open; our in-app panel is not a substitute")
    XCTAssertTrue(system.buttons["Add Controls"].exists)
    XCTAssertTrue(system.buttons["Power"].exists)
    system.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.98))
      .press(forDuration:0.1,thenDragTo:system.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.3)),withVelocity:.slow,thenHoldForDuration:0.3)
    XCTAssertTrue(field.waitForExistence(timeout:5))
    XCTAssertEqual(field.value as? String,"temperature 73")
    XCTAssertEqual(app.staticTexts["assistant.reply"].label,"What can I help you with?")
    shot("assistant-system-control-center-return-unsent")
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
  }

  func testAssistantCommandPeriodDismissesWithoutSending() {
    launch();app.typeKey("s",modifierFlags:[.command,.shift])
    let field=app.textFields["assistant.input"]
    XCTAssertTrue(field.waitForExistence(timeout:5))
    field.typeText("temperature 73")
    app.typeKey(".",modifierFlags:[.command])
    expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:app.buttons["assistant.keyboard.dismiss"])
    waitForExpectations(timeout:5)
    XCTAssertEqual(field.value as? String,"temperature 73")
    XCTAssertEqual(app.staticTexts["assistant.reply"].label,"What can I help you with?")
    shot("assistant-command-period-unsent")
    app.typeKey("s",modifierFlags:[.command,.shift])
    XCTAssertTrue(app.buttons["assistant.keyboard.dismiss"].waitForExistence(timeout:5))
    XCTAssertEqual(field.value as? String,"temperature 73")
    tap("assistant.keyboard.dismiss");tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
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
    scrollPhotoControlFullyIntoView(button)
    button.tap()
    if name == "Apple Music",app.buttons["device.unlock"].waitForExistence(timeout:2) {
      tap("device.unlock")
      XCTAssertTrue(button.waitForExistence(timeout:8))
      scrollPhotoControlFullyIntoView(button)
      button.tap() // Authentication does not itself connect or share a source.
    }
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
  private func calendarSwitcherCard(from source:XCUIApplication,bounds:CGRect,checkpoint:String,
    preserveReturnOnPrivacyFailure:Bool=false)->XCUIElement {
    let origin=source.coordinate(withNormalizedOffset:.zero)
    let start=CGPoint(x:bounds.midX,y:bounds.maxY-1)
    let end=CGPoint(x:bounds.midX,y:bounds.minY+bounds.height*0.42)
    origin.withOffset(CGVector(dx:start.x,dy:start.y))
      .press(forDuration:0.1,thenDragTo:origin.withOffset(CGVector(dx:end.x,dy:end.y)),
        withVelocity:.slow,thenHoldForDuration:1)
    let system=XCUIApplication(bundleIdentifier:"com.apple.springboard")
    XCTAssertTrue(system.windows["SBSwitcherWindow:Main"].waitForExistence(timeout:5))
    XCTAssertTrue(system.otherElements["AppSwitcherContentView"].exists)
    let card=system.otherElements.matching(NSPredicate(format:
      "identifier BEGINSWITH %@","card:org.example.HomeViewReplica:")).firstMatch
    XCTAssertTrue(card.waitForExistence(timeout:5));XCTAssertEqual(card.label,"HomeView")
    for _ in 0..<4 {
      let f=card.frame
      if bounds.contains(f) {break}
      let visible=f.intersection(bounds),distance=max(-bounds.width*0.55,min(bounds.width*0.55,bounds.midX-f.midX))
      let a=system.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:visible.midX,dy:visible.midY))
      a.press(forDuration:0.1,thenDragTo:a.withOffset(CGVector(dx:distance,dy:0)),withVelocity:.slow,thenHoldForDuration:0.3)
    }
    let f=card.frame
    let tree=XCTAttachment(string:system.debugDescription)
    tree.name="switcher-"+checkpoint+"-native-system-tree";tree.lifetime = .keepAlways;add(tree)
    let screenshot=XCUIScreen.main.screenshot()
    let screen=XCTAttachment(screenshot:screenshot)
    screen.name="switcher-"+checkpoint+"-native-system-screen";screen.lifetime = .keepAlways;add(screen)
    XCTAssertTrue(bounds.contains(f),"Entire HomeView card must be visible, not a clipped sliver")
    let image=screenshot.image.cgImage!,scale=CGFloat(image.width)/bounds.width
    let pixelFrame=CGRect(x:f.minX*scale,y:f.minY*scale,width:f.width*scale,height:f.height*scale).integral
    let cropped=UIImage(cgImage:image.cropping(to:pixelFrame)!),png=cropped.pngData()!
    let crop=XCTAttachment(image:cropped)
    crop.name="switcher-"+checkpoint+"-whole-homeview-card";crop.lifetime = .keepAlways;add(crop)
    let bytes=[UInt8](viewportPixels(png,inset:0));var black=0
    for i in stride(from:0,to:bytes.count,by:4) {
      if max(bytes[i],max(bytes[i+1],bytes[i+2]))<20 {black+=1}
    }
    let fraction=Double(black)/Double(bytes.count/4)
    let data:[String:Any] = ["appState":app.state.rawValue,"systemState":system.state.rawValue,
      "cardIdentifier":card.identifier,"cardLabel":card.label,"wholeCardVisible":bounds.contains(f),
      "cardFrame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
      "pixelFrame":[Double(pixelFrame.minX),Double(pixelFrame.minY),Double(pixelFrame.width),Double(pixelFrame.height)],
      "screenFrame":[Double(bounds.minX),Double(bounds.minY),Double(bounds.width),Double(bounds.height)],
      "blackFraction":fraction,"blackThreshold":20,"minimumBlackFraction":0.98,
      "acceptance":"coarse full-card pixel guard plus required actual-image review; no OCR or hardware guarantee"]
    let receipt=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    receipt.name="switcher-"+checkpoint+"-snapshot-receipt";receipt.lifetime = .keepAlways;add(receipt)
    // Only the independent privacy guard may continue; navigation/card identity
    // failures above remain fatal, so a return cannot be assigned to another app.
    let previous=continueAfterFailure
    if preserveReturnOnPrivacyFailure {continueAfterFailure=true}
    XCTAssertGreaterThanOrEqual(fraction,0.98,"Full card should show the existing black shield, not the white/green calendar")
    continueAfterFailure=previous
    return card
  }
  func testCalendarNativeAppSwitcherSnapshotHidesPersonalContents() {
    continueAfterFailure=false
    launch(["--page","Settings","--persistence-test",UUID().uuidString])
    connectService("Calendar")
    drawer();tap("app.Calendar");tap("device.unlock")
    XCTAssertTrue(app.staticTexts["Device fixture meeting"].waitForExistence(timeout:5))
    shot("switcher-calendar-visible-before")
    let frame=app.frame
    calendarSwitcherCard(from:app,bounds:frame,checkpoint:"inactive").tap()
    // The real switcher can leave this scene inactive without backgrounding.
    // Returning from inactivity need not revoke the authenticated calendar.
    XCTAssertTrue(app.staticTexts["Device fixture meeting"].waitForExistence(timeout:5))
    shot("switcher-calendar-return-after-inactive")
    XCUIDevice.shared.press(.home)
    expectation(for:NSPredicate { _,_ in self.app.state == .runningBackground || self.app.state == .runningBackgroundSuspended },evaluatedWith:app)
    waitForExpectations(timeout:5)
    let system=XCUIApplication(bundleIdentifier:"com.apple.springboard")
    calendarSwitcherCard(from:system,bounds:frame,checkpoint:"background").tap()
    XCTAssertTrue(app.staticTexts["mock.badge"].waitForExistence(timeout:8))
    XCTAssertFalse(app.staticTexts["Device fixture meeting"].exists)
    tap("nav.faces");drawer();tap("app.Calendar")
    XCTAssertTrue(app.buttons["device.unlock"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["Device fixture meeting"].exists)
    shot("switcher-calendar-return-requires-fresh-unlock")
    tap("device.unlock")
    XCTAssertTrue(app.staticTexts["Device fixture meeting"].waitForExistence(timeout:5))
  }
  func testNativeAppSwitcherSnapshotCoversOpenWeatherCityDraft() {
    continueAfterFailure=false
    launchWeatherSurfaceFixture()
    touchWeatherControl("weather.cities")
    let field=app.textFields["weather.app.city.input"],canary="OWNED_PRIVATE_CITY_CANARY"
    XCTAssertTrue(field.waitForExistence(timeout:5));field.tap();field.typeText(canary)
    XCTAssertTrue((field.value as? String ?? "").hasSuffix(canary))
    shot("switcher-weather-dialog-draft-before")
    let frame=app.frame
    calendarSwitcherCard(from:app,bounds:frame,checkpoint:"weather-dialog-inactive").tap()
    XCTAssertTrue(field.waitForExistence(timeout:5))
    XCTAssertTrue((field.value as? String ?? "").hasSuffix(canary),"Inactive snapshot protection must not discard the open draft")
    tap("weather.city.done")
    XCTAssertEqual(app.staticTexts["weather.app.city"].label,"Berlin","No implicit provider update from snapshot protection")
    shot("switcher-weather-dialog-returned-without-update")
  }
  func testNativeAppSwitcherSnapshotCoversOpenProfileEditor() {
    continueAfterFailure=false
    launch(["--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("nav.apps");tap("personal.profile");tap("profile.Alex")
    app.buttons["personal.profile"].press(forDuration:1)
    tap("personal.edit")
    XCTAssertTrue(app.staticTexts["Home Screen · Alex"].waitForExistence(timeout:5))
    shot("switcher-profile-dialog-before")
    let frame=app.frame
    calendarSwitcherCard(from:app,bounds:frame,checkpoint:"profile-dialog-inactive").tap()
    XCTAssertTrue(app.staticTexts["Home Screen · Alex"].waitForExistence(timeout:5))
    tap("personal.editor.done")
    XCTAssertTrue(app.buttons["personal.profile"].waitForExistence(timeout:5))
    shot("switcher-profile-dialog-returned")
  }
  func testNativeAppSwitcherSnapshotCoversUnsentAssistantKeyboardDraft() {
    continueAfterFailure=false
    launch(["--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("nav.assistant")
    let field=app.textFields["assistant.input"],canary="OWNED_PRIVATE_ASSISTANT_CANARY"
    field.tap();field.typeText(canary)
    XCTAssertEqual(field.value as? String,canary)
    XCTAssertEqual(app.staticTexts["assistant.reply"].label,"What can I help you with?")
    shot("switcher-assistant-keyboard-draft-before")
    let frame=app.frame
    calendarSwitcherCard(from:app,bounds:frame,checkpoint:"assistant-keyboard-inactive").tap()
    XCTAssertTrue(field.waitForExistence(timeout:5));XCTAssertEqual(field.value as? String,canary)
    XCTAssertEqual(app.staticTexts["assistant.reply"].label,"What can I help you with?")
    shot("switcher-assistant-keyboard-draft-returned-unsent")
  }
  func testNativeAppSwitcherSnapshotCoversUnaddedReminderKeyboardDraft() {
    continueAfterFailure=false
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    connectService("Reminders");drawer();tap("app.Reminders");tap("device.unlock")
    XCTAssertTrue(app.buttons["device.reminder.Device fixture reminder"].waitForExistence(timeout:5))
    let field=app.textFields["device.reminder.input"],canary="OWNED_PRIVATE_REMINDER_CANARY"
    field.tap();field.typeText(canary)
    XCTAssertEqual(field.value as? String,canary)
    shot("switcher-reminder-keyboard-draft-before")
    let frame=app.frame
    calendarSwitcherCard(from:app,bounds:frame,checkpoint:"reminder-keyboard-inactive").tap()
    XCTAssertTrue(field.waitForExistence(timeout:5));XCTAssertEqual(field.value as? String,canary)
    XCTAssertFalse(app.buttons["device.reminder."+canary].exists,"Inactive protection must not create a reminder")
    shot("switcher-reminder-keyboard-draft-returned-unadded")
  }
  func testDemoArtworkInformationIsExplicitAndNeverAutoplays() {
    launch(["--page","Music"])
    let info=app.buttons["music.artwork.info.demo"]
    XCTAssertTrue(info.waitForExistence(timeout:5));XCTAssertTrue(info.isHittable)
    XCTAssertGreaterThanOrEqual(info.frame.width,44)
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    info.tap()
    XCTAssertEqual(app.staticTexts["music.artwork.source"].label,"Bundled demo player")
    XCTAssertTrue(app.staticTexts["music.lyrics.availability"].label.contains("No lyrics are included"))
    XCTAssertTrue(app.staticTexts["music.artwork.motion"].label.contains("No animated cover video"))
    shot("music-artwork-demo-information")
    tap("music.artwork.done")
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
  }
  func testConnectedArtworkInformationKeepsTheExplicitQueuePlaying() {
    launch(["--page","Settings"]);connectService("Apple Music")
    drawer();tap("app.Music")
    let search=app.textFields["music.search.input"];XCTAssertTrue(search.waitForExistence(timeout:5))
    search.tap();search.typeText("Synthetic song");tap("music.search")
    XCTAssertTrue(app.buttons["music.result.0"].waitForExistence(timeout:5));tap("music.result.0")
    let play=app.buttons["music.connected.play"];XCTAssertEqual(play.label,"Pause")
    let title=app.staticTexts["music.current.title"].label
    let info=app.buttons["music.artwork.info.catalog"];XCTAssertTrue(info.waitForExistence(timeout:5))
    XCTAssertTrue(info.isHittable);XCTAssertGreaterThanOrEqual(info.frame.width,44);info.tap()
    XCTAssertEqual(app.staticTexts["music.artwork.source"].label,"Apple Music connection")
    XCTAssertTrue(app.staticTexts["music.lyrics.availability"].label.contains("not supplied by this connection"))
    XCTAssertTrue(app.staticTexts["music.artwork.availability"].label.contains("static cover images"))
    shot("music-artwork-catalog-information")
    tap("music.artwork.done")
    XCTAssertEqual(play.label,"Pause");XCTAssertEqual(app.staticTexts["music.current.title"].label,title)
  }
  func testArtworkInformationWithReducedMotionNeverAddsAnimationOrLyrics() {
    launch(["--page","Music","--reduce-motion"])
    tap("music.artwork.info.demo")
    XCTAssertTrue(app.staticTexts["music.artwork.motion"].label.contains("including with Reduce Motion"))
    XCTAssertTrue(app.staticTexts["music.lyrics.availability"].label.contains("No sample text"))
    shot("music-artwork-reduced-motion-information")
    tap("music.artwork.done");XCTAssertEqual(app.buttons["player.play"].label,"Play")
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
    drawer();tap("app.Settings")
    let share=app.buttons["guest.music.share"];scrollPhotoControlFullyIntoView(share);share.tap()
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
    XCTAssertEqual(app.buttons["connect.Calendar"].label, "Connect Calendar")
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
  func testModularLargeDateAndTemperatureRenderForOneAndTwoDigitDays() {
    for day in [1,13,30] {
      launch(["--face","Modular","--reference-zone","UTC","--reference-date",
        String(format:"2026-04-%02dT10:09:30Z",day)])
      XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
      XCTAssertEqual(app.staticTexts["modular.weather.temperature"].firstMatch.label,"54°")
      let png=viewportBytes("modular-night-primary-day-\(day)")
      let image=UIImage(data:png)!.cgImage!
      let date=image.cropping(to:CGRect(x:Double(image.width)*0.06,y:Double(image.height)*0.18,
        width:Double(image.width)*0.42,height:Double(image.height)*0.30).integral)!
      var pixels=[UInt8](repeating:0,count:date.width*date.height*4)
      pixels.withUnsafeMutableBytes {
        let context=CGContext(data:$0.baseAddress,width:date.width,height:date.height,
          bitsPerComponent:8,bytesPerRow:date.width*4,space:CGColorSpaceCreateDeviceRGB(),
          bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
        context.draw(date,in:CGRect(x:0,y:0,width:date.width,height:date.height))
      }
      let ink=stride(from:0,to:pixels.count,by:4).filter {
        max(pixels[$0],max(pixels[$0+1],pixels[$0+2]))<70
      }.count
      XCTAssertGreaterThan(ink,1000,"The actual date must contain visible dark ink for day \(day)")
      print("MODULAR_LIGHT_EDGE day=\(day) actual_date_ink=\(ink)")
      app.terminate()
    }
  }
  func testModularNightWholeViewportContainsNoColorLeak() {
    launch(["--face","Modular"])
    tap("nav.controls");tap("controls.night");tap("nav.faces")
    let pixels=[UInt8](viewportPixels(viewportBytes("modular-night-primary-viewport"),inset:0))
    var lit=0,wrong=0
    for i in stride(from:0,to:pixels.count,by:4) where pixels[i]>25 {
      lit+=1
      if Double(pixels[i+1])>Double(pixels[i])*0.4 ||
        Double(pixels[i+2])>Double(pixels[i])*0.4 { wrong+=1 }
    }
    XCTAssertGreaterThan(lit,100)
    XCTAssertEqual(wrong,0,"The night treatment must include the entire native viewport")
  }
  func testModularWeatherReferenceFieldsRender() {
    launch(["--face","Modular"])
    XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
    let viewport=app.otherElements["reference.viewport"].frame
    var frames:[String:[String:Double]]=[:]
    for field in ["city","temperature","condition","highlow"] {
      let element=app.staticTexts["modular.weather."+field].firstMatch
      XCTAssertTrue(element.waitForExistence(timeout:5))
      let frame=element.frame
      XCTAssertFalse(frame.isEmpty)
      frames[field]=["x":Double((frame.minX-viewport.minX)/viewport.width),
        "y":Double((frame.minY-viewport.minY)/viewport.height),
        "width":Double(frame.width/viewport.width),"height":Double(frame.height/viewport.height)]
      let shot=XCTAttachment(screenshot:element.screenshot())
      shot.name="modular-reference-"+field;shot.lifetime = .keepAlways;add(shot)
      print("MODULAR_REFERENCE field=\(field) label=\(element.label)")
    }
    let widget=app.buttons["modular.weather.widget"].firstMatch.frame
    frames["widget"]=["x":Double((widget.minX-viewport.minX)/viewport.width),
      "y":Double((widget.minY-viewport.minY)/viewport.height),
      "width":Double(widget.width/viewport.width),"height":Double(widget.height/viewport.height)]
    let data=try! JSONSerialization.data(withJSONObject:frames,options:.sortedKeys)
    let geometry=XCTAttachment(data:data,uniformTypeIdentifier:"public.json")
    geometry.name="modular-weather-reference-frames";geometry.lifetime = .keepAlways;add(geometry)
    viewportBytes("modular-weather-reference")
    XCTAssertEqual(app.staticTexts["modular.weather.temperature"].firstMatch.label,"54°")
    XCTAssertTrue(app.staticTexts["modular.weather.condition"].firstMatch.label.contains("Demo"))
  }
  func testModularWeatherConnectedAndMissingValuesStayVisibleWithoutDemoFallback() {
    for missing in [false,true] {
      let state=missing ? "missing":"connected"
      launch(["--face","Modular","--page","Settings"]+(missing ? ["--weather-missing"]:[]))
      connectService("Weather");tap("nav.faces")
      XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
      let city=app.staticTexts["modular.weather.city"].firstMatch
      let temperature=app.staticTexts["modular.weather.temperature"].firstMatch
      let condition=app.staticTexts["modular.weather.condition"].firstMatch
      XCTAssertEqual(city.label,missing ? "Berlin":"Fixture City")
      XCTAssertEqual(temperature.label,missing ? "—":"55°")
      XCTAssertFalse(condition.label.contains("Demo"))
      let viewport=app.otherElements["reference.viewport"].frame
      for field in ["city","temperature","condition","highlow"] {
        let text=app.staticTexts["modular.weather."+field].firstMatch
        XCTAssertFalse(text.frame.isEmpty)
        XCTAssertGreaterThanOrEqual(text.frame.minX,viewport.minX)
        XCTAssertLessThanOrEqual(text.frame.maxX,viewport.maxX)
        XCTAssertGreaterThanOrEqual(text.frame.minY,viewport.minY)
        XCTAssertLessThanOrEqual(text.frame.maxY,viewport.maxY)
      }
      let shot=temperature.screenshot()
      let attachment=XCTAttachment(screenshot:shot)
      attachment.name="modular-weather-"+state+"-temperature"
      attachment.lifetime = .keepAlways;add(attachment)
      let pixels=[UInt8](viewportPixels(shot.pngRepresentation,inset:0))
      var dark=0
      for i in stride(from:0,to:pixels.count,by:4) {
        if (0..<3).allSatisfy({pixels[i+$0]<70}) { dark += 1 }
      }
      XCTAssertGreaterThan(dark,100,"The actual connected value or missing-value dash must visibly render")
      viewportBytes("modular-weather-"+state)
      print("MODULAR_REFERENCE_DATA state=\(state) city=\(city.label) temperature=\(temperature.label) condition=\(condition.label) dark=\(dark)")
      app.buttons["modular.weather.widget"].firstMatch.tap()
      XCTAssertTrue(app.staticTexts["weather.app.city"].waitForExistence(timeout:5))
      XCTAssertEqual(app.staticTexts["weather.app.city"].label,missing ? "Berlin":"Fixture City")
      XCTAssertTrue(app.staticTexts["Conditions"].exists)
      viewportBytes("modular-weather-"+state+"-opened-city")
      app.terminate()
    }
  }
  func testModularWeatherCityCaptionKeepsVisibleDataProvenance() {
    for connected in [false,true] {
      let state=connected ? "connected":"demo"
      launch(["--face","Modular"]+(connected ? ["--page","Settings"]:[]))
      if connected { connectService("Weather");tap("nav.faces") }
      XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
      let city=app.staticTexts["modular.weather.city"].firstMatch
      let condition=app.staticTexts["modular.weather.condition"].firstMatch
      XCTAssertTrue(city.waitForExistence(timeout:5))
      XCTAssertEqual(city.label,connected ? "Fixture City":"San Francisco")
      XCTAssertEqual(condition.label.contains("Demo"),!connected)
      let data=viewportBytes("modular-city-"+state)
      let viewport=app.otherElements["reference.viewport"].frame
      let row=app.otherElements["modular.weather.cityRow"].firstMatch.frame
      let geometry:[String:Double]=["x":Double((row.minX-viewport.minX)/viewport.width),
        "y":Double((row.minY-viewport.minY)/viewport.height),
        "width":Double(row.width/viewport.width),"height":Double(row.height/viewport.height)]
      let attachment=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:geometry,options:.sortedKeys),
        uniformTypeIdentifier:"public.json")
      attachment.name="modular-city-"+state+"-row";attachment.lifetime = .keepAlways;add(attachment)
      let native=XCTAttachment(screenshot:city.screenshot());native.name="modular-city-"+state+"-native-caption"
      native.lifetime = .keepAlways;add(native)
      XCTAssertFalse(data.isEmpty)
      print("MODULAR_CITY state=\(state) city=\(city.label) condition=\(condition.label)")
      app.terminate()
    }
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
  func testNativeAppSwitcherCoversRootWriteErrorAlertWithoutChangingReadOnlyState() {
    continueAfterFailure=false
    let id=UUID().uuidString
    print("ALERT_FIXTURE_ROOT_UUID="+id)
    launch(["--persistence-test",id,"--reset-test-store","--state-future-fixture","--screen-thermostat"])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
    let previous=app.staticTexts["thermostat.value"].label
    tap("thermostat.up")
    let alert=app.alerts.firstMatch
    XCTAssertTrue(alert.waitForExistence(timeout:5))
    let message=alert.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Original saved data is unchanged")).firstMatch
    XCTAssertTrue(message.exists);let originalMessage=message.label
    shot("switcher-root-write-alert-before")
    calendarSwitcherCard(from:app,bounds:app.frame,checkpoint:"root-write-alert",preserveReturnOnPrivacyFailure:true).tap()
    shot("switcher-root-write-alert-returned")
    XCTAssertTrue(alert.waitForExistence(timeout:5));XCTAssertEqual(message.label,originalMessage)
    alert.buttons["OK"].tap();XCTAssertEqual(app.staticTexts["thermostat.value"].label,previous)
    app.terminate();launch(["--persistence-test",id,"--screen-thermostat"])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,previous)
  }
  func testNativeAppSwitcherCoversEditorSlotWriteErrorAlertAndKeepsPicker() {
    continueAfterFailure=false
    let id=UUID().uuidString
    print("ALERT_FIXTURE_EDITOR_UUID="+id)
    launch(["--persistence-test",id,"--reset-test-store","--state-future-fixture","--face","Modular"])
    app.otherElements["face.Modular"].press(forDuration:1)
    XCTAssertTrue(app.buttons["editor.done"].waitForExistence(timeout:5))
    let previous=app.buttons["widget.0"].label
    tap("widget.0");tap("complication.choose.Clock")
    let alert=app.alerts.firstMatch
    XCTAssertTrue(alert.waitForExistence(timeout:5))
    let message=alert.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Original saved data is unchanged")).firstMatch
    XCTAssertTrue(message.exists);let originalMessage=message.label
    shot("switcher-editor-slot-alert-before")
    calendarSwitcherCard(from:app,bounds:app.frame,checkpoint:"editor-slot-alert",preserveReturnOnPrivacyFailure:true).tap()
    shot("switcher-editor-slot-alert-returned")
    XCTAssertTrue(alert.waitForExistence(timeout:5));XCTAssertEqual(message.label,originalMessage)
    alert.buttons["OK"].tap()
    XCTAssertTrue(app.buttons["complications.done"].waitForExistence(timeout:5));tap("complications.done")
    XCTAssertEqual(app.buttons["widget.0"].label,previous);tap("editor.done")
    app.terminate();launch(["--persistence-test",id])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
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
    var timing:[String:Double]=[:]
    defer {
      let report=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:timing,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
      report.name="timer-idle-monotonic-touch-windows";report.lifetime = .keepAlways;add(report)
    }
    let firstSent=ProcessInfo.processInfo.systemUptime
    timing["first_sent"]=firstSent
    timeTouch.tap()
    let firstReturned=ProcessInfo.processInfo.systemUptime
    timing["first_returned"]=firstReturned
    XCTAssertTrue(pause.waitForExistence(timeout:3))
    XCTAssertEqual(pause.label,"Resume timer")
    // AX polling also consumes the real four-second visibility window.
    // Anchor the second touch to dispatch time, not to polling completion.
    Thread.sleep(forTimeInterval:max(0,firstSent+2.8-ProcessInfo.processInfo.systemUptime))
    XCTAssertLessThan(ProcessInfo.processInfo.systemUptime-firstSent,3.8,"Test input exceeded its first reveal window")
    XCTAssertTrue(pause.exists)
    let secondSent=ProcessInfo.processInfo.systemUptime
    timing["second_sent"]=secondSent
    XCTAssertLessThan(secondSent-firstSent,3.8,"AX query consumed the second-touch budget")
    timeTouch.tap()
    let secondReturned=ProcessInfo.processInfo.systemUptime
    timing["second_returned"]=secondReturned
    let checkAt=max(secondReturned+2.3,firstReturned+5.2)
    XCTAssertLessThan(checkAt-secondSent,3.8,"Test input left no valid reset observation window")
    Thread.sleep(forTimeInterval:max(0,checkAt-ProcessInfo.processInfo.systemUptime))
    let checked=ProcessInfo.processInfo.systemUptime
    timing["checked"]=checked
    XCTAssertGreaterThan(checked-firstReturned,5)
    XCTAssertLessThan(checked-secondSent,3.8)
    // More than five seconds after the first reveal, but fewer than four since
    // the second real touch: a mere one-shot show timer would already have hidden.
    XCTAssertTrue(pause.exists)
    XCTAssertEqual(countdown.label,"10:56")
    shot("timer-idle-touch-reset-visible")
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

extension HomeViewUITests {
  private func startOwnedLifecycleBread(storeID:String) -> Int {
    launch(["--persistence-test",storeID,"--multiple-timers-fixture"])
    verifyTimerChoice(103,title:"BREAD",value:"10:00")
    XCTAssertEqual(timerChoicesContainer.value as? String,"3 timers")
    XCTAssertEqual(app.staticTexts["timer.systemStatus"].label,"Foreground timer")
    tap("timer.pause")
    XCTAssertEqual(app.buttons["timer.pause"].label,"Pause timer")
    expectation(for:NSPredicate(format:"label != %@","10:00"),evaluatedWith:app.staticTexts["timer.countdown"])
    waitForExpectations(timeout:6)
    return timerSelectionSeconds()
  }
  private func waitForLifecycleRemaining(atMost seconds:Int) {
    XCTAssertTrue(seconds>0 && seconds<3600)
    // These fixtures stay below one hour; fixed-width MM:SS sorts numerically.
    let limit=String(format:"%02d:%02d",seconds/60,seconds%60)
    expectation(for:NSPredicate(format:"label <= %@",limit),evaluatedWith:app.staticTexts["timer.countdown"])
    waitForExpectations(timeout:6)
    XCTAssertLessThanOrEqual(timerSelectionSeconds(),seconds)
  }
  private func recordLifecycleElapsed(_ name:String,before:Int,uptime:Double) {
    let after=timerSelectionSeconds(),elapsed=ProcessInfo.processInfo.systemUptime-uptime
    XCTAssertGreaterThan(after,0)
    XCTAssertGreaterThanOrEqual(before-after,4)
    // The app samples Date on a one-second pulse and rounds displayed seconds
    // upward; this is a coarse local elapsed-time check, not Original timing.
    XCTAssertLessThanOrEqual(abs(Double(before-after)-elapsed),3)
    let report:[String:Any] = ["before_seconds":before,"after_seconds":after,
      "observed_monotonic_elapsed_seconds":elapsed,"display_drop_seconds":before-after,
      "allowed_pulse_rounding_observation_seconds":3,"system_alarm_requested":false]
    let data=try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys])
    let attachment=XCTAttachment(data:data,uniformTypeIdentifier:"public.json")
    attachment.name="timer-lifecycle-"+name+"-metrics";attachment.lifetime = .keepAlways;add(attachment)
  }
  private func verifyLifecyclePausedPeersAndStopBread() {
    timerChoice(101).tap();verifyTimerChoice(101,title:"TEA",value:"03:00")
    XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
    timerChoice(102).tap();verifyTimerChoice(102,title:"PASTA",value:"08:00")
    XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
    timerChoice(103).tap();verifyTimerChoice(103,title:"BREAD")
    XCTAssertEqual(app.buttons["timer.pause"].label,"Pause timer")
    tap("timer.pause")
    XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
  }
  @objc func testLocalTimersKeepElapsedTimeAndPausedPeersAcrossBackground() {
    let id=UUID().uuidString
    _=startOwnedLifecycleBread(storeID:id)
    viewportShot("timer-lifecycle-before-background")
    let before=timerSelectionSeconds(),uptime=ProcessInfo.processInfo.systemUptime
    XCUIDevice.shared.press(.home)
    Thread.sleep(forTimeInterval:4)
    app.activate()
    XCTAssertTrue(app.staticTexts["timer.countdown"].waitForExistence(timeout:6))
    waitForLifecycleRemaining(atMost:before-4)
    XCTAssertEqual(timerChoicesContainer.value as? String,"3 timers")
    verifyTimerChoice(103,title:"BREAD")
    recordLifecycleElapsed("background",before:before,uptime:uptime)
    viewportShot("timer-lifecycle-after-background")
    verifyLifecyclePausedPeersAndStopBread()
    viewportShot("timer-lifecycle-background-peers-preserved")
  }
  @objc func testLocalTimersReloadOwnStoredDeadlinesAfterProcessRestart() {
    let id=UUID().uuidString
    _=startOwnedLifecycleBread(storeID:id)
    viewportShot("timer-lifecycle-before-process-restart")
    let before=timerSelectionSeconds(),uptime=ProcessInfo.processInfo.systemUptime
    app.terminate()
    Thread.sleep(forTimeInterval:3)
    // No fixture and no reset flag: the new process must read this UUID store.
    launch(["--persistence-test",id,"--page","Timers"])
    XCTAssertEqual(timerChoicesContainer.value as? String,"3 timers")
    waitForLifecycleRemaining(atMost:before-4)
    verifyTimerChoice(103,title:"BREAD")
    XCTAssertEqual(app.staticTexts["timer.systemStatus"].label,"Foreground timer")
    recordLifecycleElapsed("process-restart",before:before,uptime:uptime)
    viewportShot("timer-lifecycle-after-process-restart")
    verifyLifecyclePausedPeersAndStopBread()
    viewportShot("timer-lifecycle-restart-peers-preserved")
  }
}


extension HomeViewUITests {
  @objc func testWeatherDayShadowPreservesNightAndClearFacePixels() {
    for (flag,name) in [("--weather-stale-night","night"),("--weather-clear","clear")] {
      launch(["--face","Weather","--page","Settings",flag])
      connectService("Weather");tap("nav.faces")
      XCTAssertTrue(app.otherElements["face.Weather"].waitForExistence(timeout:5))
      XCTAssertFalse(app.staticTexts["weather.source"].label.hasPrefix("Demo"))
      if name == "night" { XCTAssertTrue(app.staticTexts["weather.source"].label.hasPrefix("Stale reading")) }
      viewportShot("weather-shadow-preserved-"+name+"-face")
    }
  }
}

extension HomeViewUITests {
  private func controlPercent(_ name: String) -> String {
    (app.sliders[name].value as? String ?? "").filter { !$0.isWhitespace }
  }
  @objc func testLocalControlsPersistWithNativeKeepAwakeReadback() {
    let id = UUID().uuidString
    launch(["--page", "Settings", "--persistence-test", id, "--reset-test-store"])
    let wake = app.buttons["settings.keepawake"]
    XCTAssertEqual(wake.value as? String, "Off")
    wake.tap()
    expectation(for: NSPredicate(format: "value == %@", "On"), evaluatedWith: wake)
    waitForExpectations(timeout: 5)
    tap("nav.controls")
    XCTAssertTrue(app.staticTexts["controls.scope"].exists)
    XCTAssertEqual(app.buttons["controls.online"].value as? String, "On")
    tap("controls.online"); tap("controls.night"); tap("controls.distance")
    XCTAssertFalse(app.staticTexts["Mock home offline"].exists,
      "The control itself shows offline; a second banner must not cover the header")
    XCTAssertEqual(app.staticTexts["mock.badge"].label, "MOCK OFFLINE")
    app.buttons["Decrease Display dimming"].tap()
    app.buttons["Decrease Demo audio"].tap()
    XCTAssertEqual(controlPercent("Display dimming"), "90%")
    XCTAssertEqual(controlPercent("Demo audio"), "45%")
    viewportShot("controls-persisted-values")
    app.terminate()
    launch(["--page", "Settings", "--persistence-test", id])
    expectation(for: NSPredicate(format: "value == %@", "On"), evaluatedWith: app.buttons["settings.keepawake"])
    waitForExpectations(timeout: 5)
    XCUIDevice.shared.press(.home); app.activate()
    expectation(for: NSPredicate(format: "value == %@", "On"), evaluatedWith: app.buttons["settings.keepawake"])
    waitForExpectations(timeout: 5)
    tap("nav.controls")
    XCTAssertEqual(app.buttons["controls.online"].value as? String, "Off")
    XCTAssertEqual(app.buttons["controls.night"].value as? String, "On")
    XCTAssertEqual(app.buttons["controls.distance"].value as? String, "On")
    XCTAssertEqual(controlPercent("Display dimming"), "90%")
    XCTAssertEqual(controlPercent("Demo audio"), "45%")
    tap("controls.online"); tap("controls.night"); tap("controls.distance")
    tap("controls.settings")
    app.buttons["settings.keepawake"].tap()
    expectation(for: NSPredicate(format: "value == %@", "Off"), evaluatedWith: app.buttons["settings.keepawake"])
    waitForExpectations(timeout: 5)
    viewportShot("controls-keepawake-released")
  }
  @objc func testReadOnlyControlChangesRollBackBeforeNativeEffects() {
    let id = UUID().uuidString
    launch(["--page", "Settings", "--persistence-test", id, "--reset-test-store", "--state-future-fixture"])
    XCTAssertEqual(app.buttons["settings.keepawake"].value as? String, "Off")
    app.buttons["settings.keepawake"].tap()
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
    app.alerts.buttons["OK"].tap()
    XCTAssertEqual(app.buttons["settings.keepawake"].value as? String, "Off")
    tap("nav.controls")
    for identifier in ["controls.online", "controls.night", "controls.distance"] {
      let previous = app.buttons[identifier].value as? String
      tap(identifier)
      XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
      app.alerts.buttons["OK"].tap()
      XCTAssertEqual(app.buttons[identifier].value as? String, previous)
    }
    for (name,expected) in [("Display dimming", "100%"), ("Demo audio", "55%")] {
      app.buttons["Decrease " + name].tap()
      XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
      app.alerts.buttons["OK"].tap()
      XCTAssertEqual(controlPercent(name), expected)
    }
    viewportShot("controls-readonly-rollback")
    app.terminate()
    launch(["--page", "Settings", "--persistence-test", id])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
    XCTAssertEqual(app.buttons["settings.keepawake"].value as? String, "Off")
  }
}

extension HomeViewUITests {
  private func podcastSeconds() -> Int {
    let label=app.staticTexts["podcast.position"].label
    let parts=label.components(separatedBy:" / ").first!.split(separator:":")
    return parts.count==2 ? (Int(parts[0]) ?? -1000)*60+(Int(parts[1]) ?? -1000):-1000
  }
  @objc func testPublicPodcastRSSNativeSeekPauseNavigationAndRelaunch() {
    let id=UUID().uuidString
    let base=["--page","Podcasts","--podcast-fixture","--persistence-test",id]
    launch(base+["--reset-test-store"])
    XCTAssertEqual(app.buttons["podcast.play"].label,"Play Demo Episode")
    tap("podcast.feeds");tap("podcast.feed.fixture")
    let episode=app.buttons["podcast.episode.0"]
    XCTAssertTrue(episode.waitForExistence(timeout:8));scrollPhotoControlFullyIntoView(episode);episode.tap()
    XCTAssertEqual(app.staticTexts["podcast.title"].label,"Own Audio Episode One")
    XCTAssertTrue(app.staticTexts["podcast.status"].label.contains("Paused"))
    tap("podcast.play")
    expectation(for:NSPredicate(format:"label == %@","Playing"),evaluatedWith:app.staticTexts["podcast.status"])
    waitForExpectations(timeout:12)
    tap("podcast.play")
    XCTAssertEqual(app.staticTexts["podcast.status"].label,"Paused")
    tap("podcast.forward")
    XCTAssertGreaterThanOrEqual(podcastSeconds(),15)
    XCTAssertLessThan(podcastSeconds(),22)
    let position=podcastSeconds()
    viewportShot("rss-podcast-paused-native-seek")
    app.terminate();launch(base)
    XCTAssertEqual(app.staticTexts["podcast.title"].label,"Own Audio Episode One")
    XCTAssertEqual(podcastSeconds(),position,accuracy:1)
    XCTAssertTrue(app.staticTexts["podcast.status"].label.contains("Paused"))
    tap("podcast.play")
    expectation(for:NSPredicate(format:"label == %@","Playing"),evaluatedWith:app.staticTexts["podcast.status"])
    waitForExpectations(timeout:12)
    tap("nav.faces")
    viewportShot("rss-podcast-face-before-return")
    XCTAssertTrue(app.buttons["activity.podcast"].waitForExistence(timeout:5))
    tap("activity.podcast")
    XCTAssertEqual(app.staticTexts["podcast.title"].label,"Own Audio Episode One")
    tap("podcast.play")
    XCTAssertEqual(app.staticTexts["podcast.status"].label,"Paused")
    let beforeBackwardSeek=podcastSeconds()
    tap("podcast.back")
    XCTAssertEqual(podcastSeconds(),max(0,beforeBackwardSeek-15),accuracy:1)
    viewportShot("rss-podcast-resumed-navigation")
  }
  @objc func testPublicPodcastFeedErrorsRemovalAndBackgroundNeverAutoplayDemo() {
    launch(["--page","Podcasts","--podcast-fixture"])
    tap("podcast.feeds")
    let address=app.textFields["podcast.feed.url"]
    address.tap();address.typeText("http://not-secure.example/rss\n")
    tap("podcast.feed.load")
    XCTAssertTrue(app.staticTexts["podcast.feed.status"].label.contains("HTTPS"))
    tap("podcast.feed.fixture")
    let episode=app.buttons["podcast.episode.0"]
    XCTAssertTrue(episode.waitForExistence(timeout:8));scrollPhotoControlFullyIntoView(episode);episode.tap()
    tap("podcast.play")
    expectation(for:NSPredicate(format:"label == %@","Playing"),evaluatedWith:app.staticTexts["podcast.status"])
    waitForExpectations(timeout:12)
    XCUIDevice.shared.press(.home);app.activate()
    XCTAssertEqual(app.buttons["podcast.play"].label,"Play")
    XCTAssertEqual(app.staticTexts["podcast.status"].label,"Paused")
    viewportShot("rss-podcast-background-paused")
    tap("podcast.feeds")
    let remove=app.buttons["podcast.feed.remove"]
    scrollPhotoControlFullyIntoView(remove);remove.tap()
    XCTAssertFalse(app.buttons["podcast.episode.0"].exists)
    XCTAssertTrue(app.staticTexts["podcast.feed.status"].label.contains("removed"))
    tap("podcast.feeds")
    XCTAssertEqual(app.buttons["podcast.play"].label,"Play Demo Episode")
    XCTAssertFalse(app.buttons["Pause podcast"].exists)
    viewportShot("rss-podcast-removed-explicit-demo")
  }
}

extension HomeViewUITests {
  @objc func testPodcastFailedHTTPSLoadKeepsSelectionAndMusicTakesAudioFocus() {
    launch(["--page","Podcasts","--podcast-fixture"])
    tap("podcast.feeds");tap("podcast.feed.fixture")
    let episode=app.buttons["podcast.episode.0"]
    XCTAssertTrue(episode.waitForExistence(timeout:8));scrollPhotoControlFullyIntoView(episode);episode.tap()
    tap("podcast.play")
    expectation(for:NSPredicate(format:"label == %@","Playing"),evaluatedWith:app.staticTexts["podcast.status"])
    waitForExpectations(timeout:12)
    tap("podcast.feeds")
    let address=app.textFields["podcast.feed.url"]
    address.tap();address.typeText("https://fixtures.invalid/unavailable.xml\n")
    tap("podcast.feed.load")
    XCTAssertTrue(app.staticTexts["podcast.feed.status"].label.contains("could not be loaded"))
    XCTAssertTrue(app.buttons["podcast.episode.0"].exists)
    tap("podcast.feeds")
    XCTAssertEqual(app.staticTexts["podcast.title"].label,"Own Audio Episode One")
    XCTAssertFalse(app.buttons["Play Demo Episode"].exists)
    viewportShot("rss-failed-load-keeps-real-selection")
    XCTAssertEqual(app.staticTexts["podcast.status"].label,"Playing")
    drawer();tap("app.Music");tap("player.play")
    tap("nav.faces")
    XCTAssertFalse(app.buttons["activity.podcast"].exists)
    drawer()
    let podcasts=app.buttons["app.Podcasts"]
    for _ in 0..<10 where !podcasts.isHittable { app.scrollViews.firstMatch.swipeUp() }
    podcasts.tap()
    XCTAssertEqual(app.buttons["podcast.play"].label,"Play")
    XCTAssertEqual(app.staticTexts["podcast.status"].label,"Paused")
    viewportShot("rss-music-focus-pauses-podcast")
  }
}


extension HomeViewUITests {
  @objc func testConnectedMusicResumeTakesFocusFromNativePodcast() {
    launch(["--page","Settings","--podcast-fixture"])
    connectService("Apple Music")
    drawer();tap("app.Music")
    let query=app.textFields["music.search.input"]
    query.tap();query.typeText("sample");tap("music.search");tap("music.result.0")
    XCTAssertEqual(app.buttons["music.connected.play"].label,"Pause")
    drawer()
    let podcasts=app.buttons["app.Podcasts"]
    for _ in 0..<10 where !podcasts.isHittable { app.scrollViews.firstMatch.swipeUp() }
    podcasts.tap()
    tap("podcast.feeds");tap("podcast.feed.fixture")
    let episode=app.buttons["podcast.episode.0"]
    XCTAssertTrue(episode.waitForExistence(timeout:8));scrollPhotoControlFullyIntoView(episode);episode.tap()
    tap("podcast.play")
    expectation(for:NSPredicate(format:"label == %@","Playing"),evaluatedWith:app.staticTexts["podcast.status"])
    waitForExpectations(timeout:12)
    drawer();tap("app.Music")
    XCTAssertEqual(app.buttons["music.connected.play"].label,"Play")
    tap("music.connected.play")
    XCTAssertEqual(app.buttons["music.connected.play"].label,"Pause")
    drawer()
    let podcastReturn=app.buttons["app.Podcasts"]
    for _ in 0..<10 where !podcastReturn.isHittable { app.scrollViews.firstMatch.swipeUp() }
    podcastReturn.tap()
    XCTAssertEqual(app.staticTexts["podcast.status"].label,"Paused")
    XCTAssertEqual(app.buttons["podcast.play"].label,"Play")
    viewportShot("rss-connected-music-resume-focus")
  }
}


extension HomeViewUITests {
  func testAssistantCapabilitiesExplainLocalScopeAndLeaveDraftUnsent() {
    launch()
    tap("nav.assistant")
    let request=app.textFields["assistant.input"]
    request.tap();request.typeText("Timer auf 90 Sekunden")
    tap("assistant.capabilities")
    let activation=app.staticTexts["assistant.capabilities.activation"]
    XCTAssertTrue(activation.waitForExistence(timeout:5))
    for _ in 0..<6 where !activation.isHittable { app.scrollViews.firstMatch.swipeUp() }
    shot("assistant-activation-no-wakeword-or-auto-recording")
    let service=app.staticTexts["assistant.capabilities.service"]
    XCTAssertTrue(service.waitForExistence(timeout:5))
    XCTAssertTrue(service.label.contains("No Siri AI or cloud AI provider"))
    XCTAssertTrue(app.staticTexts["assistant.capabilities.languages"].label.contains("Replies are currently English"))
    let limits=app.staticTexts["assistant.capabilities.limits"]
    for _ in 0..<6 where !limits.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(limits.label.contains("30 seconds"));XCTAssertTrue(limits.label.contains("1000 characters"))
    shot("assistant-capability-limits")
    let subscriptions=app.staticTexts["assistant.capabilities.subscriptions"]
    for _ in 0..<6 where !subscriptions.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(subscriptions.label.contains("No cloud AI quota or subscription"))
    XCTAssertTrue(subscriptions.label.contains("Apple Home is not connected"))
    tap("assistant.capabilities.done")
    XCTAssertEqual(request.value as? String,"Timer auf 90 Sekunden")
    XCTAssertEqual(app.staticTexts["assistant.reply"].label,"What can I help you with?")
    XCTAssertFalse(app.buttons["assistant.voice.cancel"].exists)
    XCTAssertEqual(app.staticTexts["assistant.voice.status"].label,"Tap to speak · On-device only")
    viewportShot("assistant-capability-return-unsent-draft",assistantRectangle:true)
  }
}


extension HomeViewUITests {
  func testRecipeHandoffResumesExactStepOnlyAfterExplicitUnlockAndNeverStartsTimer() {
    launch(["--recipe-handoff-fixture","valid"])
    XCTAssertTrue(app.buttons["recipe.handoff.accept"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["cooking.text"].exists)
    viewportShot("recipe-handoff-awaits-explicit-accept")
    tap("recipe.handoff.accept")
    let text=app.staticTexts["cooking.text"]
    XCTAssertTrue(text.waitForExistence(timeout:5));XCTAssertTrue(text.label.hasPrefix("Blend until smooth"))
    XCTAssertTrue(app.staticTexts["Step 3"].exists)
    viewportShot("recipe-handoff-resumed-local-step-three")
    XCTAssertEqual(app.buttons["cooking.next"].label,"Finish")
    tap("cooking.next")
    XCTAssertTrue(app.buttons["recipe.start"].waitForExistence(timeout:5))
    tap("nav.faces")
    XCTAssertFalse(app.descendants(matching:.any)["compact.activity"].exists)
    drawer();tap("app.Timers")
    XCTAssertFalse(app.staticTexts["timer.countdown"].exists)
    XCTAssertTrue(app.buttons["timer.start"].exists)
  }
  func testRecipeHandoffRejectsMissingRecipeAndUnsupportedVersion() {
    launch(["--recipe-handoff-fixture","version"])
    XCTAssertTrue(app.staticTexts["recipe.handoff.status"].label.contains("version is not supported"))
    XCTAssertFalse(app.buttons["recipe.handoff.accept"].exists)
    XCTAssertFalse(app.staticTexts["cooking.text"].exists)
    viewportShot("recipe-handoff-unsupported-version")
    launch(["--recipe-handoff-fixture","missing"])
    tap("recipe.handoff.accept")
    XCTAssertTrue(app.staticTexts["recipe.handoff.status"].label.contains("not available on this device"))
    XCTAssertFalse(app.staticTexts["cooking.text"].exists)
    viewportShot("recipe-handoff-missing-local-recipe")
  }
  func testRecipeHandoffDeniedUnlockAndReadOnlyStoreCannotContinue() {
    launch(["--recipe-handoff-fixture","valid","--device-unlock-denied"])
    tap("recipe.handoff.accept")
    XCTAssertTrue(app.staticTexts["recipe.handoff.status"].label.contains("unlock was not granted"))
    XCTAssertFalse(app.staticTexts["cooking.text"].exists)
    viewportShot("recipe-handoff-unlock-denied")
    let id=UUID().uuidString
    launch(["--recipe-handoff-fixture","valid","--persistence-test",id,"--reset-test-store","--state-future-fixture"])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
    tap("recipe.handoff.accept")
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout:5));app.alerts.buttons["OK"].tap()
    XCTAssertTrue(app.staticTexts["recipe.handoff.status"].label.contains("could not be saved"))
    XCTAssertFalse(app.staticTexts["cooking.text"].exists)
    viewportShot("recipe-handoff-readonly-not-resumed")
    app.terminate();launch(["--persistence-test",id])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
  }
  func testRecipeHandoffUnavailableOfferKeepsCookingState() {
    launch(["--screen-recipe"])
    tap("recipe.start");tap("cooking.next")
    XCTAssertTrue(app.staticTexts["cooking.text"].label.hasPrefix("Add the squash"))
    tap("cooking.handoff");tap("recipe.handoff.offer")
    XCTAssertTrue(app.staticTexts["recipe.handoff.status"].label.contains("unavailable here"))
    XCTAssertTrue(app.staticTexts["recipe.handoff.status"].label.contains("No recipe was sent"))
    XCTAssertFalse(app.buttons["recipe.handoff.stop"].exists)
    viewportShot("recipe-handoff-clearly-unavailable-no-send")
    tap("recipe.handoff.done")
    XCTAssertTrue(app.staticTexts["cooking.text"].label.hasPrefix("Add the squash"))
    XCTAssertTrue(app.staticTexts["Step 2"].exists)
  }
}


extension HomeViewUITests {
  func testRecipeHandoffBackgroundDropsPendingTransferAndDoesNotResumeIt() {
    launch(["--recipe-handoff-fixture","valid"])
    XCTAssertTrue(app.buttons["recipe.handoff.accept"].waitForExistence(timeout:5))
    XCUIDevice.shared.press(.home);app.activate()
    XCTAssertFalse(app.buttons["recipe.handoff.accept"].exists)
    XCTAssertFalse(app.staticTexts["cooking.text"].exists)
    XCTAssertTrue(app.staticTexts["recipe.handoff.status"].label.contains("No recipe is being offered"))
    viewportShot("recipe-handoff-background-pending-cleared")
  }
}

extension HomeViewUITests {
  private func chooseSyntheticOnDeviceAnswers() {
    tap("nav.assistant");tap("assistant.capabilities")
    tap("assistant.provider.ondevice");tap("assistant.capabilities.done")
    XCTAssertTrue(app.staticTexts["assistant.ai.status"].waitForExistence(timeout:5))
  }
  private func askSyntheticQuestion(_ prompt:String) {
    let field=app.textFields["assistant.input"];field.tap();field.typeText(prompt);tap("assistant.send")
  }
  func testOnDeviceAnswersNeedExplicitChoiceKeepDialogueAndNeverExecuteCommands() {
    launch(["--assistant-ai-fixture","ready"])
    tap("nav.assistant");XCTAssertFalse(app.staticTexts["assistant.ai.status"].exists)
    tap("assistant.capabilities")
    XCTAssertTrue(app.staticTexts["assistant.provider.availability"].label.contains("Not selected"))
    shot("ondevice-explicit-provider-choice")
    tap("assistant.provider.ondevice");tap("assistant.capabilities.done")
    askSyntheticQuestion("Set a timer for 5 minutes")
    let first=app.staticTexts["assistant.ai.answer.0"]
    XCTAssertTrue(first.waitForExistence(timeout:5));XCTAssertTrue(first.label.contains("Synthetic answer"))
    askSyntheticQuestion("What was the fictional recipe called?")
    XCTAssertTrue(app.staticTexts["assistant.ai.answer.1"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["assistant.ai.answer.1"].label.contains("Moon Soup"))
    viewportShot("ondevice-synthetic-followup-answer-only",assistantRectangle:true)
    tap("nav.faces");drawer();tap("app.Timers")
    XCTAssertFalse(app.staticTexts["timer.countdown"].exists);XCTAssertTrue(app.buttons["timer.start"].exists)
    tap("nav.assistant");XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
  }
  func testOnDeviceUnavailableAndFailureAreExplicitWithoutCloudFallback() {
    launch(["--assistant-ai-fixture","unavailable"]);chooseSyntheticOnDeviceAnswers()
    askSyntheticQuestion("hello")
    XCTAssertTrue(app.staticTexts["assistant.ai.status"].label.contains("unavailable"))
    XCTAssertTrue(app.staticTexts["assistant.ai.status"].label.contains("No cloud fallback"))
    XCTAssertEqual(app.textFields["assistant.input"].value as? String,"hello")
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
    viewportShot("ondevice-unavailable-draft-retained",assistantRectangle:true)
    launch(["--assistant-ai-fixture","error"]);chooseSyntheticOnDeviceAnswers()
    askSyntheticQuestion("Synthetic question")
    let status=app.staticTexts["assistant.ai.status"]
    XCTAssertTrue(status.waitForExistence(timeout:5))
    XCTAssertTrue(status.label.contains("could not answer"));XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
    viewportShot("ondevice-failure-context-cleared",assistantRectangle:true)
  }
  func testOnDeviceStopAndBackgroundDiscardPendingConversation() {
    launch(["--assistant-ai-fixture","slow"]);chooseSyntheticOnDeviceAnswers()
    askSyntheticQuestion("Synthetic slow question")
    XCTAssertEqual(app.buttons["assistant.ai.reset"].label,"Stop")
    XCTAssertFalse(app.buttons["assistant.send"].isEnabled)
    tap("assistant.ai.reset")
    XCTAssertTrue(app.staticTexts["assistant.ai.status"].label.contains("Stopped"))
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
    viewportShot("ondevice-stopped-no-late-answer",assistantRectangle:true)
    askSyntheticQuestion("Another synthetic slow question")
    XCUIDevice.shared.press(.home);app.activate()
    XCTAssertTrue(app.buttons["nav.assistant"].waitForExistence(timeout:5));tap("nav.assistant")
    XCTAssertTrue(app.staticTexts["assistant.reply"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
    viewportShot("ondevice-background-provider-reset",assistantRectangle:true)
  }
}

extension HomeViewUITests {
  private func unlockSyntheticReadout() {
    XCTAssertEqual(app.buttons["answer.speech.read"].label,"Unlock readout")
    tap("answer.speech.read")
    expectation(for:NSPredicate(format:"label == %@","Read"),evaluatedWith:app.buttons["answer.speech.read"])
    waitForExpectations(timeout:5)
    XCTAssertTrue(app.staticTexts["answer.speech.status"].label.contains("nothing has been played"))
  }
  private func startSyntheticReadout() {
    tap("answer.speech.read")
    expectation(for:NSPredicate(format:"label == %@","Stop"),evaluatedWith:app.buttons["answer.speech.read"])
    waitForExpectations(timeout:5)
    XCTAssertTrue(app.staticTexts["answer.speech.status"].label.contains("Reading"))
  }
  func testAnswerReadoutChoiceRateExplicitUnlockAndStop() {
    launch(["--answer-speech-fixture"]);tap("nav.assistant");tap("answer.speech.settings")
    let voice=app.buttons["answer.speech.voice"]
    XCTAssertTrue(voice.waitForExistence(timeout:5));voice.tap();tap("Synthetic English Two")
    let language=app.buttons["answer.speech.language"];language.tap();tap("de-DE")
    XCTAssertTrue(app.buttons["answer.speech.voice"].label.contains("Synthetic Deutsch"))
    let before=app.staticTexts["answer.speech.rate.label"].label
    app.sliders["answer.speech.rate"].adjust(toNormalizedSliderPosition:0.8)
    XCTAssertNotEqual(app.staticTexts["answer.speech.rate.label"].label,before)
    shot("answer-readout-system-voice-rate-choice")
    tap("answer.speech.settings.done")
    unlockSyntheticReadout();viewportShot("answer-readout-unlock-does-not-speak",assistantRectangle:true)
    startSyntheticReadout();viewportShot("answer-readout-explicit-speaking",assistantRectangle:true)
    tap("answer.speech.read")
    XCTAssertEqual(app.buttons["answer.speech.read"].label,"Read")
    XCTAssertTrue(app.staticTexts["answer.speech.status"].label.contains("stopped"))
  }
  func testCardReadoutRequiresExplicitReadAndChangingCardsStopsWithoutSendingDraft() {
    launch(["--answer-speech-fixture"]);tap("nav.assistant")
    let input=app.textFields["assistant.input"],draft="temperature 91"
    input.tap();input.typeText(draft);selectAnswerExample("message")
    let read=app.buttons["answer.speech.read"]
    XCTAssertEqual(read.label,"Unlock readout")
    revealPlanControl(read);unlockSyntheticReadout();startSyntheticReadout()
    XCTAssertTrue(responseElement("assistant.card.message").exists)
    viewportShot("card-readout-message-explicit-synthetic",assistantRectangle:true)
    selectAnswerExample("agenda")
    XCTAssertEqual(read.label,"Read");XCTAssertEqual(input.value as? String,draft)
    XCTAssertTrue(app.staticTexts["answer.speech.status"].label.contains("stopped"))
    revealPlanControl(read);startSyntheticReadout()
    selectAnswerExample("recipe")
    XCTAssertEqual(read.label,"Read");XCTAssertEqual(input.value as? String,draft)
    XCTAssertTrue(app.buttons["assistant.card.openRecipe"].exists)
    revealPlanControl(read);startSyntheticReadout();tap("answer.speech.read")
    XCTAssertEqual(read.label,"Read")
    viewportShot("card-readout-recipe-stopped-without-opening",assistantRectangle:true)
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
  }
  func testAnswerReadoutUnavailableDeniedAndMutedDoNotSpeak() {
    launch(["--answer-speech-fixture","--answer-speech-unavailable"]);tap("nav.assistant")
    tap("answer.speech.read")
    XCTAssertEqual(app.buttons["answer.speech.read"].label,"Unlock readout")
    XCTAssertTrue(app.staticTexts["answer.speech.status"].label.contains("available system voice"))
    viewportShot("answer-readout-no-voice-no-unlock",assistantRectangle:true)
    launch(["--answer-speech-fixture","--device-unlock-denied"]);tap("nav.assistant")
    tap("answer.speech.read")
    XCTAssertTrue(app.staticTexts["answer.speech.status"].label.contains("not granted"))
    XCTAssertEqual(app.buttons["answer.speech.read"].label,"Unlock readout")
    viewportShot("answer-readout-unlock-denied",assistantRectangle:true)
    launch(["--answer-speech-fixture"]);tap("nav.assistant");tap("answer.speech.settings")
    let mute=app.switches["answer.speech.mute"]
    for _ in 0..<4 where !mute.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(mute.waitForExistence(timeout:5));mute.tap();tap("answer.speech.settings.done")
    tap("answer.speech.read")
    XCTAssertTrue(app.staticTexts["answer.speech.status"].label.contains("muted"))
    XCTAssertEqual(app.buttons["answer.speech.read"].label,"Unlock readout")
    viewportShot("answer-readout-muted-no-unlock",assistantRectangle:true)
  }
  func testLongAnswerReadoutPausesDemoMusicAndSettingsKeepAnswer() {
    launch(["--answer-speech-fixture","--assistant-ai-fixture","long","--page","Music"])
    tap("player.play")
    expectation(for:NSPredicate(format:"label == %@","Pause"),evaluatedWith:app.buttons["player.play"])
    waitForExpectations(timeout:8)
    chooseSyntheticOnDeviceAnswers();askSyntheticQuestion("Synthetic long answer, please")
    let answer=app.staticTexts["assistant.ai.answer.0"]
    XCTAssertTrue(answer.waitForExistence(timeout:5));XCTAssertGreaterThan(answer.label.count,3000)
    tap("answer.speech.settings");tap("answer.speech.settings.done")
    XCTAssertTrue(answer.exists);XCTAssertGreaterThan(answer.label.count,3000)
    unlockSyntheticReadout();startSyntheticReadout()
    let document=app.scrollViews["assistant.content"]
    for _ in 0..<8 where answer.frame.intersection(document.frame).height<44 { document.swipeUp() }
    XCTAssertGreaterThanOrEqual(answer.frame.intersection(document.frame).height,44,
      "Long text must be actually readable by scrolling, not only present in the AX tree")
    XCTAssertLessThanOrEqual(document.frame.maxY,app.textFields["assistant.input"].frame.minY)
    viewportShot("answer-readout-long-answer-active",assistantRectangle:true)
    tap("nav.faces");drawer();tap("app.Music")
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    tap("nav.assistant");XCTAssertEqual(app.buttons["answer.speech.read"].label,"Read")
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
  }
  func testAnswerReadoutBackgroundLocksAndNeverResumes() {
    launch(["--answer-speech-fixture"]);tap("nav.assistant")
    unlockSyntheticReadout();startSyntheticReadout()
    XCUIDevice.shared.press(.home);app.activate()
    XCTAssertTrue(app.buttons["nav.assistant"].waitForExistence(timeout:5));tap("nav.assistant")
    XCTAssertEqual(app.buttons["answer.speech.read"].label,"Unlock readout")
    XCTAssertTrue(app.staticTexts["answer.speech.status"].label.contains("stopped"))
    viewportShot("answer-readout-background-locked-no-resume",assistantRectangle:true)
  }
  func testTimerChimeInterruptsAnswerReadoutAndTimerCompletes() {
    launch(["--answer-speech-fixture"]);tap("nav.assistant");unlockSyntheticReadout()
    askSyntheticQuestion("set a timer for 8 seconds")
    startSyntheticReadout()
    expectation(for:NSPredicate(format:"label == %@","Read"),evaluatedWith:app.buttons["answer.speech.read"])
    waitForExpectations(timeout:12)
    XCTAssertTrue(app.staticTexts["answer.speech.status"].label.contains("stopped"))
    viewportShot("answer-readout-timer-interrupt-no-resume",assistantRectangle:true)
    tap("nav.faces");drawer();tap("app.Timers")
    XCTAssertEqual(app.staticTexts["timer.title"].label,"DONE")
  }
  func testMicrophonePreviewStopsReadoutWithoutImplicitSendOrResume() {
    launch(["--answer-speech-fixture"]);tap("nav.assistant")
    unlockSyntheticReadout();startSyntheticReadout();tap("assistant.voice")
    XCTAssertTrue(app.staticTexts["assistant.voice.status"].label.contains("Synthetic"))
    XCTAssertEqual(app.buttons["answer.speech.read"].label,"Read")
    XCTAssertFalse(app.buttons["answer.speech.read"].isEnabled)
    tap("assistant.voice")
    XCTAssertEqual(app.textFields["assistant.input"].value as? String,"temperature 72")
    XCTAssertEqual(app.buttons["answer.speech.read"].label,"Read")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("What can I help"))
    viewportShot("answer-readout-microphone-draft-no-resume",assistantRectangle:true)
  }
}

extension HomeViewUITests {
  func testPowerCapabilityIsExplicitlyUnavailableWithoutPowerGuesses() {
    launch(["--page","Settings"])
    let power=app.buttons["settings.power"]
    for _ in 0..<5 where !power.isHittable { app.scrollViews.firstMatch.swipeUp() }
    tap("settings.power")
    let assessment=app.staticTexts["power.assessment"]
    XCTAssertTrue(assessment.waitForExistence(timeout:5))
    XCTAssertEqual(assessment.label,"Adapter adequacy: Not available")
    let policy=app.staticTexts["power.noheuristics"]
    XCTAssertTrue(policy.label.contains("battery percentage"));XCTAssertTrue(policy.label.contains("No adapter warning"))
    XCTAssertTrue(app.staticTexts["power.platform"].label.contains("does not turn on battery monitoring"))
    let limits=app.staticTexts["power.limits"]
    for _ in 0..<5 where !limits.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(limits.label.contains("not an independent measurement"))
    XCTAssertFalse(app.buttons["power.refresh"].exists)
    shot("power-capability-explicitly-unavailable")
    tap("power.capabilities.done")
    XCTAssertTrue(app.buttons["settings.power"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["Mock home only"].exists)
    viewportShot("power-capability-return-no-home-connection")
  }
}


extension HomeViewUITests {
  func testDialogScopeNewAndSameLaunchArgumentsRestartNeverRestoreHistory() {
    let storeID=UUID().uuidString
    let receipt=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:["storeID":storeID]),uniformTypeIdentifier:"public.json")
    receipt.name="dialog-persistent-store-id";receipt.lifetime = .keepAlways;add(receipt)
    launch(["--persistence-test",storeID,"--assistant-ai-fixture","ready"])
    tap("nav.apps");app.buttons["Choose profile"].tap();tap("profile.Alex")
    chooseSyntheticOnDeviceAnswers()
    XCTAssertTrue(app.staticTexts["assistant.ai.history.scope"].label.contains("Not Siri history"))
    XCTAssertTrue(app.staticTexts["assistant.ai.history.scope"].label.contains("No device sync"))
    askSyntheticQuestion("Fictional first profile question")
    XCTAssertTrue(app.staticTexts["assistant.ai.answer.0"].waitForExistence(timeout:5))
    askSyntheticQuestion("Fictional follow up")
    XCTAssertTrue(app.staticTexts["assistant.ai.answer.1"].waitForExistence(timeout:5))
    tap("assistant.ai.reset")
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.1"].exists)
    XCTAssertTrue(app.staticTexts["assistant.ai.status"].label.contains("Nothing is saved"))
    askSyntheticQuestion("New independent question")
    XCTAssertTrue(app.staticTexts["assistant.ai.answer.0"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["assistant.ai.answer.0"].label.contains("Synthetic answer:"))
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.1"].exists)
    viewportShot("dialog-new-cleared-provider-and-visible-context",assistantRectangle:true)
    // Flush the ordinary Snapshot writer in the owned UUID test store, then
    // relaunch the same arguments without resetting or creating another store.
    XCUIDevice.shared.press(.home);app.activate()
    app.terminate();app.launch()
    XCTAssertTrue(app.buttons["nav.assistant"].waitForExistence(timeout:15));tap("nav.assistant")
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
    XCTAssertTrue(app.staticTexts["assistant.reply"].exists)
    tap("assistant.capabilities");tap("assistant.provider.ondevice");tap("assistant.capabilities.done")
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
    viewportShot("dialog-process-restart-no-history-restored",assistantRectangle:true)
  }
  func testDialogCapabilityBoundaryAndProfileIsolation() {
    launch(["--assistant-ai-fixture","ready"])
    tap("nav.apps");app.buttons["Choose profile"].tap();tap("profile.Alex")
    chooseSyntheticOnDeviceAnswers()
    askSyntheticQuestion("Synthetic Alex-only question")
    XCTAssertTrue(app.staticTexts["assistant.ai.answer.0"].waitForExistence(timeout:5))
    tap("assistant.capabilities")
    let detail=app.staticTexts["assistant.capabilities.history"]
    XCTAssertTrue(detail.waitForExistence(timeout:5))
    for _ in 0..<8 { if detail.isHittable { break };app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(detail.isHittable)
    XCTAssertTrue(detail.label.contains("not your Siri history"))
    XCTAssertTrue(detail.label.contains("Nothing is saved or synced to iCloud"))
    XCTAssertTrue(detail.label.contains("cannot read or delete your Siri history"))
    shot("dialog-capabilities-no-siri-import-or-device-sync")
    tap("assistant.capabilities.done");tap("nav.apps")
    app.buttons["Choose profile"].tap();tap("profile.Jamie")
    tap("nav.assistant")
    XCTAssertTrue(app.staticTexts["assistant.reply"].exists)
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
    tap("assistant.capabilities");tap("assistant.provider.ondevice");tap("assistant.capabilities.done")
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
    askSyntheticQuestion("Synthetic Jamie-only question")
    XCTAssertTrue(app.staticTexts["assistant.ai.answer.0"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["assistant.ai.answer.0"].label.contains("Synthetic answer:"))
    XCTAssertFalse(app.staticTexts["Synthetic Alex-only question"].exists)
    viewportShot("dialog-profile-switch-no-inherited-conversation",assistantRectangle:true)
  }
}


extension HomeViewUITests {
  private func finishSetupSteps() {
    XCTAssertTrue(app.staticTexts["setup.step"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["setup.step"].label,"Step 1 of 3")
    tap("setup.next");tap("setup.next")
    XCTAssertEqual(app.staticTexts["setup.step"].label,"Step 3 of 3")
    XCTAssertTrue(app.staticTexts["setup.permission"].label.contains("Nothing on this page requests permission"))
  }
  func testIntroductionDeferralCompletionAndRestartPreserveExplicitChoice() {
    let id=UUID().uuidString
    launch(["--persistence-test",id,"--setup-introduction-fixture"])
    XCTAssertTrue(app.staticTexts["setup.scope"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["setup.scope"].label.contains("Apple Home stays disconnected"))
    XCTAssertTrue(app.staticTexts["setup.nostore"].label.contains("cannot install"))
    shot("setup-first-device-and-mock-scope")
    tap("setup.next")
    XCTAssertTrue(app.staticTexts["setup.owner"].label.contains("not authentication"))
    tap("setup.back");tap("setup.later")
    XCTAssertFalse(app.staticTexts["setup.step"].exists)
    app.terminate();app.launch()
    XCTAssertTrue(app.buttons["nav.controls"].waitForExistence(timeout:15))
    XCTAssertFalse(app.staticTexts["setup.step"].exists)
    tap("nav.controls");tap("controls.settings");tap("settings.introduction")
    finishSetupSteps();shot("setup-services-no-permissions-or-store")
    tap("setup.finish")
    app.terminate();app.launch()
    XCTAssertTrue(app.buttons["nav.controls"].waitForExistence(timeout:15))
    XCTAssertFalse(app.staticTexts["setup.step"].exists)
    tap("nav.controls");tap("controls.settings");tap("settings.introduction")
    XCTAssertEqual(app.staticTexts["setup.step"].label,"Step 1 of 3")
    tap("setup.later")
    viewportShot("setup-can-reopen-after-completion-without-home")
  }
  func testIntroductionDeniedServiceCanDisconnectAndConnectLater() {
    let id=UUID().uuidString
    launch(["--persistence-test",id,"--setup-introduction-fixture","--connection-denied"])
    finishSetupSteps();tap("setup.settings")
    XCTAssertTrue(app.buttons["settings.introduction"].waitForExistence(timeout:5))
    connectService("Calendar",success:false)
    XCTAssertEqual(app.buttons["connect.Calendar"].label,"Connect Calendar")
    XCTAssertTrue(app.staticTexts["connections.home.locked"].label.contains("disconnected"))
    let forget=app.buttons["connection.forget.Calendar"],actualScroll=app.scrollViews.firstMatch
    let forgetFrame=forget.frame,scrollFrame=actualScroll.frame,viewport=app.otherElements["reference.viewport"].frame
    let actualClip=scrollFrame.intersection(viewport)
    func box(_ f:CGRect)->[Double] {[f.minX,f.minY,f.width,f.height]}
    let report:[String:Any]=["id":forget.identifier,"label":forget.label,"frame":box(forgetFrame),
      "scroll":box(scrollFrame),"viewport":box(viewport),"actual_clip":box(actualClip),
      "fully_in_clip":axContains(actualClip,forgetFrame),"AX_hittable":forget.isHittable,
      "status_before":app.staticTexts["connection.status.Calendar"].label,
      "scope":"Initial observation, not input-qualified. Explicit preparation follows before the original unchanged tap/status assertion."]
    let diagnostic=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    diagnostic.name="native-voiceover-forget-original-input-geometry";diagnostic.lifetime = .keepAlways;add(diagnostic)
    viewportShot("forget-original-input-before")
    scrollPhotoControlFullyIntoView(forget)
    let qualifiedClip=actualScroll.frame.intersection(app.otherElements["reference.viewport"].frame)
    XCTAssertTrue(axContains(qualifiedClip,forget.frame),"Original callback probe requires a fully visible target")
    XCTAssertTrue(forget.isHittable,"Original callback probe requires native hittability after explicit scroll preparation")
    let qualified:[String:Any]=["frame":box(forget.frame),"actual_clip":box(qualifiedClip),
      "fully_in_clip":axContains(qualifiedClip,forget.frame),"AX_hittable":forget.isHittable,
      "scope":"Qualified scroll preparation only; original target, tap and callback/return assertions unchanged."]
    let ready=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:qualified,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    ready.name="native-voiceover-forget-qualified-input-geometry";ready.lifetime = .keepAlways;add(ready)
    viewportShot("forget-qualified-input")
    tap("connection.forget.Calendar")
    XCTAssertEqual(app.staticTexts["connection.status.Calendar"].label,"Disconnected")
    viewportShot("setup-denied-connection-forgotten-not-home")
    app.terminate()
    app.launchArguments.removeAll { $0=="--connection-denied" }
    app.launch()
    XCTAssertTrue(app.buttons["nav.controls"].waitForExistence(timeout:15))
    XCTAssertFalse(app.staticTexts["setup.step"].exists)
    tap("nav.controls");tap("controls.settings");connectService("Calendar")
    XCTAssertEqual(app.buttons["connect.Calendar"].label,"Disconnect Calendar")
    tap("connect.Calendar")
    XCTAssertEqual(app.staticTexts["connection.status.Calendar"].label,"Disconnected")
    viewportShot("setup-explicit-later-connect-and-disconnect")
  }
}


extension HomeViewUITests {
  private func resetStoreReceipt(_ id:String,_ scenario:String) {
    let data=try! JSONSerialization.data(withJSONObject:["storeID":id,"scenario":scenario])
    let receipt=XCTAttachment(data:data,uniformTypeIdentifier:"public.json")
    receipt.name="local-reset-store-"+scenario;receipt.lifetime = .keepAlways;add(receipt)
  }
  private func openResetReview() {
    let button=app.buttons["settings.reset"]
    XCTAssertTrue(button.waitForExistence(timeout:5));button.tap()
    XCTAssertTrue(app.staticTexts["reset.scope"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["reset.source"].label.contains("OS permissions remain"))
    XCTAssertFalse(app.textFields["reset.confirmation"].exists)
  }
  private func authenticateSyntheticReset() {
    let button=app.buttons["reset.authenticate"]
    for _ in 0..<6 { if button.isHittable { break };app.scrollViews.firstMatch.swipeUp() }
    button.tap()
    XCTAssertTrue(app.textFields["reset.confirmation"].waitForExistence(timeout:5))
  }
  private func scrollResetControlFullyIntoView(_ element:XCUIElement) {
    let scroll=app.scrollViews.containing(element.elementType,identifier:element.identifier).firstMatch
    XCTAssertTrue(scroll.waitForExistence(timeout:5))
    for _ in 0..<12 {
      let safe=scroll.frame.insetBy(dx:0,dy:20),target=element.frame
      if element.isHittable && safe.contains(target) { break }
      let gap:CGFloat = target.minY<safe.minY ? -(safe.minY-target.minY+14):target.maxY-safe.maxY+14
      let distance=min(max(abs(gap),24),safe.height*0.6)*(gap<0 ? -1:1)
      let start=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:safe.minX+12,dy:safe.midY+distance/2))
      let end=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:safe.minX+12,dy:safe.midY-distance/2))
      start.press(forDuration:0.1,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.2)
    }
    XCTAssertTrue(scroll.frame.insetBy(dx:0,dy:20).contains(element.frame))
  }
  private func typeResetConfirmation(_ value:String) {
    let field=app.textFields["reset.confirmation"]
    scrollResetControlFullyIntoView(field)
    field.tap();field.typeText(value+"\n")
  }
  func testLocalResetSeparateAuthenticationExactConfirmationAndDurableEmptyRestart() {
    let id=UUID().uuidString;resetStoreReceipt(id,"success")
    launch(["--page","Settings","--persistence-test",id,"--reset-content-fixture",
      "--legacy-photo-file-fixture","--setup-introduction-fixture"])
    openResetReview();shot("reset-review-before-auth-no-deletion")
    tap("reset.cancel")
    XCTAssertTrue(app.buttons["settings.reset"].exists)
    openResetReview();authenticateSyntheticReset()
    typeResetConfirmation("RESETx")
    XCTAssertFalse(app.buttons["reset.confirm"].isEnabled)
    let field=app.textFields["reset.confirmation"];field.tap()
    field.typeText(String(repeating:XCUIKeyboardKey.delete.rawValue,count:6)+"RESET\n")
    XCTAssertTrue(app.buttons["reset.confirm"].isEnabled)
    tap("reset.confirm")
    XCTAssertTrue(app.staticTexts["settings.reset.status"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["settings.reset.status"].label.contains("Local app content reset"))
    XCTAssertFalse(app.staticTexts["reset.scope"].exists)
    viewportShot("reset-complete-source-permissions-retained")
    app.terminate()
    // The legacy reader fixture intentionally rewrites a source file at every
    // launch. Stop injecting new bytes before proving reset restart retention.
    app.launchArguments.removeAll { $0=="--legacy-photo-file-fixture" }
    app.launch()
    XCTAssertTrue(app.staticTexts["setup.scope"].waitForExistence(timeout:15))
    XCTAssertEqual(app.staticTexts["setup.step"].label,"Step 1 of 3")
    shot("reset-restart-fresh-introduction-no-old-data")
    tap("setup.later")
    XCTAssertTrue(app.buttons["settings.reset"].waitForExistence(timeout:5))
  }
  func testLocalResetDeniedAuthenticationAndBackgroundRevokeWithoutClearingData() {
    let denied=UUID().uuidString;resetStoreReceipt(denied,"denied")
    launch(["--page","Settings","--persistence-test",denied,"--reset-content-fixture","--device-unlock-denied"])
    openResetReview()
    let authenticate=app.buttons["reset.authenticate"]
    for _ in 0..<6 { if authenticate.isHittable { break };app.scrollViews.firstMatch.swipeUp() }
    authenticate.tap()
    expectation(for:NSPredicate(format:"label CONTAINS %@","not granted"),evaluatedWith:app.staticTexts["reset.status"])
    waitForExpectations(timeout:5)
    XCTAssertFalse(app.textFields["reset.confirmation"].exists)
    shot("reset-denied-auth-no-content-deleted");tap("reset.cancel")
    let background=UUID().uuidString;resetStoreReceipt(background,"background")
    launch(["--page","Settings","--persistence-test",background,"--reset-content-fixture"])
    openResetReview();authenticateSyntheticReset()
    XCUIDevice.shared.press(.home);app.activate()
    XCTAssertTrue(app.buttons["reset.authenticate"].waitForExistence(timeout:8))
    XCTAssertFalse(app.textFields["reset.confirmation"].exists)
    XCTAssertTrue(app.staticTexts["reset.status"].label.contains("Authentication expired or was cleared"))
    XCTAssertFalse(app.staticTexts["reset.status"].label.hasPrefix("Authenticated."))
    shot("reset-background-requires-fresh-authentication");tap("reset.cancel")
  }
  func testLocalResetReadOnlyNewerStateIsNotDiscarded() {
    let id=UUID().uuidString;resetStoreReceipt(id,"readonly")
    launch(["--page","Settings","--persistence-test",id,"--state-future-fixture"])
    openResetReview();authenticateSyntheticReset();typeResetConfirmation("RESET")
    tap("reset.confirm")
    XCTAssertTrue(app.staticTexts["reset.status"].label.contains("read-only"))
    XCTAssertTrue(app.textFields["reset.confirmation"].exists)
    shot("reset-newer-state-preserved-not-overwritten");tap("reset.cancel")
  }
}


extension HomeViewUITests {
  func testLocalResetCleanupRetryPreservesNewContentAcrossRestart() {
    let id=UUID().uuidString;resetStoreReceipt(id,"cleanup")
    launch(["--page","Settings","--persistence-test",id,"--reset-content-fixture","--reset-fifo-fixture"])
    openResetReview();authenticateSyntheticReset();typeResetConfirmation("RESET");tap("reset.confirm")
    XCTAssertTrue(app.staticTexts["settings.reset.status"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["settings.reset.status"].label.contains("Cleanup needs attention"))
    shot("reset-partial-cleanup-explicit-not-full-success")
    // Create new user work after the logical reset. Retrying old cleanup must
    // keep this new timer, not call reset a second time.
    drawer();tap("app.Timers");tap("timer.start")
    XCTAssertTrue(app.staticTexts["timer.countdown"].waitForExistence(timeout:5))
    app.terminate();app.launch()
    XCTAssertTrue(app.buttons["settings.reset"].waitForExistence(timeout:15))
    XCTAssertTrue(app.staticTexts["settings.reset.status"].label.contains("previous reset cleanup"))
    openResetReview()
    XCTAssertTrue(app.staticTexts["reset.cleanup.scope"].exists)
    authenticateSyntheticReset();typeResetConfirmation("RESET")
    XCTAssertFalse(app.buttons["reset.confirm"].exists)
    // A host-only observer removes the deliberately injected FIFO from the
    // exact inode-verified retired test directory, never from real app data.
    let folder=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
    try! FileManager.default.createDirectory(at:folder,withIntermediateDirectories:true)
    let signal=folder.appendingPathComponent("reset-control-"+id+".json")
    let ack=folder.appendingPathComponent("reset-control-"+id+".ack")
    try! JSONSerialization.data(withJSONObject:["storeID":id,"job":ProcessInfo.processInfo.environment["HOMEVIEW_RESET_JOB"] ?? "missing-job"]).write(to:signal,options:.atomic)
    expectation(for:NSPredicate { _,_ in FileManager.default.fileExists(atPath:ack.path) },evaluatedWith:nil)
    waitForExpectations(timeout:15)
    tap("reset.cleanup")
    XCTAssertTrue(app.staticTexts["settings.reset.status"].label.contains("Current app content is unchanged"))
    viewportShot("reset-retry-cleans-only-retired-files")
    drawer();tap("app.Timers")
    XCTAssertTrue(app.staticTexts["timer.countdown"].waitForExistence(timeout:5))
    app.terminate();app.launch()
    XCTAssertTrue(app.buttons["settings.reset"].waitForExistence(timeout:15))
    XCTAssertFalse(app.staticTexts["settings.reset.status"].label.contains("previous reset cleanup"))
  }
}

extension HomeViewUITests {
  func revealPlanControl(_ element:XCUIElement) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    let scroll=app.scrollViews["assistant.content"],viewport=app.otherElements["reference.viewport"]
    var observations:[[String:Any]]=[]
    func record(_ safe:CGRect,_ target:CGRect) {
      func box(_ f:CGRect)->[Double] { [f.minX,f.minY,f.width,f.height] }
      observations.append(["safe":box(safe),"target":box(target),"hittable":element.isHittable])
    }
    func attach() {
      let attachment=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:observations,options:[.prettyPrinted,.sortedKeys]),uniformTypeIdentifier:"public.json")
      attachment.name="plan-control-"+element.identifier.replacingOccurrences(of:".",with:"-");attachment.lifetime = .keepAlways;add(attachment)
      shot("plan-control-"+element.identifier.replacingOccurrences(of:".",with:"-"))
    }
    for _ in 0..<24 {
      let safe=scroll.frame.intersection(viewport.frame).insetBy(dx:8,dy:16),target=element.frame
      record(safe,target)
      if !target.isEmpty && safe.contains(target) { attach();return }
      let gap=target.minY<safe.minY ? -(safe.minY-target.minY+12):target.maxY-safe.maxY+12
      let distance=min(max(abs(gap),24),safe.height*0.5)*(gap<0 ? -1:1)
      let origin=app.coordinate(withNormalizedOffset:.zero)
      origin.withOffset(CGVector(dx:safe.midX,dy:safe.midY+distance/2))
        .press(forDuration:0.1,thenDragTo:origin.withOffset(CGVector(dx:safe.midX,dy:safe.midY-distance/2)),withVelocity:.slow,thenHoldForDuration:0.2)
    }
    attach()
    XCTFail("Plan control is not fully visible: "+element.identifier)
  }
  func activatePlanControl(_ element:XCUIElement) {
    revealPlanControl(element)
    if element.isHittable { element.tap() }
    else {
      // The native button can have false AX hittability while fully rendered.
      // Require contained bounds, deliver a real coordinate tap, and assert its
      // actual state transition in the caller rather than weakening the result.
      let frame=element.frame,appFrame=app.frame
      XCTAssertTrue(appFrame.contains(frame))
      app.coordinate(withNormalizedOffset:.zero).withOffset(
        CGVector(dx:frame.midX-appFrame.minX,dy:frame.midY-appFrame.minY)).tap()
    }
  }
  func previewSyntheticPlan(_ request:String) {
    tap("nav.assistant")
    let input=app.textFields["assistant.input"]
    input.tap();input.typeText(request);tap("assistant.send")
    XCTAssertTrue(app.staticTexts["assistant.plan.status"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["assistant.plan.status"].label.contains("Nothing has run"))
  }
  func runSyntheticPlan() {
    let confirm=app.buttons["assistant.plan.confirm"]
    activatePlanControl(confirm)
  }
  func testDemoPlanPreviewCancellationAndUnsafeWholeRequestNeverAct() {
    launch()
    previewSyntheticPlan("plan: temperature 72; brightness 30")
    let cancel=app.buttons["assistant.plan.cancel"]
    activatePlanControl(cancel)
    XCTAssertTrue(app.staticTexts["assistant.plan.status"].label.contains("Cancelled"))
    XCTAssertFalse(app.buttons["assistant.plan.confirm"].exists)
    let input=app.textFields["assistant.input"]
    input.tap();input.typeText("plan: temperature 72; call Alex");tap("assistant.send")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("No actions taken"))
    XCTAssertFalse(app.buttons["assistant.plan.confirm"].exists)
    if app.buttons["assistant.keyboard.dismiss"].exists { tap("assistant.keyboard.dismiss") }
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
    shot("plan-preview-cancel-unsafe-request-no-thermostat-change")
  }
  func testDemoPlanExplicitConfirmationPersistsEachStepAndNeverReplaysOnRestart() {
    let storeID=UUID().uuidString;print("PLAN_SUCCESS_STORE_ID="+storeID)
    launch(["--persistence-test",storeID,"--reset-test-store"])
    previewSyntheticPlan("plan: temperature 72; brightness 30; timer for 1 hour named Synthetic plan timer")
    revealPlanControl(app.buttons["assistant.plan.confirm"])
    viewportShot("plan-three-step-preview-no-execution",assistantRectangle:true)
    runSyntheticPlan()
    expectation(for:NSPredicate(format:"label CONTAINS %@","All 3"),evaluatedWith:app.staticTexts["assistant.plan.status"])
    waitForExpectations(timeout:8)
    for index in 0..<3 { XCTAssertTrue(app.staticTexts["assistant.plan.step.\(index)"].label.hasPrefix("Confirmed")) }
    XCTAssertFalse(app.buttons["assistant.plan.confirm"].exists)
    revealPlanControl(app.staticTexts["assistant.plan.status"])
    viewportShot("plan-all-three-saved-readbacks",assistantRectangle:true)
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"72°")
    app.terminate();launch(["--persistence-test",storeID,"--screen-thermostat"])
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"72°")
    tap("nav.assistant");XCTAssertFalse(app.buttons["assistant.plan.confirm"].exists)
    XCTAssertFalse(app.staticTexts["assistant.plan.status"].exists)
    shot("plan-restart-no-pending-plan-or-auto-replay")
  }
  func testDemoPlanRealMockOfflineMiddleFailureKeepsFirstTimerAndSkipsDependentStep() {
    let storeID=UUID().uuidString;print("PLAN_PARTIAL_STORE_ID="+storeID)
    launch(["--persistence-test",storeID,"--reset-test-store"])
    tap("nav.controls");tap("controls.online")
    previewSyntheticPlan("plan: timer for 1 hour named First local step; temperature 72; brightness 30")
    runSyntheticPlan()
    expectation(for:NSPredicate(format:"label CONTAINS %@","1 of 3"),evaluatedWith:app.staticTexts["assistant.plan.status"])
    waitForExpectations(timeout:8)
    XCTAssertFalse(app.alerts.firstMatch.exists,"Plan failures belong in the visible per-step result, not a blocking global alert")
    XCTAssertTrue(app.staticTexts["assistant.plan.step.0"].label.hasPrefix("Confirmed"))
    XCTAssertTrue(app.staticTexts["assistant.plan.step.1"].label.hasPrefix("Failed"))
    XCTAssertTrue(app.staticTexts["assistant.plan.step.2"].label.contains("Previous step was not confirmed"))
    XCTAssertFalse(app.buttons["assistant.plan.confirm"].exists)
    revealPlanControl(app.staticTexts["assistant.plan.step.2"])
    viewportShot("plan-middle-offline-one-confirmed-one-failed-one-not-run",assistantRectangle:true)
    app.terminate();launch(["--persistence-test",storeID,"--screen-thermostat"])
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
    tap("nav.assistant");XCTAssertFalse(app.staticTexts["assistant.plan.status"].exists)
  }
}

extension HomeViewUITests {
  func testAssistantContextBoundaryIsVisibleAndUsesOnlySentText() {
    launch(["--assistant-ai-fixture","ready"])
    tap("nav.assistant");tap("assistant.capabilities")
    let context=app.staticTexts["assistant.capabilities.personalContext"]
    XCTAssertTrue(context.waitForExistence(timeout:5))
    for _ in 0..<8 where !context.isHittable { app.scrollViews.firstMatch.swipeUp() }
    XCTAssertTrue(context.label.contains("only the text you explicitly Send"))
    XCTAssertTrue(context.label.contains("Device unlock, a demo profile and a connected source do not grant model access"))
    shot("assistant-context-no-personal-or-screen-sharing")
    // Return to the provider controls instead of tapping an offscreen element.
    for _ in 0..<8 where !app.buttons["assistant.provider.ondevice"].isHittable { app.scrollViews.firstMatch.swipeDown() }
    tap("assistant.provider.ondevice");tap("assistant.capabilities.done")
    let scope=app.staticTexts["assistant.ai.context.scope"]
    XCTAssertTrue(scope.waitForExistence(timeout:5))
    XCTAssertEqual(scope.label,"Only text you Send · No app data or screen access")
    let prompt="What can you see on my calendar and other apps?"
    askSyntheticQuestion(prompt)
    XCTAssertTrue(app.staticTexts["assistant.ai.answer.0"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["assistant.ai.question.0"].label,prompt)
    XCTAssertTrue(app.staticTexts["assistant.ai.answer.0"].label.contains("Synthetic answer"))
    if app.buttons["assistant.keyboard.dismiss"].exists { tap("assistant.keyboard.dismiss") }
    viewportShot("assistant-context-explicit-text-synthetic-answer",assistantRectangle:true)
    tap("nav.faces");tap("nav.assistant")
    XCTAssertFalse(app.staticTexts["assistant.ai.answer.0"].exists)
    XCTAssertFalse(app.staticTexts["assistant.ai.question.0"].exists)
    viewportShot("assistant-context-route-exit-cleared",assistantRectangle:true)
  }
}

extension HomeViewUITests {
  private func prepareExplicitGuestMusicQueue() {
    launch(["--page","Settings"])
    connectService("Apple Music")
    drawer();tap("app.Music")
    let field=app.textFields["music.search.input"]
    XCTAssertTrue(field.waitForExistence(timeout:5));field.tap();field.typeText("sample");tap("music.search");tap("music.result.0")
    XCTAssertEqual(app.staticTexts["music.current.title"].label,"Connected fixture song")
    drawer();tap("app.Settings")
    let share=app.buttons["guest.music.share"]
    scrollPhotoControlFullyIntoView(share);share.tap()
    XCTAssertTrue(app.staticTexts["guest.music.status"].label.contains("Current queue shared"))
    let guest=app.buttons["guest.music.use"];scrollPhotoControlFullyIntoView(guest);guest.tap()
    XCTAssertTrue(app.staticTexts["music.current.title"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["music.current.title"].label,"Connected fixture song")
    XCTAssertFalse(app.textFields["music.search.input"].exists)
    XCTAssertFalse(app.buttons["music.browse"].exists)
    viewportShot("guest-policy-only-explicit-shared-queue-no-search")
  }
  func testGuestMusicSharingRequiresDeviceOwnerAndRevocationStopsTheGuestQueue() {
    prepareExplicitGuestMusicQueue()
    tap("music.connected.play")
    XCTAssertEqual(app.buttons["music.connected.play"].label,"Play")
    tap("music.connected.play")
    XCTAssertEqual(app.buttons["music.connected.play"].label,"Pause")
    drawer();tap("app.Settings")
    XCTAssertFalse(app.buttons["guest.music.share"].exists,"A guest cannot extend or change the sharing grant")
    let auth=app.buttons["guest.music.authenticate"];scrollPhotoControlFullyIntoView(auth);auth.tap();tap("device.unlock")
    let revoke=app.buttons["guest.music.share"];scrollPhotoControlFullyIntoView(revoke)
    XCTAssertEqual(revoke.label,"Stop guest sharing");revoke.tap()
    XCTAssertTrue(app.staticTexts["guest.music.status"].label.contains("sharing is off"))
    XCTAssertFalse(app.buttons["guest.music.use"].exists)
    shot("guest-policy-owner-explicit-revocation")
    XCUIDevice.shared.press(.home);app.activate()
    drawer();tap("app.Music")
    XCTAssertTrue(app.buttons["device.unlock"].waitForExistence(timeout:8))
    XCTAssertFalse(app.staticTexts["music.current.title"].exists)
    XCTAssertFalse(app.textFields["music.search.input"].exists)
    viewportShot("guest-policy-revoked-source-locked")
  }
  func testGuestMusicBackgroundRevokesSharingAndAssistantCannotResumePrivateSource() {
    prepareExplicitGuestMusicQueue()
    XCUIDevice.shared.press(.home);app.activate()
    XCTAssertTrue(app.buttons["device.unlock"].waitForExistence(timeout:8))
    XCTAssertFalse(app.staticTexts["music.current.title"].exists)
    XCTAssertFalse(app.textFields["music.search.input"].exists)
    viewportShot("guest-policy-background-cleared-shared-source")
    tap("nav.assistant")
    let field=app.textFields["assistant.input"];field.tap();field.typeText("music");tap("assistant.send")
    XCTAssertTrue(app.buttons["device.unlock"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["music.current.title"].exists)
    XCTAssertFalse(app.buttons["music.connected.play"].exists)
    viewportShot("guest-policy-assistant-cannot-resume-locked-source")
  }
}

extension HomeViewUITests {
  private func stopSyntheticVoicePreview(_ transcript:String) {
    tap("assistant.voice")
    XCTAssertTrue(app.staticTexts["assistant.voice.status"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["assistant.voice.status"].label.contains("Synthetic"))
    XCTAssertFalse(app.buttons["assistant.send"].isEnabled)
    XCTAssertFalse(app.buttons["assistant.voice.language"].isEnabled,"Capture locale cannot change during recording")
    tap("assistant.voice")
    XCTAssertTrue(app.buttons["assistant.voice.language"].isEnabled)
    XCTAssertEqual(app.textFields["assistant.input"].value as? String,transcript)
    let preview=app.staticTexts["assistant.voice.preview"]
    XCTAssertTrue(preview.waitForExistence(timeout:5));XCTAssertEqual(preview.label,transcript)
    let viewport=app.otherElements["reference.viewport"].frame
    XCTAssertGreaterThan(preview.frame.height,0)
    XCTAssertTrue(viewport.insetBy(dx:8,dy:8).contains(preview.frame),"The complete named-command preview must be visible, not just its AX text")
    XCTAssertTrue(app.buttons["assistant.send"].isEnabled)
  }
  func testVoiceNamedTimerAndAmbiguousTranscriptNeedExplicitSend() {
    let command="Timer auf 90 Sekunden namens Synthetic Tea"
    launch(["--voice-transcript",command]);tap("nav.assistant")
    stopSyntheticVoicePreview(command)
    XCTAssertEqual(app.staticTexts["assistant.reply"].label,"What can I help you with?")
    viewportShot("voice-owned-timer-ready-no-action",assistantRectangle:true)
    tap("assistant.send")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("90 seconds"))
    tap("nav.faces");drawer();tap("app.Timers")
    XCTAssertEqual(app.staticTexts["timer.title"].label,"SYNTHETIC TEA")
    tap("timer.pause")
    viewportShot("voice-owned-named-timer-created")
    launch(["--voice-transcript","set a timer"]);tap("nav.assistant")
    let language=app.buttons["assistant.voice.language"]
    XCTAssertEqual(language.label,"Input language: Deutsch")
    language.tap();tap("English")
    XCTAssertEqual(language.label,"Input language: English")
    stopSyntheticVoicePreview("set a timer");tap("assistant.send")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("Specify"))
    tap("nav.faces");drawer();tap("app.Timers")
    XCTAssertTrue(app.buttons["timer.start"].exists);XCTAssertFalse(app.staticTexts["timer.countdown"].exists)
    viewportShot("voice-owned-ambiguous-transcript-no-timer")
  }
  func testVoiceCookingStepRemainsPreviewUntilSend() {
    let command="nächster schritt"
    launch(["--screen-recipe","--voice-transcript",command]);tap("recipe.start")
    XCTAssertTrue(app.staticTexts["cooking.text"].label.contains("olive oil"))
    tap("nav.assistant");stopSyntheticVoicePreview(command)
    XCTAssertTrue(app.textFields["assistant.input"].exists);XCTAssertFalse(app.staticTexts["cooking.text"].exists)
    viewportShot("voice-owned-cooking-step-ready-no-action",assistantRectangle:true)
    tap("assistant.send")
    XCTAssertTrue(app.staticTexts["cooking.text"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["cooking.text"].label.contains("squash"))
    viewportShot("voice-owned-cooking-step-explicitly-advanced")
  }
  func testVoiceRecognitionErrorAndOverflowDiscardSpeechAndRetainTypedFallback() {
    let partial="Timer auf 90 Sekunden namens Synthetic Partial"
    launch(["--voice-transcript",partial,"--voice-recognition-error"]);tap("nav.assistant")
    let field=app.textFields["assistant.input"];field.tap();field.typeText("temperature 71")
    tap("assistant.voice")
    XCTAssertFalse(app.buttons["assistant.send"].isEnabled)
    tap("assistant.voice")
    let status=app.staticTexts["assistant.voice.status"]
    expectation(for:NSPredicate(format:"label CONTAINS %@","No speech draft was retained"),evaluatedWith:status)
    waitForExpectations(timeout:5)
    XCTAssertEqual(field.value as? String,"temperature 71")
    viewportShot("voice-owned-error-retains-typed-fallback",assistantRectangle:true)
    tap("assistant.send");tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"71°")
    drawer();tap("app.Timers");XCTAssertFalse(app.staticTexts["timer.countdown"].exists)
    launch(["--voice-transcript",String(repeating:"x",count:1001)]);tap("nav.assistant");tap("assistant.voice")
    expectation(for:NSPredicate(format:"label CONTAINS %@","exceeded 1000"),evaluatedWith:app.staticTexts["assistant.voice.status"])
    waitForExpectations(timeout:5)
    XCTAssertFalse(app.buttons["assistant.send"].isEnabled)
    XCTAssertTrue(["","Type a request"].contains(app.textFields["assistant.input"].value as? String ?? "invalid"))
    viewportShot("voice-owned-overflow-rejected-not-truncated",assistantRectangle:true)
  }
  func testVoiceContextLossCancelsCaptureAndDiscardsOldTranscript() {
    launch(["--voice-transcript","Timer auf 90 Sekunden namens Synthetic Abandoned"]);tap("nav.assistant")
    let field=app.textFields["assistant.input"];field.tap();field.typeText("temperature 73")
    tap("assistant.voice");tap("nav.faces");tap("nav.assistant")
    XCTAssertEqual(field.value as? String,"temperature 73")
    XCTAssertEqual(app.staticTexts["assistant.voice.status"].label,"Tap to speak · On-device only")
    tap("assistant.voice");XCUIDevice.shared.press(.home);app.activate()
    XCTAssertTrue(field.waitForExistence(timeout:8))
    XCTAssertTrue(["","Type a request"].contains(field.value as? String ?? "invalid"))
    XCTAssertFalse(app.buttons["assistant.send"].isEnabled)
    XCTAssertEqual(app.staticTexts["assistant.voice.status"].label,"Tap to speak · On-device only")
    viewportShot("voice-owned-background-context-cleared",assistantRectangle:true)
  }
}

extension HomeViewUITests {
  private func dismissLocalWriteError() {
    XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout:5))
    XCTAssertTrue(app.alerts.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Original saved data is unchanged")).firstMatch.exists)
    app.alerts.buttons["OK"].tap()
  }
  @objc func testReadOnlyFaceStyleAndSlotEditsKeepCurrentSelections() {
    let id=UUID().uuidString
    print("WRITE_BOUNDARY_EDITOR_ID="+id)
    launch(["--persistence-test",id,"--state-future-fixture","--face","Modular"])
    app.otherElements["face.Modular"].press(forDuration:1)
    XCTAssertTrue(app.buttons["editor.done"].waitForExistence(timeout:5))
    XCTAssertEqual(app.buttons["Mist style"].value as? String,"Selected")
    tap("Sage style");dismissLocalWriteError()
    XCTAssertEqual(app.buttons["Mist style"].value as? String,"Selected")
    let previous=app.buttons["widget.0"].label
    tap("widget.0");tap("complication.choose.Clock");dismissLocalWriteError()
    viewportShot("write-boundary-slot-after-save-error")
    print("WRITE_BOUNDARY_SLOT_UI="+app.debugDescription)
    XCTAssertTrue(app.buttons["complications.done"].waitForExistence(timeout:5),"Failed slot write must retain the originating picker")
    tap("complications.done")
    XCTAssertEqual(app.buttons["widget.0"].label,previous)
    viewportShot("write-boundary-readonly-face-and-slot-unchanged")
    tap("editor.done")
    XCTAssertTrue(app.otherElements["face.Modular"].waitForExistence(timeout:5))
    app.terminate();launch(["--persistence-test",id])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
  }
  @objc func testReadOnlyRecipePinKeepsUnpinnedCookingContext() {
    let id=UUID().uuidString
    print("WRITE_BOUNDARY_RECIPE_ID="+id)
    launch(["--persistence-test",id,"--state-future-fixture","--screen-recipe"])
    tap("recipe.start");tap("cooking.next")
    let previous=app.staticTexts["cooking.text"].label
    XCTAssertEqual(app.buttons["recipe.pin"].value as? String,"Not pinned")
    tap("recipe.pin");dismissLocalWriteError()
    XCTAssertEqual(app.buttons["recipe.pin"].value as? String,"Not pinned")
    XCTAssertEqual(app.staticTexts["cooking.text"].label,previous)
    viewportShot("write-boundary-readonly-recipe-unpinned-context-kept")
    app.terminate();launch(["--persistence-test",id,"--screen-recipe"])
    XCTAssertTrue(app.staticTexts["store.readOnly"].exists)
    tap("recipe.start")
    XCTAssertEqual(app.buttons["recipe.pin"].value as? String,"Not pinned")
  }
  @objc func testRecipePinUnpinDoesNotCrashAndSurvivesProcessRestart() {
    let id=UUID().uuidString
    print("WRITE_BOUNDARY_RECIPE_POSITIVE_ID="+id)
    launch(["--persistence-test",id,"--screen-recipe"])
    tap("recipe.start")
    XCTAssertEqual(app.buttons["recipe.pin"].value as? String,"Not pinned")
    tap("recipe.pin");XCTAssertEqual(app.buttons["recipe.pin"].value as? String,"Pinned")
    tap("recipe.pin");XCTAssertEqual(app.buttons["recipe.pin"].value as? String,"Not pinned")
    tap("recipe.pin");XCTAssertEqual(app.buttons["recipe.pin"].value as? String,"Pinned")
    viewportShot("write-boundary-recipe-pinned-after-unpin-retry")
    app.terminate();launch(["--persistence-test",id,"--screen-recipe"])
    tap("recipe.start");XCTAssertEqual(app.buttons["recipe.pin"].value as? String,"Pinned")
    tap("recipe.pin");XCTAssertEqual(app.buttons["recipe.pin"].value as? String,"Not pinned")
    app.terminate();launch(["--persistence-test",id,"--screen-recipe"])
    tap("recipe.start");XCTAssertEqual(app.buttons["recipe.pin"].value as? String,"Not pinned")
    viewportShot("write-boundary-recipe-unpinned-after-process-restart")
  }
}


extension HomeViewUITests {
  @objc func testPhotoRotationChoiceSurvivesRestartWithoutReselectingGallery() {
    let id=UUID().uuidString
    print("PHOTO_ROTATION_STORE_ID="+id)
    launch(["--page","Settings","--persistence-test",id])
    let gallery=app.buttons["photos.gallery"]
    scrollPhotoControlFullyIntoView(gallery);gallery.tap()
    XCTAssertTrue(app.staticTexts["photo.index"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["photo.index"].label.contains("OF 2"))
    tap("nav.controls");tap("controls.settings")
    let rotation=app.switches["photos.rotate"]
    scrollPhotoControlFullyIntoView(rotation)
    XCTAssertEqual(rotation.value as? String,"1")
    rotation.tap();XCTAssertEqual(rotation.value as? String,"0")
    viewportShot("photo-write-rotation-disabled")
    app.terminate()
    launch(["--page","Settings","--persistence-test",id])
    scrollPhotoControlFullyIntoView(rotation)
    XCTAssertEqual(rotation.value as? String,"0")
    viewportShot("photo-write-rotation-disabled-after-restart")
  }
}

extension HomeViewUITests {
  private func setTimerActivityEnabled(_ on:Bool) {
    let control=app.switches["timer.activity.enabled"],expected=on ? "1":"0"
    XCTAssertTrue(control.waitForExistence(timeout:5));XCTAssertTrue(control.isHittable)
    if control.value as? String != expected {
      // UIKit exposes the label and trailing switch as one wide AX row.
      // Its midpoint is the label, not the visible switch control.
      let frame=control.frame
      XCTAssertTrue(app.frame.contains(frame));XCTAssertGreaterThan(frame.width,44)
      control.coordinate(withNormalizedOffset:.zero)
        .withOffset(CGVector(dx:frame.width-25,dy:frame.height/2)).tap()
    }
    expectation(for:NSPredicate(format:"value == %@",expected),evaluatedWith:control)
    waitForExpectations(timeout:5)
  }
  private func openTimerActivitySettings() {
    let button=app.buttons["settings.timer-activity"]
    scrollPhotoControlFullyIntoView(button);button.tap()
    XCTAssertTrue(app.switches["timer.activity.enabled"].waitForExistence(timeout:5))
  }
  private func expectTimerActivityStatus(_ text:String) {
    expectation(for:NSPredicate(format:"label CONTAINS %@",text),evaluatedWith:app.staticTexts["timer.activity.status"])
    waitForExpectations(timeout:8)
  }
  private func createOwnActivityTimer() {
    tap("timer.activity.done");tap("nav.faces");drawer();tap("app.Timers");tap("timer.start")
    XCTAssertTrue(app.buttons["timer.pause"].waitForExistence(timeout:5))
    tap("nav.controls");tap("controls.settings");openTimerActivitySettings()
  }
  func testTimerActivityExplicitOptInAndOptOutPersistWithoutImplicitSystemActivity() {
    let id=UUID().uuidString,args=["--persistence-test",id,"--timer-activity-fixture","--page","Settings"]
    launch(args);openTimerActivitySettings()
    let enabled=app.switches["timer.activity.enabled"]
    XCTAssertEqual(enabled.value as? String,"0");setTimerActivityEnabled(true)
    XCTAssertEqual(enabled.value as? String,"1")
    createOwnActivityTimer();expectTimerActivityStatus("Synthetic timer activity (active)")
    XCTAssertTrue(app.staticTexts["timer.activity.status"].label.contains("No system activity created"))
    shot("timer-live-activity-synthetic-opted-in")
    setTimerActivityEnabled(false);expectTimerActivityStatus("Synthetic timer activity (ended)")
    XCTAssertEqual(enabled.value as? String,"0")
    shot("timer-live-activity-synthetic-off")
    app.terminate();launch(args);openTimerActivitySettings()
    XCTAssertEqual(app.switches["timer.activity.enabled"].value as? String,"0")
    XCTAssertFalse(app.buttons["timer.activity.show"].isEnabled)
  }
  func testTimerActivityRestartKeepsPreferenceButRequiresExplicitNewStart() {
    let id=UUID().uuidString,args=["--persistence-test",id,"--timer-activity-fixture","--page","Settings"]
    launch(args);openTimerActivitySettings();setTimerActivityEnabled(true)
    createOwnActivityTimer();expectTimerActivityStatus("Synthetic timer activity (active)")
    app.terminate();launch(args);openTimerActivitySettings()
    XCTAssertEqual(app.switches["timer.activity.enabled"].value as? String,"1")
    expectTimerActivityStatus("Start a timer or choose")
    tap("timer.activity.show");expectTimerActivityStatus("Synthetic timer activity (active)")
    shot("timer-live-activity-synthetic-explicit-restart")
    setTimerActivityEnabled(false);expectTimerActivityStatus("Synthetic timer activity (ended)")
  }
}

extension HomeViewUITests {
  private func expectOwnSystemActivity(_ running:Int,_ paused:Int,_ count:Int=1) -> Bool {
    let predicate=NSPredicate(format:"label == %@","Own activities=\(count); running=\(running); paused=\(paused)")
    return XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:predicate,object:app.staticTexts["timer.activity.system-report"])],timeout:10) == .completed
  }
  func testOwnTimerSystemActivityReadbackPauseAndExplicitCleanup() {
    let id=UUID().uuidString
    launch(["--persistence-test",id,"--timer-activity-system-test","--page","Settings"])
    openTimerActivitySettings();setTimerActivityEnabled(true)
    createOwnActivityTimer()
    let started=expectOwnSystemActivity(1,0)
    if started {
      shot("timer-system-activity-own-registry-running")
      tap("timer.activity.done");tap("nav.faces");drawer();tap("app.Timers");tap("timer.pause")
      tap("nav.controls");tap("controls.settings");openTimerActivitySettings()
      let paused=expectOwnSystemActivity(0,1)
      shot("timer-system-activity-own-registry-paused")
      tap("timer.activity.done");tap("nav.faces");drawer();tap("app.Timers");tap("timer.pause")
      tap("nav.controls");tap("controls.settings");openTimerActivitySettings()
      let resumed=expectOwnSystemActivity(1,0)
      XCUIDevice.shared.press(.home)
      let springboard=XCUIApplication(bundleIdentifier:"com.apple.springboard")
      springboard.activate()
      XCTAssertTrue(springboard.wait(for:.runningForeground,timeout:10))
      let outsideReady=XCTWaiter.wait(for:[XCTNSPredicateExpectation(
        predicate:NSPredicate(format:"state != %@",NSNumber(value:XCUIApplication.State.runningForeground.rawValue)),object:app)],timeout:10) == .completed
      let outside=XCTAttachment(screenshot:springboard.screenshot());outside.name="timer-system-activity-outside-app";outside.lifetime = .keepAlways;add(outside)
      app.activate()
      if app.switches["timer.activity.enabled"].value as? String=="1" {setTimerActivityEnabled(false)}
      let cleaned=expectOwnSystemActivity(0,0,0)
      shot("timer-system-activity-own-registry-cleaned")
      XCTAssertTrue(paused,"Actual ActivityKit registry did not reflect pause")
      XCTAssertTrue(resumed,"Actual ActivityKit registry did not reflect resume")
      XCTAssertTrue(cleaned,"Own ActivityKit registry was not empty after explicit opt-out")
      XCTAssertTrue(outsideReady,"HomeView did not leave the foreground before outside capture")
    } else {
      shot("timer-system-activity-request-not-established")
      if app.switches["timer.activity.enabled"].value as? String=="1" {setTimerActivityEnabled(false)}
      XCTAssertTrue(expectOwnSystemActivity(0,0,0),"Owned failed-start experiment did not clean up")
    }
    XCTAssertTrue(started,"No own ActivityKit system activity established; not an outside-app visibility PASS")
  }
}

extension HomeViewUITests {
  func testHiddenTimerHasNamedAccessibleControlWithoutPreciseGesture() {
    launch(["--reference-timer","--reference-resting","--timer-idle-test"])
    let countdown=app.staticTexts["timer.countdown"]
    XCTAssertTrue(countdown.waitForExistence(timeout:5));XCTAssertEqual(countdown.label,"10:56")
    XCTAssertFalse(app.buttons["timer.pause"].exists);XCTAssertFalse(app.buttons["timer.delete"].exists)
    viewportShot("timer-accessibility-resting-before-control")
    let show=app.buttons["timer.revealControls"]
    XCTAssertTrue(show.waitForExistence(timeout:3),"Hidden timer needs a named accessibility control, not only an anonymous surface gesture")
    XCTAssertEqual(show.label,"Show timer controls");XCTAssertEqual(show.value as? String,"10:56")
    show.tap()
    XCTAssertTrue(app.buttons["timer.pause"].waitForExistence(timeout:3));XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
    XCTAssertTrue(app.buttons["timer.delete"].exists)
    XCTAssertEqual(countdown.label,"10:56")
    viewportShot("timer-accessibility-controls-revealed")
    tap("timer.delete");XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:3))
  }
}

extension HomeViewUITests {
  func testTimerVisibleControlsAutomaticHitRegionAudit() throws {
    launch(["--reference-timer"])
    XCTAssertTrue(app.buttons["timer.pause"].waitForExistence(timeout:5))
    XCTAssertEqual(app.buttons["timer.pause"].label,"Resume timer")
    viewportShot("timer-hit-region-before-audit")
    var reports:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let element=issue.element,frame=element?.frame ?? .zero
      reports.append(["identifier":element?.identifier ?? "", "label":element?.label ?? "",
        "frame":[Double(frame.minX),Double(frame.minY),Double(frame.width),Double(frame.height)],
        "auditType":issue.auditType.rawValue,"description":issue.compactDescription,
        "detail":issue.detailedDescription])
      // Collect every finding, then fail on the entire unfiltered list below.
      return true
    }
    let attachment=XCTAttachment(data:try JSONSerialization.data(withJSONObject:reports,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    attachment.name="timer-hit-region-all-findings";attachment.lifetime = .keepAlways;add(attachment)
    XCTAssertTrue(reports.isEmpty,"Unfiltered automatic hit-region audit found \(reports.count) issues: \(reports)")
  }
}

extension HomeViewUITests {
  private func tapFooterOuterEdge(_ id:String,_ edge:String) {
    let button=app.buttons[id]
    XCTAssertTrue(button.waitForExistence(timeout:5));XCTAssertTrue(button.isHittable)
    // Frame conversion/subtraction can lose several ULPs; allow 1e-9pt only.
    let f=button.frame
    XCTAssertEqual(f.width,44,accuracy:0.000_000_001);XCTAssertEqual(f.height,44,accuracy:0.000_000_001)
    XCTAssertTrue(app.frame.contains(f))
    let point:CGVector
    switch edge {
    case "top":point=CGVector(dx:f.midX-app.frame.minX,dy:f.minY+2-app.frame.minY)
    case "right":point=CGVector(dx:f.maxX-2-app.frame.minX,dy:f.midY-app.frame.minY)
    default:point=CGVector(dx:f.midX-app.frame.minX,dy:f.maxY-2-app.frame.minY)
    }
    app.coordinate(withNormalizedOffset:.zero).withOffset(point).tap()
  }
  func testFooterTargetsAre44PointsNonoverlappingAndOuterEdgesNavigate() {
    launch(["--reference-timer"])
    let ids=["nav.faces","nav.apps","nav.assistant","nav.controls"],frames=ids.map {app.buttons[$0].frame}
    for f in frames {XCTAssertEqual(f.width,44,accuracy:0.000_000_001);XCTAssertEqual(f.height,44,accuracy:0.000_000_001)}
    for i in frames.indices {for j in frames.indices where j>i {XCTAssertTrue(frames[i].intersection(frames[j]).isNull,"Footer targets must not overlap")}}
    // These y positions lie outside the footer's retained 30pt layout slot.
    tapFooterOuterEdge("nav.controls","top")
    XCTAssertTrue(app.buttons["controls.settings"].waitForExistence(timeout:5))
    tapFooterOuterEdge("nav.faces","top")
    XCTAssertTrue(app.buttons["home.thermostat"].waitForExistence(timeout:5))
    tapFooterOuterEdge("nav.apps","right")
    XCTAssertTrue(app.buttons["all.apps"].waitForExistence(timeout:5))
    tapFooterOuterEdge("nav.assistant","bottom")
    XCTAssertTrue(app.descendants(matching:.any).matching(identifier:"assistant.input").firstMatch.waitForExistence(timeout:5))
    shot("footer-44pt-outer-edge-actions-assistant")
  }
}

extension HomeViewUITests {
  func testWorldClockTwoCalendarDaysAheadIsNotLabelledTomorrow() {
    launch(["--page","World Clock","--reference-zone","Etc/GMT+12",
      "--reference-date","2026-01-01T11:30:00Z"])
    tap("world.add")
    let search=app.textFields["world.search"]
    search.tap();search.typeText("Auckland")
    tap("world.choose.Pacific/Auckland")
    app.swipeUp()
    let row=app.otherElements["world.row.Pacific/Auckland"]
    XCTAssertTrue(row.waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["world.time.Pacific/Auckland"].exists)
    viewportShot("world-date-two-days-before-assertion")
    XCTAssertTrue(row.staticTexts["2 days ahead"].exists,
      "Auckland is Jan2 while the UTC-12 reference is Dec31; not merely next day")
    XCTAssertFalse(row.staticTexts["Next day"].exists)
  }
}

extension HomeViewUITests {
  private func auditRecipeHitRegions(_ state:String) throws {
    viewportShot("recipe-hit-region-"+state)
    var reports:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let element=issue.element,frame=element?.frame ?? .zero
      reports.append(["identifier":element?.identifier ?? "","label":element?.label ?? "",
        "frame":[Double(frame.minX),Double(frame.minY),Double(frame.width),Double(frame.height)],
        "auditType":issue.auditType.rawValue,"description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let attachment=XCTAttachment(data:try JSONSerialization.data(withJSONObject:reports,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    attachment.name="recipe-hit-region-"+state+"-all-findings";attachment.lifetime = .keepAlways;add(attachment)
    XCTAssertTrue(reports.isEmpty,"Unfiltered recipe hit-region audit found \(reports.count) issues: \(reports)")
  }
  func testRecipeCoverAutomaticHitRegionAudit() throws {
    launch(["--screen-recipe"])
    XCTAssertTrue(app.buttons["recipe.ingredients"].waitForExistence(timeout:5))
    try auditRecipeHitRegions("cover")
  }
  func testRecipeIngredientsAutomaticHitRegionAudit() throws {
    launch(["--screen-recipe"]);tap("recipe.ingredients")
    XCTAssertTrue(app.buttons["ingredient.0"].waitForExistence(timeout:5))
    try auditRecipeHitRegions("ingredients")
  }
  func testRecipeCookingAutomaticHitRegionAudit() throws {
    launch(["--screen-recipe"]);tap("recipe.start")
    XCTAssertTrue(app.staticTexts["cooking.text"].waitForExistence(timeout:5))
    try auditRecipeHitRegions("cooking")
  }
}

extension HomeViewUITests {
  private func selectAnswerExample(_ name:String) {
    if app.buttons["assistant.keyboard.dismiss"].exists {tap("assistant.keyboard.dismiss")}
    revealPlanControl(app.buttons["assistant.examples"])
    tap("assistant.examples");tap("assistant.example."+name)
    XCTAssertTrue(app.staticTexts["assistant.card.scope"].waitForExistence(timeout:5))
  }
  private func responseElement(_ id:String)->XCUIElement {
    app.descendants(matching:.any).matching(identifier:id).firstMatch
  }
  func testAssistantMessageEvidenceIsReadOnlyAndKeepsUnsentDraft() {
    launch();tap("nav.assistant")
    let input=app.textFields["assistant.input"],draft="temperature 91"
    input.tap();input.typeText(draft);selectAnswerExample("message")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("fictional"))
    let card=responseElement("assistant.card.message");revealPlanControl(card)
    XCTAssertTrue(card.label.contains("Avery Morgan"));XCTAssertTrue(card.label.contains("6:30 PM"))
    XCTAssertTrue(card.label.contains("Fictional message"));XCTAssertFalse(app.buttons["assistant.card.message"].exists)
    XCTAssertFalse(app.buttons["assistant.card.openRecipe"].exists)
    viewportShot("assistant-message-readonly-evidence",assistantRectangle:true)
    card.tap();XCTAssertTrue(card.exists);XCTAssertEqual(input.value as? String,draft)
    activatePlanControl(app.buttons["assistant.card.source.bundled"])
    XCTAssertTrue(app.buttons["assistant.card.source.done"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","No personal calendar, message or account was searched")).firstMatch.exists)
    XCTAssertFalse(responseElement("assistant.card.source.open").exists)
    shot("assistant-message-source-no-account-or-link");tap("assistant.card.source.done")
    activatePlanControl(app.buttons["assistant.card.followup.agenda"])
    XCTAssertFalse(card.exists);XCTAssertEqual(input.value as? String,draft)
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
  }
  func testAssistantMessageEvidenceClearsOnBackgroundAndExplicitSend() {
    launch();tap("nav.assistant");selectAnswerExample("message")
    XCTAssertTrue(responseElement("assistant.card.message").exists)
    XCUIDevice.shared.press(.home);app.activate()
    XCTAssertTrue(app.staticTexts["mock.badge"].waitForExistence(timeout:5));tap("nav.assistant")
    XCTAssertFalse(responseElement("assistant.card.message").exists)
    selectAnswerExample("message")
    let input=app.textFields["assistant.input"];input.tap();input.typeText("SYNTHETIC unknown question");tap("assistant.send")
    XCTAssertFalse(responseElement("assistant.card.message").exists)
    XCTAssertFalse(app.staticTexts["assistant.card.scope"].exists)
    shot("assistant-message-cleared-after-local-send")
  }
  func testAssistantKnowledgeImageSourceAndAgendaFollowUp() {
    launch();tap("nav.assistant");selectAnswerExample("knowledge")
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("1842"))
    let image=responseElement("assistant.card.image")
    revealPlanControl(image)
    XCTAssertTrue(image.label.contains("fern-like"))
    viewportShot("assistant-card-knowledge-image",assistantRectangle:true)
    let source=app.buttons["assistant.card.source.museum"]
    activatePlanControl(source)
    XCTAssertTrue(responseElement("assistant.card.source.open").waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","not a live search")).firstMatch.exists)
    shot("assistant-card-source-no-auto-browser")
    tap("assistant.card.source.done")
    XCTAssertFalse(responseElement("assistant.card.source.open").exists)
    activatePlanControl(app.buttons["assistant.card.followup.agenda"])
    let event=responseElement("assistant.card.event.0")
    revealPlanControl(event)
    XCTAssertTrue(event.label.contains("Riley"));XCTAssertTrue(event.label.contains("All day"))
    XCTAssertFalse(app.buttons["assistant.card.openRecipe"].exists)
    viewportShot("assistant-card-agenda",assistantRectangle:true)
  }
  func testAssistantRecipeCardPreservesDraftAndRequiresExplicitOpen() {
    launch();tap("nav.assistant")
    let draft="set a timer for 5 minutes",input=app.textFields["assistant.input"]
    input.tap();input.typeText(draft)
    selectAnswerExample("recipe")
    XCTAssertEqual(input.value as? String,draft)
    XCTAssertFalse(app.buttons["recipe.ingredients"].exists)
    let open=app.buttons["assistant.card.openRecipe"]
    revealPlanControl(open)
    viewportShot("assistant-card-recipe-explicit-action",assistantRectangle:true)
    activatePlanControl(open)
    XCTAssertTrue(app.staticTexts["assistant.exampleRecipe.title"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["assistant.exampleRecipe.title"].label,"Butternut Squash Soup")
    shot("assistant-card-opened-readonly-bundled-recipe")
    tap("nav.faces");drawer();tap("app.Timers")
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["timer.countdown"].exists)
    tap("nav.assistant");XCTAssertEqual(input.value as? String,draft)
    XCTAssertFalse(app.staticTexts["assistant.card.scope"].exists)
  }
  func testAssistantLoadingEmptyFailureAndExplicitExampleRecovery() {
    launch();tap("nav.assistant")
    for (name,state) in [("loading","loading"),("empty","empty"),("failure","failure")] {
      selectAnswerExample(name)
      let status=responseElement("assistant.card."+state)
      revealPlanControl(status)
      viewportShot("assistant-card-"+state,assistantRectangle:true)
      XCTAssertFalse(app.buttons["assistant.card.openRecipe"].exists)
      XCTAssertFalse(app.buttons["assistant.card.source.museum"].exists)
    }
    activatePlanControl(app.buttons["assistant.card.followup.knowledge"])
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("1842"))
  }
  func testAssistantCardsClearOnSendNavigationAndBackground() {
    launch();tap("nav.assistant");selectAnswerExample("recipe")
    let input=app.textFields["assistant.input"]
    input.tap();input.typeText("SYNTHETIC unknown question");tap("assistant.send")
    XCTAssertFalse(app.staticTexts["assistant.card.scope"].exists)
    XCTAssertFalse(app.buttons["assistant.card.openRecipe"].exists)
    selectAnswerExample("agenda");tap("nav.faces");tap("nav.assistant")
    XCTAssertFalse(app.staticTexts["assistant.card.scope"].exists)
    selectAnswerExample("knowledge")
    XCUIDevice.shared.press(.home);app.activate()
    XCTAssertTrue(app.staticTexts["mock.badge"].waitForExistence(timeout:5))
    tap("nav.assistant")
    XCTAssertFalse(app.staticTexts["assistant.card.scope"].exists)
    XCTAssertTrue(app.textFields["assistant.input"].exists)
    shot("assistant-card-background-no-restored-result")
  }
  func testAssistantExampleKeepsCompletedVoiceDraftUnsent() {
    let spoken="temperature 72",typed="OLD UNSENT TYPED DRAFT"
    launch(["--voice-transcript",spoken]);tap("nav.assistant")
    let input=app.textFields["assistant.input"]
    input.tap();input.typeText(typed)
    tap("assistant.voice")
    XCTAssertTrue(app.staticTexts["assistant.voice.status"].label.contains("Synthetic"))
    XCTAssertFalse(app.buttons["assistant.examples"].isEnabled)
    XCTAssertFalse(app.buttons["assistant.send"].isEnabled)
    tap("assistant.voice")
    XCTAssertEqual(input.value as? String,spoken)
    XCTAssertTrue(app.staticTexts["assistant.voice.preview"].waitForExistence(timeout:5))
    selectAnswerExample("knowledge")
    XCTAssertEqual(input.value as? String,spoken)
    XCTAssertFalse(app.staticTexts["assistant.voice.preview"].exists)
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("1842"))
    shot("assistant-card-completed-voice-draft-kept-unsent")
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°")
    tap("nav.assistant");XCTAssertEqual(input.value as? String,spoken)
    tap("assistant.send")
    XCTAssertFalse(app.staticTexts["assistant.card.scope"].exists)
    if app.buttons["assistant.keyboard.dismiss"].exists {tap("assistant.keyboard.dismiss")}
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"72°")
  }
}

extension HomeViewUITests {
  private func tapRecipeTargetEdge(_ button:XCUIElement,bottom:Bool=false) {
    XCTAssertTrue(button.waitForExistence(timeout:5));XCTAssertTrue(button.isHittable)
    let f=button.frame
    XCTAssertGreaterThanOrEqual(f.height,44-0.000_001)
    XCTAssertGreaterThanOrEqual(f.width,44-0.000_001)
    app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(
      dx:f.midX-app.frame.minX,dy:(bottom ? f.maxY-2:f.minY+2)-app.frame.minY)).tap()
  }
  func testRecipeAccessibleProgressAndNativeEdgeActions() {
    launch(["--screen-recipe"]);tap("recipe.ingredients")
    let first=app.buttons["ingredient.0"],second=app.buttons["ingredient.1"]
    XCTAssertTrue(first.waitForExistence(timeout:5));XCTAssertEqual(first.value as? String,"Unchecked")
    XCTAssertTrue(first.frame.intersection(second.frame).isNull)
    tapRecipeTargetEdge(first)
    XCTAssertEqual(first.value as? String,"Checked")
    viewportShot("recipe-ingredients-checked-edge")
    tapRecipeTargetEdge(first,bottom:true);XCTAssertEqual(first.value as? String,"Unchecked")
    let last=app.buttons["ingredient.5"],list=app.scrollViews.firstMatch
    XCTAssertTrue(list.exists)
    for _ in 0..<3 where !list.frame.insetBy(dx:-0.5,dy:-0.5).contains(last.frame) {list.swipeUp()}
    XCTAssertTrue(list.frame.insetBy(dx:-0.5,dy:-0.5).contains(last.frame))
    tapRecipeTargetEdge(last,bottom:true);XCTAssertEqual(last.value as? String,"Checked")
    app.terminate();launch(["--screen-recipe"]);tap("recipe.start")
    let step=app.staticTexts["cooking.step"]
    XCTAssertTrue(step.waitForExistence(timeout:5));XCTAssertEqual(step.label,"Step 1 of 3")
    let timer=app.buttons["cooking.timer"],handoff=app.buttons["cooking.handoff"]
    XCTAssertTrue(timer.frame.intersection(handoff.frame).isNull)
    tapRecipeTargetEdge(timer,bottom:true)
    tapRecipeTargetEdge(handoff)
    XCTAssertTrue(app.buttons["recipe.handoff.offer"].waitForExistence(timeout:5))
    // Only open the local handoff sheet; do not offer an activity or unlock.
    tap("recipe.handoff.done");tap("cooking.next")
    XCTAssertEqual(app.staticTexts["cooking.step"].label,"Step 2 of 3")
    viewportShot("recipe-cooking-progress-after-edge-actions")
    tap("nav.faces");drawer();tap("app.Timers")
    XCTAssertTrue(app.staticTexts["timer.countdown"].waitForExistence(timeout:5))
    XCTAssertTrue(app.staticTexts["timer.title"].label.contains("STEP 1"))
    XCTAssertEqual(app.staticTexts["timer.systemStatus"].label,"Foreground timer")
    let fields=app.staticTexts["timer.countdown"].label.split(separator:":").compactMap {Int($0)}
    XCTAssertEqual(fields.count,2)
    let remaining=fields.reduce(0){$0*60+$1}
    XCTAssertGreaterThan(remaining,0);XCTAssertLessThanOrEqual(remaining,300)
    viewportShot("recipe-timer-created-by-edge-action")
  }
}


extension HomeViewUITests {
  func testAssistantBundledRecipeDoesNotOpenOrReplaceSelectedCanary() {
    let storeID=UUID().uuidString
    print("ASSISTANT_RECIPE_TARGET_STORE_ID="+storeID)
    launch(["--page","Safari","--browser-multiple-recipes","--persistence-test",storeID,"--reset-test-store"])
    XCTAssertTrue(app.webViews.firstMatch.staticTexts["Garden Tomato Pasta"].waitForExistence(timeout:10))
    tap("browser.recipe")
    XCTAssertTrue(app.buttons["Second local recipe"].waitForExistence(timeout:5))
    app.buttons["Second local recipe"].tap()
    XCTAssertTrue(app.staticTexts["Second local recipe"].waitForExistence(timeout:5))
    tap("recipe.start")
    XCTAssertEqual(app.staticTexts["cooking.text"].label,"Mix the second fixture.")
    tap("nav.assistant")
    let draft="set a timer for 5 minutes",input=app.textFields["assistant.input"]
    input.tap();input.typeText(draft);selectAnswerExample("recipe")
    XCTAssertEqual(input.value as? String,draft)
    XCTAssertTrue(app.staticTexts["Butternut Squash Soup"].exists)
    activatePlanControl(app.buttons["assistant.card.openRecipe"])
    expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:input)
    waitForExpectations(timeout:5)
    // Capture the actual destination before the assertion; do not accept the
    // old selected recipe merely because some recipe view opened.
    shot("assistant-recipe-target-after-open-with-canary-selected")
    XCTAssertTrue(app.staticTexts["Butternut Squash Soup"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["Second local recipe"].exists)
    XCTAssertTrue(app.staticTexts["assistant.exampleRecipe.scope"].label.contains("Read-only"))
    tapAssistantControlEdge(app.buttons["assistant.exampleRecipe.back"])
    XCTAssertEqual(input.value as? String,draft)
    if app.buttons["assistant.keyboard.dismiss"].exists {tap("assistant.keyboard.dismiss")}
    tap("nav.faces");drawer();tap("app.Recipes")
    // The drawer intentionally opens the selected recipe cover, not the library.
    XCTAssertTrue(app.staticTexts["Second local recipe"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["Butternut Squash Soup"].exists)
    XCTAssertTrue(app.buttons["recipe.start"].exists)
    shot("assistant-recipe-target-selected-canary-not-replaced")
    app.terminate();launch(["--persistence-test",storeID]);drawer();tap("app.Recipes")
    // The drawer intentionally opens the selected recipe cover, not the library.
    XCTAssertTrue(app.staticTexts["Second local recipe"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["Butternut Squash Soup"].exists)
    XCTAssertTrue(app.buttons["recipe.start"].exists)
    shot("assistant-recipe-target-canary-after-restart")
  }
  private func revealReadonlyExampleText(_ element:XCUIElement) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    let scroll=app.scrollViews["assistant.exampleRecipe.content"],viewport=app.otherElements["reference.viewport"]
    for _ in 0..<16 {
      let safe=scroll.frame.intersection(viewport.frame).insetBy(dx:8,dy:12),target=element.frame
      if !target.isEmpty,safe.contains(target) {break}
      let gap=target.minY<safe.minY ? -(safe.minY-target.minY+12):target.maxY-safe.maxY+12
      let distance=min(max(abs(gap),20),safe.height*0.5)*(gap<0 ? -1:1)
      let origin=app.coordinate(withNormalizedOffset:.zero)
      origin.withOffset(CGVector(dx:safe.minX+10,dy:safe.midY+distance/2))
        .press(forDuration:0.1,thenDragTo:origin.withOffset(CGVector(dx:safe.minX+10,dy:safe.midY-distance/2)),withVelocity:.slow,thenHoldForDuration:0.2)
    }
    XCTAssertGreaterThan(element.frame.height,0)
    XCTAssertTrue(scroll.frame.intersection(viewport.frame).insetBy(dx:8,dy:12).contains(element.frame))
  }
  func testAssistantReadonlyRecipeNarrowWideAndBackKeepsDraft() {
    launch();tap("nav.assistant")
    let input=app.textFields["assistant.input"],draft="UNSENT RECIPE PREVIEW DRAFT"
    input.tap();input.typeText(draft);selectAnswerExample("recipe")
    activatePlanControl(app.buttons["assistant.card.openRecipe"])
    XCTAssertTrue(app.staticTexts["assistant.exampleRecipe.title"].waitForExistence(timeout:5))
    let ingredient=app.staticTexts["assistant.exampleRecipe.ingredient.0"]
    for (name,orientation) in [("portrait",UIDeviceOrientation.portrait),("landscape",.landscapeLeft)] {
      rotateAssistantDevice(orientation)
      revealReadonlyExampleText(ingredient)
      XCTAssertEqual(ingredient.label,"1 butternut squash, peeled and cubed")
      let back=app.buttons["assistant.exampleRecipe.back"],frame=app.otherElements["reference.viewport"].frame
      XCTAssertTrue(frame.contains(back.frame))
      XCTAssertGreaterThanOrEqual(back.frame.width,44-0.000_001)
      XCTAssertGreaterThanOrEqual(back.frame.height,44-0.000_001)
      // App-window screenshots use inconsistent rotation crop coordinates on
      // this runtime. Use the actual whole display, with dimensions checked.
      let screen=XCUIScreen.main.screenshot()
      XCTAssertEqual(screen.image.size.width,app.frame.width)
      XCTAssertEqual(screen.image.size.height,app.frame.height)
      let picture=XCTAttachment(screenshot:screen)
      picture.name="assistant-readonly-recipe-"+name+"-visible-ingredient"
      picture.lifetime = .keepAlways;add(picture)
    }
    tapAssistantControlEdge(app.buttons["assistant.exampleRecipe.back"],bottom:true)
    XCTAssertEqual(input.value as? String,draft)
    XCTAssertEqual(app.staticTexts["assistant.reply"].label,"Here is the bundled butternut squash soup recipe.")
    XCTAssertFalse(app.buttons["assistant.card.openRecipe"].exists)
  }
}

extension HomeViewUITests {
  private func auditAssistantHitRegions(_ state:String) throws {
    viewportShot("assistant-hit-region-"+state,assistantRectangle:true)
    var reports:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let element=issue.element,frame=element?.frame ?? .zero
      reports.append(["identifier":element?.identifier ?? "","label":element?.label ?? "",
        "frame":[Double(frame.minX),Double(frame.minY),Double(frame.width),Double(frame.height)],
        "auditType":issue.auditType.rawValue,"description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let attachment=XCTAttachment(data:try JSONSerialization.data(withJSONObject:reports,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    attachment.name="assistant-hit-region-"+state+"-all-findings";attachment.lifetime = .keepAlways;add(attachment)
    XCTAssertTrue(reports.isEmpty,"Unfiltered assistant hit-region audit found \(reports.count) issues: \(reports)")
  }

  private func launchAssistantHitRegionProbe() {
    launch(["--answer-speech-fixture","--device-unlock-denied"])
    tap("nav.assistant")
    if app.buttons["assistant.keyboard.dismiss"].exists {tap("assistant.keyboard.dismiss")}
  }
  func testAssistantInitialAutomaticHitRegionAudit() throws {
    launchAssistantHitRegionProbe();try auditAssistantHitRegions("initial")
  }
  func testAssistantCardActionsAutomaticHitRegionAudit() throws {
    launchAssistantHitRegionProbe();selectAnswerExample("knowledge")
    revealPlanControl(app.buttons["assistant.card.source.museum"])
    try auditAssistantHitRegions("card-actions")
  }
  func testAssistantSourceAutomaticHitRegionAudit() throws {
    launchAssistantHitRegionProbe();selectAnswerExample("knowledge")
    activatePlanControl(app.buttons["assistant.card.source.museum"])
    XCTAssertTrue(app.buttons["assistant.card.source.done"].waitForExistence(timeout:5))
    try auditAssistantHitRegions("source")
  }
  func testAssistantCapabilitiesAutomaticHitRegionAudit() throws {
    launchAssistantHitRegionProbe();tap("assistant.capabilities")
    XCTAssertTrue(app.buttons["assistant.capabilities.done"].waitForExistence(timeout:5))
    try auditAssistantHitRegions("capabilities")
  }
  private func tapAssistantControlEdge(_ button:XCUIElement,bottom:Bool=false) {
    XCTAssertTrue(button.waitForExistence(timeout:5))
    let f=button.frame
    XCTAssertGreaterThanOrEqual(f.width,44-0.000_001)
    XCTAssertGreaterThanOrEqual(f.height,44-0.000_001)
    XCTAssertTrue(app.frame.contains(f))
    let origin=app.coordinate(withNormalizedOffset:.zero)
    origin.withOffset(CGVector(dx:f.midX-app.frame.minX,dy:(bottom ? f.maxY-2:f.minY+2)-app.frame.minY)).tap()
  }
  func testAssistantRecipeActionActualOuterEdge() {
    launchAssistantHitRegionProbe()
    let input=app.textFields["assistant.input"],draft="set a timer for 5 minutes"
    input.tap();input.typeText(draft);selectAnswerExample("recipe")
    let open=app.buttons["assistant.card.openRecipe"];revealPlanControl(open)
    viewportShot("assistant-hit-region-recipe-before-edge",assistantRectangle:true)
    tapAssistantControlEdge(open)
    XCTAssertTrue(app.staticTexts["assistant.exampleRecipe.title"].waitForExistence(timeout:5))
    XCTAssertEqual(app.staticTexts["assistant.exampleRecipe.title"].label,"Butternut Squash Soup")
    shot("assistant-hit-region-recipe-edge-readonly-preview")
    tap("nav.faces");drawer();tap("app.Timers")
    XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout:5))
    XCTAssertFalse(app.staticTexts["timer.countdown"].exists)
  }
  func testAssistantSourceAndDoneActualOuterEdges() {
    launchAssistantHitRegionProbe();selectAnswerExample("knowledge")
    let source=app.buttons["assistant.card.source.museum"];revealPlanControl(source)
    viewportShot("assistant-hit-region-source-before-edge",assistantRectangle:true)
    tapAssistantControlEdge(source)
    XCTAssertTrue(app.buttons["assistant.card.source.done"].waitForExistence(timeout:5))
    viewportShot("assistant-hit-region-done-before-edge",assistantRectangle:true)
    tapAssistantControlEdge(app.buttons["assistant.card.source.done"],bottom:true)
    XCTAssertFalse(responseElement("assistant.card.source.open").exists)
    let followup=app.buttons["assistant.card.followup.agenda"]
    revealPlanControl(followup);tapAssistantControlEdge(followup)
    XCTAssertTrue(app.staticTexts["assistant.reply"].label.contains("sample agenda"))
    viewportShot("assistant-hit-region-source-edge-followup",assistantRectangle:true)
  }
  func testAssistantHeaderControlsActualOuterEdges() {
    launchAssistantHitRegionProbe()
    let capabilities=app.buttons["assistant.capabilities"],read=app.buttons["answer.speech.read"],settings=app.buttons["answer.speech.settings"]
    let controls=[capabilities,read,settings]
    for control in controls {
      XCTAssertGreaterThanOrEqual(control.frame.width,44-0.000_001)
      XCTAssertGreaterThanOrEqual(control.frame.height,44-0.000_001)
    }
    for i in controls.indices {for j in controls.indices where i<j {
      XCTAssertTrue(controls[i].frame.intersection(controls[j].frame).isNull)
    }}
    tapAssistantControlEdge(capabilities)
    XCTAssertTrue(app.buttons["assistant.capabilities.done"].waitForExistence(timeout:5))
    tap("assistant.capabilities.done")
    tapAssistantControlEdge(settings,bottom:true)
    XCTAssertTrue(app.buttons["answer.speech.settings.done"].waitForExistence(timeout:5))
    tap("answer.speech.settings.done")
    // Explicit denied-unlock fixture only; no real authentication or speech.
    tapAssistantControlEdge(read,bottom:true)
    XCTAssertTrue(app.staticTexts["answer.speech.status"].label.contains("not granted"))
    XCTAssertEqual(read.label,"Unlock readout")
    viewportShot("assistant-hit-region-header-edge-actions",assistantRectangle:true)
  }
}

extension HomeViewUITests {
  private func auditWorldClockHitRegions(_ state:String) throws {
    viewportShot("world-hit-region-"+state)
    var reports:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let element=issue.element,frame=element?.frame ?? .zero
      reports.append(["identifier":element?.identifier ?? "","label":element?.label ?? "",
        "frame":[Double(frame.minX),Double(frame.minY),Double(frame.width),Double(frame.height)],
        "auditType":issue.auditType.rawValue,"description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let attachment=XCTAttachment(data:try JSONSerialization.data(withJSONObject:reports,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    attachment.name="world-hit-region-"+state+"-all-findings";attachment.lifetime = .keepAlways;add(attachment)
    XCTAssertTrue(reports.isEmpty,"Unfiltered world-clock hit-region audit found \(reports.count) issues: \(reports)")
  }
  func testWorldClockSelectedAutomaticHitRegionAudit() throws {
    launch(["--page","World Clock"])
    XCTAssertTrue(app.buttons["world.remove.America/Los_Angeles"].waitForExistence(timeout:5))
    try auditWorldClockHitRegions("selected")
  }
  func testWorldClockChooserAutomaticHitRegionAudit() throws {
    launch(["--page","World Clock"]);tap("world.add")
    XCTAssertTrue(app.buttons["world.choose.Europe/London"].waitForExistence(timeout:5))
    try auditWorldClockHitRegions("chooser")
  }
  func testWorldClockFilteredAutomaticHitRegionAudit() throws {
    launch(["--page","World Clock"]);tap("world.add")
    let search=app.textFields["world.search"]
    search.tap();search.typeText("Kathmandu\n")
    expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:app.keyboards.firstMatch)
    waitForExpectations(timeout:5)
    XCTAssertTrue(app.buttons["world.choose.Asia/Kathmandu"].waitForExistence(timeout:5))
    try auditWorldClockHitRegions("filtered")
  }
  private func revealWorldClockControl(_ element:XCUIElement) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    let list=app.scrollViews.firstMatch,viewport=app.otherElements["reference.viewport"]
    var observations:[[String:Any]]=[]
    func record(_ safe:CGRect,_ target:CGRect) {
      observations.append(["safe":[Double(safe.minX),Double(safe.minY),Double(safe.width),Double(safe.height)],
        "target":[Double(target.minX),Double(target.minY),Double(target.width),Double(target.height)]])
    }
    for _ in 0..<12 {
      let safe=list.frame.intersection(viewport.frame).insetBy(dx:4,dy:0),target=element.frame
      record(safe,target)
      if !target.isEmpty && safe.contains(target) {break}
      let gap=target.minY<safe.minY ? -(safe.minY-target.minY+12):target.maxY-safe.maxY+12
      let distance=min(max(abs(gap),24),safe.height*0.5)*(gap<0 ? -1:1)
      let origin=app.coordinate(withNormalizedOffset:.zero)
      origin.withOffset(CGVector(dx:safe.minX+8,dy:safe.midY+distance/2))
        .press(forDuration:0.1,thenDragTo:origin.withOffset(CGVector(dx:safe.minX+8,dy:safe.midY-distance/2)),withVelocity:.slow,thenHoldForDuration:0.2)
    }
    // The first row is flush with the scroll view's top edge. Requiring an
    // extra eight-point inset is not a product contract and cannot be reached
    // by scrolling past the beginning. Retain full containment and actual
    // two-point-inside edge taps, with the real rectangles attached.
    let safe=list.frame.intersection(viewport.frame).insetBy(dx:4,dy:0)
    record(safe,element.frame)
    let geometry=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:observations,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    geometry.name="world-visible-"+element.identifier;geometry.lifetime = .keepAlways;add(geometry)
    XCTAssertTrue(safe.contains(element.frame))
  }
  private func tapWorldClockEdge(_ button:XCUIElement,bottom:Bool=false) {
    XCTAssertTrue(button.waitForExistence(timeout:5))
    let frame=button.frame,viewport=app.otherElements["reference.viewport"].frame
    let data:[String:Any]=["identifier":button.identifier,"label":button.label,
      "frame":[Double(frame.minX),Double(frame.minY),Double(frame.width),Double(frame.height)],
      "viewport":[Double(viewport.minX),Double(viewport.minY),Double(viewport.width),Double(viewport.height)],
      "edge":bottom ? "bottom":"top","hittable":button.isHittable]
    let geometry=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    geometry.name="world-edge-"+button.identifier+"-"+(bottom ? "bottom":"top")
    geometry.lifetime = .keepAlways;add(geometry)
    XCTAssertTrue(viewport.contains(frame))
    tapRecipeTargetEdge(button,bottom:bottom)
  }
  func testWorldClockAddDoneChooseRemoveAndCloseActualEdges() {
    launch(["--page","World Clock"])
    viewportShot("world-hit-region-before-edge-actions")
    let add=app.buttons["world.add"]
    tapWorldClockEdge(add)
    XCTAssertEqual(add.label,"Done")
    tapWorldClockEdge(add,bottom:true)
    XCTAssertEqual(add.label,"Add City")
    tapWorldClockEdge(add)
    let london=app.buttons["world.choose.Europe/London"]
    revealWorldClockControl(london)
    tapWorldClockEdge(london)
    XCTAssertEqual(add.label,"Add City")
    let remove=app.buttons["world.remove.Europe/London"]
    revealWorldClockControl(remove)
    XCTAssertTrue(app.staticTexts["world.time.Europe/London"].exists)
    viewportShot("world-hit-region-added-london-before-remove")
    tapWorldClockEdge(remove,bottom:true)
    XCTAssertFalse(app.buttons["world.remove.Europe/London"].exists)
    XCTAssertTrue(app.buttons["world.remove.America/Los_Angeles"].exists)
    viewportShot("world-hit-region-after-remove")
    tapWorldClockEdge(app.buttons["close"])
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
  }
}

extension HomeViewUITests {
  private var localAlarmDeletes:XCUIElementQuery {
    app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","alarm.delete."))
  }
  private var localAlarmToggles:XCUIElementQuery {
    app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","alarm.toggle."))
  }
  private func launchLocalAlarmAudit() {
    // No --system-alarms: AppModel's explicit uitesting guard disables
    // native scheduling. Only synthetic foreground state is exercised.
    launch(["--page","Alarms"])
    XCTAssertEqual(localAlarmDeletes.count,1)
    XCTAssertTrue(app.staticTexts["Off"].exists)
    XCTAssertFalse(app.staticTexts["System alert enabled"].exists)
  }
  private func auditLocalAlarmHitRegions(_ state:String) throws {
    XCTAssertFalse(app.staticTexts["System alert enabled"].exists)
    viewportShot("alarm-hit-region-"+state)
    var reports:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let element=issue.element,frame=element?.frame ?? .zero
      reports.append(["identifier":element?.identifier ?? "","label":element?.label ?? "",
        "frame":[Double(frame.minX),Double(frame.minY),Double(frame.width),Double(frame.height)],
        "auditType":issue.auditType.rawValue,"description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let attachment=XCTAttachment(data:try JSONSerialization.data(withJSONObject:reports,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    attachment.name="alarm-hit-region-"+state+"-all-findings";attachment.lifetime = .keepAlways;add(attachment)
    XCTAssertTrue(reports.isEmpty,"Unfiltered local alarm hit-region audit found \(reports.count) issues: \(reports)")
  }
  func testLocalAlarmInitialAutomaticHitRegionAudit() throws {
    launchLocalAlarmAudit();try auditLocalAlarmHitRegions("initial")
  }
  func testLocalAlarmTwoRowsAutomaticHitRegionAudit() throws {
    launchLocalAlarmAudit();tap("alarm.add")
    XCTAssertEqual(localAlarmDeletes.count,2)
    XCTAssertTrue(app.staticTexts["Foreground alarm"].exists)
    try auditLocalAlarmHitRegions("two-rows")
  }
  func testLocalAlarmEmptyAutomaticHitRegionAudit() throws {
    launchLocalAlarmAudit();localAlarmDeletes.firstMatch.tap()
    XCTAssertEqual(localAlarmDeletes.count,0)
    try auditLocalAlarmHitRegions("empty")
  }
  private func tapLocalAlarmEdge(_ button:XCUIElement,bottom:Bool=false) {
    XCTAssertTrue(button.waitForExistence(timeout:5))
    if button.identifier.hasPrefix("alarm.delete.") || button.identifier.hasPrefix("alarm.toggle.") {
      let scroll=app.scrollViews.firstMatch,viewport=app.otherElements["reference.viewport"]
      for _ in 0..<10 {
        let safe=scroll.frame.intersection(viewport.frame).insetBy(dx:0,dy:2),target=button.frame
        if safe.contains(target) { break }
        let gap=target.minY<safe.minY ? -(safe.minY-target.minY+3):target.maxY-safe.maxY+3
        let distance=min(max(abs(gap),12),safe.height*0.5)*(gap<0 ? -1:1)
        let start=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:safe.minX+8,dy:safe.midY+distance/2))
        let end=app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:safe.minX+8,dy:safe.midY-distance/2))
        start.press(forDuration:0.1,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.2)
      }
    }
    let frame=button.frame,viewport=app.otherElements["reference.viewport"].frame
    let data:[String:Any]=["identifier":button.identifier,"label":button.label,
      "frame":[Double(frame.minX),Double(frame.minY),Double(frame.width),Double(frame.height)],
      "viewport":[Double(viewport.minX),Double(viewport.minY),Double(viewport.width),Double(viewport.height)],
      "edge":bottom ? "bottom":"top","hittable":button.isHittable]
    let geometry=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    geometry.name="alarm-edge-"+button.identifier.replacingOccurrences(of:".",with:"-")+"-"+(bottom ? "bottom":"top")
    geometry.lifetime = .keepAlways;add(geometry)
    XCTAssertTrue(viewport.contains(frame))
    if button.identifier.hasPrefix("alarm.delete.") || button.identifier.hasPrefix("alarm.toggle.") {
      XCTAssertTrue(app.scrollViews.firstMatch.frame.intersection(viewport).contains(frame),
        "Alarm target must be inside the actual unclipped list, not only the outer viewport")
    }
    tapRecipeTargetEdge(button,bottom:bottom)
  }
  func testLocalAlarmAddToggleDeleteAndCloseActualEdges() {
    launchLocalAlarmAudit()
    let initialToggle=localAlarmToggles.firstMatch
    XCTAssertTrue(initialToggle.label.contains("07:00"))
    XCTAssertEqual(initialToggle.value as? String,"Off")
    let initialDelete="alarm.delete."+initialToggle.identifier.dropFirst("alarm.toggle.".count)
    viewportShot("alarm-hit-region-before-edge-actions")
    tapLocalAlarmEdge(initialToggle)
    XCTAssertEqual(initialToggle.value as? String,"On")
    XCTAssertTrue(app.staticTexts["Foreground alarm"].exists)
    XCTAssertFalse(app.staticTexts["Off"].exists)
    tapLocalAlarmEdge(initialToggle,bottom:true)
    XCTAssertEqual(initialToggle.value as? String,"Off")
    XCTAssertTrue(app.staticTexts["Off"].exists)
    XCTAssertFalse(app.staticTexts["Foreground alarm"].exists)
    tapLocalAlarmEdge(app.buttons["alarm.add"])
    XCTAssertEqual(localAlarmDeletes.count,2)
    XCTAssertTrue(app.staticTexts["Foreground alarm"].exists)
    let added=localAlarmDeletes.allElementsBoundByIndex.filter {$0.identifier != initialDelete}
    XCTAssertEqual(added.count,1)
    viewportShot("alarm-hit-region-added-local-before-delete")
    tapLocalAlarmEdge(added[0],bottom:true)
    XCTAssertEqual(localAlarmDeletes.count,1)
    XCTAssertTrue(app.buttons[initialDelete].exists)
    XCTAssertFalse(app.staticTexts["Foreground alarm"].exists)
    tapLocalAlarmEdge(app.buttons[initialDelete])
    XCTAssertEqual(localAlarmDeletes.count,0)
    tapLocalAlarmEdge(app.buttons["alarm.add"],bottom:true)
    XCTAssertEqual(localAlarmDeletes.count,1)
    XCTAssertTrue(app.staticTexts["Foreground alarm"].exists)
    XCTAssertFalse(app.staticTexts["System alert enabled"].exists)
    viewportShot("alarm-hit-region-after-edge-actions")
    tapLocalAlarmEdge(app.buttons["close"])
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
  }
}

extension HomeViewUITests {
  private func launchLocalRemindersAudit() {
    launch();drawer();tap("app.Reminders");tap("profile.Alex")
    XCTAssertTrue(app.buttons["reminder.Pick up groceries"].exists)
    XCTAssertTrue(app.buttons["reminder.Water the plants"].exists)
    XCTAssertFalse(app.buttons["device.reminder.add"].exists)
  }
  private func auditLocalReminderHitRegions(_ state:String) throws {
    viewportShot("reminder-hit-region-"+state)
    var reports:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let element=issue.element,frame=element?.frame ?? .zero
      reports.append(["identifier":element?.identifier ?? "","label":element?.label ?? "",
        "frame":[Double(frame.minX),Double(frame.minY),Double(frame.width),Double(frame.height)],
        "auditType":issue.auditType.rawValue,"description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let attachment=XCTAttachment(data:try JSONSerialization.data(withJSONObject:reports,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    attachment.name="reminder-hit-region-"+state+"-all-findings";attachment.lifetime = .keepAlways;add(attachment)
    XCTAssertTrue(reports.isEmpty,"Unfiltered local reminder hit-region audit found \(reports.count) issues: \(reports)")
  }
  func testLocalRemindersInitialAutomaticHitRegionAudit() throws {
    launchLocalRemindersAudit();try auditLocalReminderHitRegions("initial")
  }
  func testLocalRemindersEmptyAutomaticHitRegionAudit() throws {
    launchLocalRemindersAudit();app.buttons["Delete Pick up groceries"].tap();app.buttons["Delete Water the plants"].tap()
    XCTAssertFalse(app.buttons["reminder.Pick up groceries"].exists)
    XCTAssertFalse(app.buttons["reminder.Water the plants"].exists)
    try auditLocalReminderHitRegions("empty")
  }
  func testLocalRemindersKeyboardAutomaticHitRegionAudit() throws {
    launchLocalRemindersAudit()
    let input=app.textFields["reminder.input"];input.tap();input.typeText("SYNTHETIC EDGE ITEM")
    XCTAssertTrue(app.keyboards.firstMatch.exists)
    XCTAssertEqual(input.value as? String,"SYNTHETIC EDGE ITEM")
    try auditLocalReminderHitRegions("keyboard-draft")
  }
  private func tapLocalReminderEdge(_ element:XCUIElement,bottom:Bool=false) {
    XCTAssertTrue(element.waitForExistence(timeout:5))
    let f=element.frame,v=app.otherElements["reference.viewport"].frame
    let data:[String:Any]=["identifier":element.identifier,"label":element.label,
      "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
      "viewport":[Double(v.minX),Double(v.minY),Double(v.width),Double(v.height)],
      "edge":bottom ? "bottom":"top","hittable":element.isHittable]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="reminder-edge-"+element.identifier.replacingOccurrences(of:".",with:"-")+"-"+(bottom ? "bottom":"top")
    a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(v.contains(f));tapRecipeTargetEdge(element,bottom:bottom)
  }
  func testLocalRemindersDeleteCompleteInputAddAndCloseActualEdges() {
    launchLocalRemindersAudit();viewportShot("reminder-hit-region-before-edge-actions")
    tapLocalReminderEdge(app.buttons["Delete Pick up groceries"])
    XCTAssertFalse(app.buttons["reminder.Pick up groceries"].exists)
    let water=app.buttons["reminder.Water the plants"]
    XCTAssertTrue(water.exists)
    tapLocalReminderEdge(water);XCTAssertEqual(water.value as? String,"Completed")
    tapLocalReminderEdge(water,bottom:true);XCTAssertEqual(water.value as? String,"Not completed")
    tapLocalReminderEdge(app.buttons["Delete Water the plants"],bottom:true)
    XCTAssertFalse(water.exists)
    let input=app.textFields["reminder.input"]
    tapLocalReminderEdge(input);input.typeText("SYNTHETIC EDGE ITEM")
    XCTAssertTrue(app.keyboards.firstMatch.exists)
    viewportShot("reminder-hit-region-keyboard-before-add")
    tapLocalReminderEdge(app.buttons["reminder.add"])
    XCTAssertTrue(app.buttons["reminder.SYNTHETIC EDGE ITEM"].waitForExistence(timeout:5))
    XCTAssertEqual(input.value as? String,"New reminder")
    tapLocalReminderEdge(app.buttons["Delete SYNTHETIC EDGE ITEM"],bottom:true)
    XCTAssertFalse(app.buttons["reminder.SYNTHETIC EDGE ITEM"].exists)
    viewportShot("reminder-hit-region-empty-after-edge-actions")
    tapLocalReminderEdge(app.buttons["close"],bottom:true)
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
  }
}

extension HomeViewUITests {
  private func launchLocalCalendarAudit() {
    launch(["--face","Calendar","--page","Calendar","--reference-date","2026-12-31T23:30:00Z",
      "--reference-zone","Pacific/Kiritimati"])
    XCTAssertTrue(app.staticTexts["January"].exists)
    XCTAssertEqual(app.buttons["calendar.day.5"].value as? String,"Selected")
    XCTAssertFalse(app.buttons["calendar.refresh"].exists)
    let days=[27,28,29,30,31,1,2]
    for i in 0..<7 {XCTAssertTrue(app.buttons["calendar.day.\(i)"].staticTexts[String(days[i])].exists)}
  }
  private func auditLocalCalendarHitRegions(_ state:String) throws {
    viewportShot("calendar-hit-region-"+state)
    var reports:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let element=issue.element,frame=element?.frame ?? .zero
      reports.append(["identifier":element?.identifier ?? "","label":element?.label ?? "",
        "frame":[Double(frame.minX),Double(frame.minY),Double(frame.width),Double(frame.height)],
        "auditType":issue.auditType.rawValue,"description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let a=XCTAttachment(data:try JSONSerialization.data(withJSONObject:reports,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="calendar-hit-region-"+state+"-all-findings";a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(reports.isEmpty,"Unfiltered local calendar hit-region audit found \(reports.count) issues: \(reports)")
  }
  func testLocalCalendarInitialAutomaticHitRegionAudit() throws {
    launchLocalCalendarAudit();try auditLocalCalendarHitRegions("local-january1")
  }
  func testLocalCalendarPreviousYearSelectedAutomaticHitRegionAudit() throws {
    launchLocalCalendarAudit();tap("calendar.day.0")
    XCTAssertEqual(app.buttons["calendar.day.0"].value as? String,"Selected")
    XCTAssertFalse(app.staticTexts["CANCELED: Coffee with Jamie"].exists)
    try auditLocalCalendarHitRegions("selected-december27")
  }
  private func tapLocalCalendarEdge(_ element:XCUIElement,bottom:Bool=false) {
    let f=element.frame,v=app.otherElements["reference.viewport"].frame
    let data:[String:Any]=["identifier":element.identifier,"label":element.label,
      "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
      "viewport":[Double(v.minX),Double(v.minY),Double(v.width),Double(v.height)],
      "edge":bottom ? "bottom":"top","hittable":element.isHittable]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="calendar-edge-"+element.identifier.replacingOccurrences(of:".",with:"-")+"-"+(bottom ? "bottom":"top")
    a.lifetime = .keepAlways;add(a);XCTAssertTrue(v.contains(f));tapRecipeTargetEdge(element,bottom:bottom)
  }
  func testLocalCalendarAllDayEdgesKeepSelectionAndLocalToday() {
    launchLocalCalendarAudit();viewportShot("calendar-hit-region-before-edge-actions")
    for i in 0..<7 {
      if i>0 {XCTAssertLessThanOrEqual(app.buttons["calendar.day.\(i-1)"].frame.maxX,app.buttons["calendar.day.\(i)"].frame.minX)}
      tapLocalCalendarEdge(app.buttons["calendar.day.\(i)"])
      for j in 0..<7 {XCTAssertEqual(app.buttons["calendar.day.\(j)"].value as? String,j==i ? "Selected":"")}
      XCTAssertEqual(app.staticTexts["CANCELED: Coffee with Jamie"].exists,i==5)
    }
    viewportShot("calendar-hit-region-selected-january2")
    tapLocalCalendarEdge(app.buttons["calendar.day.0"],bottom:true)
    XCTAssertEqual(app.buttons["calendar.day.0"].value as? String,"Selected")
    XCTAssertNotEqual(app.buttons["calendar.day.6"].value as? String,"Selected")
    viewportShot("calendar-hit-region-selected-december27-after-edge")
    tapLocalCalendarEdge(app.buttons["close"],bottom:true)
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
    tap("nav.faces")
    XCTAssertEqual(app.staticTexts["calendar.face.selected"].label,"1")
    XCTAssertEqual(app.staticTexts["calendar.face.selected"].value as? String,"Today")
    XCTAssertTrue(app.staticTexts["January 2027"].exists)
    viewportShot("calendar-hit-region-face-local-today-preserved")
  }
}

extension HomeViewUITests {
  private func launchPausedDemoMusicAudit() {
    launch(["--page","Music"])
    XCTAssertTrue(app.buttons["music.artwork.info.demo"].exists)
    XCTAssertFalse(app.buttons["music.artwork.info.catalog"].exists)
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    XCTAssertTrue(app.staticTexts["FEVER DREAM"].exists)
  }
  private func auditDemoMusicHitRegions(_ state:String) throws {
    if state=="information" {shot("demo-music-hit-region-"+state)}
    else {viewportShot("demo-music-hit-region-"+state)}
    var reports:[[String:Any]]=[]
    try app.performAccessibilityAudit(for:.hitRegion) { issue in
      let element=issue.element,frame=element?.frame ?? .zero
      reports.append(["identifier":element?.identifier ?? "","label":element?.label ?? "",
        "frame":[Double(frame.minX),Double(frame.minY),Double(frame.width),Double(frame.height)],
        "auditType":issue.auditType.rawValue,"description":issue.compactDescription,"detail":issue.detailedDescription])
      return true
    }
    let a=XCTAttachment(data:try JSONSerialization.data(withJSONObject:reports,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="demo-music-hit-region-"+state+"-all-findings";a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(reports.isEmpty,"Unfiltered demo music hit-region audit found \(reports.count) issues: \(reports)")
  }
  func testDemoMusicPausedAutomaticHitRegionAudit() throws {
    launchPausedDemoMusicAudit();try auditDemoMusicHitRegions("paused")
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
  }
  func testDemoMusicLibraryAutomaticHitRegionAudit() throws {
    launchPausedDemoMusicAudit();app.buttons["Music library"].tap()
    for title in ["FEVER DREAM","A Little Sunshine","Evening Light"] {XCTAssertTrue(app.staticTexts[title].exists)}
    XCTAssertFalse(app.buttons["player.play"].exists)
    // Deliberately do not select a library row: those actions start demo audio.
    try auditDemoMusicHitRegions("library")
  }
  func testDemoMusicInformationAutomaticHitRegionAudit() throws {
    launchPausedDemoMusicAudit();tap("music.artwork.info.demo")
    XCTAssertEqual(app.staticTexts["music.artwork.source"].label,"Bundled demo player")
    try auditDemoMusicHitRegions("information")
    tap("music.artwork.done");XCTAssertEqual(app.buttons["player.play"].label,"Play")
  }
  private func tapDemoMusicEdge(_ element:XCUIElement,bottom:Bool=false) {
    let f=element.frame,v=app.otherElements["reference.viewport"].frame
    let data:[String:Any]=["identifier":element.identifier,"label":element.label,
      "frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],
      "viewport":[Double(v.minX),Double(v.minY),Double(v.width),Double(v.height)],
      "edge":bottom ? "bottom":"top","hittable":element.isHittable]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="demo-music-edge-"+element.label.replacingOccurrences(of:" ",with:"-")+"-"+(bottom ? "bottom":"top")
    a.lifetime = .keepAlways;add(a);XCTAssertTrue(v.contains(f));tapRecipeTargetEdge(element,bottom:bottom)
  }
  func testDemoMusicNavigationInformationAndCloseActualEdgesWithoutPlayback() {
    launchPausedDemoMusicAudit();viewportShot("demo-music-hit-region-before-edge-actions")
    tapDemoMusicEdge(app.buttons["player.next"])
    XCTAssertTrue(app.staticTexts["A Little Sunshine"].exists)
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    tapDemoMusicEdge(app.buttons["Previous track"],bottom:true)
    XCTAssertTrue(app.staticTexts["FEVER DREAM"].exists)
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    let play=app.buttons["player.play"],f=play.frame
    let geometry:[String:Any]=["identifier":play.identifier,"label":play.label,"frame":[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)],"hittable":play.isHittable,"activated":false]
    let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:geometry,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    a.name="demo-music-play-measured-not-activated";a.lifetime = .keepAlways;add(a)
    XCTAssertTrue(play.isHittable);XCTAssertGreaterThanOrEqual(f.width,44-1e-6);XCTAssertGreaterThanOrEqual(f.height,44-1e-6)
    let previous=app.buttons["Previous track"].frame,next=app.buttons["player.next"].frame
    XCTAssertLessThanOrEqual(previous.maxX,f.minX);XCTAssertLessThanOrEqual(f.maxX,next.minX)
    viewportShot("demo-music-hit-region-tracks-changed-still-paused")
    tapDemoMusicEdge(app.buttons["music.artwork.info.demo"])
    XCTAssertEqual(app.staticTexts["music.artwork.source"].label,"Bundled demo player")
    shot("demo-music-hit-region-information-after-edge")
    tap("music.artwork.done");XCTAssertEqual(app.buttons["player.play"].label,"Play")
    tapDemoMusicEdge(app.buttons["Music library"])
    for title in ["FEVER DREAM","A Little Sunshine","Evening Light"] {XCTAssertTrue(app.staticTexts[title].exists)}
    viewportShot("demo-music-hit-region-library-after-edge")
    tapDemoMusicEdge(app.buttons["close"],bottom:true)
    XCTAssertTrue(app.buttons["personal.photos.open"].waitForExistence(timeout:5))
  }
}

extension HomeViewUITests {
  func testDemoMusicProgressStaysReadableAndPassiveWithoutPlayback() {
    launchPausedDemoMusicAudit()
    let progress=app.descendants(matching:.any).matching(identifier:"player.progress").firstMatch
    XCTAssertTrue(progress.waitForExistence(timeout:5))
    XCTAssertEqual(progress.label,"Demo progress")
    XCTAssertEqual(progress.value as? String,"0 of 180 seconds")
    XCTAssertFalse(app.sliders["player.progress"].exists)
    XCTAssertFalse(app.buttons["player.progress"].exists)
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
    viewportShot("demo-music-hit-region-readable-passive-progress")
    tap("music.artwork.info.demo")
    XCTAssertEqual(app.staticTexts["music.artwork.source"].label,"Bundled demo player")
    // Separate the first display sample from a later sample. Accessibility
    // presence alone does not establish that presentation has visually settled.
    let began=ProcessInfo.processInfo.systemUptime
    func pose()->[String:[Double]] {
      var result:[String:[Double]]=[:]
      for (key,e) in [("app",app),("done",app.buttons["music.artwork.done"]),
        ("source",app.staticTexts["music.artwork.source"]),("footer",app.staticTexts["music.artwork.motion"])] {
        let f=e.frame;result[key]=[Double(f.minX),Double(f.minY),Double(f.width),Double(f.height)]
      }
      return result
    }
    let before=pose(),a=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
    a.name="immediate-display-demo-music-hit-region-information";a.lifetime = .keepAlways;add(a)
    RunLoop.current.run(until:Date().addingTimeInterval(2))
    let after=pose(),elapsed=ProcessInfo.processInfo.systemUptime-began
    XCTAssertTrue(app.buttons["music.artwork.done"].isHittable)
    let settled=XCTAttachment(screenshot:XCUIScreen.main.screenshot())
    settled.name="settled-display-demo-music-hit-region-information";settled.lifetime = .keepAlways;add(settled)
    let data:[String:Any]=["before":before,"after":after,"elapsed_seconds":elapsed,"declared_wait_seconds":2]
    let geometry=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:data,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
    geometry.name="demo-music-information-capture-poses";geometry.lifetime = .keepAlways;add(geometry)
    tap("music.artwork.done")
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
  }
}

extension HomeViewUITests {
  func testPodcastSourceCaptionsSelectionSeekOffAndSourceChange() {
    launch(["--page","Podcasts","--podcast-fixture","--podcast-caption-fixture","--mute-podcast-fixture"])
    tap("podcast.feeds");tap("podcast.feed.fixture")
    let episode=app.buttons["podcast.episode.0"]
    XCTAssertTrue(episode.waitForExistence(timeout:8));scrollPhotoControlFullyIntoView(episode);episode.tap()
    let captions=app.buttons["podcast.captions"]
    XCTAssertTrue(captions.exists)
    XCTAssertFalse(captions.isEnabled)
    XCTAssertTrue(app.staticTexts["podcast.status"].label.contains("Paused"))
    let play=app.buttons["podcast.play"]
    scrollPhotoControlFullyIntoView(play);play.tap()
    expectation(for:NSPredicate(format:"enabled == true"),evaluatedWith:captions)
    waitForExpectations(timeout:12)
    scrollPhotoControlFullyIntoView(captions);captions.tap()
    tap("podcast.captions.option.0")
    let cue=app.staticTexts["podcast.captions.current"]
    expectation(for:NSPredicate(format:"exists == true AND label CONTAINS %@","first marker"),evaluatedWith:cue)
    waitForExpectations(timeout:12)
    scrollPhotoControlFullyIntoView(play);play.tap()
    XCTAssertEqual(app.staticTexts["podcast.status"].label,"Paused")
    scrollPhotoControlFullyIntoView(cue);viewportShot("podcast-source-first-cue")
    scrollPhotoControlFullyIntoView(captions);captions.tap();tap("podcast.captions.off")
    XCTAssertFalse(cue.exists)
    XCTAssertEqual(captions.value as? String,"off")
    captions.tap();tap("podcast.captions.option.0")
    let forward=app.buttons["podcast.forward"]
    scrollPhotoControlFullyIntoView(forward)
    let back=app.buttons["podcast.back"]
    back.tap();back.tap();back.tap()
    XCTAssertEqual(podcastSeconds(),0)
    forward.tap();forward.tap();forward.tap()
    XCTAssertEqual(podcastSeconds(),45)
    play.tap()
    expectation(for:NSPredicate(format:"exists == true AND label CONTAINS %@","final marker"),evaluatedWith:cue)
    waitForExpectations(timeout:12)
    scrollPhotoControlFullyIntoView(cue);viewportShot("podcast-source-seek-final-cue")
    tap("podcast.feeds")
    let second=app.buttons["podcast.episode.1"]
    XCTAssertTrue(second.waitForExistence(timeout:5))
    for _ in 0..<8 where !second.isHittable {app.scrollViews.firstMatch.swipeUp()}
    // Last feed row: require full containment, not an unattainable extra
    // 40-point margin beyond the existing short feed's scroll-content end.
    XCTAssertTrue(app.scrollViews.firstMatch.frame.intersection(app.otherElements["reference.viewport"].frame).contains(second.frame))
    second.tap()
    XCTAssertFalse(cue.exists)
    scrollPhotoControlFullyIntoView(play);play.tap()
    let status=app.staticTexts["podcast.captions.status"]
    expectation(for:NSPredicate(format:"label == %@","No captions supplied by this episode."),evaluatedWith:status)
    waitForExpectations(timeout:12)
    XCTAssertFalse(captions.isEnabled);XCTAssertFalse(cue.exists)
    scrollPhotoControlFullyIntoView(status);viewportShot("podcast-source-no-invented-captions")
  }
}

extension HomeViewUITests {
  func testAlarmRecurrenceChoicesPersistWithoutSystemScheduling() {
    for title in ["Once", "Every day", "Mon–Fri", "Sat–Sun"] {
      let store=UUID().uuidString
      launch(["--page","Alarms","--persistence-test",store,"--reset-test-store"])
      let initial=localAlarmToggles.firstMatch.identifier
      tap("alarm.recurrence")
      let option=app.buttons[title].firstMatch
      XCTAssertTrue(option.waitForExistence(timeout:5));option.tap()
      tap("alarm.add")
      XCTAssertEqual(localAlarmToggles.count,2)
      let added=localAlarmToggles.allElementsBoundByIndex.first {$0.identifier != initial}!
      let suffix=String(added.identifier.dropFirst("alarm.toggle.".count))
      XCTAssertEqual(app.staticTexts["alarm.repeat."+suffix].label,title)
      XCTAssertEqual(added.value as? String,"On")
      XCTAssertFalse(app.staticTexts["System alert enabled"].exists)
      viewportShot("alarm-recurrence-"+title.replacingOccurrences(of:" ",with:"-"))
      app.terminate()
      launch(["--page","Alarms","--persistence-test",store])
      XCTAssertEqual(app.staticTexts["alarm.repeat."+suffix].label,title)
      XCTAssertEqual(app.buttons["alarm.toggle."+suffix].value as? String,"On")
      tap("alarm.toggle."+suffix)
      XCTAssertEqual(app.buttons["alarm.toggle."+suffix].value as? String,"Off")
      app.terminate()
      launch(["--page","Alarms","--persistence-test",store])
      XCTAssertEqual(app.buttons["alarm.toggle."+suffix].value as? String,"Off")
      XCTAssertEqual(app.staticTexts["alarm.repeat."+suffix].label,title)
      tap("alarm.toggle."+suffix)
      XCTAssertEqual(app.buttons["alarm.toggle."+suffix].value as? String,"On")
      tap("alarm.delete."+suffix)
      XCTAssertEqual(localAlarmToggles.count,1)
      app.terminate()
    }
  }
}


extension HomeViewUITests {
  private func verifyPresentedSnapshot(_ checkpoint:String,done:String,checkReturn:()->Void = {}) {
    XCTAssertTrue(app.buttons[done].waitForExistence(timeout:5))
    shot("switcher-sheets-"+checkpoint+"-before")
    calendarSwitcherCard(from:app,bounds:app.frame,checkpoint:checkpoint).tap()
    XCTAssertTrue(app.buttons[done].waitForExistence(timeout:5))
    shot("switcher-sheets-"+checkpoint+"-returned")
    checkReturn()
    tap(done)
  }
  func testNativeAppSwitcherCoversDetailAndEditorSheets() {
    continueAfterFailure=true
    launch(["--page","World Clock","--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("world.detail.open.Europe/Berlin")
    verifyPresentedSnapshot("world-detail",done:"world.detail.done")
    XCTAssertTrue(app.buttons["world.detail.open.Europe/Berlin"].exists)
    app.terminate();launchFaceEditorAudit("Modular")
    let slot=app.buttons["widget.0"];scrollEditorIntoView(slot);slot.tap()
    verifyPresentedSnapshot("complication-picker",done:"complications.done")
    XCTAssertTrue(app.buttons["editor.done"].exists)
    app.terminate();launch(["--page","Music","--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("music.artwork.info.demo")
    verifyPresentedSnapshot("artwork-info",done:"music.artwork.done")
    XCTAssertEqual(app.buttons["player.play"].label,"Play")
  }
  func testNativeAppSwitcherCoversControlAndSettingsSheets() {
    continueAfterFailure=true
    launch(["--persistence-test",UUID().uuidString,"--reset-test-store","--timer-activity-fixture"])
    openMockNotices();tap("notices.load");tap("notices.authenticate")
    XCTAssertTrue(app.staticTexts["Synthetic Alex arrived"].waitForExistence(timeout:5))
    verifyPresentedSnapshot("house-notices",done:"notices.done")
    tap("controls.settings")
    let power=app.buttons["settings.power"];scrollPhotoControlFullyIntoView(power);power.tap()
    verifyPresentedSnapshot("power-settings",done:"power.capabilities.done")
    openTimerActivitySettings()
    XCTAssertEqual(app.switches["timer.activity.enabled"].value as? String,"0")
    verifyPresentedSnapshot("timer-activity-settings",done:"timer.activity.done")
    openTimerActivitySettings()
    XCTAssertEqual(app.switches["timer.activity.enabled"].value as? String,"0")
    tap("timer.activity.done")
  }
  func testNativeAppSwitcherCoversAssistantSheetsWithoutSendingDraft() {
    continueAfterFailure=true
    launch(["--persistence-test",UUID().uuidString,"--reset-test-store","--answer-speech-fixture"])
    tap("nav.assistant")
    let input=app.textFields["assistant.input"],draft="OWNED_SHEETS_UNSENT_DRAFT"
    input.tap();input.typeText(draft)
    if app.buttons["assistant.keyboard.dismiss"].exists {tap("assistant.keyboard.dismiss")}
    tap("assistant.capabilities")
    verifyPresentedSnapshot("assistant-capabilities",done:"assistant.capabilities.done")
    XCTAssertEqual(input.value as? String,draft)
    tap("answer.speech.settings")
    verifyPresentedSnapshot("answer-readout-settings",done:"answer.speech.settings.done")
    XCTAssertEqual(input.value as? String,draft)
    selectAnswerExample("knowledge")
    activatePlanControl(app.buttons["assistant.card.source.museum"])
    verifyPresentedSnapshot("assistant-source",done:"assistant.card.source.done")
    XCTAssertEqual(input.value as? String,draft)
    XCTAssertFalse(app.staticTexts["assistant.exampleRecipe.title"].exists)
  }
  func testNativeAppSwitcherCoversSetupAndResetWithoutDeletion() {
    continueAfterFailure=true
    launch(["--page","Settings","--persistence-test",UUID().uuidString,"--reset-test-store"])
    tap("settings.introduction")
    verifyPresentedSnapshot("setup-introduction",done:"setup.later")
    openResetReview();authenticateSyntheticReset()
    let field=app.textFields["reset.confirmation"]
    scrollResetControlFullyIntoView(field);field.tap();field.typeText("NOT_RESET")
    XCTAssertFalse(app.buttons["reset.confirm"].isEnabled)
    verifyPresentedSnapshot("local-reset",done:"reset.cancel") {
      XCTAssertEqual(field.value as? String,"NOT_RESET")
      XCTAssertFalse(app.buttons["reset.confirm"].isEnabled)
    }
    XCTAssertFalse(app.staticTexts["settings.reset.status"].label.contains("Local app content reset"))
    XCTAssertTrue(app.buttons["settings.reset"].exists)
  }
}


extension HomeViewUITests {
  private func verifyRootInputSnapshot(_ field:XCUIElement,_ checkpoint:String) {
    XCTAssertTrue(field.waitForExistence(timeout:5))
    if !field.isHittable || !app.otherElements["reference.viewport"].frame.contains(field.frame) {
      scrollPhotoControlFullyIntoView(field)
    }
    field.tap();field.typeText("OWNEDPRIVATEINPUT")
    let draft=field.value as? String ?? ""
    XCTAssertTrue(draft.contains("OWNEDPRIVATEINPUT"))
    shot("switcher-root-"+checkpoint+"-before")
    calendarSwitcherCard(from:app,bounds:app.frame,checkpoint:"root-"+checkpoint).tap()
    XCTAssertTrue(field.waitForExistence(timeout:5));XCTAssertEqual(field.value as? String,draft)
    shot("switcher-root-"+checkpoint+"-returned-unsent")
  }
  private func launchRootInput(_ page:String) {
    launch(["--page",page,"--persistence-test",UUID().uuidString,"--reset-test-store"])
  }
  func testSnapshotProtectsUnsentDemoMessageField() {
    launchRootInput("Messages")
    verifyRootInputSnapshot(app.textFields["Demo message"],"message")
    XCTAssertFalse(app.staticTexts["OWNEDPRIVATEINPUT"].exists)
  }
  func testSnapshotProtectsUncalledFaceTimeRecipientField() {
    launchRootInput("FaceTime")
    verifyRootInputSnapshot(app.textFields["facetime.recipient"],"facetime")
    XCTAssertFalse(app.staticTexts["FaceTime not opened in tests"].exists)
  }
  func testSnapshotProtectsUnsentIntercomField() {
    launchRootInput("Intercom")
    verifyRootInputSnapshot(app.textFields["intercom.input"],"intercom")
    XCTAssertFalse(app.staticTexts["Dinner is ready!OWNEDPRIVATEINPUT"].exists)
  }
  func testSnapshotProtectsUnselectedWorldClockQueryField() {
    launchRootInput("World Clock");tap("world.add")
    verifyRootInputSnapshot(app.textFields["world.search"],"world-query")
    XCTAssertTrue(app.buttons["world.add"].exists)
  }
  func testSnapshotProtectsUnaddedLocalReminderField() {
    launchRootInput("Reminders")
    verifyRootInputSnapshot(app.textFields["reminder.input"],"local-reminder")
    XCTAssertFalse(app.buttons["reminder.OWNEDPRIVATEINPUT"].exists)
  }
  func testSnapshotProtectsUnfetchedPodcastFeedField() {
    launchRootInput("Podcasts");tap("podcast.feeds")
    verifyRootInputSnapshot(app.textFields["podcast.feed.url"],"podcast-url")
  }
  func testSnapshotProtectsUnsubmittedMusicSearchField() {
    launchRootInput("Settings");connectService("Apple Music")
    drawer();tap("app.Music")
    verifyRootInputSnapshot(app.textFields["music.search.input"],"music-query")
    XCTAssertFalse(app.buttons["music.result.0"].exists)
  }
  func testSnapshotProtectsUnsubmittedSettingsCityField() {
    launchRootInput("Settings")
    verifyRootInputSnapshot(app.textFields["weather.city"],"settings-city")
  }
  func testSnapshotProtectsUnloadedBrowserAddressField() {
    launchLocalBrowserAudit()
    verifyRootInputSnapshot(app.textFields["browser.address"],"browser-address")
  }
}

extension HomeViewUITests {
  func testNativeMessageReadOnlyQualificationAndRestore()throws {
    continueAfterFailure=true;executionTimeAllowance=180
    guard #available(iOS 27.0,*) else {XCTFail("Native VoiceOver service requires iOS27");return}
    let service=XCUIDevice.shared.voiceOverService,original=service.isEnabled
    var events:[[String:Any]]=[],restored=false
    func normalized(_ text:String)->String {text.lowercased().components(separatedBy:CharacterSet.alphanumerics.inverted).joined()}
    func record(_ event:String,_ fields:[String:Any]=[:]) {var row=fields;row["event"]=event;events.append(row)}
    defer {
      do {
        if service.isEnabled != original {if original {try service.enable()} else {try service.disable()}}
        restored=service.isEnabled==original;XCTAssertTrue(restored)
        record("restored",["original":original,"enabled":service.isEnabled,"matches_original":restored])
      } catch {XCTFail("Restore original owned-simulator VoiceOver state")}
      let report:[String:Any]=["events":events,"restored":restored,
        "scope":"Actual native short read-only/fictional/sender qualification plus separate full AX source fields. Native output reporter previously observed64character prefix even for independent UIKit. No whole-body/timestamp spoken, raw activation, acoustic or original-parity PASS."]
      let a=XCTAttachment(data:try! JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),uniformTypeIdentifier:"public.json")
      a.name="native-message-readonly-qualification";a.lifetime = .keepAlways;add(a)
    }
    if service.isEnabled {try service.disable()}
    launch(["--persistence-test",UUID().uuidString,"--reset-test-store"]);tap("nav.assistant")
    let field=app.textFields["assistant.input"],draft="temperature 91"
    field.tap();field.typeText(draft);selectAnswerExample("message")
    let card=responseElement("assistant.card.message");revealPlanControl(card)
    let label=card.label
    record("actual-full-AX-card",["label":label,"characters":label.count])
    for value in ["Avery Morgan","Today, 9:41 AM","I’ll arrive at Central Station at 6:30 PM on Friday, October 16."] {
      XCTAssertTrue(label.contains(value),"Preserve complete declared source field in the AX label")
    }
    XCTAssertTrue(normalized(label).contains(normalized("Read-only excerpt")),"Visible read-only qualifier must not disappear from the ignored-child accessible element")
    viewportShot("native-message-qualifier-before-voiceover",assistantRectangle:true)
    try service.enable();XCTAssertTrue(service.isEnabled)
    record("native-enabled",["enabled":service.isEnabled])
    var target:String?
    let deadline=ProcessInfo.processInfo.systemUptime+45
    for _ in 0..<32 {
      guard ProcessInfo.processInfo.systemUptime<deadline else {break}
      let speech=try service.moveForward().utterance;record("move-forward",["utterance":speech,"characters":speech.count])
      if normalized(speech).contains(normalized("Fictional message")),speech.contains("Avery Morgan") {target=speech;break}
    }
    guard let target else {XCTFail("Native focus did not reach the fictional message card");return}
    let readonly=normalized(target).contains(normalized("Read-only excerpt"))
    record("target-native-qualification",["utterance":target,"characters":target.count,"read_only_reported":readonly])
    XCTAssertTrue(readonly,"Native focused card must identify the read-only nature, not merely sender/time")
    let anchor=try service.currentSpeech().utterance
    record("move-backward",["utterance":try service.moveBackward().utterance])
    let returned=try service.moveForward().utterance;record("move-forward-return",["utterance":returned])
    XCTAssertEqual(normalized(returned),normalized(anchor))
    XCTAssertEqual(field.value as? String,draft,"Reading must not submit or lose the draft")
    XCTAssertFalse(app.buttons["assistant.card.message"].exists,"The excerpt remains non-executable")
    viewportShot("native-message-qualifier-focused",assistantRectangle:true)
    try service.disable();XCTAssertFalse(service.isEnabled)
    tap("nav.faces");tap("home.thermostat")
    XCTAssertEqual(app.staticTexts["thermostat.value"].label,"68°","No unsent command execution")
  }
}
