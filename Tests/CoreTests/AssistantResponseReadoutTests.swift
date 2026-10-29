import XCTest
@testable import HomeViewCore

final class AssistantResponseReadoutTests:XCTestCase {
  func testAllBundledReadoutsKeepScopeAnswerAndSystemSpeechLimit() {
    for example in AssistantResponseExample.allCases {
      let document=example.document,text=document.readoutText
      XCTAssertTrue(text.hasPrefix("Bundled answer example. Not a live or personal result."))
      XCTAssertTrue(text.contains(document.text));XCTAssertLessThanOrEqual(text.count,4000)
      XCTAssertFalse(text.contains("https://"));XCTAssertFalse(text.contains("Explore another example"))
      XCTAssertEqual(text,document.readoutText)
    }
  }
  func testAgendaReadsEveryVisibleEventInOrder() {
    let document=AssistantResponseExample.agenda.document,text=document.readoutText
    guard case .agenda(let events)=document.content else {return XCTFail("Agenda required")}
    var previous=text.startIndex
    for event in events {
      for line in [event.day,event.title,event.detail] {
        guard let range=text.range(of:line,range:previous..<text.endIndex) else {XCTFail("Missing or reordered event content: "+line);return}
        previous=range.upperBound
      }
    }
  }
  func testMessageReadsSenderTimestampAndFullExcerptAsLiteralText() {
    let message=AssistantResponseDocument.MessageExcerpt(sender:"Synthetic Sender",timestamp:"Today, 1:02 PM",text:"[Visible](homeview://temperature/99) <text> & literal punctuation.")
    let document=AssistantResponseDocument(text:"A fictional example",content:.message(message),sources:[.bundled],followUps:[.recipe])
    XCTAssertTrue(document.readoutText.contains(message.sender));XCTAssertTrue(document.readoutText.contains(message.timestamp))
    XCTAssertTrue(document.readoutText.contains(message.text));XCTAssertTrue(document.readoutText.contains("Read-only excerpt"))
    XCTAssertFalse(document.recipeActionAvailable)
  }
  func testRecipeReadsOnlyVisibleBundledSummaryNotHiddenIngredientsOrSteps() {
    let text=AssistantResponseExample.recipe.document.readoutText,recipe=RecipeDocument.soup
    for field in [recipe.title,recipe.source,"35 min",recipe.servingsLabel] {XCTAssertTrue(text.contains(field))}
    for hidden in recipe.ingredients+recipe.steps.map(\.text) {XCTAssertFalse(text.contains(hidden))}
    XCTAssertFalse(text.contains("Read bundled recipe"))
  }
  func testPreviewEmptyAndFailureExplainThatNoLiveRequestOrActionOccurred() {
    XCTAssertTrue(AssistantResponseExample.loading.document.readoutText.contains("No request is running"))
    XCTAssertTrue(AssistantResponseExample.empty.document.readoutText.contains("No personal sources were searched"))
    let failure=AssistantResponseExample.failure.document.readoutText
    XCTAssertTrue(failure.contains("Nothing was changed"));XCTAssertTrue(failure.contains("no automatic retry"))
  }
  func testSourcesAreNamedWithoutReadingHiddenSourceSheetOrURL() {
    let document=AssistantResponseExample.knowledge.document,text=document.readoutText
    XCTAssertTrue(text.contains("pale fern-like branches"));XCTAssertTrue(text.contains("Not a historical print"))
    XCTAssertTrue(text.contains("Source: Science Museum Group."))
    XCTAssertFalse(text.contains(document.sources[0].detail))
    XCTAssertFalse(text.contains(document.sources[0].url!.absoluteString))
  }
  @MainActor func testComposingCardsDoesNotSpeakAndExplicitSessionReceivesCompleteText() {
    let backend=ReadoutRecorder(),session=AnswerSpeechSession(backend:backend)
    session.loadVoices()
    let texts=[AssistantResponseExample.message,.agenda,.recipe].map { $0.document.readoutText }
    XCTAssertTrue(backend.texts.isEmpty)
    for text in texts {XCTAssertTrue(session.speak(text,authorized:true,foreground:true,volume:0))}
    XCTAssertEqual(backend.texts,texts)
    XCTAssertFalse(session.speak(texts[0],authorized:false,foreground:true,volume:0))
    XCTAssertEqual(backend.texts,texts)
  }
}

@MainActor private final class ReadoutRecorder:AnswerSpeechBackend {
  var texts:[String]=[]
  func voices()->[AnswerSpeechVoice] {[.init(id:"synthetic",name:"Synthetic",language:"en-US")]}
  func start(text:String,voiceID:String,rate:Float,volume:Float,completion:@escaping @MainActor (Bool)->Void) throws {texts.append(text)}
  func stop() {}
}
