import Foundation
@main struct PersistenceWriteGate {
 @MainActor static func main() throws {
  let args=ProcessInfo.processInfo.arguments
  guard args.contains("--uitesting"),let i=args.firstIndex(of:"--case"),args.indices.contains(i+1),let j=args.firstIndex(of:"--persistence-test"),args.indices.contains(j+1),let id=UUID(uuidString:args[j+1]),!args.contains("--reset-test-store"),!args.contains("--system-alarms"),Bundle.main.url(forResource:"demo-tone",withExtension:"wav")==nil else {fatalError("Owned local-only no-audio-asset probe required")}
  let name=args[i+1],m=AppModel(),fm=FileManager.default,store=m.gateStoreURL,dir=m.gateStoreURL.deletingLastPathComponent(),due=["timer_due","alarm_due","timer_due_idle_privacy"].contains(args[i+1]),cal=Calendar.current
  guard dir.lastPathComponent=="test-"+id.uuidString,!fm.fileExists(atPath:store.path) else {fatalError("Fresh owned root only")}
  m.data.volume=0
  if name=="alarm_due" {
   let date=Date();m.addAlarm(hour:cal.component(.hour,from:date),minute:cal.component(.minute,from:date))
  } else {
   guard m.addTimer(seconds:60,title:"Synthetic expiry"),m.addTimer(seconds:600,title:"Synthetic paused peer") else {fatalError("Timer setup failed")}
   m.toggleTimer(m.data.timers[1].id)
   if name=="paused_timer" {m.toggleTimer(m.data.timers[0].id)}
   else {m.data.timers[0].deadline=Date().addingTimeInterval(-2)}
   if name=="already_delivered" {m.data.timers[0].didAlert=true}
  }
  guard m.persist(),m.data.nativeTimerIDs.isEmpty,m.data.nativeAlarmIDs.isEmpty else {fatalError("Owned local positive save required")}
  let idlePrivacy=name=="timer_due_idle_privacy"
  if idlePrivacy {
    m.signIn("Alex");m.messageText="SYNTHETIC_PRIVATE_DRAFT"
    m.route = .app(.messages);m.idleSeconds=0;m.lastInteraction=Date().addingTimeInterval(-600)
  }
  let before=try Snapshot.canonicalBytes(JSONEncoder().encode(m.data)),original=try Data(contentsOf:store),selection=m.selectedTimer,attempt=m.answerSpeechAttempt
  let preserved=dir.appendingPathComponent("before-fault.json"),canary=store.appendingPathComponent("owned-canary.txt"),marker=Data("OWNED_EXPIRY_WRITE_CANARY".utf8)
  try fm.moveItem(at:store,to:preserved);try fm.createDirectory(at:store,withIntermediateDirectories:false);try marker.write(to:canary)
  m.tick()
  if name=="alarm_due" {
   guard let alarm=m.data.alarms.last,alarm.hour==cal.component(.hour,from:m.now),alarm.minute==cal.component(.minute,from:m.now) else {fatalError("Fixture crossed a minute boundary; not an application verdict")}
  }
  let failedWriteHadBanner=m.toast != nil
  var checks:[String:Bool]=["snapshot_unchanged_on_failed_write":try Snapshot.canonicalBytes(JSONEncoder().encode(m.data))==before,"no_banner_before_durable_commit":m.toast==nil,"selection_unchanged_on_failed_write":m.selectedTimer==selection,"no_chime_request_before_durable_commit":m.answerSpeechAttempt-attempt==(idlePrivacy ? 1:0),"expected_write_error":due ? m.error != nil:m.error==nil,"original_bytes_unchanged":try Data(contentsOf:preserved)==original,"canary_unchanged":try Data(contentsOf:canary)==marker]
  if idlePrivacy {
    checks["privacy_still_locks_on_failed_write"]=m.profile==nil && m.messageText.isEmpty
    checks["privacy_route_still_returns_to_face"]=m.route == .face
  }
  guard try Data(contentsOf:canary)==marker,try fm.contentsOfDirectory(atPath:store.path)==["owned-canary.txt"] else {fatalError("Owned fault identity mismatch")}
  try fm.removeItem(at:canary);try fm.removeItem(at:store);try fm.moveItem(at:preserved,to:store)
  let restored=AppModel();checks["restart_reads_original"]=try Snapshot.canonicalBytes(JSONEncoder().encode(restored.data))==before
  let nextAttempt=restored.answerSpeechAttempt;restored.tick()
  if name=="alarm_due" {
   guard let alarm=restored.data.alarms.last,alarm.hour==cal.component(.hour,from:restored.now),alarm.minute==cal.component(.minute,from:restored.now) else {fatalError("Retry fixture crossed minute boundary")}
  }
  checks["event_only_after_successful_save"]=due ? restored.toast != nil:restored.toast==nil
  checks["one_chime_request_after_commit"]=restored.answerSpeechAttempt-nextAttempt==(due ? 1:0)
  checks["no_duplicate_banner_across_failed_write_restart"] = !(failedWriteHadBanner && restored.toast != nil)
  checks["saved_marker_matches_model"]=try Snapshot.canonicalBytes(Data(contentsOf:store))==Snapshot.canonicalBytes(JSONEncoder().encode(restored.data))
  let last=AppModel(),lastAttempt=last.answerSpeechAttempt;last.tick()
  checks["no_repeat_after_committed_marker"]=last.toast==nil && last.answerSpeechAttempt==lastAttempt
  checks["no_system_alarm_IDs"]=last.data.nativeTimerIDs.isEmpty && last.data.nativeAlarmIDs.isEmpty
  let failed=checks.filter{!$0.value}.map(\.key).sorted();let r:[String:Any]=["case":name,"checks":checks,"failed":failed,"verdict":failed.isEmpty ? "PASS":"FAIL","assertions":checks.count,"owned_uuid":id.uuidString,"audio_asset_present":false,"acoustic_playback_tested":false]
  print(String(data:try JSONSerialization.data(withJSONObject:r,options:[.sortedKeys]),encoding:.utf8)!)
 }
}
