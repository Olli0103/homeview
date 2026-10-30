import Foundation

/// Actual AppModel/LockActionSession/MockLockDevice; own UUID storage only.
@main struct MockLockPersistentObservation {
  @MainActor static func main() async throws {
    let args=ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"),let i=args.firstIndex(of:"--persistence-test"),
      args.indices.contains(i+1),UUID(uuidString:args[i+1]) != nil,
      !args.contains("--system-alarms"),!args.contains("--reset-test-store"),
      Bundle.main.url(forResource:"demo-tone",withExtension:"wav")==nil else {fatalError("Own mock store only")}
    let model=AppModel(),baseline=Snapshot(),store=model.gateStoreURL
    var checks:[String:Bool]=[:]
    func seed() async throws {
      model.setLockForeground(false);model.data=baseline
      guard model.persist(),await model.connections.unlock() else {throw LockDeviceError.unavailable}
      model.route = .lock;model.setLockForeground(true)
    }
    func write(_ home:MockHome) throws {
      var foreign=baseline;foreign.home=home
      try JSONEncoder().encode(foreign).write(to:store,options:.atomic)
    }
    func prepare() async throws -> UUID {
      await model.securityLock.prepare()
      guard let id=model.securityLock.proposal?.id else {throw LockDeviceError.unavailable}
      return id
    }
    try await seed();let neighbourProposal=try await prepare()
    var foreign=baseline.home
    foreign.temperature=74;foreign.fanSpeed=63;foreign.brightness=37
    foreign.audit=["Owned foreign lock-neighbour receipt"]
    try write(foreign)
    var expected=foreign;try expected.transact(.lock,authorized:true)
    await model.securityLock.confirm(id:neighbourProposal)
    let stored=try Snapshot.decodeMigrating(Data(contentsOf:store)).home
    checks["neighbour_action_confirmed"]=model.securityLock.phase == .confirmed
    checks["neighbour_exact_home_preserved"]=stored==expected
    checks["neighbour_foreign_audit_retained"]=stored.audit.starts(with:foreign.audit)
    checks["neighbour_temperature_preserved"]=stored.temperature==74
    checks["neighbour_fan_and_light_preserved"]=stored.fanSpeed==63 && stored.brightness==37
    let committed=try Data(contentsOf:store)
    await model.securityLock.confirm(id:neighbourProposal)
    checks["consumed_approval_no_replay"]=try Data(contentsOf:store)==committed

    try await seed();let changedProposal=try await prepare()
    foreign=baseline.home;foreign.locked=false
    foreign.audit=["Owned foreign lock target changed"]
    try write(foreign);let changed=try Data(contentsOf:store)
    await model.securityLock.confirm(id:changedProposal)
    checks["foreign_target_invalidates_approval"]=model.securityLock.phase == .failed
    checks["foreign_target_no_write"]=try Data(contentsOf:store)==changed
    checks["foreign_target_latest_reading"]=model.securityLock.reading?.state == .unlocked

    try await seed();let offlineProposal=try await prepare()
    foreign=baseline.home;foreign.online=false;try write(foreign)
    let offline=try Data(contentsOf:store)
    await model.securityLock.confirm(id:offlineProposal)
    checks["foreign_offline_invalidates_approval"]=model.securityLock.phase == .failed
    checks["foreign_offline_no_write"]=try Data(contentsOf:store)==offline

    try await seed();let brokenProposal=try await prepare()
    let broken=Data("{OWNED_BROKEN_LOCK_STORE".utf8);try broken.write(to:store,options:.atomic)
    await model.securityLock.confirm(id:brokenProposal)
    checks["malformed_store_invalidates_approval"]=model.securityLock.phase == .failed
    checks["malformed_store_no_write"]=try Data(contentsOf:store)==broken

    try await seed();foreign=baseline.home;foreign.locked=false;try write(foreign)
    let beforePrepare=try Data(contentsOf:store)
    await model.securityLock.prepare()
    checks["prepare_observes_persisted_lock"]=model.securityLock.reading?.state == .unlocked
    checks["prepare_proposes_from_persisted_lock"]=model.securityLock.proposal?.targetLocked == true
    checks["prepare_does_not_write"]=try Data(contentsOf:store)==beforePrepare
    model.securityLock.cancelProposal()
    checks["cancel_no_write"]=try Data(contentsOf:store)==beforePrepare

    try await seed();let revokedProposal=try await prepare()
    let beforeRevoke=try Data(contentsOf:store);model.connections.lock()
    await model.securityLock.confirm(id:revokedProposal)
    checks["revocation_no_write"]=try Data(contentsOf:store)==beforeRevoke
    checks["revocation_not_confirmed"]=model.securityLock.phase != .confirmed
    model.setLockForeground(false)
    checks["no_system_alarm_or_timer_ids"]=model.data.nativeAlarmIDs.isEmpty && model.data.nativeTimerIDs.isEmpty
    let failures=checks.filter{!$0.value}.map(\.key).sorted()
    print(String(data:try JSONSerialization.data(withJSONObject:["checks":checks,
      "assertions":checks.count,"failed":failures,"verdict":failures.isEmpty ? "PASS":"FAIL"],
      options:[.sortedKeys]),encoding:.utf8)!)
    exit(failures.isEmpty ? 0:1)
  }
}
