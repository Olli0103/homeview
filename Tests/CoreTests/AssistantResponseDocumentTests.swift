import XCTest
@testable import HomeViewCore

final class AssistantResponseDocumentTests:XCTestCase {
  func testExamplesAreDeterministicBoundedAndFollowUpsOnlySelectExamples() {
    XCTAssertEqual(AssistantResponseExample.allCases.count,6)
    for example in AssistantResponseExample.allCases {
      let d=example.document
      XCTAssertEqual(d,example.document)
      XCTAssertFalse(d.text.isEmpty);XCTAssertLessThan(d.text.count,1000)
      XCTAssertTrue(d.followUps.allSatisfy {AssistantResponseExample.allCases.contains($0)})
      XCTAssertEqual(d.recipeActionAvailable,example == .recipe)
    }
  }
  func testKnowledgeHasOneExplicitSourceAndNoProviderDefinedURL() {
    let d=AssistantResponseExample.knowledge.document
    XCTAssertEqual(d.content,.illustration);XCTAssertEqual(d.sources,[.museum])
    let url=d.sources.first!.url!
    XCTAssertEqual(url.scheme,"https");XCTAssertEqual(url.host,"collection.sciencemuseumgroup.org.uk")
    XCTAssertNil(url.user);XCTAssertNil(url.password);XCTAssertNil(url.query)
    XCTAssertTrue(d.text.contains("1842"));XCTAssertTrue(d.sources[0].detail.contains("not a live search"))
  }
  func testAgendaContainsOnlyThreeBundledNonActionableEvents() {
    let d=AssistantResponseExample.agenda.document
    guard case .agenda(let events)=d.content else {return XCTFail("Agenda expected")}
    XCTAssertEqual(events.count,3);XCTAssertEqual(d.sources,[.bundled]);XCTAssertNil(d.sources[0].url)
    XCTAssertFalse(d.recipeActionAvailable)
    XCTAssertEqual(events.map(\.kind),[.birthday,.event,.birthday])
    XCTAssertEqual(events.map(\.detail),["All day","3:00–4:00 PM","All day"])
  }
  func testLoadingEmptyAndFailureHaveNoRecipeActionOrExternalSource() {
    for example in [AssistantResponseExample.loading,.empty,.failure] {
      XCTAssertTrue(example.document.sources.isEmpty)
      XCTAssertFalse(example.document.recipeActionAvailable)
      XCTAssertFalse(example.document.followUps.isEmpty)
    }
  }
}
