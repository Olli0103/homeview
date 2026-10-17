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
    XCTAssertEqual(result.coverage, 0)
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
