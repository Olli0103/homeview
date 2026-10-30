import XCTest
@testable import HomeViewCore

final class ArtworkMotionTests: XCTestCase {
  func testEveryIndependentRestrictionPreventsMotion() {
    var permitted=0
    for mask in 0..<64 {
      let playing=mask&1 != 0,foreground=mask&2 != 0,reduce=mask&4 != 0
      let autoplay=mask&8 != 0,lowPower=mask&16 != 0,hot=mask&32 != 0
      let result=ArtworkMotionPolicy.allows(playing:playing,foreground:foreground,
        reduceMotion:reduce,autoplay:autoplay,lowPower:lowPower,thermalRestricted:hot)
      XCTAssertEqual(result,mask==11,"Only explicit playback, active scene and autoplay with no restrictions may animate")
      if result { permitted+=1 }
    }
    XCTAssertEqual(permitted,1)
  }
}
