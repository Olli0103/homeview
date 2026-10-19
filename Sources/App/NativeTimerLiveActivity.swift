import Foundation

@MainActor final class UnavailableTimerActivityBackend:TimerActivityBackend {
  var supported:Bool { false }
  func apply(_ state:TimerActivityState?,mayStart:@escaping @MainActor ()->Bool) async throws -> TimerActivityDelivery { .unavailable }
}
@MainActor final class FixtureTimerActivityBackend:TimerActivityBackend {
  var supported:Bool { true }
  private var active=false
  func apply(_ state:TimerActivityState?,mayStart:@escaping @MainActor ()->Bool) async throws -> TimerActivityDelivery {
    if state==nil { active=false;return .synthetic(active:false) }
    if !active { guard mayStart() else {return .waitingForExplicitStart};active=true }
    return .synthetic(active:active)
  }
}
#if canImport(ActivityKit) && os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit
@MainActor final class NativeTimerActivityBackend:TimerActivityBackend {
  var supported:Bool { true }
  func apply(_ state:TimerActivityState?,mayStart:@escaping @MainActor ()->Bool) async throws -> TimerActivityDelivery {
    if await Self.updateExisting(state) {return state==nil ? .ended:.active}
    guard let state else {return .ended}
    guard mayStart() else {return .waitingForExplicitStart}
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {return .unavailable}
    let content=ActivityContent(state:state,staleDate:state.deadline)
    // No await between the live foreground/action fence and the public request.
    _ = try Activity.request(attributes:HomeViewTimerAttributes(schemaVersion:1),content:content,pushType:nil)
    return .active
  }
  // ActivityKit's non-Sendable handles stay on this unshared nonisolated path;
  // only our Codable/Sendable state crosses the application actor boundary.
  nonisolated private static func updateExisting(_ state:TimerActivityState?) async -> Bool {
    let owned=Activity<HomeViewTimerAttributes>.activities
    guard let state else {
      for activity in owned { await activity.end(nil,dismissalPolicy:.immediate) }
      return true
    }
    let content=ActivityContent(state:state,staleDate:state.deadline)
    if let current=owned.first(where:{$0.activityState == .active || $0.activityState == .stale}) {
      await current.update(content)
      for duplicate in owned where duplicate.id != current.id {await duplicate.end(nil,dismissalPolicy:.immediate)}
      return true
    }
    for ended in owned {await ended.end(nil,dismissalPolicy:.immediate)}
    return false
  }
}
#endif
@MainActor func makeTimerActivityBackend()->any TimerActivityBackend {
  let args=ProcessInfo.processInfo.arguments
  if args.contains("--uitesting") {
    if args.contains("--timer-activity-fixture") {return FixtureTimerActivityBackend()}
    // Only an explicit synthetic, UUID-owned system-activity experiment may use ActivityKit.
    let owned=args.firstIndex(of:"--persistence-test").flatMap {i in args.indices.contains(i+1) ? UUID(uuidString:args[i+1]):nil} != nil
    if !owned || !args.contains("--timer-activity-system-test") {return UnavailableTimerActivityBackend()}
  }
  #if canImport(ActivityKit) && os(iOS) && !targetEnvironment(macCatalyst)
  return NativeTimerActivityBackend()
  #else
  return UnavailableTimerActivityBackend()
  #endif
}

/// Read-only evidence for an explicitly owned synthetic system-activity run.
@MainActor func timerActivitySystemFixtureReport()->String? {
  let args=ProcessInfo.processInfo.arguments
  guard args.contains("--uitesting"),args.contains("--timer-activity-system-test"),
    let i=args.firstIndex(of:"--persistence-test"),args.indices.contains(i+1),UUID(uuidString:args[i+1]) != nil else {return nil}
  #if canImport(ActivityKit) && os(iOS) && !targetEnvironment(macCatalyst)
  let owned=Activity<HomeViewTimerAttributes>.activities.filter {$0.activityState == .active || $0.activityState == .stale}
  return "Own activities=\(owned.count); running=\(owned.first?.content.state.runningCount ?? 0); paused=\(owned.first?.content.state.pausedCount ?? 0)"
  #else
  return "System timer activities unavailable on this platform."
  #endif
}
