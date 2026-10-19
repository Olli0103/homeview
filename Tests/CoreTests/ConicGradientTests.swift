import XCTest
@testable import HomeViewCore

final class ConicGradientTests: XCTestCase {
  func testZeroAngleIsTopAndPositiveTurnsAreClockwise() {
    XCTAssertEqual(ConicGradientModel.turn(x: 0, y: -1), 0)
    XCTAssertEqual(ConicGradientModel.turn(x: 1, y: 0), 0.25)
    XCTAssertEqual(ConicGradientModel.turn(x: 0, y: 1), 0.5)
    XCTAssertEqual(ConicGradientModel.turn(x: -1, y: 0), 0.75)
  }
  func testStopsAndWrapAreContinuousAtFullTurn() {
    XCTAssertEqual(ConicGradientModel.sample(x: 1, y: 0, phase: 0), .init(0.753, 0.644, 0.634))
    let before = ConicGradientModel.sample(x: -0.000001, y: -1, phase: 0)
    let after = ConicGradientModel.sample(x: 0.000001, y: -1, phase: 0)
    for i in 0..<3 { XCTAssertEqual(before[i], after[i], accuracy: 0.00001) }
    XCTAssertEqual(ConicGradientModel.sample(x: 1, y: 0, phase: 1),
                   ConicGradientModel.sample(x: 1, y: 0, phase: 0))
  }
  func testTimeWrapAndReducedMotionFreezeGradientPhase() {
    XCTAssertEqual(ConicGradientModel.phase(minutes: 60, reducedMotion: false), 0)
    XCTAssertEqual(ConicGradientModel.phase(minutes: -15, reducedMotion: false), 0.75)
    XCTAssertEqual(ConicGradientModel.phase(minutes: 12.5, reducedMotion: false), 12.5/60)
    for minute in [0.0, 10, 59.99, Double.nan] {
      XCTAssertEqual(ConicGradientModel.phase(minutes: minute, reducedMotion: true), 0)
    }
    XCTAssertEqual(ConicGradientModel.wrap(.infinity), 0)
    XCTAssertEqual(ConicGradientModel.turn(x: .nan, y: 0), 0)
  }
}
