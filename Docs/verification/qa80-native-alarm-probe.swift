import Foundation

/// No AlarmKit import/link: only the AppModel's exact supported branch is selected.
@MainActor final class NativeAlarmService {
  static var events:[String]=[]
  static var replies:[CheckedContinuation<Void,Error>]=[]
  static var active=Set<UUID>()
  static var hold=false
  static var fail=false
  func scheduleTimer(id:UUID,seconds:TimeInterval,title:String) async throws {try await schedule(id)}
  func scheduleAlarm(id:UUID,hour:Int,minute:Int) async throws {try await schedule(id)}
  private func schedule(_ id:UUID) async throws {
    Self.events.append("schedule")
    if Self.hold {try await withCheckedThrowingContinuation {Self.replies.append($0)}}
    if Self.fail {throw CocoaError(.fileWriteUnknown)}
    Self.active.insert(id)
  }
  func cancel(_ id:UUID) throws {Self.events.append("cancel");if Self.fail {throw CocoaError(.fileWriteUnknown)};Self.active.remove(id)}
  func pause(_ id:UUID) throws {Self.events.append("pause");if Self.fail {throw CocoaError(.fileWriteUnknown)}}
  func resume(_ id:UUID) throws {Self.events.append("resume");if Self.fail {throw CocoaError(.fileWriteUnknown)}}
  func activeIDs() throws -> Set<UUID> {Self.active}
  func canResetLocalState() throws -> Bool {Self.active.isEmpty}
}

