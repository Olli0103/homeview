import Foundation
import Observation

enum LockReportedState: String, Equatable, Sendable {
  case locked, unlocked, unknown, jammed
  var lockedValue: Bool? {
    switch self { case .locked: true; case .unlocked: false; default: nil }
  }
  var title: String {
    switch self { case .locked: "Locked"; case .unlocked: "Unlocked"; case .unknown: "Unknown"; case .jammed: "Jammed" }
  }
}
struct LockReading: Equatable, Sendable {
  let state: LockReportedState
  var batteryPercent: Int? = nil
  var batteryFault = false
  var valid: Bool { batteryPercent.map { (0...100).contains($0) } ?? true }
  var canCommand: Bool { valid && state.lockedValue != nil && !batteryFault }
  var batteryText: String {
    if batteryFault { return "Battery fault · Control unavailable" }
    guard let batteryPercent,valid else { return "Battery level unavailable" }
    return batteryPercent<=20 ? "Low battery · \(batteryPercent)%" : "Battery \(batteryPercent)%"
  }
}
struct LockAccessContext: Equatable, Sendable {
  let generation: Int
  let active: Bool
  let authenticated: Bool
}
enum LockDeviceError: Error { case unavailable, denied, stateChanged, notWritable }
@MainActor protocol LockDeviceProvider: AnyObject {
  func read() async throws -> LockReading
  /// The adapter must reject a changed observation before mutation. No toggle/retry contract.
  func setLocked(_ target: Bool, expected: LockReading) async throws
}

/// Single-device, RAM-only authorization. No household identity, real Home or persisted grants.
@MainActor @Observable final class LockActionSession {
  struct Proposal: Equatable, Identifiable, Sendable {
    let id: UUID
    let targetLocked: Bool
    let observed: LockReading
    let generation: Int
    let createdUptime: TimeInterval
    var title: String { targetLocked ? "Confirm Lock" : "Confirm Unlock" }
  }
  enum Phase: Equatable { case idle, reading, approval, checking, sending, verifying, confirmed, cancelled, expired, failed, unverified }
  private(set) var reading: LockReading?
  private(set) var proposal: Proposal?
  private(set) var phase: Phase = .idle
  private(set) var status = "Mock lock · No command sent"
  @ObservationIgnored private let provider: any LockDeviceProvider
  @ObservationIgnored private let context: @MainActor () -> LockAccessContext
  @ObservationIgnored private let uptime: @MainActor () -> TimeInterval
  @ObservationIgnored private var epoch = UUID()
  @ObservationIgnored private var operation: UUID?
  @ObservationIgnored private var writeAttempted = false
  @ObservationIgnored private var operationCreated: TimeInterval?
  static let approvalLifetime: TimeInterval = 30
  var busy: Bool { operation != nil }

