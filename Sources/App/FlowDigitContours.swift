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
    let cuts = digit == 1 ? [0.50, 0.70] : digit == 2 ? [0.45, 0.70] : [0.30, 0.75]
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