@main struct PersistenceWriteGate {
 @MainActor static func main() async throws {
  let args=ProcessInfo.processInfo.arguments
  guard args.contains("--uitesting"),args.contains("--system-alarms"),
    let i=args.firstIndex(of:"--case"),let j=args.firstIndex(of:"--persistence-test"),
    let id=UUID(uuidString:args[j+1]) else {fatalError("Fresh owned UUID fake-only probe required")}
  let name=args[i+1],m=AppModel(),fm=FileManager.default,store=m.gateStoreURL,dir=m.gateStoreURL.deletingLastPathComponent()
  guard dir.lastPathComponent=="test-"+id.uuidString,!fm.fileExists(atPath:store.path) else {fatalError("Fresh store required")}
  var checks:[String:Bool]=[:]
  func check(_ key:String,_ value:Bool) {checks[key]=value}
  func bytes() throws -> Data {try Snapshot.canonicalBytes(JSONEncoder().encode(m.data))}
  func disk() throws -> Data {try Snapshot.canonicalBytes(Data(contentsOf:store))}
  func wait(_ condition:()->Bool) async {
    for _ in 0..<10000 {if condition() {return};await Task.yield()}
    fatalError("Bounded actor barrier did not settle")
  }
  let preserved=dir.appendingPathComponent("before-fault.json"),canary=store.appendingPathComponent("owned-canary.txt"),marker=Data("OWNED_QA80_FAULT".utf8)
  func fault() throws {try fm.moveItem(at:store,to:preserved);try fm.createDirectory(at:store,withIntermediateDirectories:false);try marker.write(to:canary)}
  func unfault() throws {
    guard try fm.contentsOfDirectory(atPath:store.path)==["owned-canary.txt"],try Data(contentsOf:canary)==marker else {fatalError("Fault identity changed")}
    try fm.removeItem(at:canary);try fm.removeItem(at:store);try fm.moveItem(at:preserved,to:store)
  }
  if name.hasPrefix("write_") || name.hasPrefix("provider_") || name.hasPrefix("positive_") {
    let timer=name.contains("timer")
    var t=Countdown(title:"OWNED_NATIVE_TIMER",seconds:300)
    if name.contains("resume") {t.pause(at:m.now)}
    let a=AlarmItem(hour:10,minute:30)
    m.data.connectionConsent=[];m.data.timers=[t];m.data.alarms=[a]
    m.data.nativeTimerIDs=[t.id];m.data.nativeAlarmIDs=[a.id];NativeAlarmService.active=[t.id,a.id]
    guard m.persist() else {fatalError("Positive setup save failed")}
    let before=try bytes(),original=try Data(contentsOf:store)
    if name.hasPrefix("write_") {try fault()}
    if name.hasPrefix("provider_") {NativeAlarmService.fail=true}
    switch name {
    case let n where n.contains("pause") || n.contains("resume"):m.toggleTimer(t.id)
    case let n where n.contains("remove_timer"):m.removeTimer(t.id)
    case let n where n.contains("disable"):m.toggleAlarm(a.id)
    default:m.removeAlarm(a.id)
    }
    if name.hasPrefix("write_") {
      check("snapshot_unchanged",try bytes()==before);check("no_system_effect_before_failed_save",NativeAlarmService.events.isEmpty)
      check("error_visible",m.error != nil);check("original_bytes_unchanged",try Data(contentsOf:preserved)==original)
      check("canary_unchanged",try Data(contentsOf:canary)==marker);try unfault()
      check("restart_matches_original",try Snapshot.canonicalBytes(JSONEncoder().encode(AppModel().data))==before)
    } else if name.hasPrefix("provider_") {
      check("failed_effect_rolls_back_memory",try bytes()==before);check("failed_effect_rolls_back_disk",try disk()==before)
      check("error_visible",m.error != nil)
    } else {
      check("saved_effect_matches_memory",try bytes()==disk());check("state_changed",try bytes() != before)
      check("one_system_effect",NativeAlarmService.events.count==1);check("no_error",m.error==nil)
    }
    check("unrelated_peer_unchanged",timer ? m.data.alarms==[a]:m.data.timers==[t])
  } else {
    NativeAlarmService.hold=true
    let timer=name.contains("timer")
    if timer {_ = m.addTimer(seconds:300,title:"OWNED_PENDING_TIMER")} else {m.addAlarm(hour:10,minute:30)}
    await wait {!NativeAlarmService.replies.isEmpty}
    let target=timer ? m.data.timers.last!.id:m.data.alarms.last!.id
    let before=try bytes()
    if name.contains("write") {try fault()}
    else if timer {m.toggleTimer(target)}
    else {m.toggleAlarm(target);m.toggleAlarm(target)}
    NativeAlarmService.replies.removeFirst().resume()
    if name=="pending_alarm_reenable" {
      await wait {!NativeAlarmService.replies.isEmpty}
      check("stale_completion_did_not_install_ownership",!m.data.nativeAlarmIDs.contains(target))
      check("old_cleanup_precedes_new_schedule",Array(NativeAlarmService.events.prefix(3))==["schedule","cancel","schedule"])
      NativeAlarmService.replies.removeFirst().resume()
    }
    await wait {m.nativeSchedulesInFlight==0}
    if name.contains("write") {
      check("ownership_not_claimed_on_failed_save",timer ? !m.data.nativeTimerIDs.contains(target):!m.data.nativeAlarmIDs.contains(target))
      check("uncommitted_schedule_cancelled",!NativeAlarmService.active.contains(target))
      check("snapshot_rolled_back",try bytes()==before);check("error_visible",m.error != nil)
      check("fault_canary_unchanged",try Data(contentsOf:canary)==marker);try unfault()
    } else if timer {
      check("paused_timer_does_not_gain_system_owner",!m.data.nativeTimerIDs.contains(target))
      check("stale_running_schedule_cancelled",!NativeAlarmService.active.contains(target))
      check("paused_choice_preserved",m.data.timers.first(where:{$0.id==target})?.deadline==nil)
      check("disk_matches_memory",try bytes()==disk())
    } else {
      check("latest_owns_schedule",m.data.nativeAlarmIDs.contains(target));check("latest_still_active",NativeAlarmService.active.contains(target))
      check("disk_matches_memory",try bytes()==disk())
    }
  }
  let failed=checks.filter {!$0.value}.map(\.key).sorted()
  print(String(data:try JSONSerialization.data(withJSONObject:["case":name,"checks":checks,"failed":failed,"events":NativeAlarmService.events,"assertions":checks.count,"verdict":failed.isEmpty ? "PASS":"FAIL","owned_uuid":id.uuidString],options:[.sortedKeys]),encoding:.utf8)!)
 }
}
