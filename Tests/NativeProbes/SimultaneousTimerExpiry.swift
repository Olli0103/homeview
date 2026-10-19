import Foundation

/// Compiled with the actual application sources by check_simultaneous_timer_expiry.py.
/// No UIApplication, microphone, speaker asset, Home manager or alarm authorization.
@main struct SimultaneousTimerExpiry {
  @MainActor static func main() throws {
    let args=ProcessInfo.processInfo.arguments
    func argument(_ key:String)->String {
      guard let i=args.firstIndex(of:key),args.indices.contains(i+1) else {fatalError("Missing probe argument")}
      return args[i+1]
    }
    let name=argument("--case"),phase=argument("--phase")
    guard args.contains("--uitesting"),let id=UUID(uuidString:argument("--persistence-test")),
      ["simultaneous","staggered","write_failure"].contains(name),
      ["seed","reconcile","verify"].contains(phase),
      !args.contains("--reset-test-store"),!args.contains("--system-alarms"),
      Bundle.main.url(forResource:"demo-tone",withExtension:"wav")==nil
    else {fatalError("Owned local-only probe required")}
    let m=AppModel(),fm=FileManager.default,store=m.gateStoreURL,dir=m.gateStoreURL.deletingLastPathComponent()
    guard dir.lastPathComponent=="test-"+id.uuidString else {fatalError("Wrong owned root")}
    var checks:[String:Bool]=[:]
    func bytes(_ state:Snapshot)throws->Data {try Snapshot.canonicalBytes(JSONEncoder().encode(state))}
    if phase=="seed" {
      guard !fm.fileExists(atPath:store.path) else {fatalError("Seed requires new store")}
      m.data.alarms=[];m.data.volume=0;m.data.timerLiveActivitiesEnabled=false
      let start=Date(),due=start.addingTimeInterval(1)
      m.data.timers=(0..<3).map { index in
        var t=Countdown(title:"Synthetic batch \(index+1)",seconds:60,now:start)
        t.deadline=due
        if name=="staggered",index==1 {t.deadline=start.addingTimeInterval(3600)}
        if name=="staggered",index==2 {t.deadline=start.addingTimeInterval(-10);t.didAlert=true}
        return t
      }
      var paused=Countdown(title:"Synthetic paused control",seconds:90,now:start)
      paused.deadline=nil;paused.pausedRemaining=90;m.data.timers.append(paused)
      m.data.timers.append(Countdown(title:"Synthetic future control",seconds:7200,now:start))
      checks["seed_saved"]=m.persist()
      checks["seed_five_timers"]=m.data.timers.count==5
      checks["seed_no_banner"]=m.toast==nil
      checks["seed_receipts_only_explicit_control"]=m.data.timers.filter(\.didAlert).count==(name=="staggered" ? 1:0)
      checks["seed_disk_matches"]=try Snapshot.canonicalBytes(Data(contentsOf:store))==bytes(m.data)
    } else {
      guard m.data.timers.count==5,!m.storeReadOnly else {fatalError("Missing valid fixture")}
      let before=m.data,initial=try bytes(before),initialDisk=try Data(contentsOf:store)
      let dueIDs=before.timers.filter {!$0.didAlert && $0.remaining(at:Date())==0}.map(\.id)
      let expected=name=="staggered" ? 1:3
      checks["expected_due_count"]=dueIDs.count==(phase=="reconcile" ? expected:0)
      checks["paused_control_preserved"]=before.timers[3].deadline==nil && before.timers[3].pausedRemaining==90 && !before.timers[3].didAlert
      checks["future_control_running"]=before.timers[4].remaining(at:Date())>7000 && !before.timers[4].didAlert
      m.selectedTimer=before.timers[4].id
      if phase=="reconcile",name=="write_failure" {
        let preserved=dir.appendingPathComponent("before-batch-fault.json"),canary=store.appendingPathComponent("owned-canary.txt"),marker=Data("OWNED_SIMULTANEOUS_TIMER_FAULT".utf8)
        try fm.moveItem(at:store,to:preserved);try fm.createDirectory(at:store,withIntermediateDirectories:false);try marker.write(to:canary)
        let selection=m.selectedTimer,attempt=m.answerSpeechAttempt
        m.tick();m.tick()
        checks["failed_batch_no_receipts"]=try bytes(m.data)==initial
        checks["failed_batch_no_banner"]=m.toast==nil
        checks["failed_batch_no_chime_requests"]=m.answerSpeechAttempt==attempt
        checks["failed_batch_no_selection_change"]=m.selectedTimer==selection
        checks["failed_batch_reports_error"]=m.error != nil
        checks["failed_batch_original_bytes_preserved"]=try Data(contentsOf:preserved)==initialDisk
        checks["failed_batch_canary_preserved"]=try Data(contentsOf:canary)==marker
        guard try Data(contentsOf:canary)==marker,try fm.contentsOfDirectory(atPath:store.path)==["owned-canary.txt"] else {fatalError("Fault identity changed")}
        try fm.removeItem(at:canary);try fm.removeItem(at:store);try fm.moveItem(at:preserved,to:store)
      }
      let attempt=m.answerSpeechAttempt
      m.tick()
      checks["one_chime_request_per_new_local_completion"]=m.answerSpeechAttempt-attempt==dueIDs.count
      checks["all_due_receipts_saved"]=dueIDs.allSatisfy { id in m.data.timers.first(where:{$0.id==id})?.didAlert==true }
      checks["only_due_receipts_changed"]=zip(before.timers,m.data.timers).allSatisfy { old,new in var expected=old;if dueIDs.contains(old.id) {expected.didAlert=true};return new==expected }
      checks["order_and_IDs_preserved"]=m.data.timers.map(\.id)==before.timers.map(\.id)
      checks["saved_model_matches"]=try Snapshot.canonicalBytes(Data(contentsOf:store))==bytes(m.data)
      checks["completion_banner_matches_batch"]=phase=="verify" ? m.toast==nil:m.toast==before.timers.last(where:{dueIDs.contains($0.id)}).map {"\($0.title) finished"}
      checks["selection_valid"]=m.selectedTimer==dueIDs.last ?? before.timers[4].id
      let saved=try Data(contentsOf:store),secondAttempt=m.answerSpeechAttempt,selection=m.selectedTimer,toast=m.toast
      m.tick();m.tick()
      checks["repeated_ticks_no_new_chime_request"]=m.answerSpeechAttempt==secondAttempt
      checks["repeated_ticks_no_rewrite"]=try Data(contentsOf:store)==saved
      checks["repeated_ticks_selection_and_banner_stable"]=m.selectedTimer==selection && m.toast==toast
    }
    checks["no_system_alarm_IDs"]=m.data.nativeTimerIDs.isEmpty && m.data.nativeAlarmIDs.isEmpty
    checks["no_live_activity_opt_in"] = !m.data.timerLiveActivitiesEnabled
    let failures=checks.filter {!$0.value}.map(\.key).sorted()
    let result:[String:Any]=["case":name,"phase":phase,"checks":checks,"assertions":checks.count,"failed":failures,"verdict":failures.isEmpty ? "PASS":"FAIL","owned_uuid":id.uuidString,"acoustic_playback_tested":false,"actual_OS_alarm_tested":false]
    print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
  }
}
