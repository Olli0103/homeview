import SwiftUI

#if os(iOS)
import UIKit

/// Scene-level snapshot cover for presentations above the SwiftUI root overlay.
/// It never becomes key or changes picker, input, authentication or model state.
struct NativeSnapshotShield: UIViewRepresentable {
  func makeUIView(context: Context) -> Anchor { Anchor() }
  func updateUIView(_ view: Anchor, context: Context) {}
  static func dismantleUIView(_ view: Anchor, coordinator: ()) { view.detach() }

  final class Anchor: UIView {
    private weak var observedScene: UIWindowScene?
    private var cover: UIWindow?

    override func didMoveToWindow() {
      super.didMoveToWindow()
      guard let scene=window?.windowScene else { detach();return }
      guard observedScene !== scene else { return }
      detach();observedScene=scene
      let center=NotificationCenter.default
      center.addObserver(self,selector:#selector(conceal(_:)),name:UIScene.willDeactivateNotification,object:scene)
      center.addObserver(self,selector:#selector(reveal(_:)),name:UIScene.didActivateNotification,object:scene)
      center.addObserver(self,selector:#selector(disconnect(_:)),name:UIScene.didDisconnectNotification,object:scene)
      if scene.activationState != .foregroundActive { showCover() }
    }

    @objc private func conceal(_ notification: Notification) { showCover() }
    @objc private func reveal(_ notification: Notification) { removeCover() }
    @objc private func disconnect(_ notification: Notification) { detach() }

    private func showCover() {
      guard cover == nil,let scene=observedScene else { return }
      // Only public levels of app-owned scene windows; not a claim about the
      // separate system keyboard layer, which remains an explicit test boundary.
      let frontLevel=max(UIWindow.Level.alert.rawValue,
        scene.windows.map { $0.windowLevel.rawValue }.max() ?? UIWindow.Level.normal.rawValue)
      let window=UIWindow(windowScene:scene)
      window.frame=scene.coordinateSpace.bounds
      window.windowLevel=UIWindow.Level(rawValue:frontLevel+1)
      window.backgroundColor = .black;window.isUserInteractionEnabled=false
      let controller=UIViewController();controller.view.backgroundColor = .black
      controller.view.accessibilityIdentifier="privacy.snapshot.native.shield"
      window.rootViewController=controller;cover=window
      window.isHidden=false
    }

    private func removeCover() {
      cover?.isHidden=true;cover?.rootViewController=nil;cover?.windowScene=nil;cover=nil
    }

    func detach() {
      NotificationCenter.default.removeObserver(self)
      removeCover();observedScene=nil
    }
  }
}
#endif
