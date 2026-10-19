import XCTest
import Darwin
@testable import HomeViewCore

final class LocalStateResetTests:XCTestCase {
  private var base:URL!
  override func setUpWithError() throws {
    let parent=ProcessInfo.processInfo.environment["HOMEVIEW_TEST_ARTIFACTS"].map { URL(fileURLWithPath:$0,isDirectory:true) }
      ?? FileManager.default.temporaryDirectory
    base=parent.appendingPathComponent("local-reset-"+UUID().uuidString,isDirectory:true)
    try FileManager.default.createDirectory(at:base,withIntermediateDirectories:true)
  }
  override func tearDownWithError() throws { try FileManager.default.removeItem(at:base) }
  private func oldStore()->URL {
    base.appendingPathComponent("test-"+UUID().uuidString,isDirectory:true)
  }
  private func seed(_ root:URL)throws {
    try FileManager.default.createDirectory(at:root.appendingPathComponent("photos"),withIntermediateDirectories:true)
    try FileManager.default.createDirectory(at:root.appendingPathComponent("State Recovery"),withIntermediateDirectories:true)
    var state=Snapshot();state.personal["Alex"]=PersonalContent()
    state.personal["Alex"]!.messages=["SYNTHETIC_OLD_LOCAL_CANARY"]
    state.connectionConsent=[.calendar,.music]
    try JSONEncoder().encode(state).write(to:root.appendingPathComponent("mock-state.json"))
    try Data("SYNTHETIC_PHOTO_COPY".utf8).write(to:root.appendingPathComponent("photos/old.jpg"))
    try Data("SYNTHETIC_RECOVERY_COPY".utf8).write(to:root.appendingPathComponent("State Recovery/old.json"))
  }
  func testAtomicResetRemovesAppCopiesAndRecoveryButNotOutsideSymlinkTarget() throws {
    let root=oldStore();try seed(root)
    let outside=base.appendingPathComponent("outside",isDirectory:true)
    try FileManager.default.createDirectory(at:outside,withIntermediateDirectories:true)
    let canary=outside.appendingPathComponent("keep.txt"),bytes=Data("SYNTHETIC_OUTSIDE_CANARY".utf8)
    try bytes.write(to:canary)
    try FileManager.default.createSymbolicLink(at:root.appendingPathComponent("photos/outside-link"),withDestinationURL:outside)
    let result=try LocalStateReset.reset(directory:root)
    XCTAssertTrue(result.oldFilesRemoved);XCTAssertTrue(result.snapshot.personal.isEmpty)
    XCTAssertEqual(result.snapshot.connectionConsent,[])
    let saved=try Snapshot.decodeMigrating(Data(contentsOf:root.appendingPathComponent("mock-state.json")))
    XCTAssertTrue(saved.personal.isEmpty);XCTAssertEqual(saved.photoSelection,.none)
    XCTAssertEqual(saved.connectionConsent,[]);XCTAssertTrue(saved.nativeAlarmIDs.isEmpty)
    XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:root.path),["mock-state.json"])
    XCTAssertEqual(try Data(contentsOf:canary),bytes)
  }
  func testFIFOIsNotOpenedAndCleanupResidueRemainsRetryable() throws {
    let root=oldStore();try seed(root)
    XCTAssertEqual(mkfifo(root.appendingPathComponent("pending.pipe").path,mode_t(0o600)),0)
    let result=try LocalStateReset.reset(directory:root)
    XCTAssertFalse(result.oldFilesRemoved)
    XCTAssertTrue(result.snapshot.personal.isEmpty)
    XCTAssertFalse(LocalStateReset.retryCleanup(directory:root))
    let current=try Data(contentsOf:root.appendingPathComponent("mock-state.json"))
    XCTAssertThrowsError(try LocalStateReset.reset(directory:root),"A new reset must not lose an old cleanup record")
    XCTAssertEqual(try Data(contentsOf:root.appendingPathComponent("mock-state.json")),current)
    let journal=try XCTUnwrap(JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("reset-cleanup.json"))) as? [String:Any])
    let retired=base.appendingPathComponent(try XCTUnwrap(journal["stage"] as? String),isDirectory:true)
    XCTAssertEqual(unlink(retired.appendingPathComponent("pending.pipe").path),0)
    XCTAssertTrue(LocalStateReset.retryCleanup(directory:root))
    XCTAssertFalse(FileManager.default.fileExists(atPath:retired.path))
    XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:root.path),["mock-state.json"])
  }
  func testUnownedDirectoryRejectedBeforeAnyFileOrStageChange() throws {
    let root=base.appendingPathComponent("not-our-store",isDirectory:true);try seed(root)
    let original=try Data(contentsOf:root.appendingPathComponent("mock-state.json"))
    let before=try FileManager.default.contentsOfDirectory(atPath:base.path)
    XCTAssertThrowsError(try LocalStateReset.reset(directory:root))
    XCTAssertEqual(try Data(contentsOf:root.appendingPathComponent("mock-state.json")),original)
    XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:base.path),before)
  }
  func testSymlinkRootCannotResetItsTargetOrCreateAStage() throws {
    let outside=base.appendingPathComponent("outside",isDirectory:true);try seed(outside)
    let root=oldStore();try FileManager.default.createSymbolicLink(at:root,withDestinationURL:outside)
    let original=try Data(contentsOf:outside.appendingPathComponent("mock-state.json"))
    let before=try FileManager.default.contentsOfDirectory(atPath:base.path)
    XCTAssertThrowsError(try LocalStateReset.reset(directory:root))
    XCTAssertEqual(try Data(contentsOf:outside.appendingPathComponent("mock-state.json")),original)
    XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath:base.path),before)
  }
  func testForgedCleanupJournalCannotSelectAnUnownedOrWrongInodeDirectory() throws {
    let root=oldStore();try seed(root)
    let lookalike=base.appendingPathComponent(".homeview-reset-"+UUID().uuidString,isDirectory:true)
    try FileManager.default.createDirectory(at:lookalike,withIntermediateDirectories:true)
    let canary=lookalike.appendingPathComponent("canary"),bytes=Data("SYNTHETIC_DO_NOT_DELETE".utf8)
    try bytes.write(to:canary)
    for stage in ["../outside",lookalike.lastPathComponent] {
      let journal:[String:Any]=["stage":stage,"device":0,"inode":0]
      try JSONSerialization.data(withJSONObject:journal).write(to:root.appendingPathComponent("reset-cleanup.json"))
      XCTAssertFalse(LocalStateReset.retryCleanup(directory:root))
      XCTAssertEqual(try Data(contentsOf:canary),bytes)
    }
  }
}


