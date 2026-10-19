import Foundation
import Darwin
@main struct NativeResetGate {
 @MainActor static func main() async throws {
  let args=ProcessInfo.processInfo.arguments
  guard args.contains("--uitesting"),let at=args.firstIndex(of:"--persistence-test"),at+1<args.count,
    UUID(uuidString:args[at+1]) != nil,let si=args.firstIndex(of:"--reset-scenario"),si+1<args.count else {exit(91)}
  let scenario=args[si+1],id=args[at+1]
  let root=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0]
    .appendingPathComponent("HomeViewReplica/test-"+id,isDirectory:true)
  let file=root.appendingPathComponent("mock-state.json")
  let model=AppModel()
  if scenario != "readonly" {
    model.data.personal["Alex"]=PersonalContent()
    model.data.personal["Alex"]!.messages=["SYNTHETIC_LOCAL_RESET_GATE"]
    model.data.connectionConsent=[.music];model.data.volume=0
    model.pendingPage = .calendar;model.referenceClock=true;model.intercomHistory=["Synthetic old message"]
    guard model.persist() else {exit(92)}
    try FileManager.default.createDirectory(at:root.appendingPathComponent("photos"),withIntermediateDirectories:true)
    try FileManager.default.createDirectory(at:root.appendingPathComponent("State Recovery"),withIntermediateDirectories:true)
    try Data("SYNTHETIC_IMPORTED_PHOTO_COPY".utf8).write(to:root.appendingPathComponent("photos/old.jpg"))
    try Data("SYNTHETIC_RECOVERY_COPY".utf8).write(to:root.appendingPathComponent("State Recovery/old.json"))
  }
  let before=try Data(contentsOf:file)
  let siblingsBefore=Set(try FileManager.default.contentsOfDirectory(atPath:root.deletingLastPathComponent().path))
  var rows:[[String:Any]]=[]
  func check(_ id:String,_ passed:Bool){rows.append(["id":id,"passed":passed])}
  func unchanged()->Bool { (try? Data(contentsOf:file))==before }
  func newState()->Snapshot? {(try? Data(contentsOf:file)).flatMap {try? Snapshot.decodeMigrating($0)}}
  model.route = .app(.settings);model.localResetForeground=true;model.presentLocalReset()
  check("opening-review-no-delete-no-data-unlock",unchanged() && !model.localResetAuthorized && !model.connections.personalUnlocked)
  if scenario=="no-auth" {
    check("confirmation-without-auth-rejected",!model.resetLocalAppData(confirmation:"RESET") && unchanged())
  } else if scenario=="queued-auth-revoked" {
    let ticket=model.localResetRequestGeneration
    let old=Task { @MainActor in await model.authorizeLocalReset(expectedAttempt:ticket) }
    model.localResetForeground=false;model.lockPersonalAccess();model.localResetForeground=true
    await old.value
    check("queued-old-auth-cannot-revive-after-background-session",!model.localResetAuthorized && !model.localResetAuthorizing && unchanged())
  } else if scenario=="pre-cancelled-auth" {
    let ticket=model.localResetRequestGeneration
    let task=Task { @MainActor in await model.authorizeLocalReset(expectedAttempt:ticket) };task.cancel();await task.value
    check("pre-cancelled-auth-no-authority",!model.localResetAuthorized && unchanged())
  } else {
    await model.authorizeLocalReset(expectedAttempt:model.localResetRequestGeneration)
    if scenario=="denied" {
      check("denied-auth-no-confirmation-authority",!model.localResetAuthorized && unchanged())
    } else {
      check("auth-alone-no-delete-or-data-unlock",model.localResetAuthorized && unchanged() && !model.connections.personalUnlocked)
      switch scenario {
      case "consent-order":
        model.data.connectionConsent=Set(DataConnection.allCases)
        guard model.persist() else {exit(94)}
        for index in 0..<6 {
          let restarted=AppModel()
          check("multi-consent-restart-stable-"+String(index),
            restarted.data.connectionConsent==Set(DataConnection.allCases) && restarted.storeRecoveryNote==nil)
        }
        let recovery=try FileManager.default.contentsOfDirectory(atPath:root.appendingPathComponent("State Recovery").path)
        check("no-order-only-recovery-copies",!recovery.contains { $0.hasPrefix("original-") })
      case "wrong-confirmation":
        for (id,value) in [("lowercase","reset"),("suffix","RESETx"),("leading-space"," RESET"),("newline","RESET\n"),("NUL","RESET\0")] {
          check("whole-confirmation-rejects-"+id,!model.resetLocalAppData(confirmation:value) && unchanged())
        }
      case "expired":
        model.gateExpireResetProof()
        check("expired-proof-rejected",!model.localResetAuthorized && !model.resetLocalAppData(confirmation:"RESET") && unchanged())
      case "readonly":
        check("newer-store-preserved",!model.resetLocalAppData(confirmation:"RESET") && model.storeReadOnly && unchanged())
      case "pending-alarm":
        model.nativeSchedulesInFlight=1
        check("in-flight-system-request-not-forgotten",!model.resetLocalAppData(confirmation:"RESET") && model.nativeSchedulesInFlight==1 && unchanged())
      case "registered-alarm":
        let alarm=UUID();model.data.nativeAlarmIDs=[alarm];guard model.persist() else {exit(93)}
        let marked=try Data(contentsOf:file)
        check("registered-alarm-ledger-retained",!model.resetLocalAppData(confirmation:"RESET") && model.data.nativeAlarmIDs==[alarm] && (try? Data(contentsOf:file))==marked)
      case "write-fail","fsync-fail","swap-fail":
        check("swap-failure-preserves-old-state",!model.resetLocalAppData(confirmation:"RESET") && unchanged() && model.data.personal["Alex"]?.messages==["SYNTHETIC_LOCAL_RESET_GATE"])
        check("no-prepared-stage-residue",Set(try FileManager.default.contentsOfDirectory(atPath:root.deletingLastPathComponent().path))==siblingsBefore)
      case "replace-retired":
        check("retired-path-replacement-not-full-success",model.resetLocalAppData(confirmation:"RESET") && model.localResetCleanupPending && !model.localResetStatus.contains("Local app content reset."))
        let marker=try JSONSerialization.jsonObject(with:Data(contentsOf:root.appendingPathComponent("reset-cleanup.json"))) as! [String:Any]
        let canary=root.deletingLastPathComponent().appendingPathComponent(marker["stage"] as! String).appendingPathComponent("DO_NOT_DELETE")
        let original=try Data(contentsOf:canary)
        model.presentLocalReset();await model.authorizeLocalReset(expectedAttempt:model.localResetRequestGeneration)
        check("wrong-inode-retry-never-deletes-replacement-canary",!model.retryLocalResetCleanup(confirmation:"RESET") && (try? Data(contentsOf:canary))==original)
      case "retarget-root":
        check("storage-path-change-blocks-future-writes",model.resetLocalAppData(confirmation:"RESET") && model.storeReadOnly && model.localResetStatus.contains("Further writes are blocked"))
        let canary=root.appendingPathComponent("DO_NOT_DELETE"),original=try Data(contentsOf:root.appendingPathComponent("DO_NOT_DELETE"))
        check("replacement-canary-untouched-and-persist-refused",!model.persist() && !FileManager.default.fileExists(atPath:file.path) && (try? Data(contentsOf:canary))==original)
      case "audio":
        let engine=model.gateAudioEngine
        let music=await engine.playMusic(volume:0),chime=await engine.playChime(volume:0)
        let owners=await engine.gateCaptureOwners()
        let started=await engine.gateOldState(owners)
        check("real-demo-music-and-chime-clients-volume-zero",music && chime && started["musicAlive"]==true && started["chimeAlive"]==true)
        // This task is queued before reset and must not enqueue a fresh chime afterwards.
        model.playChime();check("audio-reset-commits",model.resetLocalAppData(confirmation:"RESET"))
        for _ in 0..<20 { await Task.yield() }
        let after=await engine.gateOldState(owners),current=await engine.gateCurrentState()
        check("real-old-audio-clients-released-no-late-chime",after.values.allSatisfy { !$0 } && current.values.allSatisfy { !$0 })
      default:
        model.error="Synthetic stale error";model.showAnswerSpeechStatus=true
        check("normal-reset-commits",model.resetLocalAppData(confirmation:"RESET"))
        let saved=newState()
        check("fresh-local-state-no-old-content-or-consents",saved?.personal.isEmpty==true && saved?.connectionConsent==[] && saved?.photoIDs.isEmpty==true && saved?.introduction == .pending)
        check("transient-state-and-voice-preferences-cleared",model.pendingPage==nil && model.intercomHistory.isEmpty && model.error==nil && !model.referenceClock && !model.showAnswerSpeechStatus && model.answerSpeech.voiceID==nil && model.answerSpeech.rate==0.5)
        check("no-photos-recovery-or-journal-left",try FileManager.default.contentsOfDirectory(atPath:root.path)==["mock-state.json"])
        let restarted=AppModel()
        check("actual-new-AppModel-restart-stays-empty",restarted.data.personal.isEmpty && restarted.data.connectionConsent==[] && !restarted.localResetCleanupPending)
      }
    }
  }
  print(String(decoding:try JSONSerialization.data(withJSONObject:rows,options:[.sortedKeys]),as:UTF8.self))
  exit(rows.allSatisfy{$0["passed"] as? Bool==true} ? 0:1)
 }
}
