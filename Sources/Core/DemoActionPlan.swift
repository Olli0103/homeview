import Foundation

/// A bounded, explicitly requested local-demo plan. Never generated from an AI reply.
struct DemoActionPlan: Identifiable, Equatable, Sendable {
  enum Operation: Equatable, Sendable {
    case temperature(Int), brightness(Int), foregroundTimer(seconds:Int,title:String)
    var summary:String {
      switch self {
      case .temperature(let value): "Mock thermostat → \(value)°"
      case .brightness(let value): "Mock brightness → \(value)%"
      case .foregroundTimer(let seconds,let title): "Foreground demo timer ‘\(title)’ → \(seconds) seconds"
      }
    }
  }
  enum Disposition: Equatable, Sendable {
    case awaitingApproval, queued, running, confirmed(String), failed(String), unverified(String)
    case dependencyNotMet, cancelled
    var text:String {
      switch self {
      case .awaitingApproval: "Not run · Needs confirmation"
      case .queued: "Not run · Waiting for predecessor"
      case .running: "Checking local result…"
      case .confirmed(let detail): "Confirmed · "+detail
      case .failed(let detail): "Failed · "+detail
      case .unverified(let detail): "Unverified · "+detail
      case .dependencyNotMet: "Not run · Previous step was not confirmed"
      case .cancelled: "Not run · Cancelled"
      }
    }
  }
  struct Step: Identifiable, Equatable, Sendable {
    let id:UUID
    let operation:Operation
    var disposition:Disposition = .awaitingApproval
  }
  enum Phase: Equatable, Sendable { case preview, running, completed, stopped, cancelled }
  enum Result: Equatable, Sendable { case confirmed(String), failed(String), unverified(String) }
  enum ParseResult: Equatable, Sendable {
    case notAPlan, rejected(String), proposal(DemoActionPlan)
  }
  let id:UUID
  let request:String
  let context:Int
  let createdUptime:TimeInterval
  private(set) var steps:[Step]
  private(set) var phase:Phase = .preview
  private(set) var note="Nothing has run. Confirm this local demo plan separately."
  private(set) var execution:UUID?
  var busy:Bool { phase == .running }
  var confirmedCount:Int { steps.filter { if case .confirmed = $0.disposition { return true };return false }.count }

  static func parse(_ input:String,context:Int,uptime:TimeInterval)->ParseResult {
    let raw=input.trimmingCharacters(in:.whitespacesAndNewlines)
    guard raw.lowercased().hasPrefix("plan:") else { return .notAPlan }
    guard raw.count<=1000,uptime.isFinite,uptime>=0 else {
      return .rejected("No actions taken. Use a plan of at most 1000 characters.")
    }
    let clauses=raw.dropFirst(5).components(separatedBy:";").map { $0.trimmingCharacters(in:.whitespacesAndNewlines) }
    guard (2...6).contains(clauses.count) else {
      return .rejected("No actions taken. Use ‘plan:’ followed by 2–6 steps separated by semicolons.")
    }
    var operations:[Operation]=[],problems:[String]=[]
    for (index,clause) in clauses.enumerated() {
      if case .temperature(let value)=AssistantIntent(clause),(50...90).contains(value) {
        operations.append(.temperature(value));continue
      }
      let words=clause.lowercased().split(whereSeparator: { $0.isWhitespace }).map(String.init)
      if words.count==2,["brightness","helligkeit"].contains(words[0]),
        !words[1].isEmpty,words[1].utf8.allSatisfy({ (48...57).contains($0) }),
        let value=Int(words[1]),(0...100).contains(value) {
        operations.append(.brightness(value));continue
      }
      if case .timer(let seconds,let title)=EverydayVoiceCommand(clause) {
        operations.append(.foregroundTimer(seconds:seconds,title:title));continue
      }
      problems.append("Step \(index+1) is unsupported or invalid.")
    }
    guard problems.isEmpty else {
      return .rejected("No actions taken. "+problems.joined(separator:" ")+" Only mock temperature 50–90, brightness 0–100 and explicit foreground-demo timers are supported. No messages, calls, security actions, scenes, native accounts or generated AI actions.")
    }
    return .proposal(DemoActionPlan(id:UUID(),request:raw,context:context,createdUptime:uptime,
      steps:operations.map { Step(id:UUID(),operation:$0) }))
  }
  /// Approval is short-lived, contextual and consumed once. It grants local-demo scope only.
  mutating func confirm(id expected:UUID,context current:Int,uptime:TimeInterval,active:Bool)->UUID? {
    guard expected==id,phase == .preview else { return nil }
    guard active,current==context,uptime.isFinite,uptime>=createdUptime,uptime-createdUptime<60 else {
      cancel(note:"Approval expired or the app context changed. Nothing was run.");return nil
    }
    let token=UUID();execution=token;phase = .running
    for index in steps.indices { steps[index].disposition = .queued }
    note="Running the confirmed local demo plan. Steps are sequential, not an all-or-nothing transaction."
    return token
  }
  mutating func claimNext(token:UUID)->Step? {
    guard phase == .running,execution==token,
      !steps.contains(where:{ $0.disposition == .running }),
      let index=steps.firstIndex(where:{ $0.disposition == .queued }),
      steps[..<index].allSatisfy({ if case .confirmed = $0.disposition { return true };return false }) else { return nil }
    steps[index].disposition = .running
    return steps[index]
  }
  @discardableResult
  mutating func record(step id:UUID,token:UUID,result:Result)->Bool {
    guard phase == .running,execution==token,
      let index=steps.firstIndex(where:{ $0.id==id }),steps[index].disposition == .running else { return false }
    switch result {
    case .confirmed(let text): steps[index].disposition = .confirmed(text)
    case .failed(let text): steps[index].disposition = .failed(text)
    case .unverified(let text): steps[index].disposition = .unverified(text)
    }
    if case .confirmed = result {
      if confirmedCount==steps.count { phase = .completed;execution=nil;note="All \(steps.count) local demo steps confirmed by read-back." }
    } else {
      for next in steps.indices where steps[next].disposition == .queued { steps[next].disposition = .dependencyNotMet }
      phase = .stopped;execution=nil
      note="\(confirmedCount) of \(steps.count) steps confirmed. Remaining dependent steps did not run. Completed steps were not undone."
    }
    return true
  }
  mutating func cancel(note reason:String="Cancelled. Completed steps were not undone.") {
    guard phase == .preview || phase == .running else { return }
    for index in steps.indices {
      switch steps[index].disposition {
      case .awaitingApproval,.queued: steps[index].disposition = .cancelled
      case .running: steps[index].disposition = .unverified("Stopped during a step. Its outcome is not confirmed.")
      default: break
      }
    }
    phase = .cancelled;execution=nil;note=reason
  }
}
