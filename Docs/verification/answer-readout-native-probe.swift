import Foundation
@main struct MutedNativeSpeech {
 @MainActor static func wait(_ condition:() -> Bool) async -> Bool {
  for _ in 0..<5000 { if condition() { return true };try? await Task.sleep(nanoseconds:1_000_000) }
  return condition()
 }
 @MainActor static func main() async throws {
  let backend=SystemAnswerSpeech()
  let speech=AnswerSpeechSession(backend:backend);speech.loadVoices()
  guard speech.voiceID != nil else { print("ORDINARY_VOICE_UNAVAILABLE");exit(2) }
  let long=String(String(repeating:"This is a synthetic HomeView answer. ",count:120).prefix(4000))
  let accepted=speech.speak(long,authorized:true,foreground:true,volume:0)
  let began=await wait { backend.gateNativeSpeaking }
  speech.stop()
  let stopped=await wait { !backend.gateNativeSpeaking }
  try await Task.sleep(nanoseconds:100_000_000)
  let cancelPassed=accepted && began && stopped && !speech.speaking && backend.gateClear
  let first:[String:Any]=["id":"actual-backend-stop","passed":cancelPassed,"nativeStarted":began,
    "nativeStopped":stopped,"coreStopped":!speech.speaking,"nativeCleared":backend.gateClear,"volume":0,"inputCharacters":long.count]
  let naturalAccepted=speech.speak("This is a short synthetic test.",authorized:true,foreground:true,volume:0)
  let finished=await wait { !speech.speaking }
  let second:[String:Any]=["id":"actual-backend-finish","passed":naturalAccepted && finished && speech.status=="Readout finished." && backend.gateClear,"status":speech.status,"volume":0]
  speech.stop()
  speech.speak(long,authorized:true,foreground:true,volume:0)
  let retiredClient=backend.gateCaptureClient()
  speech.stop()
  var lateStart=false,retiredAlive=0
  for _ in 0..<500 { let old=retiredClient();if old.0 {retiredAlive+=1};lateStart=lateStart || old.1;try await Task.sleep(nanoseconds:1_000_000) }
  let third:[String:Any]=["id":"immediate-stop-no-queued-late-start","passed":!lateStart && retiredAlive==0 && !speech.speaking && backend.gateClear,"retiredOwnerAliveSamples":retiredAlive,"lateNativeStart":lateStart,"volume":0]
  speech.speak(long,authorized:true,foreground:true,volume:0)
  _=await wait {backend.gateNativeSpeaking}
  speech.stop();speech.speak(long,authorized:true,foreground:true,volume:0)
  let currentBegan=await wait {backend.gateNativeSpeaking}
  try await Task.sleep(nanoseconds:100_000_000)
  let successor=currentBegan && speech.speaking && !backend.gateClear
  speech.stop();_=await wait {!backend.gateNativeSpeaking}
  let fourth:[String:Any]=["id":"old-cancel-callback-does-not-stop-successor","passed":successor && backend.gateClear && !speech.speaking,"volume":0]
  print(String(decoding:try JSONSerialization.data(withJSONObject:[first,second,third,fourth],options:[.sortedKeys]),as:UTF8.self))
  exit([first,second,third,fourth].allSatisfy {$0["passed"] as? Bool==true} ? 0:1)
 }
}
