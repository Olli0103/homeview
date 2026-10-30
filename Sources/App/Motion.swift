import SwiftUI

/// Motion follows app activity and Reduce Motion. Screenshot fixtures stay still.
struct MotionTimeline<Content: View>: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.scenePhase) private var scenePhase
  @State private var epoch = Date()
  var content: (Double) -> Content
  private var paused: Bool {
    let args = ProcessInfo.processInfo.arguments
    return reduceMotion || scenePhase != .active || args.contains("--reduce-motion")
      || args.contains("--uitesting") && !args.contains("--animation-test")
  }
  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 20, paused: paused)) { timeline in
      content(paused ? 0 : max(0, timeline.date.timeIntervalSince(epoch)))
    }
  }
}
struct GlassPressStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  func makeBody(configuration: Configuration) -> some View {
    configuration.label.scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
      .opacity(configuration.isPressed ? 0.82 : 1)
      .animation(
        reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.8),
        value: configuration.isPressed)
  }
}
/// Low-resolution fluid field rendered using public CoreGraphics and SwiftUI.
@MainActor private final class FlowFrames {
  let session=FlowComputeSession()
  private var lastTime:Double?
  private var imageRevision:UInt64?
  private var image:CGImage?
  func activate() { session.activate() }
  func deactivate() { session.deactivate();lastTime=nil }
  func request(time:Double,impulse:SIMD2<Float>) {
    let dt=lastTime.map { max(0,min(1.0/15,time-$0)) } ?? 1.0/20
    if session.request(time:Float(time),delta:Float(dt),impulse:impulse) {lastTime=time}
  }
  var currentImage:CGImage? {
    if imageRevision != session.revision || image == nil {
      let simulation=session.simulation
      let bytes:[UInt8]=simulation.dye.flatMap { color in
        [color.x,color.y,color.z,1].map {UInt8(min(255,max(0,$0*255)))}
      }
      let provider=CGDataProvider(data:Data(bytes) as CFData)!
      image=CGImage(width:simulation.side,height:simulation.side,bitsPerComponent:8,
        bitsPerPixel:32,bytesPerRow:simulation.side*4,space:CGColorSpaceCreateDeviceRGB(),
        bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue),
        provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent)
      imageRevision=session.revision
    }
    return image
  }
}
private struct FlowFrameRequest:Hashable {
  let time:Double
  let impulse:SIMD2<Float>
  let active:Bool
}

