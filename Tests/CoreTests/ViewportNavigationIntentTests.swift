import XCTest
@testable import HomeViewCore

final class ViewportNavigationIntentTests: XCTestCase {
  private func intent(_ x: Double = 300, _ y: Double = 300,
                      _ dx: Double, _ dy: Double, face: Bool = true) -> ViewportNavigationAction? {
    ViewportNavigationIntent.choose(startX:x,startY:y,dx:dx,dy:dy,edge:600,isFace:face)
  }
  func testHorizontalDominantTopDiagonalsKeepTheirFaceDirection() {
    XCTAssertEqual(intent(150,48,348,144),.face(-1))
    XCTAssertEqual(intent(498,48,-348,144),.face(1))
    XCTAssertEqual(intent(150,48,140,180),.assistant)
    XCTAssertEqual(intent(498,48,-140,180),.controlCenter)
  }
  func testInteriorVerticalIntentCannotAdvanceFace() {
    XCTAssertNil(intent(270,270,150,270))
    XCTAssertNil(intent(330,330,-150,-270))
    XCTAssertEqual(intent(270,270,270,150),.face(-1))
    XCTAssertEqual(intent(330,330,-270,-150),.face(1))
  }
  func testBottomGestureKeepsNarrowEdgeAndVerticalDistance() {
    XCTAssertEqual(intent(300,592,100,-200),.home)
    XCTAssertNil(intent(300,580,100,-200))
    XCTAssertEqual(intent(300,592,200,-100),.face(-1))
    XCTAssertNil(intent(300,592,100,-200,face:false))
  }
  func testExistingStrictDistanceBoundariesRemainUnchanged() {
    XCTAssertNil(intent(300,30,0,70))
    XCTAssertEqual(intent(300,30,0,70.001),.assistant)
    XCTAssertNil(intent(300,592,0,-70))
    XCTAssertEqual(intent(300,592,0,-70.001),.home)
    XCTAssertNil(intent(300,300,80,0))
    XCTAssertEqual(intent(300,300,80.001,0),.face(-1))
  }
  func testEqualAxesHaveNoAmbiguousNavigationWinner() {
    for (x,y) in [(300.0,30.0),(300,592),(300,300)] {
      for dx in [-100.0,100] { for dy in [-100.0,100] { XCTAssertNil(intent(x,y,dx,dy)) } }
    }
  }
  func testNonFaceRoutesKeepTopDestinationsAndNeverCycleFaces() {
    XCTAssertNil(intent(300,300,200,0,face:false))
    XCTAssertEqual(intent(300,30,100,200,face:false),.assistant)
    XCTAssertEqual(intent(500,30,-100,200,face:false),.controlCenter)
    XCTAssertNil(intent(300,30,200,100,face:false))
  }
  func testInvalidGeometryCannotSelectAnAction() {
    for value in [Double.nan,.infinity,-Double.infinity] {
      XCTAssertNil(intent(value,30,0,200))
      XCTAssertNil(intent(300,value,0,200))
      XCTAssertNil(intent(300,30,value,200))
      XCTAssertNil(intent(300,30,0,value))
      XCTAssertNil(ViewportNavigationIntent.choose(startX:1,startY:1,dx:200,dy:0,edge:value,isFace:true))
    }
    XCTAssertNil(intent(-1,30,0,200))
    XCTAssertNil(intent(300,601,200,0))
    XCTAssertNil(ViewportNavigationIntent.choose(startX:0,startY:0,dx:200,dy:0,edge:0,isFace:true))
  }
  func testExistingEdgeFractionsScaleAcrossDisplayedSquares() {
    for edge in [378.0,600,796] {
      func action(_ x:Double,_ y:Double,_ dx:Double,_ dy:Double) -> ViewportNavigationAction? {
        ViewportNavigationIntent.choose(startX:edge*x,startY:edge*y,dx:dx,dy:dy,edge:edge,isFace:true)
      }
      XCTAssertEqual(action(0.5,0.985,0,-200),.home)
      XCTAssertNil(action(0.5,0.95,0,-200))
      XCTAssertEqual(action(0.4,0.06,0,200),.assistant)
      XCTAssertEqual(action(0.85,0.06,0,200),.controlCenter)
      XCTAssertNil(action(0.4,0.13,0,200))
    }
  }
}
