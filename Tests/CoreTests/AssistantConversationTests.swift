import XCTest
@testable import HomeViewCore

@MainActor private final class ControlledAnswers:AssistantAnswerProvider {
  var availability=AssistantAIAvailability.available
  var questions:[String]=[]
  var resets=0
  var pending:[Int:CheckedContinuation<String,Error>]=[:]
  var immediate:String?
  var blockSeconds:TimeInterval=0
  func respond(to prompt:String) async throws -> String {
    let index=questions.count;questions.append(prompt)
    if blockSeconds>0 { block() }
    if let immediate { return immediate }
    return try await withCheckedThrowingContinuation { pending[index]=$0 }
  }
  private func block() { Thread.sleep(forTimeInterval:blockSeconds) }
  func reset() { resets+=1 }
  func reply(_ index:Int,_ text:String) { pending.removeValue(forKey:index)?.resume(returning:text) }
  func fail(_ index:Int) { pending.removeValue(forKey:index)?.resume(throwing:NSError(domain:"SYNTHETIC_SECRET_CANARY",code:1)) }
}
@MainActor final class AssistantConversationTests:XCTestCase {
  private func settle(_ predicate:() -> Bool) async {
    for _ in 0..<500 { if predicate() { return };try? await Task.sleep(nanoseconds:1_000_000) }
    XCTAssertTrue(predicate(),"Expected bounded completion")
  }
  func testSelectionIsExplicitAndDoesNotSendAnything() {
    let p=ControlledAnswers();let chat=AssistantConversation(provider:p)
    chat.ask("unsent question");XCTAssertFalse(chat.busy);XCTAssertTrue(chat.exchanges.isEmpty)
    let selected=AssistantConversation(provider:p);selected.select()
    XCTAssertEqual(selected.availability,.available);XCTAssertTrue(p.questions.isEmpty)
  }
  func testTwoTurnsKeepSameProviderWithoutResettingBetweenReplies() async {
    let p=ControlledAnswers()
    let c=AssistantConversation(provider:p);c.select();let resetCount=p.resets
    c.ask("Fictional name: Moon Soup");await settle { p.questions.count==1 };p.reply(0,"Understood.")
    await settle { !c.busy };c.ask("What was its name?");await settle { p.questions.count==2 };p.reply(1,"Moon Soup.")
    await settle { !c.busy };XCTAssertEqual(c.exchanges.count,2)
    XCTAssertEqual(c.exchanges.last?.answer,"Moon Soup.");XCTAssertEqual(p.resets,resetCount)
  }
  func testUnavailableEmptyAndOversizedNeverInvokeProvider() {
    let p=ControlledAnswers();p.availability = .unavailable("Synthetic model not ready")
    let c=AssistantConversation(provider:p);c.select();c.ask("hello");XCTAssertFalse(c.busy)
    p.availability = .available;c.select();c.ask("   ");c.ask(String(repeating:"x",count:1001))
    XCTAssertTrue(p.questions.isEmpty);XCTAssertFalse(c.busy)
  }
  func testSecondSendWhileBusyDoesNotReplacePendingQuestion() async {
    let p=ControlledAnswers()
    let chat=AssistantConversation(provider:p);chat.select();chat.ask("first");chat.ask("second")
    await settle { p.questions.count==1 };XCTAssertEqual(chat.pendingQuestion,"first")
    p.reply(0,"one");await settle { !chat.busy };XCTAssertEqual(p.questions,["first"])
  }
  func testCancelDiscardsContextAndLateSuccessCannotOverwriteSuccessor() async {
    let p=ControlledAnswers()
    let chat=AssistantConversation(provider:p);chat.select();chat.ask("old");await settle { p.questions.count==1 }
    chat.clear();chat.ask("new");await settle { p.questions.count==2 }
    p.reply(1,"new reply");await settle { !chat.busy };p.reply(0,"stale reply")
    await Task.yield();XCTAssertEqual(chat.exchanges.map(\.answer),["new reply"])
    XCTAssertGreaterThanOrEqual(p.resets,2)
  }
  func testLateErrorCannotClearNewPendingRequest() async {
    let p=ControlledAnswers();let chat=AssistantConversation(provider:p)
    chat.select();chat.ask("old");await settle { p.questions.count==1 };chat.clear();chat.ask("new")
    await settle { p.questions.count==2 };p.fail(0);await Task.yield()
    XCTAssertTrue(chat.busy);XCTAssertEqual(chat.pendingQuestion,"new")
    p.reply(1,"new reply");await settle { !chat.busy };XCTAssertEqual(chat.exchanges.count,1)
  }
  func testProviderErrorClearsEntireConversationAndDoesNotLeakRawDiagnostic() async {
    let p=ControlledAnswers();let c=AssistantConversation(provider:p);c.select()
    c.ask("first");await settle { p.questions.count==1 };p.reply(0,"one");await settle { !c.busy }
    c.ask("second");await settle { p.questions.count==2 };p.fail(1);await settle { !c.busy }
    XCTAssertTrue(c.exchanges.isEmpty);XCTAssertNil(c.pendingQuestion)
    XCTAssertFalse(c.status.contains("CANARY"));XCTAssertTrue(c.status.contains("Conversation cleared"))
  }
  func testTurnLimitRejectsBeforeProviderAndRequiresExplicitNewConversation() async {
    let p=ControlledAnswers();p.immediate="brief answer"
    let c=AssistantConversation(provider:p);c.select()
    for i in 0..<4 { c.ask("question \(i)");await settle { !c.busy } }
    c.ask("fifth");XCTAssertEqual(p.questions.count,4);XCTAssertEqual(c.exchanges.count,4)
    XCTAssertTrue(c.status.contains("limit reached"));c.clear();c.ask("new")
    await settle { !c.busy };XCTAssertEqual(p.questions.count,5);XCTAssertEqual(c.exchanges.count,1)
  }
  func testOversizedOrEmptyReplyNeverBecomesAnAnswer() async {
    let p=ControlledAnswers();let c=AssistantConversation(provider:p);c.select()
    for reply in ["  ",String(repeating:"x",count:4001)] {
      let index=p.questions.count;c.ask("question");await settle { p.questions.count==index+1 }
      p.reply(index,reply);await settle { !c.busy };XCTAssertTrue(c.exchanges.isEmpty)
    }
  }
  func testTimeoutReturnsToIdleAndLateCompletionCannotReappear() async {
    let p=ControlledAnswers();let c=AssistantConversation(provider:p,timeoutNanoseconds:20_000_000)
    c.select();c.ask("slow");await settle { p.questions.count==1 };await settle { !c.busy }
    XCTAssertTrue(c.status.contains("timed out"));p.reply(0,"late");await Task.yield()
    XCTAssertTrue(c.exchanges.isEmpty);XCTAssertNil(c.pendingQuestion)
  }
  func testElapsedDeadlineRejectsApparentSuccessWhenTimeoutTaskWasBlocked() async {
    let p=ControlledAnswers();p.immediate="must not commit";p.blockSeconds=0.05
    let c=AssistantConversation(provider:p,timeoutNanoseconds:10_000_000)
    c.select();c.ask("question");await settle { !c.busy }
    XCTAssertTrue(c.exchanges.isEmpty);XCTAssertTrue(c.status.contains("timed out"))
  }
  func testDeselectRevokesPendingAndRequiresExplicitSelectionAgain() async {
    let p=ControlledAnswers();let c=AssistantConversation(provider:p);c.select();c.ask("old")
    await settle { p.questions.count==1 };c.deselect();p.reply(0,"late");await Task.yield()
    c.ask("must not send");XCTAssertEqual(p.questions.count,1);XCTAssertEqual(c.availability,.notSelected)
    XCTAssertFalse(c.busy);XCTAssertTrue(c.exchanges.isEmpty)
  }
  func testPreCancelledCallerCannotBeginARequest() async {
    let p=ControlledAnswers();let c=AssistantConversation(provider:p);c.select()
    let task=Task { @MainActor in c.ask("must not send") };task.cancel();await task.value
    XCTAssertTrue(p.questions.isEmpty);XCTAssertFalse(c.busy);XCTAssertTrue(c.exchanges.isEmpty)
  }
  func testAggregateCharacterBoundaryAcceptsExactLimitAndRejectsNextQuestion() async {
    let p=ControlledAnswers();p.immediate=String(repeating:"a",count:2000)
    let c=AssistantConversation(provider:p);c.select()
    for _ in 0..<2 { c.ask(String(repeating:"q",count:1000));await settle { !c.busy } }
    XCTAssertEqual(c.exchanges.count,2);c.ask("x")
    XCTAssertEqual(p.questions.count,2);XCTAssertFalse(c.busy)
    XCTAssertTrue(c.status.contains("limit reached"))
  }

}
