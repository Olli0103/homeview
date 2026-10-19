import Foundation
import Speech
import AVFoundation
@MainActor final class VoiceHold {
 var pending:[CheckedContinuation<Void,Never>]=[]
 func wait() async {await withCheckedContinuation {pending.append($0)}}
 func release() {precondition(!pending.isEmpty);pending.removeFirst().resume()}
}
@main struct VoiceIntegrationGate {
 @MainActor static func main() async throws {
  let args=ProcessInfo.processInfo.arguments
  guard args.contains("--uitesting"),let i=args.firstIndex(of:"--case"),args.indices.contains(i+1) else {fatalError("Owned synthetic case required")}
  let name=args[i+1],model=AppModel(),flow=AssistantVoiceSession()
  let speechBefore=SFSpeechRecognizer.authorizationStatus().rawValue,micBefore=AVCaptureDevice.authorizationStatus(for:.audio).rawValue
  var assertions=0
  func require(_ b:Bool,_ why:String) {assertions+=1;precondition(b,why)}
  func active() {model.route = .assistant;model.setAnswerSpeechForeground(true)}
  func wait(_ predicate:()->Bool) async throws {
   let end=ContinuousClock.now.advanced(by:.seconds(3))
   while !predicate() && ContinuousClock.now<end {await Task.yield()}
   require(predicate(),"Bounded owned scheduler condition")
  }
  func beginVoice() async {
   active();let epoch=model.personalSessionGeneration,mode=model.assistantUsesAI,old=model.assistantInput
   flow.start(locale:"de-DE",isCurrent:{model.assistantInteractionActive && model.personalSessionGeneration==epoch && model.assistantUsesAI==mode},onAborted:{if model.personalSessionGeneration==epoch {model.assistantInput=old}})
   await flow.gateStartTask?.value
   require(flow.voice.recording && flow.voice.gateSynthetic && !flow.voice.gateHasCapture,"Actual synthetic controller recording; no capture constructed")
  }
  func draft(_ text:String) async {
   await beginVoice()
   flow.voice.gateReceive(text,final:true,ticket:flow.voice.gateToken)
   require(flow.acceptsTranscript,"Only completed current-context text is accepted")
   if flow.acceptsTranscript {model.assistantInput=flow.voice.transcript}
  }
  func submit() {flow.cancel();model.runAssistant()}
  require(model.persist(),"Owned baseline snapshot saved")
  switch name {
  case "timer_transcripts":
   require(model.addTimer(seconds:1800,title:"Synthetic untouched timer"),"Positive pre-existing timer")
   let untouched=model.data.timers[0],home=model.data.home
   for (text,seconds,title) in [
    ("Timer auf 90 Sekunden namens Synthetic Tea",90,"Synthetic Tea"),
    ("set a timer for one hour and thirty minutes named Synthetic Pasta",5400,"Synthetic Pasta"),
    ("starte einen timer für fünf Minuten namens Synthetic Suppe",300,"Synthetic Suppe"),
    ("set a timer for 1.5 hours called Synthetic Fraction",5400,"Synthetic Fraction")
   ] {
    let count=model.data.timers.count
    await draft(text)
    require(model.data.timers.count==count && model.data.home==home,"Voice draft never creates a timer or acts on the home")
    submit()
    require(model.data.timers.count==count+1,"Only explicitly submitted expected timer is created")
    require(model.data.timers.last?.duration==Double(seconds) && model.data.timers.last?.title==title,"Exact requested duration/title")
    require(model.data.timers.first(where:{$0.id==untouched.id})==untouched,"Unrelated timer unchanged")
    require(model.data.nativeTimerIDs.isEmpty,"No system alarm permission or scheduling enabled")
   }
   let stored=try Snapshot.decodeMigrating(Data(contentsOf:model.gateStoreURL))
   require(stored.timers==model.data.timers,"Actual owned saved timer read-back")
  case "ambiguity_and_error":
   let home=model.data.home
   for text in ["set a timer","Timer auf 5 oder 10 Minuten","set a timer for -1 seconds","cancel timer for 5 minutes","set a timer for 1 minute and 2 minutes"] {
    await draft(text);submit()
    require(model.data.timers.isEmpty && model.data.home==home,"Ambiguity/negation changes no resource")
   }
   active();model.assistantInput="temperature 71";await beginVoice()
   flow.voice.gateReceive("set a timer for 90 seconds",ticket:flow.voice.gateToken)
   model.assistantInput=flow.voice.transcript
   flow.voice.gateReceive("",problem:"Synthetic recognition error.",ticket:flow.voice.gateToken)
   require(!flow.acceptsTranscript && flow.blocksSubmission,"Failed partial remains blocked before UI failure cleanup")
   flow.failureObserved()
   require(model.assistantInput=="temperature 71" && !flow.blocksSubmission,"Original typed fallback restored, not a guessed speech command")
   submit();require(model.data.home.temperature==71 && model.data.timers.isEmpty,"Only explicit typed fallback acts")
  case "cooking_transcripts":
   model.startCooking();let home=model.data.home
   for (text,step) in [("nächster schritt",1),("previous step",0),("next step",1),("vorheriger schritt",0),("schritt wiederholen",0),("repeat this step",0)] {
    let before=model.cookingStep;await draft(text)
    require(model.cookingStep==before,"No cooking move during recognition or preview")
    submit();require(model.cookingStep==step && model.cookingInProgress,"Only expected explicitly submitted cooking move/repeat")
    require(model.data.timers.isEmpty && model.data.home==home,"Cooking transcript cannot create a timer or home action")
   }
   while model.cookingInProgress {model.moveCookingStep(1)}
   let stopped=model.cookingStep;await draft("next step");submit()
   require(!model.cookingInProgress && model.cookingStep==stopped,"No cooking commands without an explicit active session")
   require(model.assistantReply.contains("start cooking"),"User gets clarification instead of fabricated step movement")
  case "queued_context":
   active();let hold=VoiceHold();var epoch=model.personalSessionGeneration
   flow.gateSetBoundary {await hold.wait()}
   flow.start(locale:"de-DE",isCurrent:{model.assistantInteractionActive && model.personalSessionGeneration==epoch},onAborted:{if model.personalSessionGeneration==epoch {model.assistantInput="old draft"}})
   let old=flow.gateStartTask!;try await wait {hold.pending.count==1}
   require(flow.starting && flow.blocksSubmission,"Queued start already blocks submission")
   model.lockPersonalAccess();model.assistantInput="new session draft"
   hold.release();await old.value
   require(!flow.active && flow.voice.phase == .idle,"Old queued capture cannot start after profile/session revocation")
   require(model.assistantInput=="new session draft","Old draft never restored across a session boundary")
   epoch=model.personalSessionGeneration
   active();flow.start(locale:"en-US",isCurrent:{true})
   let cancelled=flow.gateStartTask!;try await wait {hold.pending.count==1}
   flow.cancel();flow.gateSetBoundary {await Task.yield()};await beginVoice();let token=flow.voice.gateToken
   hold.release();await cancelled.value
   require(flow.voice.gateToken==token && flow.acceptsTranscript && !flow.starting,"Old completion cannot clear the new capture")
  case "controller_cancel_and_terminals":
   let voice=VoiceInputController(),hold=VoiceHold()
   let old=Task {await hold.wait();await voice.start(locale:"en-US")}
   try await wait {hold.pending.count==1};old.cancel();await voice.start(locale:"de-DE");let token=voice.gateToken
   hold.release();await old.value
   require(voice.gateToken==token && voice.recording,"Cancelled caller cannot replace a newer capture")
   voice.gateReceive("valid partial",ticket:token);voice.gateReceive("",final:true,ticket:token)
   require(voice.phase == .failed && voice.transcript.isEmpty,"Empty final cannot preserve a discarded partial")
   await voice.start(locale:"de-DE");let next=voice.gateToken
   voice.gateReceive(String(repeating:"x",count:1001),ticket:next)
   require(voice.phase == .failed && voice.transcript.isEmpty,"Overflow rejected, not clipped into a different command")
   await voice.start(locale:"en-US");let final=voice.gateToken
   voice.gateReceive("next step",final:true,ticket:final)
   voice.gateReceive("changed later",problem:"late error",ticket:final)
   require(voice.phase == .ready && voice.transcript=="next step","Terminal response is immutable")
   voice.cancel();voice.gateReceive("stale",final:true,ticket:final)
   require(voice.phase == .idle && voice.transcript.isEmpty && !voice.gateHasCapture,"Cancelled tickets cannot revive speech")
  case "context_and_failure_scope":
   active();model.assistantInput="typed original";await beginVoice();let token=flow.voice.gateToken
   model.incomingCall=true
   flow.voice.gateReceive("timer auf 90 sekunden",ticket:token)
   require(!flow.acceptsTranscript,"Call coverage immediately denies transcript publication without waiting for a view callback")
   flow.cancelAndRestore();require(model.assistantInput=="typed original","Same-session interruption restores only original typed draft")
   require(model.data.timers.isEmpty,"Interruption cannot execute a timer")
   model.incomingCall=false;await beginVoice();model.selectAssistantAnswers(true)
   require(!flow.contextIsCurrent && !flow.acceptsTranscript,"Provider mode change invalidates the capture context")
   flow.cancelAndRestore();require(model.data.timers.isEmpty,"Provider change cannot act on a speech partial")
  case "recording_deadline":
   let voice=VoiceInputController();await voice.start(locale:"de-DE");let start=ContinuousClock.now
   let end=start.advanced(by:.seconds(32))
   while voice.recording && ContinuousClock.now<end {try await Task.sleep(for:.milliseconds(20))}
   let elapsed=Double(start.duration(to:.now).components.seconds)+Double(start.duration(to:.now).components.attoseconds)/1e18
   require(voice.phase == .ready && !voice.busy,"Actual production 30-second recording deadline finishes synthetic capture")
   require(elapsed>=29 && elapsed<=32,"Predeclared scheduling window, not exact real-time or hardware timing")
   require(!voice.gateHasCapture && voice.gateSynthetic,"Deadline test never starts a microphone")
   print("observed_recording_seconds=\(elapsed)");voice.cancel()
  default:fatalError("Unknown owned scenario")
  }
  flow.cancel()
  require(SFSpeechRecognizer.authorizationStatus().rawValue==speechBefore && AVCaptureDevice.authorizationStatus(for:.audio).rawValue==micBefore,"Permission states unchanged; no real capture requested")
  print(String(data:try JSONSerialization.data(withJSONObject:["case":name,"assertions":assertions,"verdict":"PASS","permission_states_unchanged":true],options:[.sortedKeys]),encoding:.utf8)!)
 }
}
