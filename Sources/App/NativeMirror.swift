import SwiftUI

#if canImport(AVFoundation) && (os(iOS) || os(macOS))
  import AVFoundation
  #if os(macOS)
    import AppKit
  #else
    import UIKit
  #endif

  private enum CaptureStart: Sendable {
    case started
    case failed(String)
  }
  /// Only this serial queue configures and starts/stops the session. UI only attaches its preview layer.
  private final class CaptureBox: @unchecked Sendable {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "org.example.homeview.camera")
    private var configured = false
    func start() async -> CaptureStart {
      await withCheckedContinuation { continuation in
        queue.async { [self] in
          do {
            if !configured {
              guard
                let device = AVCaptureDevice.default(
                  .builtInWideAngleCamera, for: .video, position: .front)
                  ?? AVCaptureDevice.default(for: .video)
              else {
                continuation.resume(returning: .failed("No camera is available."))
                return
              }
              let input = try AVCaptureDeviceInput(device: device)
              session.beginConfiguration()
              guard session.canAddInput(input) else {
                session.commitConfiguration()
                continuation.resume(returning: .failed("The camera input is unavailable."))
                return
              }
              session.addInput(input)
              session.sessionPreset = .high
              session.commitConfiguration()
              configured = true
            }
            session.startRunning()
            continuation.resume(
              returning: session.isRunning ? .started : .failed("Could not start the camera."))
          } catch { continuation.resume(returning: .failed("The camera could not be opened.")) }
        }
      }
    }
    func stop() { queue.async { [self] in if session.isRunning { session.stopRunning() } } }
  }
  @MainActor @Observable
  final class NativeMirrorController {
    private let capture = CaptureBox()
    var running = false
    var busy = false
    var status = "Mock camera"
    private var generation = 0
    private var captureWanted = false
    var session: AVCaptureSession { capture.session }
    func start() async {
      generation += 1
      let ticket = generation
      captureWanted = true
      busy = true
      let allowed = await AVCaptureDevice.requestAccess(for: .video)
      guard generation == ticket else { return }
      guard allowed else {
        captureWanted = false
        capture.stop()
        running = false
        status = "Camera permission was not granted."
        busy = false
        return
      }
      let result = await capture.start()
      guard generation == ticket else {
        // This box is shared by subsequent starts. Keep late cleanup only
        // while the latest intent is stopped; never stop a newer request.
        if !captureWanted { capture.stop() }
        return
      }
      busy = false
      switch result {
      case .started:
        running = true
        status = "Live camera"
      case .failed(let text):
        captureWanted = false
        capture.stop()
        running = false
        status = text
      }
    }
    func stop() {
      generation += 1
      captureWanted = false
      busy = false
      capture.stop()
      running = false
      status = "Mock camera"
    }
  }
  #if os(macOS)
    struct MirrorPreview: NSViewRepresentable {
      let controller: NativeMirrorController
      func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        let layer = AVCaptureVideoPreviewLayer(session: controller.session)
        layer.videoGravity = .resizeAspectFill
        view.layer = layer
        return view
      }
      func updateNSView(_ view: NSView, context: Context) {
        if let layer = view.layer as? AVCaptureVideoPreviewLayer, let connection = layer.connection,
          connection.isVideoMirroringSupported
        {
          connection.automaticallyAdjustsVideoMirroring = false
          connection.isVideoMirrored = true
        }
      }
    }
  #else
    private final class CameraPreviewHost: UIView {
      override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    }
    struct MirrorPreview: UIViewRepresentable {
      let controller: NativeMirrorController
      func makeUIView(context: Context) -> UIView {
        let view = CameraPreviewHost()
        let layer = view.layer as! AVCaptureVideoPreviewLayer
        layer.session = controller.session
        layer.videoGravity = .resizeAspectFill
        return view
      }
      func updateUIView(_ view: UIView, context: Context) {
        let layer = view.layer as! AVCaptureVideoPreviewLayer
        if let connection = layer.connection, connection.isVideoMirroringSupported {
          connection.automaticallyAdjustsVideoMirroring = false
          connection.isVideoMirrored = true
        }
      }
    }
  #endif
#endif

struct NativeMirrorView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.scenePhase) private var scenePhase
  #if canImport(AVFoundation) && (os(iOS) || os(macOS))
    @State private var camera: NativeMirrorController?
  #endif
  var body: some View {
    ZStack {
      Color(white: 0.13)
      #if canImport(AVFoundation) && (os(iOS) || os(macOS))
        if let camera, camera.running {
          MirrorPreview(controller: camera).scaleEffect(model.mirrorZoom)
        } else {
          mockPreview
        }
      #else
        mockPreview
      #endif
      VStack {
        AppHeader(title: "Mirror", light: true)
        Spacer()
        #if canImport(AVFoundation) && (os(iOS) || os(macOS))
          Text(camera?.status ?? "Mock camera").font(.system(size: 18)).padding(12).background(
            .black.opacity(0.5), in: Capsule()
          ).accessibilityIdentifier("mirror.mode")
          Button(camera?.running == true ? "Stop Camera" : "Use Camera") {
            if camera?.running == true {
              camera?.stop()
            } else {
              let c = camera ?? NativeMirrorController()
              camera = c
              Task { await c.start() }
            }
          }.font(.system(size: 18, weight: .medium)).disabled(camera?.busy == true)
            .accessibilityIdentifier("mirror.live")
        #else
          Text("Mock camera · Live capture is unavailable on this target").font(.system(size: 17))
            .accessibilityIdentifier("mirror.mode")
        #endif
        HStack {
          RoundButton(
            symbol: "minus.magnifyingglass", color: .white.opacity(0.2), foreground: .white,
            label: "Zoom out"
          ) { model.mirrorZoom = max(1, model.mirrorZoom - 0.25) }
          Spacer()
          RoundButton(
            symbol: "light.max", color: .white.opacity(0.2), foreground: .white,
            label: "Toggle ring light"
          ) { model.ringLight.toggle() }.accessibilityIdentifier("mirror.light").accessibilityValue(
            model.ringLight ? "On" : "Off")
          Spacer()
          RoundButton(
            symbol: "plus.magnifyingglass", color: .white.opacity(0.2), foreground: .white,
            label: "Zoom in"
          ) { model.mirrorZoom = min(2, model.mirrorZoom + 0.25) }.accessibilityIdentifier(
            "mirror.zoom"
          ).accessibilityValue(String(format: "%.2f", model.mirrorZoom))
        }.padding(35)
      }
      RoundedRectangle(cornerRadius: 60).stroke(
        .white.opacity(model.ringLight ? 0.95 : 0.05), lineWidth: 20
      ).allowsHitTesting(false)
    }.foregroundStyle(.white).buttonStyle(.plain)
      .onChange(of: scenePhase) { _, phase in
        #if canImport(AVFoundation) && (os(iOS) || os(macOS))
          if phase == .background { camera?.stop() }
        #endif
      }
      .onDisappear {
        #if canImport(AVFoundation) && (os(iOS) || os(macOS))
          camera?.stop()
          camera = nil
        #endif
      }
  }
  private var mockPreview: some View {
    Image(systemName: "person.crop.rectangle").font(.system(size: 180)).foregroundStyle(.gray)
      .scaleEffect(model.mirrorZoom)
  }
}