struct FlowArtwork: View {
  @Environment(\.scenePhase) private var scenePhase
  let date: Date
  let timeZone: TimeZone
  var far: Bool
  var typeface = 0
  var showBackground = true
  var highContrastNight = false
  var palette = 0
  @State private var frames = FlowFrames()
  @State private var impulse = SIMD2<Float>.zero
  var body: some View {
    GeometryReader { geometry in
      if highContrastNight {
        ZStack { Color.black; numerals(at: 0).foregroundStyle(.white) }
      } else {
      MotionTimeline { t in
        let frame = frames.currentImage
        let request=FlowFrameRequest(time:t,impulse:impulse,active:frames.session.active)
        return ZStack {
          Color.black
          if let frame {
            if showBackground && !drawsMaskFixture {
              fluidImage(frame)
            }
            if drawsMaskFixture {
              numerals(at: t).foregroundStyle(.white)
            } else if usesNativeGlass {
              numerals(at: t, nativeGlass: true)
            } else {
              // Own layer fallback also retains colored numerals when the
              // visible background is switched off.
              numerals(at: t).foregroundStyle(.black.opacity(showBackground ? 0.10 : 0))
                .blur(radius: 2).offset(x: 1, y: 2)
              numerals(at: t).foregroundStyle(.white)
                .blur(radius: 4)
                .layerEffect(
                  ShaderLibrary.flowGlyphMaterial(
                    .image(Image(decorative: frame, scale: 1)),
                    .float2(Float(geometry.size.width), Float(geometry.size.height))),
                  maxSampleOffset: CGSize(width: 28, height: 28))
            }
          }
        }.task(id:request) {
          if request.active { frames.request(time:request.time,impulse:request.impulse) }
        }
      }
      }
    }.clipped().modifier(FlowPaletteTreatment(index:palette,disabled:highContrastNight || drawsMaskFixture))
      .contentShape(Rectangle())
      #if !os(tvOS)
        .gesture(
          DragGesture(minimumDistance: 3).onChanged { value in
            guard !highContrastNight else { return }
            impulse = SIMD2(
              Float(value.translation.width / 300), Float(value.translation.height / 300))
          }.onEnded { _ in impulse = .zero })
      #endif
      .onChange(of:scenePhase,initial:true) { _,phase in
        if phase == .active && !highContrastNight {frames.activate()} else {frames.deactivate()}
      }
      .onChange(of:highContrastNight) { _,night in
        if scenePhase == .active && !night {frames.activate()} else {frames.deactivate()}
      }
      .onDisappear {frames.deactivate()}
      .accessibilityLabel("Flow clock")
      .accessibilityValue(displayedTime)
      .overlay {
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
          Text("active=\(frames.session.active);revision=\(frames.session.revision);pending=\(frames.session.isWorking);fallback=\(frames.session.usingCPUFallback)")
            .accessibilityValue("active=\(frames.session.active);revision=\(frames.session.revision);pending=\(frames.session.isWorking);fallback=\(frames.session.usingCPUFallback)")
            .font(.system(size:1)).foregroundStyle(.clear).allowsHitTesting(false)
            .accessibilityIdentifier("flow.compute.test")
        }
      }
  }
  private func fluidImage(_ frame: CGImage) -> some View {
    Image(decorative: frame, scale: 1).resizable().interpolation(.high)
  }
  // Test-only render controls isolate material motion from glyph morphing.
  private var fixedGlyphsFixture: Bool {
    let args=ProcessInfo.processInfo.arguments
    return args.contains("--uitesting") && args.contains("--flow-fixed-glyphs")
  }
  private var drawsMaskFixture: Bool {
    let args=ProcessInfo.processInfo.arguments
    return args.contains("--uitesting") && args.contains("--flow-mask")
  }
  private var usesNativeGlass: Bool {
    // The inline variant is ordinary public runtime text, not a bundled or
    // extracted font outline. Its alpha is treated by our existing material.
    if typeface == 2 {return false}
    #if os(visionOS)
      return false
    #else
      if #available(macOS 26.0, *) { return showBackground }
      return false
    #endif
  }
  @ViewBuilder private func nativeGlyph(_ shape: FlowDigitShape) -> some View {
    #if os(visionOS)
      shape.fill(.clear)
    #else
      if #available(macOS 26.0, *) { Color.clear.glassEffect(.clear,in:shape) }
      else { shape.fill(.clear) }
    #endif
  }
  private func displayedDigits()->[Int] {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let hour = calendar.component(.hour, from: date)
    let minute = calendar.component(.minute, from: date)
    let twelveHour = !ProcessInfo.processInfo.arguments.contains("--reference-clock")
      && (DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current)?.contains("a") ?? false)
    return FlowTypography.digits(hour: hour, minute: minute, twelveHour: twelveHour)
  }
  private var displayedTime:String {
    let digits=displayedDigits()
    return String(format:"%d%d:%d%d",digits[0],digits[1],digits[2],digits[3])
  }
  @ViewBuilder private func numerals(at time: Double, nativeGlass: Bool = false) -> some View {
    let digits=displayedDigits()
    let axes = FlowTypography.animated(at: fixedGlyphsFixture ? 0 : time)
    if typeface == 2 {
      Text(String(format:"%d%d:%d%d",digits[0],digits[1],digits[2],digits[3]))
        .font(.system(size:240,weight:.semibold,design:.rounded)).monospacedDigit().tracking(-6)
        .lineLimit(1).minimumScaleFactor(0.5).padding(.horizontal,34)
        .scaleEffect(x:1,y:1.6).frame(maxWidth:.infinity,maxHeight:.infinity)
        .accessibilityLabel("Flow time")
        .accessibilityValue(String(format:"%d%d:%d%d",digits[0],digits[1],digits[2],digits[3]))
    } else {
    VStack(spacing: 30) {
      numeralRow(Array(digits.prefix(2)), axes: axes, nativeGlass: nativeGlass)
      numeralRow(Array(digits.suffix(2)), axes: axes, nativeGlass: nativeGlass)
    }.padding(.horizontal, far ? 36 : 44).padding(.vertical, 34)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Flow time")
      .accessibilityValue(String(format: "%d%d:%d%d", digits[0], digits[1], digits[2], digits[3]))
    }
  }
  private func numeralRow(_ digits: [Int], axes: FlowTypography, nativeGlass: Bool) -> some View {
    GeometryReader { geometry in
      let scale = min(geometry.size.width / axes.pairWidth, geometry.size.height)
      HStack(spacing: axes.tracking * scale) {
        ForEach(0..<2) { i in
          let shape=FlowDigitShape(digit: digits[i], stencil: typeface == 0, typography: axes)
          Group {
            if nativeGlass { nativeGlyph(shape) }
            else { shape }
          }.frame(width: axes.advance * scale, height: scale)
        }
      }.frame(width: geometry.size.width, height: geometry.size.height)
    }
  }
}
