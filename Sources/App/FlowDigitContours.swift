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
    if stencil && [0,1,9].contains(digit) {
      // UI47 independently shows the same observed ellipse/pill/dot forms
      // as UI09. Sharing our geometry does not assert a name for UI09.
      return AbstractDigitShape(digit:digit).path(in:ink)
    }
    if digit == 0 {
      let outer = Path(roundedRect: ink,cornerRadius: ink.width * 0.48)
      let counterWidth = max(0,ink.width - (2 * typography.stroke + 0.04) * scale)
      let counterHeight = max(0,ink.height - 2 * typography.stroke * scale)
      guard counterWidth > 0, counterHeight > 0 else { return outer }
      return outer.subtracting(Path(ellipseIn: CGRect(x: ink.midX - counterWidth / 2,
        y: ink.midY - counterHeight / 2,width: counterWidth,height: counterHeight)))
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
      lineCap: .round, lineJoin: .round)).normalized(eoFill:false)
    guard stencil else { return solid }
    // Cut the united ink, not individual overlapping strokes: no dash slivers
    // at a curve junction or at the intersection of the four's two strokes.
    var bridges = Path()
    // These remaining unobserved digits retain our own fallback cuts; they
    // are not asserted to be a recovered original stencil family.
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
