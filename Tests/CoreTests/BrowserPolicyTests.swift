import XCTest
@testable import HomeViewCore

final class BrowserPolicyTests: XCTestCase {
  func testUserAddressesNormalizeToHTTPSWithoutChangingQueries() {
    XCTAssertEqual(BrowserPolicy.address(" example.org/recipe?a=1&b=2 ")?.absoluteString, "https://example.org/recipe?a=1&b=2")
    XCTAssertEqual(BrowserPolicy.address("https://example.org:8443/#part")?.port,8443)
    XCTAssertNotNil(BrowserPolicy.address("https://[::1]/"))
  }
  func testInvalidAndExternalSchemesNeverNavigate() {
    for value in ["", "https://", "https://example.org:0", "https://example.org:99999", "https://user:password@example.org", "http://example.org", "file:///tmp/test", "javascript:alert(1)", "data:text/html,test", "mailto:a@example.org", "facetime://test", "https://example.org\n/evil", "https://exa mple.org", "https://example.org/ bad"] {
      XCTAssertNil(BrowserPolicy.address(value), value)
    }
    for value in ["http://example.org","file:///tmp/test","javascript:alert(1)","data:text/html,test","facetime://test"] {
      XCTAssertFalse(BrowserPolicy.allowsNavigation(URL(string:value),fixture:false),value)
    }
  }
  func testSyntheticNavigationRequiresAnExplicitHostOwnedTestFlag() {
    let page = URL(string: "homeview-fixture://local/one")!
    XCTAssertFalse(BrowserPolicy.allowsNavigation(page, fixture: true))
    XCTAssertTrue(BrowserPolicy.allowsNavigation(page, fixture: true, testPages: true))
    for value in ["homeview-fixture://remote/one", "homeview-fixture://local/other", "homeview-fixture://local/one?cmd=unlock", "homeview-fixture://user@local/one"] {
      XCTAssertFalse(BrowserPolicy.allowsNavigation(URL(string: value), fixture: true, testPages: true))
    }
  }
  func testOnlyTheBundledFixtureMayUseExactBlankURL() {
    XCTAssertTrue(BrowserPolicy.allowsNavigation(URL(string:"about:blank"),fixture:true))
    XCTAssertFalse(BrowserPolicy.allowsNavigation(URL(string:"about:blank#payload"),fixture:true))
    XCTAssertFalse(BrowserPolicy.allowsNavigation(URL(string:"about:blank"),fixture:false))
    XCTAssertFalse(BrowserPolicy.allowsNavigation(nil,fixture:true))
    XCTAssertTrue(BrowserPolicy.allowsNavigation(URL(string:"https://example.org"),fixture:false))
  }
}
