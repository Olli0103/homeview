import XCTest
@testable import HomeViewCore

final class AssistantCommandBoundaryTests:XCTestCase {
  func testDescriptiveKnowledgeQuestionsDoNotBecomeActions() {
    for request in ["Who invented the light bulb?","What is the temperature of the Sun at 6000 degrees?",
      "What is good night in French?","Explain music theory","Can a calendar have 13 months?",
      "Why is soup a recipe?", "do not turn on the lights", "don't set temperature 72",
      "good night and toggle lights", "temperature 72 and show recipe"] {
      XCTAssertEqual(AssistantIntent(request),.unknown,request)
    }
  }
  func testExplicitLimitedCommandsRemainRecognized() {
    XCTAssertEqual(AssistantIntent("temperature 72"),.temperature(72))
    XCTAssertEqual(AssistantIntent("Temperatur 70"),.temperature(70))
    XCTAssertEqual(AssistantIntent("good night"),.scene("Good Night"))
    XCTAssertEqual(AssistantIntent("lights"),.light)
    XCTAssertEqual(AssistantIntent("show recipe"),.recipe)
    XCTAssertEqual(AssistantIntent("open calendar"),.calendar)
    XCTAssertEqual(AssistantIntent("music"),.music)
  }
}
