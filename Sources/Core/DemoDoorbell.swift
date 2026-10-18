import Foundation
import Observation

/// Synthetic events only. This is not a HomeKit subscription or camera grant.
struct DemoDoorbellEvent: Equatable, Sendable {
  var id: UUID
  var cameraIndex: Int
  var occurredAt: Date
}
enum DemoDoorbellResult: Equatable {
  case shown, replaced, duplicate, expired, invalid, cameraUnavailable, callNotInterrupted
}

/// Presentation is independent of navigation: closing cannot restore a stale
/// personal route or reset a timer/cooking session.
@MainActor @Observable
final class DemoDoorbell {
  private(set) var current: DemoDoorbellEvent?
  private(set) var deadline: TimeInterval?
  private var seen: [UUID] = []
  private let lifetime: TimeInterval = 30

  @discardableResult
  func receive(_ event: DemoDoorbellEvent, now: Date, uptime: TimeInterval,
               cameraAvailable: Bool, callInProgress: Bool) -> DemoDoorbellResult {
    let age = now.timeIntervalSince(event.occurredAt)
    guard uptime.isFinite, now.timeIntervalSince1970.isFinite,
          event.occurredAt.timeIntervalSince1970.isFinite,
          (0..<4).contains(event.cameraIndex), age >= -5 else { return .invalid }
    guard age <= lifetime else { return .expired }
    guard !seen.contains(event.id) else { return .duplicate }
    seen.append(event.id)
    if seen.count > 64 { seen.removeFirst(seen.count - 64) }
    guard cameraAvailable else { return .cameraUnavailable }
    guard !callInProgress else { return .callNotInterrupted }
    let replacing = current != nil
    current = event
    // A nearly stale event must not get a fresh full display lifetime.
    deadline = uptime + max(0, lifetime - max(0, age))
    return replacing ? .replaced : .shown
  }

  func dismiss() { current = nil; deadline = nil }

  func reconcile(at uptime: TimeInterval, cameraAvailable: Bool, callInProgress: Bool) {
    guard current != nil else { return }
    guard uptime.isFinite, cameraAvailable, !callInProgress,
          let deadline, uptime < deadline else { dismiss(); return }
  }
}
