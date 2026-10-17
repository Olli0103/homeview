import Foundation

/// CPU adaptation of the recovered Warlock fluid kernels. Own grid, forcing and palette.
/// Not Apple's complete renderer: device constants, original pass ordering and glyph material remain separate.
struct FlowSimulation: Sendable {
  let side: Int
  private(set) var velocity: [SIMD2<Float>]
  private(set) var dye: [SIMD3<Float>]
  init(side: Int = 40) {
    let n = max(8, min(128, side))
    self.side = n
    velocity = .init(repeating: .zero, count: self.side * self.side)
    dye = (0..<n * n).map { i in
      let x = Float(i % n) / Float(n - 1)
      let y = Float(i / n) / Float(n - 1)
      let blend = (sin(x * 7 + y * 5) + 1) * 0.5
      return SIMD3(0.08 + 0.82 * blend, 0.22 + 0.48 * (1 - blend), 0.95 - 0.2 * y)
    }
  }
  private func index(_ x: Int, _ y: Int) -> Int {
    min(side - 1, max(0, y)) * side + min(side - 1, max(0, x))
  }
  private func sample<T: SIMD>(_ field: [T], _ x: Float, _ y: Float) -> T
  where T.Scalar == Float {
    let px = min(Float(side - 1), max(0, x))
    let py = min(Float(side - 1), max(0, y))
    let ix = Int(px)
    let iy = Int(py)
    let fx = px - Float(ix)
    let fy = py - Float(iy)
    return (field[index(ix, iy)] * (1 - fx) + field[index(ix + 1, iy)] * fx) * (1 - fy)
      + (field[index(ix, iy + 1)] * (1 - fx) + field[index(ix + 1, iy + 1)] * fx) * fy
  }
  static func divergence(_ field: [SIMD2<Float>], side: Int) -> [Float] {
    precondition(side >= 2 && field.count == side * side)
    func at(_ x: Int, _ y: Int) -> SIMD2<Float> {
      field[min(side - 1, max(0, y)) * side + min(side - 1, max(0, x))]
    }
    return (0..<field.count).map { i in
      let x = i % side
      let y = i / side
      return 0.5 * (at(x + 1, y).x - at(x - 1, y).x + at(x, y + 1).y - at(x, y - 1).y)
    }
  }
  static func pressure(
    for divergence: [Float], side: Int, iterations: Int = 24, boundaries: Bool = false
  ) -> [Float] {
    precondition(side >= 2 && divergence.count == side * side)
    var p = [Float](repeating: 0, count: divergence.count)
    var next = p
    func index(_ x: Int, _ y: Int) -> Int {
      min(side - 1, max(0, y)) * side + min(side - 1, max(0, x))
    }
    for _ in 0..<max(0, iterations) {
      for y in 0..<side {
        for x in 0..<side {
          let i = y * side + x
          // fluidSimJacobiPressure: alpha=-1, reciprocal beta=1/4.
          next[i] =
            (p[index(x - 1, y)] + p[index(x + 1, y)]
              + p[index(x, y - 1)] + p[index(x, y + 1)] - divergence[i]) * 0.25
        }
      }
      if boundaries { next = Self.pressureBoundary(next, side: side) }
      swap(&p, &next)
    }
    return p
  }
  static func subtractGradient(_ p: [Float], from field: [SIMD2<Float>], side: Int) -> [SIMD2<
    Float
  >] {
    precondition(side >= 2 && p.count == side * side && field.count == p.count)
    func at(_ x: Int, _ y: Int) -> Float {
      p[min(side - 1, max(0, y)) * side + min(side - 1, max(0, x))]
    }
    return field.indices.map { i in
      let x = i % side
      let y = i / side
      // fluidSimGradient AIR: w - 0.5 * (right-left, bottom-top).
      return field[i] - SIMD2(at(x + 1, y) - at(x - 1, y), at(x, y + 1) - at(x, y - 1)) * 0.5
    }
  }
  /// fluidSimVorticity: 0.5 * (right.y - left.y - bottom.x + top.x).
  /// Float arithmetic here, rather than the source shader's half intermediates.
  static func vorticity(_ field: [SIMD2<Float>], side: Int) -> [Float] {
    precondition(side >= 2 && field.count == side * side)
    func at(_ x: Int, _ y: Int) -> SIMD2<Float> {
      field[min(side - 1, max(0, y)) * side + min(side - 1, max(0, x))]
    }
    return field.indices.map { i in
      let x = i % side
      let y = i / side
      return 0.5 * (at(x + 1, y).y - at(x - 1, y).y - at(x, y + 1).x + at(x, y - 1).x)
    }
  }
  /// Recovered confinement uses (dY|curl|, -dX|curl|) normalized before curl * strength * dt.
  static func confine(
    _ field: [SIMD2<Float>], curl: [Float], side: Int,
    strength: Float, delta: Float
  ) -> [SIMD2<Float>] {
    precondition(side >= 2 && field.count == side * side && curl.count == field.count)
    guard strength.isFinite, delta.isFinite, delta > 0, strength > 0 else { return field }
    func at(_ x: Int, _ y: Int) -> Float {
      abs(curl[min(side - 1, max(0, y)) * side + min(side - 1, max(0, x))])
    }
    return field.indices.map { i in
      let x = i % side
      let y = i / side
      let gradient = SIMD2(at(x, y + 1) - at(x, y - 1), at(x + 1, y) - at(x - 1, y)) * 0.5
      let normal = gradient / (sqrt(gradient.x * gradient.x + gradient.y * gradient.y) + 0.0001)
      return field[i] + SIMD2(normal.x, -normal.y) * curl[i] * strength * delta
    }
  }
  /// Own rectangular descriptor field for the recovered boundary-offset/sign operation.
  /// Nonzero normal offset reflects that component; corners use the blocked-cell case.
  static func velocityBoundary(_ field: [SIMD2<Float>], side: Int) -> [SIMD2<Float>] {
    precondition(side >= 3 && field.count == side * side)
    var result = field
    for y in 0..<side {
      for x in 0..<side {
        let edgeX = x == 0 || x == side - 1
        let edgeY = y == 0 || y == side - 1
        guard edgeX || edgeY else { continue }
        let i = y * side + x
        if edgeX && edgeY {
          result[i] = .zero
          continue
        }
        let nx = min(side - 2, max(1, x))
        let ny = min(side - 2, max(1, y))
        let value = field[ny * side + nx]
        result[i] = SIMD2(edgeX ? -value.x : value.x, edgeY ? -value.y : value.y)
      }
    }
    return result
  }
  /// fluidSimBoundaryPressure copies the neighboring sample without a velocity sign flip.
  static func pressureBoundary(_ field: [Float], side: Int) -> [Float] {
    precondition(side >= 3 && field.count == side * side)
    var result = field
    for y in 0..<side {
      for x in 0..<side where x == 0 || y == 0 || x == side - 1 || y == side - 1 {
        result[y * side + x] = field[min(side - 2, max(1, y)) * side + min(side - 2, max(1, x))]
      }
    }
    return result
  }
  mutating func step(time: Float, delta: Float, impulse: SIMD2<Float> = .zero) {
    guard time.isFinite, delta.isFinite, impulse.x.isFinite, impulse.y.isFinite else { return }
    let dt = min(1.0 / 15, max(0, delta))
    guard dt > 0 else { return }
    // The moving dye source is our adaptation, not a recovered Apple trajectory.
    let boundedImpulse = SIMD2(min(2, max(-2, impulse.x)), min(2, max(-2, impulse.y)))
    let center = SIMD2<Float>(0.5 + sin(time * 0.43) * 0.23, 0.5 + cos(time * 0.37) * 0.23)
    for y in 0..<side {
      for x in 0..<side {
        let i = index(x, y)
        let pt = SIMD2(Float(x), Float(y)) / Float(side - 1)
        let d = pt - center
        let weight = exp(-(d.x * d.x + d.y * d.y) * 28)
        let force = SIMD2(-d.y, d.x) * 60 + boundedImpulse * 25
        velocity[i] = velocity[i] * 0.993 + force * (weight * dt)
      }
    }
    velocity = Self.velocityBoundary(velocity, side: side)
    let old = velocity
    for y in 0..<side {
      for x in 0..<side {
        let i = index(x, y)
        let back = SIMD2(Float(x), Float(y)) - old[i] * dt
        velocity[i] = sample(old, back.x, back.y)
      }
    }
    velocity = Self.velocityBoundary(velocity, side: side)
    // Strength and sequence are our adaptation, not recovered device constants.
    velocity = Self.confine(
      velocity, curl: Self.vorticity(velocity, side: side),
      side: side, strength: 1.8, delta: dt)
    velocity = Self.velocityBoundary(velocity, side: side)
    let div = Self.divergence(velocity, side: side)
    velocity = Self.subtractGradient(
      Self.pressure(for: div, side: side, iterations: 16, boundaries: true), from: velocity,
      side: side)
    velocity = Self.velocityBoundary(velocity, side: side)
    // Semi-Lagrangian dye advection, same sampling direction as responsiveArtAdvectColorDyeNode.
    let oldDye = dye
    let colors: [SIMD3<Float>] = [
      SIMD3(0.02, 0.8, 1), SIMD3(0.98, 0.08, 0.75), SIMD3(0.15, 0.15, 0.85),
    ]
    let locations = (0..<3).map { source in
      let phase = time * 0.22 + Float(source) * 2.0944
      return SIMD2<Float>(0.5 + sin(phase) * 0.36, 0.5 + cos(phase * 0.8) * 0.36)
    }
    for y in 0..<side {
      for x in 0..<side {
        let i = index(x, y)
        let back = SIMD2(Float(x), Float(y)) - velocity[i] * dt * 5
        var color = sample(oldDye, back.x, back.y)
        // Continuous dye injection keeps semi-Lagrangian diffusion from flattening the field.
        // Palette and source tracks are our own, not recovered Apple parameters.
        let point = SIMD2(Float(x), Float(y)) / Float(side - 1)
        for source in 0..<3 {
          let distance = point - locations[source]
          let amount = min(
            1, exp(-(distance.x * distance.x + distance.y * distance.y) * 35) * dt * 4)
          color = color * (1 - amount) + colors[source] * amount
        }
        dye[i] = color
      }
    }
  }
}
