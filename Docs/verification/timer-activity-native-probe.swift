import Foundation
@main struct TimerActivityGate {
 enum Failure:Error {case fixture,timeout}
 @MainActor static func settle(_ m:AppModel) async throws {
  let end=ContinuousClock.now.advanced(by:.seconds(5))
  while m.timerLiveActivity.busy {guard ContinuousClock.now<end else {throw Failure.timeout};try await Task.sleep(for:.milliseconds(10))}
 }
 @MainActor static func main() async throws {
  let a=ProcessInfo.processInfo.arguments
  guard a.contains("--uitesting"),a.contains("--timer-activity-fixture"),let i=a.firstIndex(of:"--persistence-test"),a.indices.contains(i+1),let id=UUID(uuidString:a[i+1]),!a.contains("--reset-test-store"),!a.contains("--system-alarms"),!a.contains("--timer-activity-system-test"),Bundle.main.url(forResource:"demo-tone",withExtension:"wav")==nil else {throw Failure.fixture}
  let m=AppModel(),fm=FileManager.default,store=m.gateStoreURL,dir=m.gateStoreURL.deletingLastPathComponent()
  guard dir.lastPathComponent=="test-"+id.uuidString,!fm.fileExists(atPath:store.path) else {throw Failure.fixture}
  var checks:[String:Bool]=[:]
  m.setTimerActivityForeground(true);try await settle(m)
  checks["default_opt_out"] = !m.timerActivitiesEnabled
  m.setTimerLiveActivities(true);try await settle(m)
  checks["explicit_preference_saved"] = try Snapshot.decodeMigrating(Data(contentsOf:store)).timerLiveActivitiesEnabled
  guard m.addTimer(seconds:600,title:"SYNTHETIC_PRIVATE_TIMER_TITLE") else {throw Failure.fixture}
  try await settle(m)
  checks["explicit_saved_timer_starts_fixture"]=m.timerLiveActivity.status.contains("Synthetic timer activity (active)")
  let originalState=m.gateCommittedActivityState
  checks["actual_projection_one_running_timer"]=originalState?.runningCount==1 && originalState?.pausedCount==0
  let payload=try JSONEncoder().encode(originalState)
  checks["projection_has_no_title_or_profile"] = !String(decoding:payload,as:UTF8.self).contains("SYNTHETIC_PRIVATE_TIMER_TITLE") && !String(decoding:payload,as:UTF8.self).contains("Alex")
  let original=try Data(contentsOf:store),preserved=dir.appendingPathComponent("before-fault.json"),canary=store.appendingPathComponent("owned-canary.txt"),marker=Data("OWNED_ACTIVITY_CANARY".utf8)
  try fm.moveItem(at:store,to:preserved);try fm.createDirectory(at:store,withIntermediateDirectories:false);try marker.write(to:canary)
  let failedAdd=m.addTimer(seconds:900,title:"SYNTHETIC_UNSAVED_TIMER")
  checks["unsaved_timer_rejected"] = !failedAdd && m.data.timers.count==1
  checks["unsaved_timer_not_projected"]=m.gateCommittedActivityState==originalState
  m.setTimerLiveActivities(false);try await settle(m)
  checks["failed_opt_out_save_does_not_keep_runtime_consent"] = !m.timerActivitiesEnabled
  checks["failed_opt_out_save_is_visible"]=m.timerActivityPreferenceSavePending && m.error != nil
  checks["failed_opt_out_save_still_ends_fixture"]=m.timerLiveActivity.status.contains("Synthetic timer activity (ended)")
  m.showTimerLiveActivity();try await settle(m)
  checks["explicit_show_cannot_bypass_session_revocation"]=m.timerLiveActivity.status.contains("Synthetic timer activity (ended)")
  checks["old_saved_preference_not_falsely_claimed_off"]=try Snapshot.decodeMigrating(Data(contentsOf:preserved)).timerLiveActivitiesEnabled
  checks["original_store_unchanged_on_failure"]=try Data(contentsOf:preserved)==original
  checks["canary_unchanged"]=try Data(contentsOf:canary)==marker
  guard try Data(contentsOf:canary)==marker,try fm.contentsOfDirectory(atPath:store.path)==["owned-canary.txt"] else {throw Failure.fixture}
  try fm.removeItem(at:canary);try fm.removeItem(at:store);try fm.moveItem(at:preserved,to:store)
  m.setTimerLiveActivities(false);try await settle(m)
  let retrySaved=try Snapshot.decodeMigrating(Data(contentsOf:store))
  checks["retry_saves_off_and_clears_pending"] = !m.timerActivityPreferenceSavePending && !m.timerActivitiesEnabled && !retrySaved.timerLiveActivitiesEnabled
  let offRestart=AppModel();offRestart.setTimerActivityForeground(true);try await settle(offRestart)
  checks["actual_restart_stays_off"] = !offRestart.timerActivitiesEnabled && offRestart.data.timers.count==1 && offRestart.timerLiveActivity.status.contains("(ended)")
  m.setTimerLiveActivities(true);try await settle(m)
  let enabledRestart=AppModel();enabledRestart.setTimerActivityForeground(true);try await settle(enabledRestart)
  checks["restart_remembers_enabled_preference"]=enabledRestart.timerActivitiesEnabled
  checks["restart_does_not_implicitly_request_new_activity"]=enabledRestart.timerLiveActivity.status.contains("Start a timer or choose")
  enabledRestart.showTimerLiveActivity();try await settle(enabledRestart)
  checks["explicit_restart_action_can_start"]=enabledRestart.timerLiveActivity.status.contains("(active)")
  m.now=Date();m.toggleTimer(m.data.timers[0].id);try await settle(m)
  checks["saved_pause_projects_paused_state"]=m.gateCommittedActivityState?.runningCount==0 && m.gateCommittedActivityState?.pausedCount==1
  m.lockPersonalAccess();m.setTimerActivityForeground(false);try await settle(m)
  checks["generic_public_timer_may_continue_after_personal_lock"]=m.timerLiveActivity.status.contains("(active)") && m.profile==nil && !m.connections.personalUnlocked
  m.setTimerActivityForeground(true);m.data.timers[0].deadline=Date().addingTimeInterval(-1)
  guard m.persist() else {throw Failure.fixture};try await settle(m)
  checks["saved_expired_timer_ends_activity"]=m.gateCommittedActivityState==nil && m.timerLiveActivity.status.contains("(ended)")
  guard m.addTimer(seconds:600,title:"SYNTHETIC_RESET_TIMER") else {throw Failure.fixture};try await settle(m)
  m.route = .app(.settings);m.localResetForeground=true;m.presentLocalReset()
  await m.authorizeLocalReset(expectedAttempt:m.localResetRequestGeneration)
  guard m.localResetAuthorized else {throw Failure.fixture}
  checks["actual_authorized_reset_succeeds"]=m.resetLocalAppData(confirmation:"RESET");try await settle(m)
  checks["reset_clears_timer_consent_and_activity"] = !m.timerActivitiesEnabled && m.data.timers.isEmpty && !m.timerActivityPreferenceSavePending && m.timerLiveActivity.status.contains("(ended)")
  checks["no_system_alarm_ids"]=m.data.nativeTimerIDs.isEmpty && m.data.nativeAlarmIDs.isEmpty
  let failed=checks.filter{!$0.value}.map(\.key).sorted(),result:[String:Any]=["verdict":failed.isEmpty ? "PASS":"FAIL","assertions":checks.count,"checks":checks,"failed":failed,"owned_uuid":id.uuidString,"actual_AppModel":true,"backend":"Fixture only; no ActivityKit system activity","acoustic_test":false]
  print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
 }
}
