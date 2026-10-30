import SwiftUI

#if os(iOS)
import AVFoundation
import AVKit

private struct SystemAudioRoutePicker:UIViewRepresentable {
  func makeUIView(context:Context)->AVRoutePickerView {
    let view=AVRoutePickerView()
    view.prioritizesVideoDevices=false
    view.tintColor = .white
    view.activeTintColor = .systemBlue
    view.accessibilityLabel="Choose audio output"
    return view
  }
  func updateUIView(_ view:AVRoutePickerView,context:Context) {}
}
#endif

/// Sender controls only. No receiver, automatic route selection or audio start.
struct AudioRouteControls:View {
  private let synthetic=ProcessInfo.processInfo.arguments.contains("--uitesting")
  @State private var output=""
  @Environment(\.nativeCanvasScale) private var canvasScale
  var body:some View {
    HStack(spacing:12) {
      if synthetic {
        Image(systemName:"airplay.audio")
        Text("Audio routes are not queried in synthetic tests.")
          .accessibilityIdentifier("music.output.status")
      } else {
        #if os(iOS)
        SystemAudioRoutePicker().frame(width:44/max(0.01,canvasScale),height:44/max(0.01,canvasScale))
          .accessibilityIdentifier("music.output.choose")
        Text(output.isEmpty ? "Choose audio output":output)
          .accessibilityIdentifier("music.output.status")
          .task {readOutput()}
          .onReceive(NotificationCenter.default.publisher(for:AVAudioSession.routeChangeNotification)) {_ in readOutput()}
        #else
        Image(systemName:"airplay.audio")
        Text("Use system controls to choose audio output.")
          .accessibilityIdentifier("music.output.status")
        #endif
      }
    }.font(.system(size:16)).foregroundStyle(.white.opacity(0.8))
  }
  #if os(iOS)
  private func readOutput() {
    guard !synthetic else {return}
    let names=AVAudioSession.sharedInstance().currentRoute.outputs.map(\.portName)
    output=names.isEmpty ? "No audio output available":"Audio output: "+names.joined(separator:", ")
  }
  #endif
}
