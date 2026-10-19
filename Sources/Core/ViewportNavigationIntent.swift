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
    choose(startX:startX,startY:startY,dx:dx,dy:dy,width:edge,height:edge,isFace:isFace)
  }
  static func choose(startX: Double, startY: Double, dx: Double, dy: Double,
                     width: Double, height: Double, isFace: Bool) -> ViewportNavigationAction? {
    guard [startX,startY,dx,dy,width,height].allSatisfy(\.isFinite), width > 0,height > 0,
          (0...width).contains(startX), (0...height).contains(startY) else { return nil }
    if abs(dy) > abs(dx) {
      if isFace, dy < -70, startY > height*(1-16.0/600) { return .home }
      if dy > 70, startY < height*0.12 {
        return startX > width*0.74 ? .controlCenter : .assistant
      }
    } else if isFace, abs(dx) > abs(dy), abs(dx) > 80 {
      return .face(dx < 0 ? 1 : -1)
    }
    return nil
  }
}
