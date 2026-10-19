import Foundation
@main struct NativeContextGate {
 @MainActor static func main() async throws {
  let args=ProcessInfo.processInfo.arguments
  guard let i=args.firstIndex(of:"--case"),args.indices.contains(i+1) else { fatalError("Owned case required") }
  let scenario=args[i+1],model=AppModel()
  var assertions=0
  func require(_ b:Bool,_ message:String) { assertions+=1;precondition(b,message) }
  func active() { model.route = .assistant;model.setAnswerSpeechForeground(true) }
  func wait(_ predicate:()->Bool) async throws {
   let end=ContinuousClock.now.advanced(by:.seconds(3))
   while !predicate() && ContinuousClock.now<end { try await Task.sleep(for:.milliseconds(1)) }
   require(predicate(),"Bounded fixture completion")
  }
  switch scenario {
  case "model_entry":
   func blocked(_ label:String) {
    let before=model.data
    model.assistantInput="temperature 72";model.runAssistant()
    require(model.data.home.temperature==before.home.temperature,label+" temperature unchanged")
    require(model.data.timers.count==before.timers.count,label+" timers unchanged")
    model.selectAssistantAnswers(true)
    require(!model.assistantUsesAI,label+" cannot enable model offscreen")
    require(model.assistantAI.availability == .notSelected,label+" provider not selected")
   }
   blocked("initial inactive face")
   model.setAnswerSpeechForeground(true);blocked("active face")
   model.route = .assistant;model.setAnswerSpeechForeground(false);blocked("inactive assistant")
   model.setAnswerSpeechForeground(true);model.incomingCall=true;blocked("covered by call")
   model.incomingCall=false;active()
   model.assistantInput="temperature 72";model.runAssistant()
   require(model.data.home.temperature==72,"Positive active model command must work")
   require(model.assistantInput.isEmpty,"Positive command consumed explicitly submitted text")
  case "text_only":
   active()
   model.data.personal["Alex"]=PersonalContent()
   model.data.personal["Alex"]!.messages=["SYNTHETIC_PRIVATE_MESSAGE_CANARY"]
   func cacheRows()->[[String]] {
    model.connections.events.map { ["event",$0.id,$0.title,String($0.start.timeIntervalSinceReferenceDate),String($0.end.timeIntervalSinceReferenceDate),$0.location,$0.calendar,String($0.cancelled),String($0.allDay)] }
      + model.connections.reminders.map { ["reminder",$0.id,$0.title,String($0.completed),$0.listTitle,String($0.writable)] }
   }
   func question(_ prompt:String) async throws {
    let requested=model.connections.requested,cached=cacheRows()
    model.selectAssistantAnswers(true);model.assistantInput=prompt;model.runAssistant()
    try await wait { !model.assistantAI.busy }
    require(model.assistantAI.gateSubmittedTexts==[prompt],"Provider receives exactly explicit text, no source/profile/screen enrichment")
    require(model.assistantAI.exchanges.map(\.question)==[prompt],"History stores only explicit text")
    require(!model.assistantAI.exchanges.contains(where:{$0.answer.contains("CANARY")}),"No seeded private message in fixture answer")
    require(model.connections.requested==requested,"Assistant cannot request source connection")
    require(cacheRows()==cached,"Assistant cannot change personal caches")
   }
   require(!model.connections.personalUnlocked,"Guest starts device locked")
   try await question("What is on my calendar and other screens?")
   model.signIn("Alex");active()
   require(!model.connections.personalUnlocked,"Demo profile grants no device authentication")
   try await question("Find my messages for Alex")
   let unlocked=await model.connections.unlock();require(unlocked,"Synthetic device authentication positive control")
   await model.connections.connect(.calendar)
   require(!model.connections.events.isEmpty,"Synthetic authorized calendar is actually populated for exclusion test")
   try await question("What can you see on this screen?")
   require(model.data.personal["Alex"]!.messages==["SYNTHETIC_PRIVATE_MESSAGE_CANARY"],"Private source unchanged")
  case "denied_auth":
   model.signIn("Alex");active()
   let granted=await model.connections.unlock()
   require(!granted && !model.connections.personalUnlocked,"Synthetic denied authentication stays locked despite profile")
   model.assistantInput="find my calendar events";model.runAssistant()
   require(model.connections.events.isEmpty && model.connections.reminders.isEmpty,"Unsupported local context query reads no cache")
   require(model.connections.requested.isEmpty,"Unsupported query grants no source purpose or permission")
   require(model.assistantAI.gateSubmittedTexts.isEmpty,"Local query is not sent to AI implicitly")
  case "inactive_queued":
   active();model.selectAssistantAnswers(true);model.assistantInput="Synthetic pending question";model.runAssistant()
   require(model.assistantAI.busy && model.assistantAI.pendingQuestion=="Synthetic pending question","Owned queued request exists before a view callback")
   model.setAnswerSpeechForeground(false)
   require(!model.assistantAI.busy && model.assistantAI.pendingQuestion==nil,"Inactive setter synchronously revokes pending conversation without view callback")
   require(model.assistantAI.exchanges.isEmpty && model.assistantAI.gateSubmittedTexts.isEmpty,"Provider and visible conversation reset together")
   model.assistantInput="temperature 75";model.runAssistant()
   require(model.data.home.temperature==68,"Inactive direct entry cannot mutate local state")
   active();model.assistantInput="New pending";model.runAssistant()
   require(model.assistantAI.busy && model.assistantAI.pendingQuestion=="New pending","New queued request exists")
   model.route = .face
   require(!model.assistantAI.busy && model.assistantAI.pendingQuestion==nil,"Route setter synchronously revokes newer pending task")
   await Task.yield()
   require(model.assistantAI.exchanges.isEmpty,"Cancelled task cannot restore response")
  case "authentication_inactive":
   active();model.selectAssistantAnswers(true);model.assistantInput="Synthetic readout answer";model.runAssistant()
   try await wait { model.assistantAI.exchanges.count==1 }
   let before=model.assistantAI.exchanges
   model.authorizingAnswerSpeech=true;model.setAnswerSpeechForeground(false)
   require(model.assistantAI.exchanges==before,"Authentication-prompt inactivity preserves the answer for a later explicit read tap")
   model.assistantInput="Must not send while inactive";model.runAssistant()
   require(model.assistantAI.gateSubmittedTexts==["Synthetic readout answer"],"Authentication inactivity does not grant send authority")
   model.setAnswerSpeechForeground(true);model.authorizingAnswerSpeech=false
   require(model.assistantAI.exchanges==before,"Return from prompt does not automatically consume the answer")
   model.lockPersonalAccess()
   require(model.assistantAI.exchanges.isEmpty && !model.assistantUsesAI,"Actual lock still invalidates context")
  case "draft_and_plan":
   active();model.assistantInput="unsent draft"
   model.route = .face
   require(model.assistantInput=="unsent draft","Harmless draft navigation contract retained")
   active();model.assistantInput="plan: temperature 72; brightness 30";model.runAssistant()
   require(model.demoPlan?.phase == .preview,"Positive local plan preview")
   model.route = .face
   require(model.demoPlan==nil,"Route setter invalidates plan synchronously")
   require(model.assistantInput=="plan: temperature 72; brightness 30","Unrun plan restored only as unsent draft")
   require(model.data.home.temperature==68 && model.data.home.brightness==75,"Unconfirmed preview never mutates")
   model.lockPersonalAccess()
   require(model.assistantInput.isEmpty && !model.assistantUsesAI,"Lock clears text and selection")
  default:fatalError("Unknown owned scenario")
  }
  let result:[String:Any]=["case":scenario,"assertions":assertions,"verdict":"PASS"]
  print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
 }
}
