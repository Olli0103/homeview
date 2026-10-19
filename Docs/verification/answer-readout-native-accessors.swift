
// Independent read-only inspection; exact production prefix above.
extension SystemAnswerSpeech {
  var gateNativeSpeaking:Bool { synth?.isSpeaking==true }
  var gateClear:Bool { active==nil && completion==nil && !sessionActive && synth==nil }
  func gateCaptureClient() -> @MainActor () -> (Bool,Bool) {
    weak var client=synth
    return { (client != nil,client?.isSpeaking==true) }
  }
}
