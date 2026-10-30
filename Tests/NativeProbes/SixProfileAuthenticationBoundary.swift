import Foundation

/// Opt-in native contract probe: real AppModel and DeviceConnections, synthetic
/// providers and a new UUID store only. The runner adds only a store-URL getter.
@main struct SixProfileAuthenticationBoundary {
  @MainActor final class ControlledProvider: DeviceDataProvider {
    var permission = true
    var grant = true
    var holdUnlock = false
    var holdPermission = false
    var holdEvents = false
    var holdReminders = false
    var permissionCalls = 0
    var eventReads = 0
    var reminderReads = 0
    var writes = 0
    var unlocks: [CheckedContinuation<Bool, Never>] = []
    var permissions: [CheckedContinuation<Void, any Error>] = []
    var eventsReplies: [CheckedContinuation<[DeviceEvent], any Error>] = []
    var reminderReplies: [CheckedContinuation<[DeviceReminder], any Error>] = []
    func authorized(_ kind: DataConnection) -> Bool { permission }
    func authorizePersonal(_ kind: DataConnection) async throws {
      permissionCalls += 1
      if holdPermission {
        try await withCheckedThrowingContinuation { permissions.append($0) }
      } else if !permission { throw CocoaError(.userCancelled) }
    }
    func events(from: Date, to: Date) async throws -> [DeviceEvent] {
      eventReads += 1
      if holdEvents { return try await withCheckedThrowingContinuation { eventsReplies.append($0) } }
      return [event("CURRENT", from: from)]
    }
    func event(_ title: String, from: Date = Date()) -> DeviceEvent {
      DeviceEvent(id: title, title: title, start: from.addingTimeInterval(60),
        end: from.addingTimeInterval(120), location: "Synthetic", calendar: "Owned", cancelled: false)
    }
    func reminders() async throws -> [DeviceReminder] {
      reminderReads += 1
      if holdReminders { return try await withCheckedThrowingContinuation { reminderReplies.append($0) } }
      return [DeviceReminder(id: "CURRENT", title: "CURRENT", completed: false)]
    }
    func addReminder(_ title: String) async throws -> String { writes += 1; return "SYNTHETIC" }
    func completeReminder(_ id: String, completed: Bool) async throws { writes += 1 }
    func removeReminder(_ id: String) async throws { writes += 1 }
    func authorizeMusic() async throws { permissionCalls += 1 }
    func searchMusic(_ text: String) async throws -> [DeviceTrack] { [] }
    func playMusic(_ index: Int) async throws { writes += 1 }
    func resumeMusic() async throws { writes += 1 }
    func pauseMusic() {}
    var musicPlaying: Bool { false }
    var musicTime: Double { 0 }
    func weather(_ city: String) async throws -> WeatherReading { throw URLError(.unsupportedURL) }
    func unlock() async -> Bool {
      if holdUnlock { return await withCheckedContinuation { unlocks.append($0) } }
      return grant
    }
  }

