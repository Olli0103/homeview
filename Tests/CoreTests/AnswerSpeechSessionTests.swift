import XCTest
@testable import HomeViewCore

@MainActor private final class ControlledSpeech:AnswerSpeechBackend {
  var catalogue=[AnswerSpeechVoice(id:"en1",name:"Synthetic English One",language:"en-US"),
    AnswerSpeechVoice(id:"en2",name:"Synthetic English Two",language:"en-US"),
    AnswerSpeechVoice(id:"de1",name:"Synthetic Deutsch",language:"de-DE")]
  var played:[(String,String,Float,Float)]=[]
  var completions:[@MainActor (Bool) -> Void]=[]
  var stops=0
  var fails=false
  func voices() -> [AnswerSpeechVoice] { catalogue }
  func stop() { stops+=1 }
  func start(text:String,voiceID:String,rate:Float,volume:Float,completion:@escaping @MainActor (Bool) -> Void) throws {
    if fails { throw NSError(domain:"PRIVATE_SYNTHETIC_ERROR_CANARY",code:1) }
    played.append((text,voiceID,rate,volume));completions.append(completion)
  }
}
@MainActor final class AnswerSpeechSessionTests:XCTestCase {
  func testVoiceOptionsAndChangesNeverPlayOrReplayAnything() {
    let p=ControlledSpeech()
    let s=AnswerSpeechSession(backend:p);XCTAssertTrue(s.voices.isEmpty)
    s.loadVoices();s.chooseLanguage("de-DE");s.chooseVoice("de1");s.setRate(0.6);s.setMuted(true);s.setMuted(false)
    XCTAssertTrue(p.played.isEmpty);XCTAssertFalse(s.speaking);XCTAssertEqual(s.language,"de-DE")
  }
  func testLockedOrInactiveNeverStartsAndRevokesExistingReadout() {
    let p=ControlledSpeech();let s=AnswerSpeechSession(backend:p);s.loadVoices()
    XCTAssertFalse(s.speak("private",authorized:false,foreground:true,volume:1))
    XCTAssertFalse(s.speak("private",authorized:true,foreground:false,volume:1));XCTAssertTrue(p.played.isEmpty)
    XCTAssertTrue(s.speak("permitted",authorized:true,foreground:true,volume:1));XCTAssertTrue(s.speaking)
    XCTAssertFalse(s.speak("private",authorized:false,foreground:true,volume:1));XCTAssertFalse(s.speaking)
    XCTAssertEqual(p.played.count,1)
  }
  func testEmptyOversizedOrInvalidVolumeCannotReachBackend() {
    let p=ControlledSpeech();let s=AnswerSpeechSession(backend:p);s.loadVoices()
    for text in ["   ",String(repeating:"x",count:4001)] {
      XCTAssertFalse(s.speak(text,authorized:true,foreground:true,volume:1))
    }
    for volume:Float in [.nan,.infinity,-1,2] {
      XCTAssertFalse(s.speak("valid",authorized:true,foreground:true,volume:volume))
    }
    XCTAssertTrue(p.played.isEmpty)
  }
  func testFullLengthAnswerUsesChosenVoiceRateAndVolumeWithoutTruncation() {
    let p=ControlledSpeech();let s=AnswerSpeechSession(backend:p);s.loadVoices()
    s.chooseVoice("en2");s.setRate(0.65)
    let text=String(repeating:"a",count:4000)
    XCTAssertTrue(s.speak(text,authorized:true,foreground:true,volume:0.7))
    XCTAssertEqual(p.played.count,1);XCTAssertEqual(p.played[0].0,text)
    XCTAssertEqual(p.played[0].1,"en2");XCTAssertEqual(p.played[0].2,0.65);XCTAssertEqual(p.played[0].3,0.7)
  }
  func testMuteStopsAndUnmuteNeverReplays() {
    let p=ControlledSpeech();let s=AnswerSpeechSession(backend:p);s.loadVoices()
    s.speak("first",authorized:true,foreground:true,volume:1);let stopped=p.stops
    s.setMuted(true);XCTAssertFalse(s.speaking);XCTAssertGreaterThan(p.stops,stopped)
    XCTAssertFalse(s.speak("second",authorized:true,foreground:true,volume:1))
    s.setMuted(false);XCTAssertEqual(p.played.count,1);XCTAssertFalse(s.speaking)
  }
  func testStaleCompletionCannotFinishSuccessor() {
    let p=ControlledSpeech();let s=AnswerSpeechSession(backend:p);s.loadVoices()
    s.speak("old",authorized:true,foreground:true,volume:1)
    s.speak("new",authorized:true,foreground:true,volume:1)
    p.completions[0](true);XCTAssertTrue(s.speaking);XCTAssertTrue(s.status.contains("Reading"))
    p.completions[1](true);XCTAssertFalse(s.speaking);XCTAssertTrue(s.status.contains("finished"))
  }
  func testLateCancellationCannotOverwriteNewFinishedState() {
    let p=ControlledSpeech();let s=AnswerSpeechSession(backend:p);s.loadVoices()
    s.speak("old",authorized:true,foreground:true,volume:1);s.stop()
    s.speak("new",authorized:true,foreground:true,volume:1);p.completions[1](true)
    let status=s.status;p.completions[0](false);XCTAssertEqual(s.status,status);XCTAssertFalse(s.speaking)
  }
  func testBackendErrorIsSanitizedAndStopped() {
    let p=ControlledSpeech();p.fails=true
    let s=AnswerSpeechSession(backend:p);s.loadVoices()
    XCTAssertFalse(s.speak("private input",authorized:true,foreground:true,volume:1))
    XCTAssertFalse(s.speaking);XCTAssertFalse(s.status.contains("CANARY"));XCTAssertTrue(s.status.contains("unavailable"))
  }
  func testInvalidSettingsPreservePreviousChoiceAndNeverSpeak() {
    let p=ControlledSpeech();let s=AnswerSpeechSession(backend:p);s.loadVoices()
    s.chooseVoice("en2");s.chooseVoice("de1");s.chooseLanguage("unknown")
    for rate:Float in [.nan,.infinity,0.2,0.8] { s.setRate(rate) }
    XCTAssertEqual(s.voiceID,"en2");XCTAssertEqual(s.language,"en-US");XCTAssertEqual(s.rate,0.5)
    XCTAssertTrue(p.played.isEmpty)
  }
  func testMissingOrDisappearingVoiceNeverFallsBackToAnotherLanguage() {
    let p=ControlledSpeech();let s=AnswerSpeechSession(backend:p);s.loadVoices()
    p.catalogue=p.catalogue.filter { $0.language=="de-DE" };s.loadVoices()
    XCTAssertNil(s.voiceID);XCTAssertFalse(s.speak("English",authorized:true,foreground:true,volume:1))
    s.chooseLanguage("de-DE");XCTAssertEqual(s.voiceID,"de1")
    p.catalogue=[];s.loadVoices();XCTAssertNil(s.voiceID);XCTAssertTrue(s.voices.isEmpty)
  }
  func testSettingsChangeRevokesPendingCallbacks() {
    let p=ControlledSpeech();let s=AnswerSpeechSession(backend:p);s.loadVoices()
    s.speak("old",authorized:true,foreground:true,volume:1);s.chooseLanguage("de-DE")
    let state=s.status;p.completions[0](true);XCTAssertFalse(s.speaking);XCTAssertEqual(s.status,state)
  }
  func testPreCancelledCallerDoesNotStartReadout() async {
    let p=ControlledSpeech();let s=AnswerSpeechSession(backend:p);s.loadVoices()
    let task=Task { @MainActor in s.speak("private",authorized:true,foreground:true,volume:1) }
    task.cancel();let result=await task.value;XCTAssertFalse(result);XCTAssertTrue(p.played.isEmpty)
  }
}
