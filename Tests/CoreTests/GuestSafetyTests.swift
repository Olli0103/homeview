import XCTest
@testable import HomeViewCore
final class GuestSafetyTests:XCTestCase {
 func testGuestSceneCannotBypassSecurityAuthorization() {
  var home=MockHome();home.locked=false
  let before=home
  XCTAssertThrowsError(try home.transact(.scene("Good Night"),authorized:false))
  XCTAssertEqual(home,before,"Rejected security scene must leave all values unchanged")
 }
}

extension GuestSafetyTests {
 func testExplicitGuestUserAndAuthenticatedDeviceMatrix() {
  let publicActions:Set<LocalCapability>=[.publicWeather,.foregroundTimer,.mockControls,.bundledMedia,.publicPodcast]
  let authenticatedActions=publicActions.union([.mockSecurity,.connectedMusicSearch,.connectedMusicPlayback,.personalSource])
  for role in LocalAccessRole.allCases {
   for shared in [false,true] {
    var expected=role == .deviceAuthenticated ? authenticatedActions:publicActions
    if shared { expected.insert(.connectedMusicPlayback) }
    for action in LocalCapability.allCases {
     XCTAssertEqual(GuestAccessPolicy.allows(action,role:role,sharedMusicQueue:shared),expected.contains(action),"\(role) / \(action) / shared=\(shared)")
    }
   }
  }
 }
 func testNonSecurityGuestControlsRemainAvailable() throws {
  var home=MockHome()
  try home.transact(.temperature(72));try home.transact(.brightness(30));try home.transact(.scene("Good Morning"))
  XCTAssertEqual(home.temperature,70);XCTAssertEqual(home.brightness,30)
  XCTAssertThrowsError(try home.transact(.lock))
  try home.transact(.lock,authorized:true)
  XCTAssertFalse(home.locked)
 }
}
