import Foundation

/// Stroke-safe own fallback metrics, not extracted Apple font outlines.
/// Observed UI47 0/1/9 use their separate geometric shapes. Unobserved fallback
/// counters must remain open instead of merging 2/3 or 5/8 at the heavy axis.
struct FlowTypography: Equatable, Sendable {
  let width: Double
  let weight: Double
  init(width: Double = 1, weight: Double = 0.5) {
    self.width = width.isFinite ? min(1.06, max(0.9, width)) : 1
    self.weight = weight.isFinite ? min(1, max(0, weight)) : 0.5
  }
  var stroke: Double { 0.20 + weight * 0.04 }
  var advance: Double { 0.83 * width }
  var tracking: Double { 0.075 }
  var pairWidth: Double { 2 * advance + tracking }
  // Constant ink box with a full half-stroke inset, independent of weight.
  var inset: Double { stroke / 2 + 0.015 }
  func point(_ p: SIMD2<Double>) -> SIMD2<Double> {
    SIMD2(inset + p.x * (advance - 2 * inset), inset + p.y * (1 - 2 * inset))
  }
  static func digits(hour: Int, minute: Int, twelveHour: Bool) -> [Int] {
    let h = ((hour % 24) + 24) % 24
    let display = twelveHour ? (h % 12 == 0 ? 12 : h % 12) : h
    let m = ((minute % 60) + 60) % 60
    return [display / 10, display % 10, m / 10, m % 10]
  }
  static func animated(at seconds: Double) -> Self {
    let t = seconds.isFinite ? seconds.truncatingRemainder(dividingBy: 240) : 0
    return Self(width: 0.98 + 0.08 * sin(t * .pi / 30),
                weight: 0.5 + 0.5 * sin(t * .pi / 24))
  }
  enum Segment: Equatable, Sendable {
    case move(SIMD2<Double>), line(SIMD2<Double>)
    case curve(SIMD2<Double>, SIMD2<Double>, SIMD2<Double>)
    var points: [SIMD2<Double>] {
      switch self {
      case .move(let p), .line(let p): [p]
      case .curve(let a, let b, let c): [a,b,c]
      }
    }
  }
  // Original cubic skeletons, normalized inside the stroke-safe ink box.
  static func skeleton(_ digit: Int) -> [Segment] {
    func p(_ x: Double, _ y: Double) -> SIMD2<Double> { SIMD2(x,y) }
    switch digit {
    case 0: return [.move(p(0.5,0)), .curve(p(1,0),p(1,0.2),p(1,0.5)),
      .curve(p(1,0.8),p(1,1),p(0.5,1)), .curve(p(0,1),p(0,0.8),p(0,0.5)),
      .curve(p(0,0.2),p(0,0),p(0.5,0))]
    // The visible reference has a rounded stem and detached shoulder in stencil,
    // not the serif-like full-width foot of the former generic numeral.
    case 1: return [.move(p(0,0.18)), .curve(p(0.25,0.18),p(0.65,0),p(0.8,0)),
      .line(p(0.8,1))]
    case 2: return [.move(p(0,0.18)), .curve(p(0.1,0),p(0.8,0),p(1,0.18)),
      .curve(p(1,0.45),p(0.2,0.6),p(0,1)), .line(p(1,1))]
    case 3: return [.move(p(0,0.07)), .curve(p(0.9,0),p(1,0.1),p(1,0.25)),
      .curve(p(1,0.4),p(0.8,0.48),p(0.4,0.48)),
      .curve(p(0.8,0.48),p(1,0.58),p(1,0.75)), .curve(p(1,1),p(0.4,1),p(0,0.93))]
    case 4: return [.move(p(0.75,1)), .line(p(0.75,0)), .line(p(0,0.65)), .line(p(1,0.65))]
    case 5: return [.move(p(1,0)), .line(p(0.05,0)), .line(p(0,0.47)),
      .curve(p(0.6,0.36),p(1,0.45),p(1,0.73)), .curve(p(1,1),p(0.4,1),p(0,0.92))]
    case 6: return [.move(p(0.9,0)), .curve(p(0.2,0),p(0,0.35),p(0,0.7)),
      .curve(p(0,1),p(1,1),p(1,0.72)), .curve(p(1,0.44),p(0.3,0.42),p(0,0.63))]
    case 7: return [.move(p(0,0)), .line(p(1,0)), .curve(p(0.6,0.4),p(0.45,0.72),p(0.4,1))]
    case 8: return [.move(p(0.5,0.48)), .curve(p(0,0.42),p(0,0),p(0.5,0)),
      .curve(p(1,0),p(1,0.42),p(0.5,0.48)), .curve(p(0,0.55),p(0,1),p(0.5,1)),
      .curve(p(1,1),p(1,0.55),p(0.5,0.48))]
    case 9: return [.move(p(0.1,1)), .curve(p(0.8,1),p(1,0.65),p(1,0.3)),
      .curve(p(1,0),p(0,0),p(0,0.28)), .curve(p(0,0.56),p(0.7,0.58),p(1,0.37))]
    default: return []
    }
  }
}
