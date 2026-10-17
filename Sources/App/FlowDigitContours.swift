import SwiftUI

/// Original geometric stand-in. No embedded or extracted font outlines.
struct FlowDigitShape: Shape {
  let digit: Int
  let stencil: Bool
  func path(in rect: CGRect) -> Path {
    let segments = [[0,1,2,4,5,6],[2,5],[0,2,3,4,6],[0,2,3,5,6],
                    [1,2,3,5],[0,1,3,5,6],[0,1,3,4,5,6],[0,2,5],
                    [0,1,2,3,4,5,6],[0,1,2,3,5,6]]
    guard segments.indices.contains(digit) else { return Path() }
    let t: CGFloat = stencil ? 0.12 : 0.19
    let gap: CGFloat = stencil ? 0.055 : 0.025
    let bars: [CGRect] = [
      .init(x: t, y: 0, width: 1-2*t, height: t),
      .init(x: 0, y: t+gap, width: t, height: 0.5-t-2*gap),
      .init(x: 1-t, y: t+gap, width: t, height: 0.5-t-2*gap),
      .init(x: t, y: 0.5-t/2, width: 1-2*t, height: t),
      .init(x: 0, y: 0.5+t/2+gap, width: t, height: 0.5-1.5*t-2*gap),
      .init(x: 1-t, y: 0.5+t/2+gap, width: t, height: 0.5-1.5*t-2*gap),
      .init(x: t, y: 1-t, width: 1-2*t, height: t)]
    var result = Path()
    for i in segments[digit] {
      let b = bars[i]
      let target = CGRect(x: rect.minX+b.minX*rect.width,
                          y: rect.minY+b.minY*rect.height,
                          width: b.width*rect.width, height: b.height*rect.height)
      result.addRoundedRect(in: target, cornerSize: .init(width: 4, height: 4))
    }
    return result
  }
}
