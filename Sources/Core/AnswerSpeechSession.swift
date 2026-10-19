import Foundation
import Observation

struct AnswerSpeechVoice:Identifiable,Equatable,Sendable {
  let id:String
  let name:String
  let language:String
}
@MainActor protocol AnswerSpeechBackend:AnyObject {
  func voices() -> [AnswerSpeechVoice]
  func start(text:String,voiceID:String,rate:Float,volume:Float,
    completion:@escaping @MainActor (Bool) -> Void) throws
  func stop()
}
/// Text is kept only by the active system utterance, never by persistent state.
@MainActor @Observable final class AnswerSpeechSession {
  private let backend:any AnswerSpeechBackend
  private(set) var voices:[AnswerSpeechVoice]=[]
  private(set) var language="en-US"
  private(set) var voiceID:String?
  private(set) var rate:Float=0.5
  private(set) var muted=false
  private(set) var speaking=false
  private(set) var generation=0
  var status="Readout is manual. Unlock this device before speaking; no Siri voice identity is promised."
  init(backend:any AnswerSpeechBackend) { self.backend=backend }
  var languages:[String] { Array(Set(voices.map(\.language))).sorted() }
  var languageVoices:[AnswerSpeechVoice] { voices.filter { $0.language==language } }
  func resetPreferences() {
    stop();voices=[];language="en-US";voiceID=nil;rate=0.5;muted=false
    status="Readout is manual. Unlock this device before speaking; no Siri voice identity is promised."
  }
  func loadVoices() {
    stop()
    voices=Array(backend.voices().prefix(500))
    if !languageVoices.contains(where: { $0.id==voiceID }) { voiceID=languageVoices.first?.id }
    status=voices.isEmpty ? "No permitted system voice is available here.":"Choose a system voice and rate. Readout never starts automatically."
  }
  func chooseLanguage(_ value:String) {
    stop();guard languages.contains(value) else { return }
    language=value;voiceID=languageVoices.first?.id
  }
  func chooseVoice(_ id:String) {
    stop();guard languageVoices.contains(where: { $0.id==id }) else { return };voiceID=id
  }
  func setRate(_ value:Float) {
    stop();guard value.isFinite,(0.35...0.65).contains(value) else {
      status="Use a speech rate between 0.35 and 0.65.";return
    };rate=value
  }
  func setMuted(_ value:Bool) { stop();muted=value;status=value ? "Readout muted. Unmuting will not replay anything.":"Readout unmuted. Tap Read explicitly." }
  func stop(status:String="Readout stopped. Nothing will resume automatically.") {
    generation+=1;speaking=false;backend.stop();self.status=status
  }
  @discardableResult func speak(_ input:String,authorized:Bool,foreground:Bool,volume:Float) -> Bool {
    guard authorized,foreground else { stop(status:"Readout requires an active, unlocked app.");return false }
    guard !Task.isCancelled else { return false }
    let text=input.trimmingCharacters(in:.whitespacesAndNewlines)
    guard !muted else { status="Readout is muted.";return false }
    guard !text.isEmpty,text.count<=4000,volume.isFinite,(0...1).contains(volume),
      let voiceID,languageVoices.contains(where: { $0.id==voiceID }) else {
      status="Choose an available system voice and an answer of 1 to 4000 characters.";return false
    }
    stop();let ticket=generation;speaking=true;status="Reading the selected answer…"
    do {
      try backend.start(text:text,voiceID:voiceID,rate:rate,volume:volume) { [weak self] success in
        guard let self,self.generation==ticket else { return }
        self.speaking=false;self.status=success ? "Readout finished.":"System readout stopped or failed. No automatic retry."
      }
      return true
    } catch {
      guard generation==ticket else { return false }
      stop(status:"System readout is unavailable. No automatic retry.");return false
    }
  }
}
