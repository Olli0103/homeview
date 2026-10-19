import Foundation
@MainActor final class DelayedContext:AssistantAnswerProvider {
 var availability=AssistantAIAvailability.available
 var pending:[Int:CheckedContinuation<String,Error>]=[:]
 var calls=0
 var context:[String]=[]
 var resets=0
 func reset(){context=[];resets+=1}
 func respond(to prompt:String) async throws->String {
  let id=calls;calls+=1;context.append(prompt)
  return try await withCheckedThrowingContinuation {pending[id]=$0}
 }
 func finish(_ id:Int,_ answer:String){pending.removeValue(forKey:id)?.resume(returning:answer)}
}
@main struct IsolationGate {
 @MainActor static func wait(_ f:()->Bool) async {
  for _ in 0..<500 {if f(){return};try? await Task.sleep(nanoseconds:1_000_000)}
  precondition(f(),"Bounded synthetic gate stalled")
 }
 @MainActor static func main() async throws {
  let pa=DelayedContext(),pb=DelayedContext()
  let a=AssistantConversation(provider:pa),b=AssistantConversation(provider:pb)
  a.select();b.select();a.ask("Synthetic A secret");b.ask("Synthetic B secret")
  await wait {pa.calls==1 && pb.calls==1}
  a.clear();pa.finish(0,"Must not return after clear")
  pb.finish(0,"Independent B reply");await wait {!b.busy}
  for _ in 0..<20 {await Task.yield()}
  var rows:[[String:Any]]=[]
  func check(_ id:String,_ passed:Bool){rows.append(["id":id,"passed":passed])}
  check("cleared-A-no-late-return",a.exchanges.isEmpty && a.pendingQuestion==nil && !a.busy && pa.context.isEmpty)
  check("clear-A-does-not-reset-independent-B",pb.context==["Synthetic B secret"] && b.exchanges.map(\.answer)==["Independent B reply"])
  a.ask("Synthetic A successor");await wait {pa.calls==2};pa.finish(1,"New independent A");await wait {!a.busy}
  check("successor-does-not-inherit-cleared-context",pa.context==["Synthetic A successor"] && a.exchanges.count==1)
  a.deselect();let accepted=a.ask("Must not send after profile revocation")
  check("deselection-revokes-requests-and-content",!accepted && pa.calls==2 && pa.context.isEmpty && a.exchanges.isEmpty)
  let fresh=AssistantConversation(provider:DelayedContext())
  check("new-owner-has-no-context-or-selection",fresh.exchanges.isEmpty && fresh.pendingQuestion==nil && fresh.availability == .notSelected)
  print(String(decoding:try JSONSerialization.data(withJSONObject:rows,options:[.sortedKeys]),as:UTF8.self))
  exit(rows.allSatisfy{$0["passed"] as? Bool==true} ? 0:1)
 }
}
