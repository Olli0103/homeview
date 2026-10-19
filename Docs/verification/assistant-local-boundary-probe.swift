import Foundation

@MainActor final class GateProvider:AssistantAnswerProvider {
 var availability=AssistantAIAvailability.available
 var calls=0
 var resets=0
 var pending:[Int:CheckedContinuation<String,Error>]=[:]
 var block=false
 func respond(to prompt:String) async throws -> String {
  let i=calls;calls+=1
  if block { stall();return "late successful answer" }
  return try await withCheckedThrowingContinuation { pending[i]=$0 }
 }
 private func stall() { Thread.sleep(forTimeInterval:0.04) }
 func reset() { resets+=1 }
 func reply(_ index:Int,_ value:String) { pending.removeValue(forKey:index)?.resume(returning:value) }
 func fail(_ index:Int) { pending.removeValue(forKey:index)?.resume(throwing:NSError(domain:"SYNTHETIC_PRIVATE_ERROR_CANARY",code:9)) }
}
@main struct ConversationGate {
 @MainActor static func wait(_ condition:() -> Bool) async -> Bool {
  for _ in 0..<500 { if condition() { return true };try? await Task.sleep(nanoseconds:1_000_000) }
  return condition()
 }
 @MainActor static func main() async throws {
  var rows:[[String:Any]]=[]
  func record(_ name:String,_ passed:Bool) { rows.append(["scenario":name,"passed":passed]) }
  do {
   let p=GateProvider(),c=AssistantConversation(provider:GateProvider());_=c
   let chat=AssistantConversation(provider:p)
   let accepted=chat.ask("PRIVATE_PROMPT_CANARY");await Task.yield()
   record("no-choice-no-provider-effect",!accepted && p.calls==0 && !chat.busy)
   chat.select();let empty=chat.ask("\n\t "),large=chat.ask(String(repeating:"x",count:1001));await Task.yield()
   record("invalid-text-no-provider-effect",!empty && !large && p.calls==0 && !chat.busy)
   p.availability = .unavailable("Synthetic unavailable")
   let unavailable=chat.ask("must not send");await Task.yield()
   record("unavailable-no-fallback",!unavailable && p.calls==0 && !chat.busy)
  }
  for failOld in [false,true] {
   let p=GateProvider(),chat=AssistantConversation(provider:GateProvider());_=chat
   let c=AssistantConversation(provider:p);c.select();c.ask("old PRIVATE_PROMPT_CANARY")
   guard await wait({p.calls==1}) else { exit(91) }
   c.clear();c.ask("new question");guard await wait({p.calls==2}) else { exit(92) }
   p.reply(1,"current answer");guard await wait({!c.busy}) else { exit(93) }
   if failOld { p.fail(0) } else { p.reply(0,"stale answer") }
   for _ in 0..<20 { await Task.yield() }
   record(failOld ? "old-error-cannot-reset-successor":"old-success-cannot-replace-successor",c.exchanges.count==1 && c.exchanges[0].answer=="current answer" && !c.busy && !c.status.contains("CANARY") && p.pending.isEmpty)
   c.clear()
  }
  do {
   let p=GateProvider();p.block=true
   let c=AssistantConversation(provider:p,timeoutNanoseconds:5_000_000)
   c.select();let start=ContinuousClock.now;c.ask("deadline question")
   guard await wait({!c.busy}) else { exit(94) }
   record("elapsed-deadline-beats-delayed-timeout-callback",c.exchanges.isEmpty && c.status.contains("timed out") && start.duration(to:.now)<Duration.seconds(1))
  }
  do {
   let p=GateProvider();let c=AssistantConversation(provider:p);c.select()
   let t=Task { @MainActor in c.ask("must not send") };t.cancel();_=await t.value
   record("pre-cancel-no-provider-effect",p.calls==0 && !c.busy && c.exchanges.isEmpty)
  }
  do {
   let p=GateProvider();weak var released:AssistantConversation?
   do {
    let c=AssistantConversation(provider:p);released=c;c.select();c.ask("pending")
    guard await wait({p.calls==1}) else { exit(95) }
    c.deselect();p.reply(0,"late")
   }
   let freed=await wait({released==nil})
   record("cleared-owner-released-after-late-provider-settles",freed && p.pending.isEmpty)
  }
  print(String(decoding:try JSONSerialization.data(withJSONObject:rows,options:[.sortedKeys]),as:UTF8.self))
  exit(rows.allSatisfy { $0["passed"] as? Bool==true } ? 0:1)
 }
}
