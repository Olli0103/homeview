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
private final class FlowFrames {
  var simulation = FlowSimulation()
  var lastTime = -1.0
  var image: CGImage?
  func frame(time: Double, impulse: SIMD2<Float>) -> CGImage? {
    if time != lastTime || image == nil {
      let dt = lastTime < 0 ? 1.0 / 20 : max(0, min(1.0 / 15, time - lastTime))
      simulation.step(time: Float(time), delta: Float(dt), impulse: impulse)
      lastTime = time
      let bytes: [UInt8] = simulation.dye.flatMap { color in
        [color.x, color.y, color.z, 1].map { UInt8(min(255, max(0, $0 * 255))) }
      }
      let provider = CGDataProvider(data: Data(bytes) as CFData)!
      image = CGImage(
        width: simulation.side, height: simulation.side, bitsPerComponent: 8,
        bitsPerPixel: 32, bytesPerRow: simulation.side * 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
        provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
    return image
  }
}
struct FlowArtwork: View {
  let date: Date
  let timeZone: TimeZone
  var far: Bool
  var typeface = 0
  var showBackground = true
  @State private var frames = FlowFrames()
  @State private var impulse = SIMD2<Float>.zero
  var body: some View {
    GeometryReader { geometry in
      MotionTimeline { t in
        let frame = frames.frame(time: t, impulse: impulse)
        return ZStack {
          Color.black
          if let frame {
            if showBackground {
              fluidImage(frame).saturation(0.82).brightness(-0.14)
            }
            // Independent layers: background, glyph shadow, refractive foreground material.
            numerals(at: t).foregroundStyle(.black.opacity(showBackground ? 0.28 : 0))
              .blur(radius: 4).offset(x: 3, y: 5)
            numerals(at: t).foregroundStyle(.white)
              .layerEffect(
                ShaderLibrary.flowGlyphMaterial(
                  .image(Image(decorative: frame, scale: 1)),
                  .float2(Float(geometry.size.width), Float(geometry.size.height))),
                maxSampleOffset: CGSize(width: 7, height: 7))
          }
        }
      }
    }.clipped().contentShape(Rectangle())
      #if !os(tvOS)
        .gesture(
          DragGesture(minimumDistance: 3).onChanged { value in
            impulse = SIMD2(
              Float(value.translation.width / 300), Float(value.translation.height / 300))
          }.onEnded { _ in impulse = .zero })
      #endif
      .accessibilityLabel("Flow clock")
  }
  private func fluidImage(_ frame: CGImage) -> some View {
    Image(decorative: frame, scale: 1).resizable().interpolation(.high)
  }
  private func numerals(at time: Double) -> some View {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let hour = calendar.component(.hour, from: date)
    let minute = calendar.component(.minute, from: date)
    let twelveHour = !ProcessInfo.processInfo.arguments.contains("--reference-clock")
      && (DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: .current)?.contains("a") ?? false)
    let digits = FlowTypography.digits(hour: hour, minute: minute, twelveHour: twelveHour)
    let axes = FlowTypography.animated(at: time)
    return VStack(spacing: 30) {
      numeralRow(Array(digits.prefix(2)), axes: axes)
      numeralRow(Array(digits.suffix(2)), axes: axes)
    }.padding(.horizontal, far ? 36 : 44).padding(.vertical, 34)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Flow time")
      .accessibilityValue(String(format: "%d%d:%d%d", digits[0], digits[1], digits[2], digits[3]))
  }
  private func numeralRow(_ digits: [Int], axes: FlowTypography) -> some View {
    GeometryReader { geometry in
      let scale = min(geometry.size.width / axes.pairWidth, geometry.size.height)
      HStack(spacing: axes.tracking * scale) {
        ForEach(0..<2) { i in
          FlowDigitShape(digit: digits[i], stencil: typeface == 0, typography: axes)
            .frame(width: axes.advance * scale, height: scale)
        }
      }.frame(width: geometry.size.width, height: geometry.size.height)
    }
  }
}