  init(provider: any LockDeviceProvider, context: @escaping @MainActor () -> LockAccessContext,
       uptime: @escaping @MainActor () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }) {
    self.provider=provider;self.context=context;self.uptime=uptime
  }
  private func ageValid(_ created: TimeInterval) -> Bool {
    let now=uptime()
    return created.isFinite && created>=0 && now.isFinite && now>=created && now-created<Self.approvalLifetime
  }
  private func allowed(_ generation: Int, authenticated: Bool) -> Bool {
    let current=context()
    return !Task.isCancelled && current.active && current.generation==generation && (!authenticated || current.authenticated)
  }
  private func current(_ ticket: UUID, generation: Int, authenticated: Bool) -> Bool {
    epoch==ticket && allowed(generation,authenticated:authenticated)
  }
  private func beginOperation(created: TimeInterval) -> UUID {
    let ticket=UUID();epoch=ticket;operation=ticket;operationCreated=created;return ticket
  }
  private func endOperation(_ ticket: UUID) {
    if operation==ticket { operation=nil;writeAttempted=false;operationCreated=nil }
  }
  private func stop(_ message: String, clearReading: Bool = false, expired: Bool = false) {
    epoch=UUID();proposal=nil
    if clearReading { reading=nil }
    phase=writeAttempted ? .unverified : (expired ? .expired : .cancelled)
    status=writeAttempted ? "Outcome unverified · A command may have been sent. Refresh before another action." : message
  }
  func revoke() { stop("Authorization discarded · No pending approval",clearReading:true) }
  func cancelProposal() {
    guard phase == .approval,proposal != nil else { return }
    stop("Cancelled · No command sent")
  }
  func expireApproval() {
    if busy,let operationCreated,!ageValid(operationCreated) {
      stop("Lock check expired · No command sent",expired:true);return
    }
    guard let proposal else { return }
    if !allowed(proposal.generation,authenticated:true) { revoke() }
    else if !ageValid(proposal.createdUptime) { stop("Confirmation expired · No command sent",expired:true) }
  }
  func refresh() async {
    guard !busy,!Task.isCancelled,context().active else { return }
    let generation=context().generation,created=uptime()
    let ticket=beginOperation(created:created)
    proposal=nil;phase = .reading;status="Reading mock lock…"
    defer { endOperation(ticket) }
    do {
      let value=try await provider.read()
      guard current(ticket,generation:generation,authenticated:false) else { if epoch==ticket { revoke() };return }
      guard ageValid(created) else { stop("Lock check expired · No command sent",expired:true);return }
      guard value.valid else { reading=nil;phase = .failed;status="Invalid lock reading · Control unavailable";return }
      reading=value;phase = .idle;status="Observed mock state · No command sent"
    } catch {
      guard epoch==ticket else { return }
      reading=nil;phase = .failed;status="Lock state unavailable · No command sent"
    }
  }
  func prepare() async {
    guard !busy,!Task.isCancelled else { return }
    let access=context(),created=uptime()
    guard allowed(access.generation,authenticated:true),ageValid(created) else {
      stop("Device authentication required · No command sent");return
    }
    let ticket=beginOperation(created:created);proposal=nil;phase = .reading;status="Checking mock lock · No command sent"
    defer { endOperation(ticket) }
    do {
      let value=try await provider.read()
      guard current(ticket,generation:access.generation,authenticated:true) else { if epoch==ticket { revoke() };return }
      guard ageValid(created) else { stop("Authorization expired · No command sent",expired:true);return }
      guard value.valid else { reading=nil;phase = .failed;status="Invalid lock reading · Control unavailable";return }
      reading=value
      guard value.canCommand,let locked=value.state.lockedValue else {
        phase = .failed;status=value.batteryFault ? "Battery fault · No command sent" : "Lock state is not controllable · No command sent";return
      }
      proposal=Proposal(id:UUID(),targetLocked:!locked,observed:value,generation:access.generation,createdUptime:created)
      phase = .approval;status="Confirm separately · No command sent"
    } catch {
      guard epoch==ticket else { return }
      reading=nil;phase = .failed;status="Lock state unavailable · No command sent"
    }
  }
  func confirm(id: UUID) async {
    guard !busy,phase == .approval,let request=proposal,request.id==id else { return }
    guard allowed(request.generation,authenticated:true) else { revoke();return }
    guard ageValid(request.createdUptime) else { stop("Confirmation expired · No command sent",expired:true);return }
    // Consume before the first suspension. Replaying the same approval cannot create a second write.
    proposal=nil;let ticket=beginOperation(created:request.createdUptime);phase = .checking;status="Checking current state · No command sent"
    defer { endOperation(ticket) }
    do {
      let latest=try await provider.read()
      guard current(ticket,generation:request.generation,authenticated:true) else { if epoch==ticket { revoke() };return }
      guard ageValid(request.createdUptime) else { stop("Authorization expired · No command sent",expired:true);return }
      guard latest.valid,latest.canCommand,latest==request.observed else {
        reading=latest.valid ? latest : nil;phase = .failed;status="Lock state changed · Review a fresh action. No command sent.";return
      }
      phase = .sending;writeAttempted=true;status="Sending mock command · Result not confirmed"
      try await provider.setLocked(request.targetLocked,expected:latest)
      guard current(ticket,generation:request.generation,authenticated:true),ageValid(request.createdUptime) else {
        if epoch==ticket { stop("",clearReading:true) };return
      }
      phase = .verifying;status="Waiting for state confirmation…"
      let result=try await provider.read()
      guard current(ticket,generation:request.generation,authenticated:true),ageValid(request.createdUptime) else {
        if epoch==ticket { stop("",clearReading:true) };return
      }
      reading=result.valid ? result : nil
      guard result.valid,!result.batteryFault,result.state.lockedValue==request.targetLocked else {
        phase = .unverified;status="Requested state not confirmed · No automatic retry";return
      }
      phase = .confirmed;status="Mock \(request.targetLocked ? "lock" : "unlock") confirmed by state read-back"
    } catch {
      guard epoch==ticket else { return }
      if writeAttempted {
        reading=nil;phase = .unverified;status="Outcome unverified · Refresh before another action. No automatic retry."
      } else {
        reading=nil;phase = .failed;status="Lock check failed · No command sent"
      }
    }
  }
}
