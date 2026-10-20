import Foundation

enum PresenceDistanceBand: String, Equatable, Sendable { case near, far }
enum PresenceDecisionOrigin: String, Equatable, Sendable { case manual, synthetic }
enum PresenceDecisionCondition: String, Equatable, Sendable {
  case selected, waiting, tracking, unusable, stale
}

struct AnonymousDistanceObservation: Equatable, Sendable {
  var meters: Float
  var confidence: Float
}

/// Anonymous supplied observations, not an occupant count or a sensor adapter.
/// Capture/receipt time must share the owner's monotonic clock domain.
struct SyntheticPresenceFrame: Sendable {
  var sequence: UInt64
  var capturedAt: Double
  var detectedPeople: Int
  var distances: [AnonymousDistanceObservation]
  var normalizedMotion: SIMD2<Float> = .zero
}

struct AnonymousPresenceDecision: Equatable, Sendable {
  var band: PresenceDistanceBand
  var origin: PresenceDecisionOrigin
  var condition: PresenceDecisionCondition
  var flowImpulse: SIMD2<Float> = .zero
  var farthestSuppliedDistance: Float?
}

/// Own synthetic policy experiment. No capture, permission, discovery, identity,
/// authentication or AppModel integration. The app's manual mode is unchanged.
struct AnonymousPresencePolicy: Sendable {
  /// A source-lifetime fence, never a person/device identity or persisted token.
  struct SourceToken: Equatable, Sendable { fileprivate let nonce: UUID }
  private struct Candidate: Sendable {
    var band: PresenceDistanceBand
    var beganAt: Double
    var samples: Int
  }
  private(set) var manualBand: PresenceDistanceBand
  private(set) var decision: AnonymousPresenceDecision
  private var source: SourceToken?
  private var lastReceipt: Double?
  private var lastSequence: UInt64?
  private var lastCapture: Double?
  private var previousValidCapture: Double?
  private var freshAt: Double?
  private var stableBand: PresenceDistanceBand
  private var candidate: Candidate?
  private var motion = SIMD2<Float>.zero

  init(manualBand: PresenceDistanceBand = .near) {
    self.manualBand = manualBand
    stableBand = manualBand
    decision = .init(band: manualBand, origin: .manual, condition: .selected)
  }

  mutating func selectManual(_ band: PresenceDistanceBand) {
    manualBand = band
    source = nil
    lastReceipt = nil
    lastSequence = nil
    lastCapture = nil
    freshAt = nil
    fallback(.selected)
  }

  @discardableResult
  mutating func beginSyntheticSource(at time: Double) -> SourceToken? {
    guard validReceipt(time) else { return nil }
    let token = SourceToken(nonce: UUID())
    source = token
    lastReceipt = time
    lastSequence = nil
    lastCapture = nil
    freshAt = time
    fallback(.waiting)
    return token
  }

  /// False means rejected/ignored, never "no person present".
  @discardableResult
  mutating func receive(_ frame: SyntheticPresenceFrame, from token: SourceToken,
                        at time: Double) -> Bool {
    // Old sources/duplicates must not advance the current source's clock.
    guard source == token, validReceipt(time),
      lastSequence.map({ frame.sequence > $0 }) ?? true else { return false }
    if let lastCapture, frame.capturedAt.isFinite, frame.capturedAt >= 0,
      frame.capturedAt <= lastCapture { return false }
    lastReceipt = time
    lastSequence = frame.sequence
    guard frame.capturedAt.isFinite, frame.capturedAt >= 0, frame.capturedAt <= time,
      time - frame.capturedAt <= 0.5 else {
      fallback(.unusable)
      return false
    }
    lastCapture = frame.capturedAt
    guard (1...16).contains(frame.detectedPeople),
      frame.distances.count == frame.detectedPeople,
      frame.distances.allSatisfy({
        $0.meters.isFinite && (0.25...10).contains($0.meters)
          && $0.confidence.isFinite && (0.75...1).contains($0.confidence)
      }), frame.normalizedMotion.x.isFinite, frame.normalizedMotion.y.isFinite else {
      fallback(.unusable)
      return false
    }
    if let freshAt, time - freshAt >= 3 { fallback(.stale) }
    let gap = previousValidCapture.map { frame.capturedAt - $0 }
    if gap == nil || gap! > 0.5 {
      candidate = nil
      motion = .zero
    } else {
      let alpha = Float(1 - exp(-6 * min(0.25, gap!)))
      let bounded = SIMD2(min(1, max(-1, frame.normalizedMotion.x)),
                          min(1, max(-1, frame.normalizedMotion.y)))
      motion = motion * (1 - alpha) + bounded * alpha
    }
    previousValidCapture = frame.capturedAt
    freshAt = frame.capturedAt
    // Readability for the farthest SUPPLIED observation, not an inferred identity
    // or claim that occluded/out-of-view people have all been measured.
    let farthest = frame.distances.map(\.meters).max()!
    let target: PresenceDistanceBand? = farthest >= 2 ? .far : farthest <= 1.25 ? .near : nil
    if let target, target != stableBand {
      if candidate?.band == target {
        candidate!.samples = min(3, candidate!.samples + 1)
      } else {
        candidate = Candidate(band: target, beganAt: frame.capturedAt, samples: 1)
      }
      if let current = candidate, current.samples >= 3,
        frame.capturedAt - current.beganAt >= 1 {
        stableBand = target
        candidate = nil
      }
    } else {
      candidate = nil
    }
    decision = .init(band: stableBand, origin: .synthetic, condition: .tracking,
                     flowImpulse: motion, farthestSuppliedDistance: farthest)
    return true
  }

  mutating func tick(at time: Double) {
    guard source != nil, validReceipt(time) else { return }
    lastReceipt = time
    if let freshAt, time - freshAt >= 3 { fallback(.stale) }
  }

  private func validReceipt(_ time: Double) -> Bool {
    time.isFinite && time >= 0 && (lastReceipt.map { time >= $0 } ?? true)
  }
  private mutating func fallback(_ reason: PresenceDecisionCondition) {
    stableBand = manualBand
    previousValidCapture = nil
    candidate = nil
    motion = .zero
    decision = .init(band: manualBand, origin: .manual, condition: reason)
  }
}
