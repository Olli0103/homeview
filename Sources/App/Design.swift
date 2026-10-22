import SwiftUI
#if os(iOS) || os(visionOS)
  import UIKit
#endif

private struct NativeCanvasScaleKey:EnvironmentKey { static let defaultValue:CGFloat=1 }
extension EnvironmentValues {
  /// The reference canvas transform, not the physical screen's pixel scale.
  var nativeCanvasScale:CGFloat {
    get {self[NativeCanvasScaleKey.self]}
    set {self[NativeCanvasScaleKey.self]=newValue}
  }
}

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
  // Opt-in for scaled screens that require a native-sized Close control.
  // Other callers retain the existing 48-point reference-canvas size.
  var closeSize:CGFloat = 48
  var body: some View {
    ZStack {
      HStack {
        RoundButton(
          symbol: "xmark", color: light ? .white.opacity(0.18) : .black.opacity(0.07),
          foreground: light ? .white : .black, size:closeSize, label: "Close"
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
  var minimumHeight: CGFloat = 0
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      Label(title, systemImage: symbol).font(.system(size: 21, weight: .medium)).frame(
        maxWidth: .infinity
      ).padding(.vertical, 17).frame(minHeight: minimumHeight)
        .background(tint, in: Capsule()).foregroundStyle(textColor)
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
// Resolve only glass material backgrounds into a shared composition layer.
// Foreground controls never enter the material container.
struct HomeGlassAnchor {
  let bounds:Anchor<CGRect>
  let material:AnyView
}
struct HomeGlassAnchors:PreferenceKey {
  static var defaultValue:[HomeGlassAnchor] { [] }
  static func reduce(value:inout [HomeGlassAnchor],nextValue:()->[HomeGlassAnchor]) {
    value.append(contentsOf:nextValue())
  }
}
private struct HostedHomeGlassKey:EnvironmentKey { static let defaultValue=false }
extension EnvironmentValues {
  var hostedHomeGlass:Bool {
    get { self[HostedHomeGlassKey.self] }
    set { self[HostedHomeGlassKey.self]=newValue }
  }
}
/// Public native lens, separate from the controls. visionOS and older Macs use
/// a material fallback; that fallback is not claimed to have the same optics.
struct HomeGlassSurface<Surface:InsettableShape>: View {
  let shape:Surface
  @Environment(\.hostedHomeGlass) private var hosted
  @Environment(AppModel.self) private var model
  @ViewBuilder var body: some View {
    if hosted {
      Color.clear.anchorPreference(key:HomeGlassAnchors.self,value:.bounds) { bounds in
        [HomeGlassAnchor(bounds:bounds,material:AnyView(nativeSurface))]
      }
    } else { nativeSurface }
  }
  @ViewBuilder private var nativeSurface: some View {
    if model.data.night {
      shape.fill(Color(white:0.055)).overlay { shape.strokeBorder(Color(white:0.25),lineWidth:0.8) }
    } else {
    #if os(visionOS)
    fallback
    #else
    if #available(macOS 26.0, *) { Color.clear.glassEffect(.clear,in:shape) }
    else { fallback }
    #endif
    }
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
  var embossedHands = false
  var hourReach = 0.56
  var minuteReach = 0.84
  var secondsReach = 0.99
  var lightEdgeInk = false
  var majorTickLength = 10.0
  var hollowHub = false
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
        let innerR = r - (i % 5 == 0 ? majorTickLength : 6.0)
        let inner = CGPoint(x: center.x + innerR * cos(a), y: center.y + innerR * sin(a))
        var p = Path()
        p.move(to: inner)
        p.addLine(to: outer)
        context.stroke(
          p, with: .color(tint.opacity(numbered ? 0.5 : 1)),
          style: StrokeStyle(lineWidth: numbered ? 1.8 : 4, lineCap: .round))
      }
      if numbered {
        var numeralContext=context
        if lightEdgeInk {
          numeralContext.addFilter(.shadow(color:.white.opacity(0.35),radius:0.65,x:0,y:0.2))
        }
        for n in 1...12 {
          let a = Double(n) * .pi / 6 - .pi / 2
          numeralContext.draw(
            Text("\(n)").font(.system(size: r * 0.24, weight: .medium)).foregroundStyle(tint),
            at: CGPoint(x: center.x + r * 0.77 * cos(a), y: center.y + r * 0.77 * sin(a)))
        }
      }
      let reading = ClockGeometry(date: date, timeZone: timeZone)
      let h = reading.hours
      let m = reading.minutes
      let s = reading.seconds
      let hands = handColor ?? tint
      let hub = max(3, r * 0.035)
      let hubHole = hub * 0.55
      var handContext = context
      if hollowHub {
        var clipping = Path(CGRect(origin:.zero,size:size))
        clipping.addEllipse(in:CGRect(x:center.x-hubHole,y:center.y-hubHole,
          width:hubHole*2,height:hubHole*2))
        handContext.clip(to:clipping,style:FillStyle(eoFill:true))
      }
      func hand(angle: Double, length: Double, width: Double, color: Color) {
        var bodyContext=handContext
        if lightEdgeInk {
          bodyContext.addFilter(.shadow(color:.white.opacity(0.35),radius:0.65,x:0,y:0.2))
        }
        var path = Path()
        path.move(to: CGPoint(x: center.x - 8 * cos(angle), y: center.y - 8 * sin(angle)))
        path.addLine(
          to: CGPoint(x: center.x + length * cos(angle), y: center.y + length * sin(angle)))
        let style=StrokeStyle(lineWidth:width,lineCap:.round)
        if embossedHands {
          // Fade's wide hand starts outside the hub, joined by a slender stem.
          // Keep other clock faces' existing full-width hands unchanged.
          let neck = r * 0.15
          var stem = Path()
          stem.move(to: center)
          stem.addLine(to: CGPoint(x: center.x + neck * cos(angle), y: center.y + neck * sin(angle)))
          bodyContext.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: width * 0.25, lineCap: .round))
          path = Path()
          path.move(to: CGPoint(x: center.x + neck * cos(angle), y: center.y + neck * sin(angle)))
          path.addLine(to: CGPoint(x: center.x + length * cos(angle), y: center.y + length * sin(angle)))
          if !lightEdgeInk {
            var shadow=handContext
            shadow.addFilter(.shadow(color:.black.opacity(0.28),radius:1.5,x:1.2,y:2))
            shadow.stroke(path,with:.color(color),style:style)
          }
          let perpendicular=CGPoint(x:-sin(angle)*width*0.5,y:cos(angle)*width*0.5)
          bodyContext.stroke(path,with:.linearGradient(
            Gradient(colors:[color.mix(with:.white,by:0.18),color,color.mix(with:.black,by:0.12)]),
            startPoint:CGPoint(x:center.x-perpendicular.x,y:center.y-perpendicular.y),
            endPoint:CGPoint(x:center.x+perpendicular.x,y:center.y+perpendicular.y)),style:style)
        } else {
          bodyContext.stroke(path,with:.color(color),style:style)
        }
      }
      hand(angle: h * .pi / 6 - .pi / 2, length: r * hourReach, width: r * 0.065, color: hands)
      hand(angle: m * .pi / 30 - .pi / 2, length: r * minuteReach, width: r * 0.055, color: hands)
      let second = secondsColor ?? (numbered ? .white : tint)
      let angle = s * .pi / 30 - .pi / 2
      var needle = Path()
      needle.move(
        to: CGPoint(x: center.x - r * 0.15 * cos(angle), y: center.y - r * 0.15 * sin(angle)))
      needle.addLine(
        to: CGPoint(x: center.x + r * secondsReach * cos(angle), y: center.y + r * secondsReach * sin(angle)))
      handContext.stroke(
        needle, with: .color(second),
        style: StrokeStyle(lineWidth: max(0.8, r * 0.009), lineCap: .round))
      if hollowHub {
        var ring = Path(ellipseIn:CGRect(x:center.x-hub,y:center.y-hub,
          width:hub*2,height:hub*2))
        ring.addEllipse(in:CGRect(x:center.x-hubHole,y:center.y-hubHole,
          width:hubHole*2,height:hubHole*2))
        context.fill(ring,with:.color(second),style:FillStyle(eoFill:true))
      } else {
        context.fill(
          Path(
            ellipseIn: CGRect(x: center.x - hub, y: center.y - hub, width: hub * 2, height: hub * 2)),
          with: .color(second))
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: center.x - hub * 0.55, y: center.y - hub * 0.55, width: hub * 1.1, height: hub * 1.1)
          ), with: .color(hands))
      }
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
  var minimumHitSide: CGFloat = 0
  var set: @MainActor @Sendable (Double) -> Void
  var body: some View {
    VStack(spacing: 12) {
      HStack {
        Text(label)
        Spacer()
        Text("\(Int(value))%").monospacedDigit()
          .accessibilityIdentifier("adjuster.value.\(label)")
      }
      HStack {
        RoundButton(symbol: "minus", size: max(48, minimumHitSide), label: "Decrease \(label)") {
          set(max(range.lowerBound, value - 10))
        }
        #if os(tvOS) || os(watchOS)
          ProgressView(value: value, total: range.upperBound)
        #else
          if minimumHitSide > 0 {
            #if os(iOS) || os(visionOS)
              MinimumHitSlider(value: value, range: range, label: label,
                minimumHeight: minimumHitSide, set: set)
                .frame(height: minimumHitSide)
            #else
              Slider(value: Binding(get: { value }, set: set), in: range)
                .accessibilityLabel(label).frame(minHeight: minimumHitSide)
            #endif
          } else {
            Slider(value: Binding(get: { value }, set: set), in: range).accessibilityLabel(label)
          }
        #endif
        RoundButton(symbol: "plus", size: max(48, minimumHitSide), label: "Increase \(label)") {
          set(min(range.upperBound, value + 10))
        }
      }
    }.font(.system(size: 22))
  }
}

