import XCTest
#if canImport(CoreImage)
import CoreImage
#endif
@testable import HomeViewCore

final class PhotoPlacementTests: XCTestCase {
  private func mask(_ fill: (Int, Int) -> UInt8) -> PhotoSubjectMask {
    PhotoSubjectMask(width: 100, height: 100,
                     values: (0..<10_000).map { fill($0 % 100, $0 / 100) })!
  }
  func testSparseRealMatteAllowsFullHeightWithUnchangedOcclusionLimit() {
    let subject=mask { x,y in x>=10 && x<22 && y>=10 && y<48 ? 255:0 }
    let result=PhotoPlacement.choose(aspect:1,mask:subject,foregroundAvailable:true)
    XCTAssertTrue(result.depthEnabled)
    XCTAssertEqual(result.clockRect,.init(x:0.05,y:0.05,width:0.9,height:0.9))
    XCTAssertEqual(result.coverage,subject.coverage(result.clockRect),accuracy:0.000001)
    XCTAssertLessThanOrEqual(result.coverage,0.18)
  }
  func testLargerClockNeverUsesFaceBoxesOrAnEmptyMatteAsAlpha() {
    let sparse=mask { x,y in x<15 && y<40 ? 255:0 }
    for (subject,available) in [(sparse,false),(nil,true),(mask { _,_ in 0 },true)] {
      let result=PhotoPlacement.choose(aspect:1,mask:subject,
        protectedRegions:[.init(x:0.1,y:0.1,width:0.12,height:0.38)],foregroundAvailable:available)
      XCTAssertNil(result.clockFrame)
      XCTAssertEqual(result.clockRect,result.clock.rect)
      XCTAssertFalse(result.depthEnabled)
    }
  }
  func testExplicitManualClockAndLetterboxKeepTheExistingBand() {
    let sparse=mask { x,y in x<12 && y<40 ? 255:0 }
    let manual=PhotoPlacement.choose(aspect:1,mask:sparse,
      adjustment:.init(clock:.bottom))
    XCTAssertTrue(manual.depthEnabled)
    XCTAssertNil(manual.clockFrame)
    XCTAssertEqual(manual.clockRect,PhotoClockPosition.bottom.rect)
    let manualCrop=PhotoPlacement.choose(aspect:1,mask:sparse,
      adjustment:.init(automaticCrop:false))
    XCTAssertNil(manualCrop.clockFrame)
    XCTAssertEqual(manualCrop.clockRect,manualCrop.clock.rect)
    let edges=mask { x,y in (x<10 || x>90) && y>35 && y<65 ? 255:0 }
    let letterbox=PhotoPlacement.choose(aspect:2,mask:edges)
    XCTAssertNotEqual(letterbox.destination,.full)
    XCTAssertNil(letterbox.clockFrame)
  }
  func testExpandedCoverageUsesTheSameSelectedSourceCrop() {
    let left=mask { x,y in x<12 && y>35 && y<65 ? 255:0 }
    let result=PhotoPlacement.choose(aspect:2,mask:left)
    XCTAssertEqual(result.crop.x,0)
    XCTAssertEqual(result.retention,1)
    XCTAssertNotNil(result.clockFrame)
    let rect=result.clockRect
    let source=PhotoRect(x:result.crop.x+rect.x*result.crop.width,
      y:result.crop.y+rect.y*result.crop.height,
      width:rect.width*result.crop.width,height:rect.height*result.crop.height)
    XCTAssertEqual(result.coverage,left.coverage(source),accuracy:0.000001)
    XCTAssertLessThanOrEqual(result.coverage,0.18)
  }
  func testOpaqueClockAvoidsDetectedHeadWhenNoMatteExists() {
    let head=PhotoRect(x:0.3,y:0.14,width:0.4,height:0.42)
    let result=PhotoPlacement.choose(aspect:1,mask:nil,protectedRegions:[head],foregroundAvailable:false)
    XCTAssertEqual(result.protectedCoverage,0)
    XCTAssertFalse(result.depthEnabled)
    XCTAssertEqual(result.retention,1)
    XCTAssertEqual(result.clock.rect.intersection(head).area,0)
  }
  func testRectangularProtectionKeepsBothEdgeHeadsWithoutAFalseMask() {
    let heads=[PhotoRect(x:0.02,y:0.25,width:0.1,height:0.4),
               PhotoRect(x:0.88,y:0.25,width:0.1,height:0.4)]
    let result=PhotoPlacement.choose(aspect:2,mask:nil,protectedRegions:heads,foregroundAvailable:false)
    XCTAssertEqual(result.crop,.full)
    XCTAssertNotEqual(result.destination,.full)
    XCTAssertEqual(result.retention,1)
    XCTAssertEqual(result.protectedCoverage,0)
    XCTAssertFalse(result.depthEnabled)
  }
  func testNoUnobstructedOverlayPreservesWholeImageBelowClockBand() {
    let result=PhotoPlacement.choose(aspect:1,mask:nil,protectedRegions:[.full],foregroundAvailable:false)
    XCTAssertEqual(result.crop,.full)
    XCTAssertEqual(result.retention,1)
    XCTAssertNotEqual(result.destination,.full)
    XCTAssertEqual(result.clock.rect.intersection(result.destination).area,0)
    XCTAssertEqual(result.protectedCoverage,0)
    XCTAssertFalse(result.depthEnabled)
  }
  func testMissingForegroundLayerNeverClaimsDepthFromAMaskAlone() {
    let sparse=mask { _,y in y>80 ? 255:0 }
    let result=PhotoPlacement.choose(aspect:1,mask:sparse,foregroundAvailable:false)
    XCTAssertEqual(result.coverage,0)
    XCTAssertFalse(result.depthEnabled)
  }
  func testIntegralCoverageMatchesKnownSoftMaskAndClipsInvalidRectangles() {
    let mask = mask { x, _ in x < 50 ? 255 : 128 }
    XCTAssertEqual(mask.coverage(.init(x: 0, y: 0, width: 0.5, height: 1)), 1)
    XCTAssertEqual(mask.coverage(.full), (255+128)/510.0, accuracy: 0.00001)
    XCTAssertEqual(mask.coverage(.init(x: -2, y: 0, width: 2.5, height: 1)), 1)
    XCTAssertEqual(mask.coverage(.init(x: .nan, y: 0, width: 1, height: 1)), 0)
    XCTAssertNil(PhotoSubjectMask(width: Int.max, height: 1, values: []))
    XCTAssertNil(PhotoSubjectMask(width: 2, height: 2, values: [0]))
  }
  func testClockMovesAwayFromTopSubjectAndDenseMaskDisablesDepth() {
    let top = mask { _, y in y < 43 ? 255 : 0 }
    let result = PhotoPlacement.choose(aspect: 1, mask: top)
    XCTAssertEqual(result.clock, .bottom)
    // The selected bottom anchor now safely uses the medium matte-backed band.
    XCTAssertEqual(result.clockRect.height,0.56)
    XCTAssertEqual(result.clockRect,.init(x:0.05,y:0.39,width:0.9,height:0.56))
    // Summed-area sampling conservatively floors/ceils source pixels. Check
    // the expanded source rectangle, not the former compact zero-overlap band.
    XCTAssertEqual(result.coverage,top.coverage(result.clockRect),accuracy:0.000001)
    XCTAssertGreaterThan(result.coverage,0)
    XCTAssertLessThanOrEqual(result.coverage,0.18)
    XCTAssertTrue(result.depthEnabled)
    let dense = PhotoPlacement.choose(aspect: 1, mask: mask { _, _ in 255 })
    XCTAssertEqual(dense.clock, .top)
    XCTAssertFalse(dense.depthEnabled)
  }
  func testLandscapeCropKeepsOffCenterSubject() {
    let left = mask { x, y in x < 12 && y > 35 && y < 65 ? 255 : 0 }
    let result = PhotoPlacement.choose(aspect: 2, mask: left)
    XCTAssertEqual(result.crop.x, 0)
    XCTAssertEqual(result.crop.width, 0.5)
    XCTAssertEqual(result.retention, 1)
  }
  func testMultipleEdgeSubjectsUseCompleteImageInsteadOfCuttingOneOut() {
    let edges = mask { x, y in (x < 10 || x > 90) && y > 35 && y < 65 ? 255 : 0 }
    let result = PhotoPlacement.choose(aspect: 2, mask: edges)
    XCTAssertEqual(result.crop, .full)
    XCTAssertEqual(result.destination, .init(x: 0, y: 0.25, width: 1, height: 0.5))
    XCTAssertEqual(result.retention, 1)
  }
  func testAutomaticFramingNeverTradesSubjectRetentionForLessClockOverlap() {
    for offset in 0..<20 {
      let subjects = mask { x, y in
        let main = x >= 26 && x <= 65 && y >= offset && y < 100-offset
        let secondary = x >= 70 && x < 73 && y >= 20 && y < 30
        return main || secondary ? 255 : 0
      }
      let result = PhotoPlacement.choose(aspect: 2, mask: subjects)
      XCTAssertGreaterThanOrEqual(result.retention, 0.985)
    }
  }
  func testManualPositionAndCropWinAndNonFiniteOffsetsAreSanitized() {
    let top = mask { _, y in y < 43 ? 255 : 0 }
    let manual = PhotoAdjustment(clock: .top, automaticCrop: false, horizontal: .nan, vertical: 4)
    let result = PhotoPlacement.choose(aspect: 0.5, mask: top, adjustment: manual)
    XCTAssertEqual(result.clock, .top)
    XCTAssertEqual(result.crop.y, 0.5)
    XCTAssertTrue(result.coverage.isFinite)
    XCTAssertEqual(PhotoPlacement.choose(aspect: .infinity, mask: top), .init())
  }
  func testEmptyMaskAndMissingMaskChooseStableCenteredTopLayout() {
    for mask in [nil, self.mask { _, _ in 0 }] {
      let first = PhotoPlacement.choose(aspect: 2, mask: mask)
      XCTAssertEqual(first.crop, .init(x: 0.25, y: 0, width: 0.5, height: 1))
      XCTAssertEqual(first.clock, .top)
      XCTAssertFalse(first.depthEnabled)
      XCTAssertEqual(first, PhotoPlacement.choose(aspect: 2, mask: mask))
    }
  }
  func testPerPhotoManualAdjustmentSurvivesSnapshotAndLegacyDefaults() throws {
    var snapshot = Snapshot()
    snapshot.home.temperature = 72
    snapshot.photoAdjustments["synthetic-photo"] = .init(clock: .bottom, automaticCrop: false,
                                                         horizontal: 0.25, vertical: 0.75)
    let encoded = try JSONEncoder().encode(snapshot)
    let restored = try Snapshot.decodeMigrating(encoded)
    XCTAssertEqual(restored.photoAdjustments["synthetic-photo"]?.clock, .bottom)
    XCTAssertEqual(restored.photoAdjustments["synthetic-photo"]?.vertical, 0.75)
    var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    legacy.removeValue(forKey: "photoAdjustments")
    let migrated = try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject: legacy))
    XCTAssertTrue(migrated.photoAdjustments.isEmpty)
    XCTAssertEqual(migrated.home.temperature, 72)
  }
  func testMalformedPhotoOverridesDoNotResetHomeAndLargeTablesAreBounded() throws {
    var snapshot = Snapshot()
    snapshot.home.temperature = 74
    var raw = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot)) as? [String: Any])
    raw["photoAdjustments"] = ["photo": ["clock": "future-style", "horizontal": 9, "vertical": "bad"]]
    let restored = try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject: raw))
    XCTAssertEqual(restored.home.temperature, 74)
    XCTAssertEqual(restored.photoAdjustments["photo"]?.clock, .automatic)
    XCTAssertEqual(restored.photoAdjustments["photo"]?.horizontal, 1)
    XCTAssertEqual(restored.photoAdjustments["photo"]?.vertical, 0.5)
    raw["photoAdjustments"] = "not a table"
    XCTAssertTrue(try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject: raw)).photoAdjustments.isEmpty)
    raw["photoAdjustments"] = Dictionary(uniqueKeysWithValues: (0..<200).map { ("photo-\($0)", ["clock": "top"]) })
    XCTAssertEqual(try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject: raw)).photoAdjustments.count, 100)
  }
  #if canImport(CoreImage)
  func testCoreImageMaskTopRowIsNotVerticallyMirrored() throws {
    let background = CIImage(color: .black).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 200))
    let top = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 140, width: 100, height: 60))
    let mask = try XCTUnwrap(PhotoMaskRasterizer.make(top.composited(over: background),
                                                   context: CIContext(options: [.useSoftwareRenderer: true])))
    XCTAssertEqual(mask.coverage(.init(x: 0, y: 0, width: 1, height: 0.2)), 1, accuracy: 0.01)
    XCTAssertEqual(mask.coverage(.init(x: 0, y: 0.8, width: 1, height: 0.2)), 0, accuracy: 0.01)
  }
  #endif
}
