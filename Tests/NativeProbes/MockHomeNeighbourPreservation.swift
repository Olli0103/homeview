import Foundation

/// Opt-in actual-AppModel probe. The runner appends only a private-store accessor
/// to a byte-identical AppModel copy; no product method is replaced.
@main struct MockHomeNeighbourPreservation {
  @MainActor static func main() throws {
    let args=ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"),let index=args.firstIndex(of:"--persistence-test"),
      args.indices.contains(index+1),UUID(uuidString:args[index+1]) != nil,
      !args.contains("--system-alarms"),!args.contains("--reset-test-store"),
      Bundle.main.url(forResource:"demo-tone",withExtension:"wav")==nil else {
      fatalError("Owned synthetic UUID store only")
    }
    let model=AppModel(),baseline=Snapshot()
    let store=model.gateStoreURL
    var checks:[String:Bool]=[:]
    func seed() throws {
      model.setHomeControlsForeground(false)
      model.data=baseline
      guard model.persist() else {throw HomeControlFailure.unavailable}
      model.error=nil
      model.setHomeControlsForeground(true)
    }
    func writeForeign(_ home:MockHome) throws {
      var foreign=baseline;foreign.home=home
      try JSONEncoder().encode(foreign).write(to:store,options:.atomic)
    }
    func saved() throws -> MockHome {
      try Snapshot.decodeMigrating(Data(contentsOf:store)).home
    }
    func changedValue(_ slot:HomeControlSlot) -> HomeControlValue {
      switch slot {
      case .temperature:.number(74)
      case .thermostatMode:.mode(1)
      case .entryLight,.bedroomLight,.fan:.flag(false)
      case .brightness:.number(37)
      case .fanSpeed:.number(63)
      case .blinds:.number(25)
      }
    }
    // The desired characteristic is unchanged. A different persisted neighbour,
    // the lock and the prior audit must survive the explicit mock command.
    for target in HomeControlSlot.allCases {
      for neighbour in HomeControlSlot.allCases where neighbour != target {
        try seed()
        var foreign=baseline.home
        try HomeMockControls.apply(neighbour,value:changedValue(neighbour),to:&foreign)
        foreign.locked=false;foreign.lastScene="FOREIGN_NEIGHBOUR_CANARY"
        foreign.audit.append("Owned foreign neighbour receipt")
        try writeForeign(foreign)
        var expected=foreign
        try HomeMockControls.apply(target,value:changedValue(target),to:&expected)
        let state=model.requestHomeControl(target,value:changedValue(target)),actual=try saved()
        let prefix="\(target.rawValue)_preserves_\(neighbour.rawValue)"
        checks[prefix+"_confirmed"]=state == .confirmed
        checks[prefix+"_exact_home"]=actual==expected
        checks[prefix+"_lock_unchanged"]=actual.locked==foreign.locked
        checks[prefix+"_foreign_audit_retained"]=actual.audit.starts(with:foreign.audit)
      }
      // Changing the target itself must still fence a stale pending request.
      try seed()
      var foreign=baseline.home
      try HomeMockControls.apply(target,value:changedValue(target),to:&foreign)
      try writeForeign(foreign)
      let before=try Data(contentsOf:store)
      let state=model.requestHomeControl(target,value:changedValue(target))
      checks[target.rawValue+"_foreign_target_rejected"]=state == .failed(.changed)
      checks[target.rawValue+"_foreign_target_no_write"]=try Data(contentsOf:store)==before
    }
    // Ordinary scenes may not restore an old lock, fan or audit incidentally.
    // These scenes need no device-security permission and never control a lock.
    for scene in ["Good Morning","Movie Time","Chill Out","Dinner Time"] {
      try seed()
      var foreign=baseline.home
      foreign.locked=false;foreign.fan=false;foreign.fanSpeed=63
      foreign.audit=["Owned foreign scene receipt"]
      try writeForeign(foreign)
      var expected=foreign;try expected.transact(.scene(scene))
      model.command(.scene(scene));let actual=try saved()
      checks[scene+"_confirmed"]=model.lastHomeCommandState == .confirmed
      checks[scene+"_exact_home"]=actual==expected
      checks[scene+"_lock_unchanged"]=actual.locked==foreign.locked
      checks[scene+"_foreign_audit_retained"]=actual.audit.starts(with:foreign.audit)

      // A changed availability or malformed current store is not permission to
      // overwrite it from the old in-memory copy.
      try seed()
      foreign=baseline.home;foreign.online=false;try writeForeign(foreign)
      let offlineBytes=try Data(contentsOf:store)
      model.command(.scene(scene))
      checks[scene+"_foreign_offline_not_confirmed"]=model.lastHomeCommandState != .confirmed
      checks[scene+"_foreign_offline_bytes_preserved"]=try Data(contentsOf:store)==offlineBytes

      try seed()
      let malformed=Data("{OWNED_MALFORMED_MOCK_HOME".utf8)
      try malformed.write(to:store,options:.atomic)
      model.command(.scene(scene))
      checks[scene+"_malformed_not_confirmed"]=model.lastHomeCommandState != .confirmed
      checks[scene+"_malformed_bytes_preserved"]=try Data(contentsOf:store)==malformed
    }
    // End with valid owned state and prove fresh AppModel reading, not replay.
    try seed();_ = model.requestHomeControl(.temperature,value:.number(74))
    let bytes=try Data(contentsOf:store),reloaded=AppModel()
    checks["fresh_model_reads_committed_home"]=reloaded.data.home == model.data.home
    checks["fresh_model_no_write_replay"]=try Data(contentsOf:store)==bytes
    checks["no_system_alarm_or_timer_ids"]=model.data.nativeAlarmIDs.isEmpty && model.data.nativeTimerIDs.isEmpty
    model.setHomeControlsForeground(false)
    let failed=checks.filter{!$0.value}.map(\.key).sorted()
    print(String(data:try JSONSerialization.data(withJSONObject:["checks":checks,
      "assertions":checks.count,"failed":failed,"verdict":failed.isEmpty ? "PASS":"FAIL"],
      options:[.sortedKeys]),encoding:.utf8)!)
    exit(failed.isEmpty ? 0:1)
  }
}
