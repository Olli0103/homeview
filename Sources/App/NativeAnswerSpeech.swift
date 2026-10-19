import Foundation
#if !os(watchOS) && !os(tvOS)
@preconcurrency import AVFoundation

// Retain-only bridge: no utterance property is read or mutated off its owner.
// Keeps ObjectIdentifier unique until the queued MainActor callback is handled.
private final class UtteranceCallbackLifetime:@unchecked Sendable {
  private let utterance:AVSpeechUtterance
  init(_ utterance:AVSpeechUtterance) { self.utterance=utterance }
}

@MainActor final class SystemAnswerSpeech:NSObject,AnswerSpeechBackend,AVSpeechSynthesizerDelegate {
  private var synth:AVSpeechSynthesizer?
  private var active:ObjectIdentifier?
  private var completion:(@MainActor (Bool) -> Void)?
  private var sessionActive=false
  private func permittedVoices() -> [AVSpeechSynthesisVoice] {
    // Never request Personal Voice authorization or expose/use a personal voice.
    AVSpeechSynthesisVoice.speechVoices().filter { !$0.voiceTraits.contains(.isPersonalVoice) }
  }
  func voices() -> [AnswerSpeechVoice] {
    permittedVoices().map { AnswerSpeechVoice(id:$0.identifier,name:$0.name,language:$0.language) }
      .sorted { ($0.language,$0.name,$0.id)<($1.language,$1.name,$1.id) }
  }
  func start(text:String,voiceID:String,rate:Float,volume:Float,
    completion:@escaping @MainActor (Bool) -> Void) throws {
    stop()
    guard let voice=permittedVoices().first(where: { $0.identifier==voiceID }) else {
      throw NativeAudioError.missingAsset
    }
    #if os(iOS) || os(visionOS)
      let audio=AVAudioSession.sharedInstance()
      try audio.setCategory(.playback,mode:.spokenAudio,options:[])
      try audio.setActive(true);sessionActive=true
    #endif
    if synth==nil { synth=AVSpeechSynthesizer();synth?.delegate=self }
    #if os(iOS) || os(visionOS)
      synth?.usesApplicationAudioSession=true
      synth?.mixToTelephonyUplink=false
    #endif
    let utterance=AVSpeechUtterance(string:text)
    utterance.voice=voice;utterance.rate=rate;utterance.volume=volume
    active=ObjectIdentifier(utterance);self.completion=completion
    synth?.speak(utterance)
  }
  func stop() {
    active=nil;completion=nil
    synth?.stopSpeaking(at:.immediate)
    // A stop before native isSpeaking may leave a queued start. Release this
    // request's client as well; the next readout creates a fresh synthesizer.
    synth=nil
    deactivate()
  }
  private func deactivate() {
    #if os(iOS) || os(visionOS)
      if sessionActive { try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation) }
    #endif
    sessionActive=false
  }
  private func finished(_ id:ObjectIdentifier,success:Bool) {
    guard active==id else { return }
    let callback=completion;active=nil;completion=nil;synth=nil;deactivate();callback?(success)
  }
  nonisolated func speechSynthesizer(_ synthesizer:AVSpeechSynthesizer,didFinish utterance:AVSpeechUtterance) {
    let id=ObjectIdentifier(utterance),lifetime=UtteranceCallbackLifetime(utterance)
    Task { @MainActor [weak self] in withExtendedLifetime(lifetime) { self?.finished(id,success:true) } }
  }
  nonisolated func speechSynthesizer(_ synthesizer:AVSpeechSynthesizer,didCancel utterance:AVSpeechUtterance) {
    let id=ObjectIdentifier(utterance),lifetime=UtteranceCallbackLifetime(utterance)
    Task { @MainActor [weak self] in withExtendedLifetime(lifetime) { self?.finished(id,success:false) } }
  }
}
#endif

@MainActor final class FixtureAnswerSpeech:AnswerSpeechBackend {
  private let available:Bool
  private var completion:(@MainActor (Bool) -> Void)?
  init(available:Bool=true) { self.available=available }
  func voices() -> [AnswerSpeechVoice] {
    available ? [AnswerSpeechVoice(id:"fixture.en.one",name:"Synthetic English One",language:"en-US"),
      AnswerSpeechVoice(id:"fixture.en.two",name:"Synthetic English Two",language:"en-US"),
      AnswerSpeechVoice(id:"fixture.de.one",name:"Synthetic Deutsch",language:"de-DE")]:[]
  }
  func start(text:String,voiceID:String,rate:Float,volume:Float,
    completion:@escaping @MainActor (Bool) -> Void) throws { self.completion=completion }
  func stop() { completion=nil }
}
@MainActor func makeAnswerSpeechBackend() -> any AnswerSpeechBackend {
  let args=ProcessInfo.processInfo.arguments
  if args.contains("--uitesting") {
    let available=args.contains("--answer-speech-fixture") && !args.contains("--answer-speech-unavailable")
    return FixtureAnswerSpeech(available:available)
  }
  #if !os(watchOS) && !os(tvOS)
    return SystemAnswerSpeech()
  #else
    return FixtureAnswerSpeech(available:false)
  #endif
}
