import Foundation
@main struct PersistenceWriteGate {
 @MainActor static func main() throws {
  let args=ProcessInfo.processInfo.arguments
  guard args.contains("--uitesting"),let i=args.firstIndex(of:"--case"),args.indices.contains(i+1),let j=args.firstIndex(of:"--persistence-test"),args.indices.contains(j+1),let id=UUID(uuidString:args[j+1]),!args.contains("--reset-test-store"),!args.contains("--system-alarms") else {fatalError("Fresh owned local-only UUID required")}
  let name=args[i+1],m=AppModel(),fm=FileManager.default,store=m.gateStoreURL
  let dir=store.deletingLastPathComponent()
  guard dir.lastPathComponent=="test-"+id.uuidString,!fm.fileExists(atPath:store.path) else {fatalError("Fresh owned test store only")}
  let isTimer=name.hasSuffix("timer")
  if isTimer {
   guard m.addTimer(seconds:300,title:"Synthetic foreground countdown") else {fatalError("Timer setup failed")}
   if name=="resume_timer" {m.toggleTimer(m.data.timers[0].id)}
  } else {
   m.addAlarm(hour:10,minute:30)
   if name=="enable_alarm" {m.toggleAlarm(m.data.alarms.last!.id)}
  }
  let target=isTimer ? m.data.timers[0].id:m.data.alarms.last!.id
  let timerCount=m.data.timers.count,alarmCount=m.data.alarms.count,priorTimers=m.data.timers,priorAlarms=m.data.alarms
  guard m.persist(),m.data.nativeTimerIDs.isEmpty,m.data.nativeAlarmIDs.isEmpty else {fatalError("Local positive baseline only")}
  let before=try Snapshot.canonicalBytes(JSONEncoder().encode(m.data)),original=try Data(contentsOf:store),selected=m.selectedTimer
  let preserved=dir.appendingPathComponent("before-fault.json"),canary=store.appendingPathComponent("owned-canary.txt"),marker=Data("OWNED_TIMER_WRITE_CANARY".utf8)
  try fm.moveItem(at:store,to:preserved);try fm.createDirectory(at:store,withIntermediateDirectories:false);try marker.write(to:canary)
  func act() {
   switch name {
    case "pause_timer","resume_timer":m.toggleTimer(target)
    case "remove_timer":m.removeTimer(target)
    case "disable_alarm","enable_alarm":m.toggleAlarm(target)
    case "remove_alarm":m.removeAlarm(target)
    default:fatalError("Unknown case")
   }
  }
  act()
  var checks:[String:Bool]=["snapshot_unchanged":try Snapshot.canonicalBytes(JSONEncoder().encode(m.data))==before,"selection_unchanged":m.selectedTimer==selected,"save_error_visible":m.error != nil,"original_bytes_unchanged":try Data(contentsOf:preserved)==original,"fault_canary_unchanged":try Data(contentsOf:canary)==marker,"no_native_ids":m.data.nativeTimerIDs.isEmpty && m.data.nativeAlarmIDs.isEmpty]
  guard try Data(contentsOf:canary)==marker,try fm.contentsOfDirectory(atPath:store.path)==["owned-canary.txt"] else {fatalError("Owned fault identity mismatch")}
  try fm.removeItem(at:canary);try fm.removeItem(at:store);try fm.moveItem(at:preserved,to:store)
  let restored=AppModel();checks["restart_matches_original"]=try Snapshot.canonicalBytes(JSONEncoder().encode(restored.data))==before
  if args.contains("--retry-after-fault") {
   m.error=nil;act();let after=try Snapshot.canonicalBytes(JSONEncoder().encode(m.data))
   checks["retry_changes_state"]=after != before
   checks["retry_stored_exactly"]=try Snapshot.canonicalBytes(Data(contentsOf:store))==after
   checks["retry_has_no_error"]=m.error==nil
   switch name {
    case "pause_timer":checks["requested_effect_only"]=m.data.timers.count==timerCount && m.data.timers[0].id==target && m.data.timers[0].deadline==nil
    case "resume_timer":checks["requested_effect_only"]=m.data.timers.count==timerCount && m.data.timers[0].id==target && m.data.timers[0].deadline != nil
    case "remove_timer":checks["requested_effect_only"]=m.data.timers.isEmpty
    case "disable_alarm":checks["requested_effect_only"]=m.data.alarms.count==alarmCount && m.data.alarms.last?.id==target && m.data.alarms.last?.enabled==false
    case "enable_alarm":checks["requested_effect_only"]=m.data.alarms.count==alarmCount && m.data.alarms.last?.id==target && m.data.alarms.last?.enabled==true
    case "remove_alarm":checks["requested_effect_only"]=m.data.alarms.count==alarmCount-1 && !m.data.alarms.contains { $0.id==target }
    default:break
   }
   checks["unrelated_peers_unchanged"]=isTimer
    ? m.data.timers.filter { $0.id != target }==priorTimers.filter { $0.id != target }
    : m.data.alarms.filter { $0.id != target }==priorAlarms.filter { $0.id != target }
   let restarted=AppModel();checks["restart_matches_retry"]=try Snapshot.canonicalBytes(JSONEncoder().encode(restarted.data))==after
  }
  let failed=checks.filter{!$0.value}.map(\.key).sorted();let result:[String:Any]=["case":name,"checks":checks,"failed":failed,"verdict":failed.isEmpty ? "PASS":"FAIL","assertions":checks.count,"owned_uuid":id.uuidString]
  print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
 }
}
