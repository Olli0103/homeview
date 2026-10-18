import Foundation

enum ViewportNavigationAction: Equatable, Sendable {
  case home, assistant, controlCenter
  case face(Int)
}

/// Our gesture arbitration, not a reconstruction of Apple's recognizer rules.
/// Retains existing distances/edge regions but requires a dominant intent axis.
enum ViewportNavigationIntent {
  static func choose(startX: Double, startY: Double, dx: Double, dy: Double,
                     edge: Double, isFace: Bool) -> ViewportNavigationAction? {
    guard [startX,startY,dx,dy,edge].allSatisfy(\.isFinite), edge > 0,
          (0...edge).contains(startX), (0...edge).contains(startY) else { return nil }
    if abs(dy) > abs(dx) {
      if isFace, dy < -70, startY > edge*(1-16.0/600) { return .home }
      if dy > 70, startY < edge*0.12 {
        return startX > edge*0.74 ? .controlCenter : .assistant
      }
    } else if isFace, abs(dx) > abs(dy), abs(dx) > 80 {
      return .face(dx < 0 ? 1 : -1)
    }
    return nil
  }
}
