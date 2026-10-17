import SwiftUI

/// Own cubic drawing, with shared ink metrics for both stencil and solid.
struct FlowDigitShape: Shape {
  let digit: Int
  let stencil: Bool
  var typography = FlowTypography()
  func path(in rect: CGRect) -> Path {
    let scale = min(rect.width / typography.advance, rect.height)
    let origin = CGPoint(x: rect.midX - typography.advance * scale / 2,
                         y: rect.midY - scale / 2)
    func point(_ p: SIMD2<Double>) -> CGPoint {
      let v = typography.point(p)
      return CGPoint(x: origin.x + v.x * scale, y: origin.y + v.y * scale)
    }
    let ink = CGRect(x: origin.x + 0.015 * scale,y: origin.y + 0.015 * scale,
      width: (typography.advance - 0.03) * scale,height: 0.97 * scale)
    if digit == 0 {
      let outer = Path(roundedRect: ink,cornerRadius: ink.width * 0.48)
      let counterWidth = max(0,ink.width - (2 * typography.stroke + 0.04) * scale)
      let counterHeight = max(0,ink.height - 2 * typography.stroke * scale)
      guard counterWidth > 0, counterHeight > 0 else { return outer }
      return outer.subtracting(Path(ellipseIn: CGRect(x: ink.midX - counterWidth / 2,
        y: ink.midY - counterHeight / 2,width: counterWidth,height: counterHeight)))
    }
    if stencil && digit == 1 {
      var pieces = Path(roundedRect: CGRect(x: ink.maxX - typography.stroke * scale,
        y: ink.minY,width: typography.stroke * scale,height: ink.height),
        cornerRadius: typography.stroke * scale / 2)
      let dot = min(typography.stroke * 0.84,typography.advance - typography.stroke - 0.075) * scale
      pieces.addEllipse(in: CGRect(x: ink.minX,y: origin.y + 0.14 * scale,width: dot,height: dot))
      return pieces
    }
    if stencil && digit == 9 {
      var pieces = Path(ellipseIn: CGRect(x: ink.minX,y: ink.minY,width: ink.width,height: 0.64 * scale))
      let stemX = origin.x + (typography.advance * 0.49 + 0.045) * scale
      pieces.addRoundedRect(in: CGRect(x: stemX,
        y: origin.y + 0.20 * scale,width: ink.maxX - stemX,height: 0.785 * scale),
        cornerSize: CGSize(width: typography.stroke * scale / 2,height: typography.stroke * scale / 2))
      let dot = min(0.28,typography.stroke * 0.84,typography.advance - typography.stroke - 0.075) * scale
      pieces.addEllipse(in: CGRect(x: ink.minX,y: ink.maxY - dot,width: dot,height: dot))
      let seam = Path(CGRect(x: origin.x + typography.advance * 0.49 * scale,
        y: origin.y,width: 0.045 * scale,height: scale))
      return pieces.subtracting(seam)
    }
    var line = Path()
    for segment in FlowTypography.skeleton(digit) {
      switch segment {
      case .move(let p): line.move(to: point(p))
      case .line(let p): line.addLine(to: point(p))
      case .curve(let a, let b, let c):
        line.addCurve(to: point(c), control1: point(a), control2: point(b))
      }
    }
    let solid = line.strokedPath(StrokeStyle(lineWidth: typography.stroke * scale,
      lineCap: .round, lineJoin: .round))
    guard stencil else { return solid }
    // Cut the united ink, not individual overlapping strokes: no dash slivers
    // at a curve junction or at the intersection of the four's two strokes.
    var bridges = Path()
    // UI47 shows an unbroken inflated zero, a detached shoulder on one, and
    // vertical separation in nine's bowl. Uniform horizontal dash cuts were
    // an unrelated stencil treatment and did not match the reference.
    if digit == 0 { return solid }
    if digit == 1 || digit == 9 {
      bridges.addRect(CGRect(x: origin.x + typography.advance * (digit == 1 ? 0.45 : 0.50) * scale,
        y: origin.y - 1,width: 0.045 * scale,height: (digit == 1 ? 1.02 : 0.55) * scale + 2))
      if digit == 9 {
        bridges.addRect(CGRect(x: rect.minX - 1,y: origin.y + 0.74 * scale,
          width: typography.advance * 0.52 * scale,height: 0.045 * scale))
      }
      return solid.subtracting(bridges)
    }
    let cuts = digit == 2 ? [0.45, 0.70] : [0.30, 0.75]
    for y in cuts {
      bridges.addRect(CGRect(x: rect.minX - 1, y: origin.y + (y - 0.02) * scale,
                            width: rect.width + 2, height: 0.04 * scale))
    }
    return solid.subtracting(bridges)
  }
}

/// Deterministic synthetic comparison surface, reachable only in UI-test mode.
struct FlowGlyphAtlas: View {
  private let args = ProcessInfo.processInfo.arguments
  var body: some View {
    let wide = args.contains("--flow-atlas-wide")
    let axes = FlowTypography(width: wide ? 1.06 : 0.9, weight: wide ? 1 : 0)
    VStack(spacing: 28) {
      ForEach(0..<2) { row in
        HStack(spacing: 20) {
          ForEach(0..<5) { col in
            FlowDigitShape(digit: row * 5 + col, stencil: args.contains("--flow-atlas-stencil"),
              typography: axes).frame(width: 82, height: 190)
              .accessibilityLabel("Digit \(row * 5 + col)")
          }
        }
      }
    }.foregroundStyle(.white).frame(maxWidth: .infinity, maxHeight: .infinity).background(.black)
  }
}
