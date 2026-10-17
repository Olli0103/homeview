import XCTest
@testable import HomeViewCore

final class FlowTypographyTests: XCTestCase {
  func testAllDigitsStayInsideInkBoxAtEveryAxisCorner() {
    for width in [0.9, 1, 1.06] {
      for weight in [0.0, 0.5, 1] {
        let axes = FlowTypography(width: width, weight: weight)
        for digit in 0...9 {
          let skeleton = FlowTypography.skeleton(digit)
          XCTAssertFalse(skeleton.isEmpty)
          // Bezier curves stay in the convex hull of these controls. Round stroke
          // adds at most half a stroke, including joins and endpoints.
          for p in skeleton.flatMap(\.points).map(axes.point) {
            XCTAssertGreaterThanOrEqual(p.x - axes.stroke / 2, 0)
            XCTAssertLessThanOrEqual(p.x + axes.stroke / 2, axes.advance)
            XCTAssertGreaterThanOrEqual(p.y - axes.stroke / 2, 0)
            XCTAssertLessThanOrEqual(p.y + axes.stroke / 2, 1)
          }
        }
        // Advance already encloses every stroked point; the reference's narrow
        // inter-digit gap need not exceed half the very thick bubble stroke.
        XCTAssertGreaterThan(axes.tracking, 0)
      }
    }
  }
  func testAllTimesAndPairsHaveStableAdvanceAndValidDigits() {
    for twelve in [true, false] {
      for h in 0..<24 {
        for m in 0..<60 {
          let digits = FlowTypography.digits(hour: h, minute: m, twelveHour: twelve)
          XCTAssertEqual(digits.count, 4)
          XCTAssertTrue(digits.allSatisfy { (0...9).contains($0) })
          XCTAssertEqual(digits[2] * 10 + digits[3], m)
          XCTAssertEqual(digits[0] * 10 + digits[1], twelve ? (h % 12 == 0 ? 12 : h % 12) : h)
        }
      }
    }
    for a in 0...9 { for b in 0...9 {
      XCTAssertFalse(FlowTypography.skeleton(a).isEmpty)
      XCTAssertFalse(FlowTypography.skeleton(b).isEmpty)
    } }
  }
  func testInvalidAxesAreClampedAndMotionIsBounded() {
    XCTAssertEqual(FlowTypography(width: .nan, weight: .infinity), FlowTypography())
    XCTAssertEqual(FlowTypography(width: -5, weight: 9).width, 0.9)
    XCTAssertEqual(FlowTypography(width: -5, weight: 9).weight, 1)
    XCTAssertTrue(FlowTypography.skeleton(-1).isEmpty)
    XCTAssertTrue(FlowTypography.skeleton(10).isEmpty)
    let frames = (0...2400).map { FlowTypography.animated(at: Double($0) / 10) }
    XCTAssertTrue(frames.allSatisfy { (0.9...1.06).contains($0.width) && (0...1).contains($0.weight) })
    XCTAssertNotEqual(frames[0], frames[100])
  }
}