#if os(iOS) || os(visionOS)
// A SwiftUI Slider's outer frame does not enlarge its underlying UISlider.
// Opt-in callers host the standard native control at the requested real height.
private struct MinimumHitSlider: UIViewRepresentable {
  var value: Double
  var range: ClosedRange<Double>
  var label: String
  var minimumHeight: CGFloat
  var set: @MainActor @Sendable (Double) -> Void
  func makeCoordinator() -> Coordinator { Coordinator(set: set) }
  func makeUIView(context: Context) -> UISlider {
    let slider = UISlider()
    slider.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
    return slider
  }
  func updateUIView(_ slider: UISlider, context: Context) {
    context.coordinator.set = set
    slider.minimumValue = Float(range.lowerBound)
    slider.maximumValue = Float(range.upperBound)
    slider.value = Float(value)
    slider.accessibilityLabel = label
    slider.accessibilityValue = "\(Int(value))%"
  }
  func sizeThatFits(_ proposal: ProposedViewSize, uiView: UISlider, context: Context) -> CGSize? {
    CGSize(width: proposal.width ?? max(0, uiView.intrinsicContentSize.width), height: minimumHeight)
  }
  @MainActor final class Coordinator: NSObject {
    var set: @MainActor @Sendable (Double) -> Void
    init(set: @escaping @MainActor @Sendable (Double) -> Void) { self.set = set }
    @objc func changed(_ slider: UISlider) { set(Double(slider.value)) }
  }
}
#endif

// Independent simple geometry: seven symmetric bars, not extracted contours.
struct IntercomMark: Shape {
  func path(in rect:CGRect) -> Path {
    let side=min(rect.width,rect.height),bar=side*0.065
    let heights:[CGFloat]=[0.44,0.79,0.97,1,0.97,0.79,0.44]
    var path=Path()
    for (index,fraction) in heights.enumerated() {
      let h=side*fraction
      let box=CGRect(x:rect.midX-side/2+CGFloat(index)*(side-bar)/6,
        y:rect.midY-h/2,width:bar,height:h)
      path.addRoundedRect(in:box,cornerSize:CGSize(width:bar/2,height:bar/2))
    }
    return path
  }
}
