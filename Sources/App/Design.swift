import SwiftUI

extension Color {
  static let timerAccent = Color(red: 1, green: 145.0 / 255, blue: 47.0 / 255)
  static let mist = Color(red: 146.0 / 255, green: 171.0 / 255, blue: 177.0 / 255)
  static let lilac = Color(red: 0.77, green: 0.75, blue: 0.89)
  static let ink = Color(red: 0.08, green: 0.09, blue: 0.11)
  static let violetInk = Color(red: 0.51, green: 0.48, blue: 0.69)
}
struct RoundButton: View {
  let symbol: String
  var color: Color = .black.opacity(0.10)
  var foreground: Color = .primary
  var size: CGFloat = 48
  var label: String = ""
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(systemName: symbol).font(.system(size: size * 0.4, weight: .medium)).foregroundStyle(
        foreground
      ).frame(width: size, height: size).background(color, in: Circle())
    }
    .buttonStyle(GlassPressStyle()).accessibilityLabel(label.isEmpty ? symbol : label)
  }
}
struct AppHeader: View {
  @Environment(AppModel.self) private var model
  var title = ""
  var light = false
  var body: some View {
    ZStack {
      HStack {
        RoundButton(
          symbol: "xmark", color: light ? .white.opacity(0.18) : .black.opacity(0.07),
          foreground: light ? .white : .black, label: "Close"
        ) { model.route = .personal }.accessibilityIdentifier("close")
        Spacer()
        Text(model.clock, style: .time).font(.system(size: 22, weight: .medium))
          .environment(\.timeZone, model.displayTimeZone)
      }
      if !title.isEmpty {
        Text(title).font(.system(size: 23, weight: .semibold))
          .lineLimit(1).minimumScaleFactor(0.7).frame(maxWidth: 310)
          .allowsHitTesting(false)
      }
    }.foregroundStyle(light ? .white : .black).padding(.horizontal, 28).padding(.top, 24)
  }
}
struct Pill: View {
  var title: String
  var symbol: String
  var tint: Color = .black.opacity(0.08)
  var textColor: Color = .primary
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      Label(title, systemImage: symbol).font(.system(size: 21, weight: .medium)).frame(
        maxWidth: .infinity
      ).padding(.vertical, 17).background(tint, in: Capsule()).foregroundStyle(textColor)
    }.buttonStyle(.plain)
  }
}
struct Tile<Content: View>: View {
  var glass = false
  var active = false
  @ViewBuilder var content: Content
  private var fittedContent: some View {
    content.frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  @ViewBuilder
  var body: some View {
    if glass {
      fittedContent.background {
        HomeGlassSurface(shape:RoundedRectangle(cornerRadius:34))
          .allowsHitTesting(false).accessibilityHidden(true)
      }
    } else {
      fittedContent.background(active ? Color.lilac : Color(white: 0.9),
        in: RoundedRectangle(cornerRadius: 34))
    }
  }
}
/// Public native lens, separate from the controls. visionOS and older Macs use
/// a material fallback; that fallback is not claimed to have the same optics.
struct HomeGlassSurface<Surface:InsettableShape>: View {
  let shape:Surface
  @ViewBuilder var body: some View {
    #if os(visionOS)
    fallback
    #else
    if #available(macOS 26.0, *) { Color.clear.glassEffect(.clear,in:shape) }
    else { fallback }
    #endif
  }
  private var fallback: some View {
    shape.fill(.ultraThinMaterial).overlay { shape.strokeBorder(.white.opacity(0.45),lineWidth:0.8) }
  }
}
struct AnalogClock: View {
  @Environment(AppModel.self) private var model
  var date: Date
  var timeZone: TimeZone = .current
  var tint: Color = .black
  var numbered = true
  var handColor: Color? = nil
  var showTicks = true
  var secondsColor: Color? = nil
  var body: some View {
    MotionTimeline { _ in clock(date: model.referenceClock ? date : Date()) }
  }
  private func clock(date: Date) -> some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let r = min(size.width, size.height) * 0.46
      for i in 0..<60 where showTicks && (numbered || i % 5 == 0) {
        let a = Double(i) * .pi / 30 - .pi / 2
        let outer = CGPoint(x: center.x + r * cos(a), y: center.y + r * sin(a))
        let innerR = r - (i % 5 == 0 ? 10.0 : 6.0)
        let inner = CGPoint(x: center.x + innerR * cos(a), y: center.y + innerR * sin(a))
        var p = Path()
        p.move(to: inner)
        p.addLine(to: outer)
        context.stroke(
          p, with: .color(tint.opacity(numbered ? 0.5 : 1)),
          style: StrokeStyle(lineWidth: numbered ? 1.8 : 4, lineCap: .round))
      }
      if numbered {
        for n in 1...12 {
          let a = Double(n) * .pi / 6 - .pi / 2
          context.draw(
            Text("\(n)").font(.system(size: r * 0.24, weight: .medium)).foregroundStyle(tint),
            at: CGPoint(x: center.x + r * 0.77 * cos(a), y: center.y + r * 0.77 * sin(a)))
        }
      }
      let reading = ClockGeometry(date: date, timeZone: timeZone)
      let h = reading.hours
      let m = reading.minutes
      let s = reading.seconds
      let hands = handColor ?? tint
      func hand(angle: Double, length: Double, width: Double, color: Color) {
        var path = Path()
        path.move(to: CGPoint(x: center.x - 8 * cos(angle), y: center.y - 8 * sin(angle)))
        path.addLine(
          to: CGPoint(x: center.x + length * cos(angle), y: center.y + length * sin(angle)))
        context.stroke(
          path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
      }
      hand(angle: h * .pi / 6 - .pi / 2, length: r * 0.56, width: r * 0.065, color: hands)
      hand(angle: m * .pi / 30 - .pi / 2, length: r * 0.84, width: r * 0.055, color: hands)
      let second = secondsColor ?? (numbered ? .white : tint)
      let angle = s * .pi / 30 - .pi / 2
      var needle = Path()
      needle.move(
        to: CGPoint(x: center.x - r * 0.15 * cos(angle), y: center.y - r * 0.15 * sin(angle)))
      needle.addLine(
        to: CGPoint(x: center.x + r * 0.99 * cos(angle), y: center.y + r * 0.99 * sin(angle)))
      context.stroke(
        needle, with: .color(second),
        style: StrokeStyle(lineWidth: max(0.8, r * 0.009), lineCap: .round))
      let hub = max(3, r * 0.035)
      context.fill(
        Path(
          ellipseIn: CGRect(x: center.x - hub, y: center.y - hub, width: hub * 2, height: hub * 2)),
        with: .color(second))
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: center.x - hub * 0.55, y: center.y - hub * 0.55, width: hub * 1.1, height: hub * 1.1)
        ), with: .color(hands))
    }.accessibilityLabel("Analog clock")
  }
}
struct PrismBackground: View {
  var theme = 0
  var body: some View {
    GeometryReader { geometry in
      MotionTimeline { phase in
        Rectangle().fill(.white).colorEffect(ShaderLibrary.homePrismScene(
          .float2(Float(geometry.size.width),Float(geometry.size.height)),
          .float(Float(phase)),.float(Float(theme))))
      }
    }.allowsHitTesting(false).accessibilityHidden(true)
  }
}
struct ValueAdjuster: View {
  var value: Double
  var range: ClosedRange<Double> = 0...100
  var label: String
  var set: @MainActor @Sendable (Double) -> Void
  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text(label)
        Spacer()
        Text("\(Int(value))%").monospacedDigit()
      }
      HStack {
        RoundButton(symbol: "minus", label: "Decrease \(label)") {
          set(max(range.lowerBound, value - 10))
        }
        #if os(tvOS) || os(watchOS)
          ProgressView(value: value, total: range.upperBound)
        #else
          Slider(value: Binding(get: { value }, set: set), in: range).accessibilityLabel(label)
        #endif
        RoundButton(symbol: "plus", label: "Increase \(label)") {
          set(min(range.upperBound, value + 10))
        }
      }
    }.font(.system(size: 22))
  }
}