@MainActor private final class ResetVoiceBackend:AnswerSpeechBackend {
  var completion:(@MainActor (Bool)->Void)?
  var starts=0
  func voices()->[AnswerSpeechVoice] { [.init(id:"synthetic-de",name:"Synthetic",language:"de-DE")] }
  func start(text:String,voiceID:String,rate:Float,volume:Float,completion:@escaping @MainActor (Bool)->Void)throws {
    starts+=1;self.completion=completion
  }
  func stop() {}
}
extension LocalStateResetTests {
  @MainActor func testReadoutResetDiscardsVoicePreferencesAndLateCompletionWithoutReplay() {
    let backend=ResetVoiceBackend()
    let speech=AnswerSpeechSession(backend:backend)
    speech.loadVoices();speech.chooseLanguage("de-DE");speech.setRate(0.65)
    XCTAssertTrue(speech.speak("Synthetic answer",authorized:true,foreground:true,volume:0))
    speech.setMuted(true);speech.resetPreferences();let status=speech.status
    backend.completion?(false)
    XCTAssertFalse(speech.speaking);XCTAssertFalse(speech.muted);XCTAssertTrue(speech.voices.isEmpty)
    XCTAssertNil(speech.voiceID);XCTAssertEqual(speech.language,"en-US");XCTAssertEqual(speech.rate,0.5)
    XCTAssertEqual(backend.starts,1);XCTAssertEqual(speech.status,status)
  }
}
