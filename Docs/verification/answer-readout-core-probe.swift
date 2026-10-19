import Foundation
@MainActor final class GateSpeech:AnswerSpeechBackend {
 var fail=false
 var starts=0
 var stops=0
 var callbacks:[@MainActor (Bool) -> Void]=[]
 func voices() -> [AnswerSpeechVoice] { [AnswerSpeechVoice(id:"en",name:"Synthetic",language:"en-US")] }
 func stop() { stops+=1 }
 func start(text:String,voiceID:String,rate:Float,volume:Float,completion:@escaping @MainActor (Bool) -> Void) throws {
  if fail { throw NSError(domain:"PRIVATE_ERROR_CANARY",code:1) }
  starts+=1;callbacks.append(completion)
 }
}
@main struct CoreSpeechGate {
 @MainActor static func main() async throws {
  var rows:[[String:Any]]=[]
  func row(_ id:String,_ passed:Bool) { rows.append(["id":id,"passed":passed]) }
  do {
   let p=GateSpeech();let c=AnswerSpeechSession(backend:p)
   c.loadVoices();c.setRate(0.6);c.setMuted(true);c.setMuted(false)
   row("settings-never-start-or-replay",p.starts==0 && !c.speaking)
   let locked=c.speak("PRIVATE_TEXT_CANARY",authorized:false,foreground:true,volume:1)
   let background=c.speak("PRIVATE_TEXT_CANARY",authorized:true,foreground:false,volume:1)
   row("locked-and-background-zero-start",!locked && !background && p.starts==0)
   let empty=c.speak(" ",authorized:true,foreground:true,volume:1)
   let huge=c.speak(String(repeating:"x",count:4001),authorized:true,foreground:true,volume:1)
   let invalidVolume=c.speak("text",authorized:true,foreground:true,volume:.nan)
   row("invalid-input-zero-start",!empty && !huge && !invalidVolume && p.starts==0)
   let t=Task { @MainActor in c.speak("PRIVATE_TEXT_CANARY",authorized:true,foreground:true,volume:1) };t.cancel()
   let result=await t.value
   row("pre-cancel-zero-start",!result && p.starts==0)
  }
  do {
   let p=GateSpeech();let c=AnswerSpeechSession(backend:p);c.loadVoices()
   c.speak("old",authorized:true,foreground:true,volume:1);c.stop()
   c.speak("current",authorized:true,foreground:true,volume:1)
   p.callbacks[0](true);p.callbacks[0](false)
   row("late-old-events-cannot-finish-current",c.speaking && p.starts==2 && c.status.contains("Reading"))
   c.setMuted(true);let state=c.status;p.callbacks[1](true);c.setMuted(false)
   row("mute-revokes-events-and-unmute-never-replays",!c.speaking && p.starts==2 && state.contains("muted"))
  }
  do {
   let p=GateSpeech();p.fail=true
   let c=AnswerSpeechSession(backend:p);c.loadVoices()
   let result=c.speak("PRIVATE_TEXT_CANARY",authorized:true,foreground:true,volume:1)
   row("backend-error-sanitized-and-stopped",!result && !c.speaking && !c.status.contains("CANARY") && p.starts==0 && p.stops>=2)
  }
  do {
   let p=GateSpeech();weak var released:AnswerSpeechSession?
   do {
    let c=AnswerSpeechSession(backend:p);released=c;c.loadVoices();c.speak("synthetic",authorized:true,foreground:true,volume:1);c.stop()
   }
   for callback in p.callbacks { callback(false) }
   row("retained-backend-callback-does-not-retain-owner",released==nil)
  }
  print(String(decoding:try JSONSerialization.data(withJSONObject:rows,options:[.sortedKeys]),as:UTF8.self))
  exit(rows.allSatisfy { $0["passed"] as? Bool==true } ? 0:1)
 }
}
