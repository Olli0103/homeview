#if os(visionOS)
import SwiftUI
import UIKit

/// Opt-in OS geometry driver for one owned synthetic simulator window.
/// It requests a real UIWindowScene update, never substitutes view geometry.
@MainActor @Observable private final class VisionWindowTestDriver {
  @ObservationIgnored weak var window:UIWindow?
  @ObservationIgnored var initial:CGSize?
  var report="unattached"
  var request="initial"
  var error="none"
  func attach(_ window:UIWindow?) {
    self.window=window
    if initial == nil,let window {initial=window.bounds.size}
    refresh()
  }
  func refresh() {
    guard let window,let scene=window.windowScene else {return}
    let w=window.bounds.size,s=scene.effectiveGeometry.coordinateSpace.bounds.size
    let value="request=\(request); window=\(Int(w.width))x\(Int(w.height)); scene=\(Int(s.width))x\(Int(s.height)); error=\(error)"
    if report != value {report=value}
  }
  func resize(_ name:String,_ size:CGSize?) {
    guard let scene=window?.windowScene,let size=size ?? initial else {return}
    request=name;error="none"
    scene.requestGeometryUpdate(.Vision(size:size)) { [weak self] failure in
      self?.error=String((failure as NSError).code);self?.refresh()
    }
    Task { @MainActor [weak self] in
      for _ in 0..<30 {
        try? await Task.sleep(for:.milliseconds(100))
        self?.refresh()
      }
    }
  }
}

@MainActor private struct VisionWindowTestAnchor:UIViewRepresentable {
  let driver:VisionWindowTestDriver
  final class Anchor:UIView {
    var driver:VisionWindowTestDriver?
    override func didMoveToWindow() {
      super.didMoveToWindow()
      Task { @MainActor [weak self] in self?.driver?.attach(self?.window) }
    }
    override func layoutSubviews() {
      super.layoutSubviews()
      Task { @MainActor [weak self] in self?.driver?.refresh() }
    }
  }
  func makeUIView(context:Context)->Anchor {
    let view=Anchor();view.driver=driver;view.isUserInteractionEnabled=false;return view
  }
  func updateUIView(_ view:Anchor,context:Context) {}
}

struct VisionWindowSystemTestModifier:ViewModifier {
  @State private var driver=VisionWindowTestDriver()
  private var allowed:Bool {
    let a=ProcessInfo.processInfo.arguments
    guard a.contains("--uitesting"),a.contains("--vision-window-system-test"),
      let i=a.firstIndex(of:"--persistence-test"),a.indices.contains(i+1),
      UUID(uuidString:a[i+1]) != nil else {return false}
    return true
  }
  func body(content:Content)->some View {
    if allowed {
      content.background(VisionWindowTestAnchor(driver:driver))
        .overlay(alignment:.topLeading) {
          VStack(alignment:.leading,spacing:2) {
            HStack {
              Button("Wide") {driver.resize("wide",CGSize(width:1000,height:650))}.accessibilityIdentifier("vision.window.wide")
              Button("Portrait") {driver.resize("portrait",CGSize(width:650,height:1000))}.accessibilityIdentifier("vision.window.portrait")
              Button("Compact") {driver.resize("compact",CGSize(width:500,height:650))}.accessibilityIdentifier("vision.window.compact")
              Button("Restore") {driver.resize("restore",nil)}.accessibilityIdentifier("vision.window.restore")
            }
            Text(driver.report).accessibilityIdentifier("vision.window.report")
          }.font(.system(size:10)).padding(4).background(.regularMaterial)
        }
    } else {content}
  }
}
#endif
