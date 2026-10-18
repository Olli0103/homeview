import XCTest
@testable import HomeViewCore

final class PhotoClockInkTests: XCTestCase {
  private func raster(_ values: [UInt8], width: Int = 4, height: Int = 4) -> PhotoClockInkRaster {
    PhotoClockInkRaster(width:width,height:height,values:values)!
  }
  private func mask(_ values: [UInt8], width: Int = 4, height: Int = 4) -> PhotoSubjectMask {
    PhotoSubjectMask(width:width,height:height,values:values)!
  }
  func testSharedGeometryUsesNarrowOneAndPreservesBandEdges() throws {
    let band = PhotoRect(x:0.05,y:0.39,width:0.90,height:0.56)
    let frames = try XCTUnwrap(PhotoClockGlyphLayout.frames(digits:[1,0,0,9],in:band))
    XCTAssertEqual(frames[0].rect.width/frames[1].rect.width,0.75,accuracy:0.000001)
    XCTAssertEqual(frames[0].rect.x,band.x)
    XCTAssertEqual(frames[3].rect.x+frames[3].rect.width,0.95,accuracy:0.000001)
    XCTAssertTrue(frames.allSatisfy { $0.rect.y == 0.39 && $0.rect.height == 0.56 })
    XCTAssertEqual(Set(frames.map(\.stroke)).count,1)
    XCTAssertEqual(PhotoClockGlyphLayout.digits(in:"10 09"),[1,0,0,9])
    XCTAssertNil(PhotoClockGlyphLayout.digits(in:"10:09"))
    XCTAssertNil(PhotoClockGlyphLayout.frames(digits:[1,0,9],in:band))
    XCTAssertNil(PhotoClockGlyphLayout.frames(digits:[1,0,0,12],in:band))
  }
  func testSoftAlphaAndInkStrengthAreWeightedNotBinarized() throws {
    let subject = mask(Array(repeating:128,count:16))
    let glyphs = [raster(Array(repeating:64,count:16)),raster(Array(repeating:255,count:16)),
                  raster(Array(repeating:1,count:16)),raster(Array(repeating:128,count:16))]
    let result = try XCTUnwrap(subject.inkCoverage(glyphs,crop:.full))
    XCTAssertEqual(result.overall,128/255.0,accuracy:0.000001)
    for fraction in result.perDigit { XCTAssertEqual(fraction,128/255.0,accuracy:0.000001) }
    XCTAssertFalse(result.allowed)
  }
  func testTopOriginIsNotMirroredAndSelectedCropIsApplied() throws {
    let subject = mask((0..<16).map { $0 < 8 ? 255:0 })
    let top = raster((0..<16).map { $0 < 4 ? 255:0 })
    let bottom = raster((0..<16).map { $0 >= 12 ? 255:0 })
    XCTAssertEqual(try XCTUnwrap(subject.inkCoverage(Array(repeating:top,count:4),crop:.full)).overall,1)
    XCTAssertEqual(try XCTUnwrap(subject.inkCoverage(Array(repeating:bottom,count:4),crop:.full)).overall,0)
    let crop = PhotoRect(x:0,y:0.5,width:1,height:0.5)
    // Cell-center bilinear sampling straddles the real mask edge by one eighth.
    XCTAssertEqual(try XCTUnwrap(subject.inkCoverage(Array(repeating:top,count:4),crop:crop)).overall,0.25)
  }
  func testRasterAndCoverageRejectMissingOrAmbiguousEvidence() {
    let subject = mask(Array(repeating:255,count:16))
    let empty = raster(Array(repeating:0,count:16))
    let full = raster(Array(repeating:255,count:16))
    XCTAssertNil(PhotoClockInkRaster(width:Int.max,height:2,values:[]))
    XCTAssertNil(subject.inkCoverage(Array(repeating:empty,count:4),crop:.full))
    XCTAssertNil(subject.inkCoverage([full,full,full],crop:.full))
    XCTAssertNil(subject.inkCoverage([full,full,full,raster([255],width:1,height:1)],crop:.full))
    XCTAssertNil(subject.inkCoverage(Array(repeating:full,count:4),crop:.init(x:0,y:0,width:.nan,height:1)))
    XCTAssertNil(subject.inkCoverage(Array(repeating:full,count:4),crop:.init(x:-0.1,y:0,width:1,height:1)))
    XCTAssertFalse(PhotoClockInkCoverage(overall:.nan,perDigit:[0,0,0,0]).allowed)
    XCTAssertFalse(PhotoClockInkCoverage(overall:0,perDigit:[0,0,0,1.01]).allowed)
  }
  func testLowTotalCannotHideAnEntireSmallDigit() throws {
    let subject = mask((0..<16).map { $0 == 0 ? 255:0 })
    let small = raster((0..<16).map { $0 == 0 ? 255:0 })
    let other = raster((0..<16).map { $0 > 0 ? 255:0 })
    let result = try XCTUnwrap(subject.inkCoverage([small,other,other,other],crop:.full))
    XCTAssertLessThan(result.overall,0.18)
    XCTAssertEqual(result.perDigit,[1,0,0,0])
    XCTAssertFalse(result.allowed)
    XCTAssertTrue(PhotoClockInkCoverage(overall:0.18,perDigit:[0.30,0,0,0]).allowed)
    XCTAssertFalse(PhotoClockInkCoverage(overall:0.180001,perDigit:[0,0,0,0]).allowed)
    XCTAssertFalse(PhotoClockInkCoverage(overall:0.10,perDigit:[0.300001,0,0,0]).allowed)
  }
  func testExpandedBandUsesInkWhileRetainingTrueRectangleCoverage() throws {
    let subject = mask((0..<10_000).map { index in
      let x=index%100, y=index/100
      return x>=30 && x<70 && y>=40 && y<90 ? 255:0
    },width:100,height:100)
    let left = raster((0..<10_000).map { $0%100>=5 && $0%100<15 ? 255:0 },width:100,height:100)
    let full = PhotoPlacement.expansionFrames(for:.top)[0]
    let legacy = PhotoPlacement.choose(aspect:1,mask:subject)
    XCTAssertNotEqual(legacy.clockFrame,full)
    let result = PhotoPlacement.choose(aspect:1,mask:subject,
      inkCandidates:[.init(frame:full,glyphs:Array(repeating:left,count:4))])
    XCTAssertEqual(result.clockFrame,full)
    XCTAssertGreaterThan(result.coverage,0.18)
    XCTAssertEqual(result.coverage,subject.coverage(full))
    XCTAssertEqual(try XCTUnwrap(result.clockInkCoverage).overall,0)
    XCTAssertTrue(result.depthEnabled)
  }
  func testSuppliedMissingDuplicateOrUnreadableInkCannotExpand() {
    let subject = mask((0..<16).map { $0 == 0 ? 255:0 })
    let full = PhotoPlacement.expansionFrames(for:.top)[0]
    let blank = raster(Array(repeating:0,count:16))
    let candidate = PhotoClockInkCandidate(frame:full,glyphs:Array(repeating:blank,count:4))
    for candidates: [PhotoClockInkCandidate] in [[],[candidate],[candidate,candidate]] {
      let result = PhotoPlacement.choose(aspect:1,mask:subject,inkCandidates:candidates)
      XCTAssertNil(result.clockFrame)
      XCTAssertNil(result.clockInkCoverage)
    }
  }
  func testInkCannotEnableMissingForegroundManualOrLetterboxExpansion() {
    let glyph = raster(Array(repeating:255,count:16))
    let candidate = PhotoClockInkCandidate(frame:PhotoPlacement.expansionFrames(for:.top)[0],
      glyphs:Array(repeating:glyph,count:4))
    let sparse = mask((0..<16).map { $0 == 0 ? 255:0 })
    for (subject,available,adjustment) in [(nil,true,PhotoAdjustment()),
        (sparse,false,PhotoAdjustment()),(sparse,true,PhotoAdjustment(clock:.bottom)),
        (sparse,true,PhotoAdjustment(automaticCrop:false))] {
      let result = PhotoPlacement.choose(aspect:1,mask:subject,foregroundAvailable:available,
        adjustment:adjustment,inkCandidates:[candidate])
      XCTAssertNil(result.clockFrame)
      XCTAssertNil(result.clockInkCoverage)
    }
    let edges = mask((0..<10_000).map { index in
      let x=index%100,y=index/100
      return (x<10 || x>90) && y>35 && y<65 ? 255:0
    },width:100,height:100)
    let boxed = PhotoPlacement.choose(aspect:2,mask:edges,inkCandidates:[candidate])
    XCTAssertNotEqual(boxed.destination,.full)
    XCTAssertNil(boxed.clockFrame)
  }
}
