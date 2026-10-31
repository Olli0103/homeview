import Foundation

/// Authorization can suspend long enough for the initiating action to become
/// obsolete. Never submit an OS effect on the strength of a pre-await decision.
enum AlarmScheduleAdmission {
  @MainActor static func perform(deadline:Date?=nil,
    isCurrent:@escaping @MainActor ()->Bool,
    now:@MainActor ()->Date = {Date()},
    authorize:@MainActor () async throws -> Void,
    schedule:@MainActor (TimeInterval?) async throws -> Void) async throws -> Bool {
    func remaining()->TimeInterval? {deadline.map {$0.timeIntervalSince(now())}}
    func allowed(_ duration:TimeInterval?)->Bool {
      guard !Task.isCancelled,isCurrent() else {return false}
      if deadline != nil {return duration.map {$0.isFinite && $0>0 && $0<=86400} ?? false}
      return true
    }
    guard allowed(remaining()) else {return false}
    try await authorize()
    // Recompute from the absolute deadline, not the original duration. There
    // is no await between this fence and invoking the provider operation.
    let duration=remaining()
    guard allowed(duration) else {return false}
    try await schedule(duration)
    return true
  }
}
