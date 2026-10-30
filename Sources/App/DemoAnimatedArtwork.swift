import AVFoundation
import Combine
import SwiftUI

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// The catalog has no animated transport. Only our fixed, silent demo video is
/// rendered here; paused/restricted states keep the existing static cover.
struct DemoAnimatedArtwork: View {
  let playing: Bool
  @Environment(\.scenePhase) private var phase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityPlayAnimatedImages) private var autoplay
  @State private var lowPower=ProcessInfo.processInfo.isLowPowerModeEnabled
  @State private var thermal=ProcessInfo.processInfo.thermalState
  private var active: Bool {
    let args=ProcessInfo.processInfo.arguments,test=args.contains("--uitesting")
    return ArtworkMotionPolicy.allows(playing:playing,foreground:phase == .active,
      reduceMotion:reduceMotion || args.contains("--reduce-motion") || test && !args.contains("--animation-test"),
      autoplay:autoplay && !(test && args.contains("--artwork-test-no-autoplay")),
      lowPower:lowPower || test && args.contains("--artwork-test-low-power"),
      thermalRestricted:thermal == .serious || thermal == .critical || test && args.contains("--artwork-test-hot"))
  }
  var body: some View {
    ZStack {
      DemoAlbumCover()
      if active {
        ArtworkVideoSurface().accessibilityHidden(true)
        GeometryReader { geometry in
          let edge=min(geometry.size.width,geometry.size.height)
          VStack {
            Spacer()
            Text("DEMO").font(.system(size:edge*0.12,weight:.bold))
              .tracking(edge*0.025).padding(.bottom,edge*0.09)
          }.frame(width:geometry.size.width,height:geometry.size.height)
            .foregroundStyle(.white).accessibilityHidden(true)
        }
      }
    }
    .onReceive(NotificationCenter.default.publisher(for:.NSProcessInfoPowerStateDidChange)
      .receive(on:RunLoop.main)) { _ in lowPower=ProcessInfo.processInfo.isLowPowerModeEnabled }
    .onReceive(NotificationCenter.default.publisher(for:ProcessInfo.thermalStateDidChangeNotification)
      .receive(on:RunLoop.main)) { _ in thermal=ProcessInfo.processInfo.thermalState }
  }
}

/// One view-owned queue, a fixed bundle file, no network or persistent cache.
@MainActor private final class ArtworkVideoPlayback {
  let layer=AVPlayerLayer()
  private var player: AVQueuePlayer?
  private var looper: AVPlayerLooper?
  private var ready: NSKeyValueObservation?
  private var generation=0
  private var requested=false

  func start() {
    guard !requested,
      let url=Bundle.main.url(forResource:"demo-artwork",withExtension:"mp4"),url.isFileURL,
      let size=try? url.resourceValues(forKeys:[.fileSizeKey]).fileSize,
      size>0,size<=ArtworkMotionPolicy.maximumBundledBytes else { return }
    requested=true;generation+=1;let ticket=generation
    let queue=AVQueuePlayer();queue.isMuted=true
    #if !os(visionOS)
    queue.allowsExternalPlayback=false
    #endif
    queue.automaticallyWaitsToMinimizeStalling=false
    player=queue;layer.player=queue;layer.videoGravity = .resizeAspectFill;layer.isHidden=true
    looper=AVPlayerLooper(player:queue,templateItem:AVPlayerItem(url:url))
    ready=layer.observe(\.isReadyForDisplay,options:[.initial,.new]) { [weak self] _,_ in
      Task { @MainActor [weak self] in
        guard let self,self.requested,self.generation==ticket else { return }
        self.layer.isHidden = !self.layer.isReadyForDisplay
      }
    }
    queue.play()
  }
  func stop() {
    generation+=1;requested=false;layer.isHidden=true
    ready?.invalidate();ready=nil;player?.pause();looper?.disableLooping()
    looper=nil;player?.removeAllItems();layer.player=nil;player=nil
  }
}

#if os(macOS)
private struct ArtworkVideoSurface: NSViewRepresentable {
  final class Host: NSView {
    let playback=ArtworkVideoPlayback()
    override init(frame:NSRect) {
      super.init(frame:frame);wantsLayer=true;layer?.addSublayer(playback.layer)
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) is not used") }
    override func layout() { super.layout();playback.layer.frame=bounds }
  }
  func makeNSView(context:Context)->Host { Host(frame:.zero) }
  func updateNSView(_ view:Host,context:Context) { view.playback.start() }
  static func dismantleNSView(_ view:Host,coordinator:()) { view.playback.stop() }
}
#elseif canImport(UIKit) && !os(watchOS)
private struct ArtworkVideoSurface: UIViewRepresentable {
  final class Host: UIView {
    let playback=ArtworkVideoPlayback()
    override init(frame:CGRect) {
      super.init(frame:frame);isUserInteractionEnabled=false;layer.addSublayer(playback.layer)
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) is not used") }
    override func layoutSubviews() { super.layoutSubviews();playback.layer.frame=bounds }
  }
  func makeUIView(context:Context)->Host { Host(frame:.zero) }
  func updateUIView(_ view:Host,context:Context) { view.playback.start() }
  static func dismantleUIView(_ view:Host,coordinator:()) { view.playback.stop() }
}
#endif
