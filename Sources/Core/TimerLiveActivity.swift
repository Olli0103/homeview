import Foundation
import Observation

/// The activity receives no timer titles, profile, source identifiers or account data.
struct TimerActivityInput: Sendable {
  let deadline:Date?
  let pausedRemaining:TimeInterval
}
struct TimerActivityState: Codable, Hashable, Sendable {
  let runningCount:Int
  let pausedCount:Int
  let deadline:Date?
  let pausedSeconds:Int?
  static func project(_ timers:[TimerActivityInput],at now:Date)->Self? {
    guard now.timeIntervalSinceReferenceDate.isFinite else { return nil }
    var deadlines:[Date]=[],paused:[Int]=[]
    for timer in timers.prefix(12) {
      if let date=timer.deadline {
        let remaining=date.timeIntervalSince(now)
        if remaining.isFinite,remaining>0,remaining<=86400 { deadlines.append(date) }
      } else if timer.pausedRemaining.isFinite,timer.pausedRemaining>0,timer.pausedRemaining<=86400 {
        paused.append(Int(ceil(timer.pausedRemaining)))
      }
    }
    guard !deadlines.isEmpty || !paused.isEmpty else { return nil }
    return Self(runningCount:deadlines.count,pausedCount:paused.count,
      deadline:deadlines.min(),pausedSeconds:paused.min())
  }
}

enum TimerActivityDelivery: Equatable, Sendable {
  case active, ended, waitingForExplicitStart, unavailable, synthetic(active:Bool)
  var message:String {
    switch self {
    case .active: "ActivityKit accepted timer updates. Visibility is controlled by the system."
    case .ended: "No own timer activity is active."
    case .waitingForExplicitStart: "Start a timer or choose Show timer activity while HomeView is open."
    case .unavailable: "Live Activities are unavailable or disabled in system settings."
    case .synthetic(let active): "Synthetic timer activity (\(active ? "active":"ended")) · No system activity created."
    }
  }
}
@MainActor protocol TimerActivityBackend: AnyObject {
  var supported:Bool { get }
  func apply(_ state:TimerActivityState?,mayStart:@escaping @MainActor ()->Bool) async throws -> TimerActivityDelivery
}

/// One serialized writer, with latest-state convergence after an in-flight update.
/// A new system request additionally needs a still-current explicit foreground action.
@MainActor @Observable final class TimerLiveActivitySession {
  private let backend:any TimerActivityBackend
  private(set) var status="Timer Live Activities are off."
  private(set) var busy=false
  var supported:Bool { backend.supported }
  private var state:TimerActivityState?
  private var enabled=false
  private var foreground=false
  private var startRequested=false
  private var initialized=false
  private var generation=0
  private var worker:Task<Void,Never>?
  init(backend:any TimerActivityBackend) { self.backend=backend }
  func synchronize(_ value:TimerActivityState?,enabled:Bool,foreground:Bool,requestStart:Bool=false) {
    let next=enabled ? value:nil
    let request=requestStart && enabled && foreground && next != nil
    let changed = !initialized || state != next || self.enabled != enabled || self.foreground != foreground || request
    self.state=next;self.enabled=enabled;self.foreground=foreground;initialized=true
    if !enabled || !foreground { startRequested=false }
    if request { startRequested=true }
    guard changed else { return }
    generation+=1
    guard worker==nil else { return }
    busy=true
    worker=Task { [weak self] in await self?.drain() }
  }
  private func drain() async {
    while true {
      let token=generation,value=state
      do {
        let result=try await backend.apply(value,mayStart:{ [weak self] in
          guard let self else { return false }
          return self.generation==token && self.enabled && self.foreground && self.startRequested
        })
        if generation==token { status=result.message }
      } catch {
        if generation==token { status="Timer activity could not be updated. The timer itself was not changed." }
      }
      if generation==token {
        startRequested=false;worker=nil;busy=false;return
      }
    }
  }
}