  @MainActor static func main() async throws {
    let args = ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"), let i = args.firstIndex(of: "--persistence-test"),
      args.indices.contains(i + 1), UUID(uuidString: args[i + 1]) != nil,
      !args.contains("--system-alarms"), !args.contains("--reset-test-store"),
      Bundle.main.url(forResource: "demo-tone", withExtension: "wav") == nil
    else { fatalError("New owned synthetic UUID store only") }
    let denied = args.contains("--device-unlock-denied")
    var checks: [String: Bool] = [:]
    func check(_ key: String, _ value: Bool) { precondition(checks[key] == nil); checks[key] = value }
    func encoded<T: Encodable>(_ value: T) throws -> Data {
      let e = JSONEncoder(); e.outputFormatting = [.sortedKeys]; return try e.encode(value)
    }
    func until(_ ready: () -> Bool) async {
      let deadline = ProcessInfo.processInfo.systemUptime + 5
      while !ready() && ProcessInfo.processInfo.systemUptime < deadline { await Task.yield() }
      precondition(ready(), "Controlled continuation was not reached")
    }
    let model = AppModel(), names = Fixtures.profiles
    check("six_distinct_profiles", names.count == 6 && Set(names).count == 6)
    check("fresh_process_not_authenticated", !model.authorized && !model.connections.personalUnlocked)
    check("fresh_process_hides_local_content", model.messages.isEmpty && model.reminders.isEmpty)
    var expected: [String: PersonalContent] = [:]
    for name in names {
      var content = PersonalContent()
      content.messages = ["OWNED_\(name)_MESSAGE"]
      content.reminders = [ReminderItem(title: "OWNED_\(name)_REMINDER")]
      expected[name] = content
    }
    model.data.personal = expected
    check("owned_seed_saved", model.persist())
    for name in names {
      model.signIn(name)
      check("\(name)_demo_not_device_auth", model.authorized && !model.connections.personalUnlocked && !model.canControlMockSecurity)
      check("\(name)_only_own_messages", model.messages == expected[name]!.messages)
      check("\(name)_only_own_reminders", model.reminders.map(\.title) == expected[name]!.reminders.map(\.title))
      check("\(name)_append_own_message", model.appendLocalMessage("OWNED_\(name)_EDIT"))
      check("\(name)_append_own_reminder", model.addLocalReminder("OWNED_\(name)_EDIT"))
      expected[name] = model.data.personal[name]
      check("\(name)_all_siblings_preserved", try encoded(model.data.personal) == encoded(expected))
      let granted = await model.connections.unlock()
      check("\(name)_device_result_separate", granted == !denied && model.connections.personalUnlocked == !denied)
      await model.connections.connect(.calendar)
      await model.connections.connect(.reminders)
      check("\(name)_private_cache_follows_device_result", denied
        ? model.connections.events.isEmpty && model.connections.reminders.isEmpty
        : !model.connections.events.isEmpty && !model.connections.reminders.isEmpty)
      model.signOut()
      check("\(name)_logout_clears_grant_and_cache", !model.connections.personalUnlocked && model.connections.events.isEmpty && model.connections.reminders.isEmpty)
      check("\(name)_logout_hides_local_records", !model.authorized && model.messages.isEmpty && model.reminders.isEmpty)
    }
    for from in names {
      for to in names {
        let key = "\(from)_to_\(to)"
        model.signIn(from)
        _ = await model.connections.unlock()
        await model.connections.connect(.calendar)
        await model.connections.connect(.reminders)
        model.assistantInput = "OWNED_\(from)_DRAFT"
        model.assistantReply = "OWNED_\(from)_ANSWER"
        model.messageText = "OWNED_\(from)_COMPOSER"
        let generation = model.personalSessionGeneration
        model.signIn(to)
        check(key + "_session_rotated", model.personalSessionGeneration > generation)
        check(key + "_device_grant_revoked", !model.connections.personalUnlocked && !model.canControlMockSecurity)
        check(key + "_private_caches_empty", model.connections.events.isEmpty && model.connections.reminders.isEmpty && model.connections.tracks.isEmpty)
        check(key + "_drafts_cleared", model.assistantInput.isEmpty && model.messageText.isEmpty)
        check(key + "_old_answer_cleared", model.assistantReply == "What can I help you with?")
        check(key + "_exact_target_records", try encoded(model.data.personal[to]!) == encoded(expected[to]!))
        check(key + "_only_target_exposed", model.messages == expected[to]!.messages && model.reminders.map(\.id) == expected[to]!.reminders.map(\.id))
        check(key + "_all_records_preserved", try encoded(model.data.personal) == encoded(expected))
      }
    }
    let name = model.profile, session = model.personalSessionGeneration
    model.signIn("NOT_AN_OWNED_PROFILE")
    check("unknown_profile_rejected_without_switch", model.profile == name && model.personalSessionGeneration == session)
    model.signOut()
    let file = try Data(contentsOf: model.gateStoreURL)
    let stored = try Snapshot.decodeMigrating(file)
    check("six_profile_edits_durable", try encoded(stored.personal) == encoded(expected))
    let restored = AppModel()
    check("restart_has_no_profile_or_auth_grant", restored.profile == nil && !restored.authorized && !restored.connections.personalUnlocked)
    check("restart_hides_personal_records", restored.messages.isEmpty && restored.reminders.isEmpty)
    for name in names {
      restored.signIn(name)
      check("restart_\(name)_only_own_records", restored.messages == expected[name]!.messages && restored.reminders.map(\.id) == expected[name]!.reminders.map(\.id))
      check("restart_\(name)_no_inherited_device_grant", !restored.connections.personalUnlocked)
    }
    restored.signOut()
    check("no_scheduled_hardware_actions", stored.nativeAlarmIDs.isEmpty && stored.nativeTimerIDs.isEmpty)

    // Controlled native session: OS permission, auth and reads stay distinct.
    let p = ControlledProvider(), s = DeviceConnections(provider: p)
    await s.connect(.calendar); await s.connect(.reminders)
    check("OS_permission_does_not_read_locked_stores", p.permissionCalls == 2 && p.eventReads == 0 && p.reminderReads == 0)
    p.grant = false
    check("denied_auth_does_not_unlock", await s.unlock() == false && !s.personalUnlocked)
    check("denied_auth_still_no_store_reads", p.eventReads == 0 && p.reminderReads == 0)
    p.holdUnlock = true
    let lateAuth = Task { await s.unlock() }
    await until { p.unlocks.count == 1 }; s.lock(); p.unlocks.removeFirst().resume(returning: true)
    check("late_auth_after_lock_rejected", await lateAuth.value == false && !s.personalUnlocked)
    p.holdUnlock = false; p.grant = true
    check("fresh_auth_after_invalidated_attempt", await s.unlock())
    check("auth_alone_does_not_read_stores", p.eventReads == 0 && p.reminderReads == 0)
    p.holdPermission = true
    let latePermission = Task { await s.connect(.calendar) }
    await until { p.permissions.count == 1 }; s.lock(); p.permissions.removeFirst().resume()
    await latePermission.value
    check("late_permission_after_lock_no_read", p.eventReads == 0 && s.events.isEmpty && !s.personalUnlocked)
    p.holdPermission = false

    for kind in [DataConnection.calendar, .reminders] {
      for lateError in [false, true] {
        let key = kind.rawValue + (lateError ? "_late_error" : "_late_success")
        _ = await s.unlock()
        if kind == .calendar { p.holdEvents = true } else { p.holdReminders = true }
        let old = Task { await s.connect(kind) }
        await until { kind == .calendar ? p.eventsReplies.count == 1 : p.reminderReplies.count == 1 }
        s.lock(); _ = await s.unlock()
        let current = Task { await s.connect(kind) }
        await until { kind == .calendar ? p.eventsReplies.count == 2 : p.reminderReplies.count == 2 }
        if kind == .calendar {
          let reply = p.eventsReplies.removeFirst()
          if lateError { reply.resume(throwing: CocoaError(.fileReadUnknown)) }
          else { reply.resume(returning: [p.event("OLD_PRIVATE_CANARY")]) }
        } else {
          let reply = p.reminderReplies.removeFirst()
          if lateError { reply.resume(throwing: CocoaError(.fileReadUnknown)) }
          else { reply.resume(returning: [DeviceReminder(id: "OLD", title: "OLD_PRIVATE_CANARY", completed: false)]) }
        }
        await old.value
        check(key + "_cannot_clear_new_busy_state", s.busy.contains(kind))
        check(key + "_cannot_restore_old_data", s.events.isEmpty && s.reminders.isEmpty)
        if kind == .calendar {
          p.eventsReplies.removeFirst().resume(returning: [p.event("CURRENT_PRIVATE_CANARY")])
        } else {
          p.reminderReplies.removeFirst().resume(returning: [DeviceReminder(id: "CURRENT", title: "CURRENT_PRIVATE_CANARY", completed: false)])
        }
        await current.value
        check(key + "_new_request_completes", !s.busy.contains(kind) && (kind == .calendar
          ? s.events.map(\.title) == ["CURRENT_PRIVATE_CANARY"]
          : s.reminders.map(\.title) == ["CURRENT_PRIVATE_CANARY"]))
        s.lock()
        check(key + "_lock_clears_current_data", s.events.isEmpty && s.reminders.isEmpty && !s.personalUnlocked)
        p.holdEvents = false; p.holdReminders = false
      }
    }
    check("controlled_provider_never_wrote_or_played", p.writes == 0)
    check("all_controlled_completions_settled", p.unlocks.isEmpty && p.permissions.isEmpty && p.eventsReplies.isEmpty && p.reminderReplies.isEmpty)
    let failed = checks.filter { !$0.value }.map(\.key).sorted()
    print(String(data: try JSONSerialization.data(withJSONObject: ["checks": checks,
      "assertions": checks.count, "failed": failed, "verdict": failed.isEmpty ? "PASS" : "FAIL",
      "fixture_authentication_denied": denied, "profile_transitions": names.count * names.count], options: [.sortedKeys]), encoding: .utf8)!)
    exit(failed.isEmpty ? 0 : 1)
  }
}
