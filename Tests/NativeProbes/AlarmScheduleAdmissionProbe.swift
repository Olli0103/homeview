import Foundation

/// Symbolic provider only: no AlarmKit link, permission dialog or real alert.
@MainActor final class NativeAlarmService {
  static var authorized:[CheckedContinuation<Void,Error>]=[]
  static var created=Set<UUID>()
  static var events:[String]=[]
  static var holdEffect=false
  static var effects:[CheckedContinuation<Void,Never>]=[]
  func authorize() async throws {
    Self.events.append("authorize")
    try await withCheckedThrowingContinuation {Self.authorized.append($0)}
  }
  func create(_ id:UUID) async {
    Self.events.append("schedule")
    if Self.holdEffect {await withCheckedContinuation {Self.effects.append($0)}}
    Self.created.insert(id)
  }
  // SCHEDULING_METHODS: the runner supplies the matching old/new adapter API.
  func cancel(_ id:UUID) throws {Self.events.append("cancel");Self.created.remove(id)}
  func pause(_ id:UUID) throws {Self.events.append("pause")}
  func resume(_ id:UUID) throws {Self.events.append("resume")}
  func activeIDs() throws -> Set<UUID> {Self.created}
  func canResetLocalState() throws -> Bool {Self.created.isEmpty}
}

@main struct AlarmScheduleAdmissionProbe {
  @MainActor static func main() async throws {
    let args=ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"),args.contains("--system-alarms"),
      let i=args.firstIndex(of:"--persistence-test"),args.indices.contains(i+1),
      let owned=UUID(uuidString:args[i+1]),let c=args.firstIndex(of:"--case"),args.indices.contains(c+1),
      Bundle.main.url(forResource:"demo-tone",withExtension:"wav")==nil
    else {fatalError("Owned symbolic-only probe required")}
    let name=args[c+1],m=AppModel(),store=m.admissionStoreURL
    guard store.deletingLastPathComponent().lastPathComponent=="test-"+owned.uuidString,
      !FileManager.default.fileExists(atPath:store.path) else {fatalError("Fresh own UUID required")}
    var checks:[String:Bool]=[:]
    func wait(_ condition:()->Bool) async throws {
      let end=Date().addingTimeInterval(5)
      while !condition() {guard Date()<end else {throw CocoaError(.coderReadCorrupt)};await Task.yield()}
    }
    let timer=name.hasPrefix("timer"),positive=name.hasSuffix("positive"),after=name.hasSuffix("after_effect")
    if timer {_ = m.addTimer(seconds:name=="timer_expired" ? 0.15:300,title:"OWNED_ADMISSION_TIMER")}
    else {m.addAlarm(hour:10,minute:30,recurrence:.once)}
    try await wait {!NativeAlarmService.authorized.isEmpty}
    let id=timer ? m.data.timers.last!.id:m.data.alarms.last!.id
    checks["no_effect_before_authorization"]=NativeAlarmService.created.isEmpty && !NativeAlarmService.events.contains("schedule")
    if after {
      NativeAlarmService.holdEffect=true
      NativeAlarmService.authorized.removeFirst().resume()
      try await wait {!NativeAlarmService.effects.isEmpty}
    }
    switch name {
    case "timer_expired":
      let deadline=m.data.timers.last!.deadline!
      try await Task.sleep(for:.seconds(max(0,deadline.timeIntervalSinceNow)+0.1))
      checks["actual_timer_deadline_passed"]=Date()>=deadline
    case "timer_pause":m.toggleTimer(id)
    case "timer_delete","timer_after_effect":m.removeTimer(id)
    case "alarm_disable":m.toggleAlarm(id)
    case "alarm_delete","alarm_after_effect":m.removeAlarm(id)
    case "alarm_replace":m.toggleAlarm(id);m.toggleAlarm(id)
    case "timer_positive","alarm_positive":break
    default:fatalError("Unknown case")
    }
    if after {NativeAlarmService.effects.removeFirst().resume()}
    else {NativeAlarmService.authorized.removeFirst().resume()}
    if name=="alarm_replace" {
      try await wait {!NativeAlarmService.authorized.isEmpty}
      checks["replaced_generation_never_scheduled"] = !NativeAlarmService.events.contains("schedule")
      NativeAlarmService.authorized.removeFirst().resume()
    }
    try await wait {m.nativeSchedulesInFlight==0}
    if positive || name=="alarm_replace" {
      checks["one_current_schedule"]=NativeAlarmService.events.filter {$0=="schedule"}.count==1
      checks["current_ownership_committed"]=timer ? m.data.nativeTimerIDs.contains(id):m.data.nativeAlarmIDs.contains(id)
      checks["current_schedule_active"]=NativeAlarmService.created==[id]
    } else {
      checks["no_stale_ownership"] = !m.data.nativeTimerIDs.contains(id) && !m.data.nativeAlarmIDs.contains(id)
      checks["no_orphan_after_settle"]=NativeAlarmService.created.isEmpty
      if after {checks["inflight_effect_cleaned_up"]=NativeAlarmService.events.suffix(2)==["schedule","cancel"]}
      else {checks["no_stale_schedule_even_transiently"] = !NativeAlarmService.events.contains("schedule")}
    }
    checks["disk_matches_memory"]=try Snapshot.canonicalBytes(Data(contentsOf:store))==Snapshot.canonicalBytes(JSONEncoder().encode(m.data))
    checks["no_spurious_error"]=m.error==nil
    checks["writer_settled"]=m.nativeSchedulesInFlight==0
    let failed=checks.filter {!$0.value}.map(\.key).sorted()
    print(String(decoding:try JSONSerialization.data(withJSONObject:["case":name,"checks":checks,"events":NativeAlarmService.events,
      "verdict":failed.isEmpty ? "PASS":"FAIL","failed":failed,"actual_OS_operations":false],options:[.sortedKeys]),as:UTF8.self))
  }
}
