import Foundation

/// Original palette and time mapping. Clockwise turns start at the top of the dial.
enum ConicGradientModel {
  struct Stop: Equatable, Sendable {
    let location: Double
    let color: SIMD3<Double>
  }
  static let fadeStops = [
    Stop(location: 0, color: .init(0.812, 0.699, 0.688)),
    Stop(location: 0.25, color: .init(0.753, 0.644, 0.634)),
    Stop(location: 0.5, color: .init(0.812, 0.699, 0.688)),
    Stop(location: 0.75, color: .init(0.872, 0.749, 0.737)),
    Stop(location: 1, color: .init(0.812, 0.699, 0.688)),
  ]
  static func wrap(_ turns: Double) -> Double {
    guard turns.isFinite else { return 0 }
    return turns - floor(turns)
  }
  static func phase(minutes: Double, reducedMotion: Bool) -> Double {
    reducedMotion ? 0 : wrap(minutes / 60)
  }
  static func turn(x: Double, y: Double) -> Double {
    guard x.isFinite, y.isFinite, x != 0 || y != 0 else { return 0 }
    return wrap(atan2(x, -y) / (2 * .pi))
  }
  static func sample(x: Double, y: Double, phase: Double) -> SIMD3<Double> {
    let location = wrap(turn(x: x, y: y) - wrap(phase))
    for index in 1..<fadeStops.count {
      let a = fadeStops[index-1], b = fadeStops[index]
      if location <= b.location {
        let t = (location-a.location)/(b.location-a.location)
        return a.color * (1-t) + b.color * t
      }
    }
    return fadeStops[0].color
  }
}
