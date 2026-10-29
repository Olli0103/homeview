import Foundation

extension AppModel {
  func stopAnswerSpeech() {
    answerSpeechAttempt+=1;preparingAnswerSpeech=false;authorizingAnswerSpeech=false
    answerSpeech.stop()
  }
  func setAnswerSpeechForeground(_ active:Bool) {
    answerSpeechForeground=active
    // A system authentication prompt is inactive, not a background lock.
    // Keep the selected answer for the required later explicit read tap.
    if !active,!authorizingAnswerSpeech { assistantAI.clear() }
    #if !os(watchOS)
      if !active { discardDemoPlan() }
    #endif
    // Device authentication may temporarily make the scene inactive. It never
    // starts speech: successful authorization only enables a second explicit tap.
    if !active,!authorizingAnswerSpeech { stopAnswerSpeech() }
  }
  var answerReadoutText:String? {
    if assistantUsesAI { return assistantAI.busy ? nil:assistantAI.exchanges.last?.answer }
    return assistantDocument?.readoutText ?? assistantReply
  }
  #if !os(watchOS)
  func readAssistantAnswer() async {
    guard !Task.isCancelled,!preparingAnswerSpeech,route == .assistant,answerSpeechForeground else { return }
    showAnswerSpeechStatus=true
    guard !answerSpeech.muted else { answerSpeech.status="Readout is muted.";return }
    guard let text=answerReadoutText else { answerSpeech.status="Wait for an answer before reading it.";return }
    if answerSpeech.voices.isEmpty { answerSpeech.loadVoices() }
    guard answerSpeech.voiceID != nil else { answerSpeech.status="Choose an available system voice before readout.";return }
    if !connections.personalUnlocked {
      stopAnswerSpeech();answerSpeechAttempt+=1
      let attempt=answerSpeechAttempt,ticket=answerSpeech.generation,session=personalSessionGeneration
      preparingAnswerSpeech=true;authorizingAnswerSpeech=true
      defer { if answerSpeechAttempt==attempt { preparingAnswerSpeech=false;authorizingAnswerSpeech=false } }
      let granted=await connections.unlock()
      guard !Task.isCancelled,answerSpeechAttempt==attempt,answerSpeech.generation==ticket,
        personalSessionGeneration==session,route == .assistant else { return }
      answerSpeech.status=granted
        ? "Device unlocked. Tap Read explicitly to speak; nothing has been played."
        : "Device unlock was not granted. Nothing was spoken."
      return
    }
    stopAudioForVoice()
    answerSpeechAttempt+=1
    let attempt=answerSpeechAttempt,ticket=answerSpeech.generation,session=personalSessionGeneration
    preparingAnswerSpeech=true
    defer { if answerSpeechAttempt==attempt { preparingAnswerSpeech=false } }
    let ready=await audio.prepareForSpeech()
    guard !Task.isCancelled,answerSpeechAttempt==attempt,answerSpeech.generation==ticket,
      personalSessionGeneration==session,connections.personalUnlocked,answerSpeechForeground,
      route == .assistant,answerReadoutText==text else { return }
    guard ready else { answerSpeech.status="A timer chime has priority. Try Read again after it finishes.";return }
    answerSpeech.speak(text,authorized:true,foreground:true,volume:Float(data.volume))
  }
  #endif
}
