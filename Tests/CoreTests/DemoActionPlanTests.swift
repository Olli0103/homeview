import XCTest
@testable import HomeViewCore

final class DemoActionPlanTests:XCTestCase {
  func plan(_ text:String="plan: temperature 72; brightness 30; timer for 90 seconds") throws->DemoActionPlan {
    guard case .proposal(let plan)=DemoActionPlan.parse(text,context:4,uptime:100) else { throw NSError(domain:"test",code:1) }
    return plan
  }
  func testExplicitPrefixAndWholeRequestValidationNeverExecuteAnAllowedPrefix() throws {
    XCTAssertEqual(DemoActionPlan.parse("temperature 72; brightness 30",context:4,uptime:100),.notAPlan)
    for input in ["plan: temperature 72; call Alex","plan: good night; temperature 72","plan: lock; brightness 30","plan: message Alex; brightness 30","plan: temperature 91; brightness 30","plan: brightness -1; temperature 70","plan: temperature 72;", "plan: temperature 72"] {
      guard case .rejected = DemoActionPlan.parse(input,context:4,uptime:100) else { return XCTFail(input) }
    }
    guard case .rejected(let details)=DemoActionPlan.parse("plan: call Alex; unlock; brightness 999",context:4,uptime:100) else { return XCTFail() }
    for index in 1...3 { XCTAssertTrue(details.contains("Step \(index)")) }
    XCTAssertEqual(try plan().steps.count,3)
  }
  func testBoundsAndClockRejectOversizedOrUnusableProposals() {
    for input in ["plan: "+String(repeating:"a",count:1001),"plan: "+Array(repeating:"temperature 70",count:7).joined(separator:";")] {
      guard case .rejected = DemoActionPlan.parse(input,context:4,uptime:100) else { return XCTFail() }
    }
    for time in [Double.nan,.infinity,-1] {
      guard case .rejected = DemoActionPlan.parse("plan: temperature 72; brightness 30",context:4,uptime:time) else { return XCTFail() }
    }
  }
  func testPreviewDoesNotClaimAndApprovalHasAnExactContextAndDeadline() throws {
    var draft=try plan();XCTAssertNil(draft.claimNext(token:UUID()))
    XCTAssertNil(draft.confirm(id:UUID(),context:4,uptime:101,active:true));XCTAssertEqual(draft.phase,.preview)
    for (context,time,active) in [(5,101.0,true),(4,160,true),(4,99,true),(4,101,false)] {
      var expired=try plan();XCTAssertNil(expired.confirm(id:expired.id,context:context,uptime:time,active:active));XCTAssertEqual(expired.phase,.cancelled)
      XCTAssertTrue(expired.steps.allSatisfy { $0.disposition == .cancelled })
    }
  }
  func testFailureInMiddlePreservesFirstReceiptAndBlocksAllDependents() throws {
    var draft=try plan();let token=try XCTUnwrap(draft.confirm(id:draft.id,context:4,uptime:101,active:true))
    let first=try XCTUnwrap(draft.claimNext(token:token));XCTAssertNil(draft.claimNext(token:token))
    XCTAssertTrue(draft.record(step:first.id,token:token,result:.confirmed("Read-back72")))
    let second=try XCTUnwrap(draft.claimNext(token:token));XCTAssertTrue(draft.record(step:second.id,token:token,result:.failed("Offline")))
    XCTAssertEqual(draft.confirmedCount,1);XCTAssertEqual(draft.phase,.stopped)
    XCTAssertEqual(draft.steps[2].disposition,.dependencyNotMet);XCTAssertNil(draft.claimNext(token:token))
    XCTAssertTrue(draft.note.contains("not undone"))
  }
  func testRepeatedApprovalAndReceiptsCannotDuplicateAStepOrCreateANewExecution() throws {
    var draft=try plan();let token=try XCTUnwrap(draft.confirm(id:draft.id,context:4,uptime:101,active:true))
    XCTAssertNil(draft.confirm(id:draft.id,context:4,uptime:102,active:true))
    let first=try XCTUnwrap(draft.claimNext(token:token));XCTAssertFalse(draft.record(step:first.id,token:UUID(),result:.confirmed("Wrong ticket")))
    XCTAssertTrue(draft.record(step:first.id,token:token,result:.confirmed("Actual read-back")))
    XCTAssertFalse(draft.record(step:first.id,token:token,result:.confirmed("Duplicate")))
    for _ in 0..<2 { let next=try XCTUnwrap(draft.claimNext(token:token));XCTAssertTrue(draft.record(step:next.id,token:token,result:.confirmed("Actual read-back"))) }
    XCTAssertEqual(draft.phase,.completed);XCTAssertEqual(draft.confirmedCount,3)
    XCTAssertNil(draft.claimNext(token:token));XCTAssertNil(draft.confirm(id:draft.id,context:4,uptime:103,active:true))
  }
  func testCancelRetainsConfirmedStepsAndDoesNotAcceptLateReceipts() throws {
    var draft=try plan();let token=try XCTUnwrap(draft.confirm(id:draft.id,context:4,uptime:101,active:true));let first=try XCTUnwrap(draft.claimNext(token:token));draft.record(step:first.id,token:token,result:.confirmed("Actual read-back"))
    draft.cancel();XCTAssertEqual(draft.confirmedCount,1);XCTAssertEqual(draft.steps[1].disposition,.cancelled);XCTAssertNil(draft.claimNext(token:token))
    XCTAssertFalse(draft.record(step:first.id,token:token,result:.confirmed("Late")))
    var during=try plan();let t=try XCTUnwrap(during.confirm(id:during.id,context:4,uptime:101,active:true));let inFlight=try XCTUnwrap(during.claimNext(token:t));during.cancel()
    if case .unverified = during.steps[0].disposition {} else { XCTFail("An in-flight effect is not fabricated as cancelled-before-start") }
    XCTAssertFalse(during.record(step:inFlight.id,token:t,result:.confirmed("Late")))
  }
  func testUnverifiedReadbackIsNotSuccessAndNeverContinues() throws {
    var draft=try plan();let token=try XCTUnwrap(draft.confirm(id:draft.id,context:4,uptime:101,active:true));let first=try XCTUnwrap(draft.claimNext(token:token));draft.record(step:first.id,token:token,result:.unverified("Saved state could not be read"))
    XCTAssertEqual(draft.confirmedCount,0);XCTAssertEqual(draft.phase,.stopped);XCTAssertEqual(draft.steps[1].disposition,.dependencyNotMet)
    XCTAssertNil(draft.claimNext(token:token))
  }
  func testForegroundTimerSupportsExistingDurationGrammarAndStableStepIdentity() throws {
    let draft=try plan("plan: Timer auf eine Stunde namens Synthetic; temperature 70")
    XCTAssertEqual(draft.steps[0].operation,.foregroundTimer(seconds:3600,title:"Synthetic"));XCTAssertNotEqual(draft.steps[0].id,draft.steps[1].id)
    XCTAssertTrue(draft.steps[0].operation.summary.contains("Foreground demo"))
  }
}
