import SwiftUI

struct FaceView: View {
  var selection: Face? = nil
  @Environment(AppModel.self) private var model
  var body: some View {
    Group {
      switch selection ?? model.data.face {
      case .home: HomeModularFace()
      case .homeClock: AlternateHomeFace()
      case .modular: ModularFace()
      case .watchModular, .infographModular, .modularDuo, .modularCompact:
        WatchModularFace(face: selection ?? model.data.face)
      case .photos: PhotoFace()
      case .weather: WeatherFace()
      case .calendar: CalendarFace()
      case .flow: FlowFace()
      case .fade: FadeFace()
      case .numerals: NumeralsFace()
      case .cameras: CameraGrid(isFace: true)
      }
    }.accessibilityElement(children: .contain).accessibilityIdentifier(
      "face.\((selection ?? model.data.face).id)")
  }
}
struct HomeModularFace: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    ZStack {
      PrismBackground(theme: model.data.theme)
      VStack(spacing: 10) {
        HStack(spacing: 10) {
          Tile(glass: true) {
            VStack(spacing: 0) {
              Button {
                model.route = .thermostat
              } label: {
                Text("\(model.data.home.temperature)").font(
                  .system(size: 164, weight: .medium, design: .rounded)
                ).frame(maxWidth: .infinity, maxHeight: .infinity)
                  .contentShape(Rectangle())
              }.accessibilityIdentifier("home.thermostat")
              HStack(alignment: .center) {
                RoundButton(
                  symbol: "chevron.down", color: .clear, foreground: .white, size: 62,
                  label: "Decrease temperature"
                ) { model.command(.temperature(model.data.home.temperature - 1)) }
                .accessibilityIdentifier("temperature.decrease")
                Spacer(minLength: 0)
                VStack(spacing: 2) {
                  Text("Thermostat").fontWeight(.semibold)
                  Text("Living Room").opacity(0.7)
                }.font(.system(size: 20))
                Spacer(minLength: 0)
                RoundButton(
                  symbol: "chevron.up", color: .clear, foreground: .white, size: 62,
                  label: "Increase temperature"
                ) { model.command(.temperature(model.data.home.temperature + 1)) }
                .accessibilityIdentifier("temperature.increase")
              }.padding(.bottom, 24).padding(.horizontal, 10)
            }
          }.frame(width: 383)
          VStack(spacing: 10) {
            AnalogClock(
              date: model.clock, timeZone: model.displayTimeZone, tint: .white, numbered: false
            ).background {
              HomeGlassSurface(shape:Circle()).allowsHitTesting(false).accessibilityHidden(true)
            }
            Button {
              model.command(.scene("Good Night"))
              model.banner("Good Night · Mock scene applied")
            } label: {
              Tile(glass: true) {
                VStack(spacing: 14) {
                  Image(systemName: "moon.stars.fill").font(.system(size: 44))
                  VStack(spacing: 2) {
                    Text("Good Night").fontWeight(.semibold)
                    Text("Scene").opacity(0.7)
                  }.font(.system(size: 20))
                }
              }
            }.accessibilityIdentifier("scene.goodnight")
          }
        }.frame(height: 383)
        HStack(spacing: 10) {
          homeTile("waveform", "Intercom", "Everywhere") { model.navigate(.intercom) }
          homeTile(
            model.data.home.locked ? "lock.fill" : "lock.open.fill", "Door Lock", "Front Door"
          ) { model.route = .lock }
          homeTile("lamp.ceiling.fill", "Lights", "Entryway") {
            model.command(.entryLight)
          }
          .accessibilityIdentifier("home.entrylight")
        }
      }.padding(10)
    }.foregroundStyle(.white).buttonStyle(.plain)
  }
  private func homeTile(
    _ icon: String, _ title: String, _ subtitle: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Tile(glass: true) {
        VStack(spacing: 16) {
          Image(systemName: icon).font(.system(size: 52, weight: .medium))
          VStack(spacing: 3) {
            Text(title).fontWeight(.semibold)
            Text(subtitle).opacity(0.65)
          }.font(.system(size: 20))
        }
      }
    }
  }
}
struct ModularFace: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 20) {
        modularWidget(model.data.complication(for: .modular, slot: Face.modular.slots[0]).rawValue)
        modularWidget(model.data.complication(for: .modular, slot: Face.modular.slots[1]).rawValue)
      }.frame(height: 270).offset(y: -5)
      HStack(alignment: .top, spacing: 20) {
        modularWidget(model.data.complication(for: .modular, slot: Face.modular.slots[2]).rawValue)
        modularWidget(model.data.complication(for: .modular, slot: Face.modular.slots[3]).rawValue)
      }.frame(height: 250).offset(y: 12)
    }.padding(40).frame(width: 600, height: 600).background(
      model.data.configuration(for: .modular).theme == 1 ? Color(red: 0.73, green: 0.76, blue: 0.63) : .mist
    ).foregroundStyle(.black)
  }
  @ViewBuilder func modularWidget(_ name: String) -> some View {
    switch name {
    case "Off":
      Color.clear.frame(maxWidth: .infinity).accessibilityLabel("Empty complication")
    case "Date":
      Button {
        model.navigate(.calendar)
      } label: {
        VStack(alignment: .leading, spacing: -2) {
          Text(
            "\(Text(model.dateLabel("EEE")+" ").foregroundStyle(.white))\(Text(model.dateLabel("MMM")).foregroundStyle(.black.opacity(0.75)))"
          )
          .font(.system(size: 52, weight: .semibold)).fixedSize().padding(.leading, 18)
          FaceDateNumber(value: model.dateLabel("d"), size: 208)
            .frame(width: 235, height: 190)
        }.frame(maxWidth: .infinity, alignment: .leading)
      }.buttonStyle(.plain)
    case "Clock":
      AnalogClock(date: model.clock, timeZone: model.displayTimeZone).frame(maxWidth: .infinity)
        .offset(x: 4, y: -7)
    case "Music":
      VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .top) {
          DemoAlbumCover().frame(width: 130, height: 130).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
          Spacer()
          Image(systemName: "music.note").foregroundStyle(.white).font(.system(size: 31))
        }
        Text(model.currentMusicTitle).font(.system(size: 20, weight: .medium)).lineLimit(1)
        Text(model.currentMusicArtist).font(.system(size: 21)).foregroundStyle(.black.opacity(0.7))
        Button {
          model.togglePlayback()
        } label: {
          Label(
            model.musicIsPlaying ? "Pause" : "Play",
            systemImage: model.musicIsPlaying ? "pause.fill" : "play.fill"
          ).font(.system(size: 23, weight: .medium)).padding(.horizontal, 20).padding(.vertical, 7)
            .background(.black.opacity(0.16), in: Capsule())
        }.buttonStyle(.plain).accessibilityIdentifier("music.play")
      }.frame(maxWidth: .infinity)
    case "Weather":
      Button {
        model.navigate(.weather)
      } label: {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 3) {
            Text(model.connections.weatherCity).font(
              .system(size: 27, weight: .semibold))
            Image(systemName: "location.fill").font(.system(size: 15))
          }.foregroundStyle(.white)
          Text(model.connections.weatherTemperature).font(
            .system(size: 122, weight: .medium, design: .rounded)
          ).tracking(-8)
          Image(systemName: model.connections.weatherSymbol).font(
            .system(size: 29))
          Text(model.connections.weatherCondition).font(.system(size: 23))
          Text(
            model.connections.weatherHighLow
          ).font(.system(size: 21))
        }.frame(maxWidth: .infinity, alignment: .leading)
      }.buttonStyle(.plain)
    case "Calendar":
      Button {
        model.navigate(.calendar)
      } label: {
        VStack(alignment: .leading, spacing: 12) {
          Text("TODAY").font(.system(size: 16, weight: .bold))
          if model.connections.enabled.contains(.calendar) {
            if model.connections.personalUnlocked {
              Text(model.connections.events.first?.title ?? "No events").font(
                .system(size: 29, weight: .semibold)
              ).lineLimit(2)
            } else {
              Text("Unlock calendar").font(.system(size: 29, weight: .semibold))
            }
          } else {
            Text("Family dinner").font(.system(size: 29, weight: .semibold))
            Text("6:00 PM · Home").font(.system(size: 20))
          }
        }.frame(maxWidth: .infinity)
      }.buttonStyle(.plain)
    default:
      VStack {
        Image(systemName: "timer").font(.system(size: 50))
        Text(model.data.timers.first?.display(at: model.now) ?? "No timers").font(
          .system(size: 36, design: .rounded))
      }.frame(maxWidth: .infinity)
    }
  }
}
struct FlowFace: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    if ProcessInfo.processInfo.arguments.contains("--uitesting"),
       ProcessInfo.processInfo.arguments.contains("--flow-glyph-atlas") {
      FlowGlyphAtlas()
    } else {
    FlowArtwork(date: model.clock, timeZone: model.displayTimeZone, far: model.data.far,
      typeface: model.data.configuration(for: .flow).flowTypeface,
      showBackground: model.data.configuration(for: .flow).flowBackground)
      .clipped().animation(.easeInOut(duration: 0.8), value: model.data.far)
    }
  }
}
struct FadeFace: View {
  @Environment(AppModel.self) private var model
  @Environment(\.accessibilityReduceMotion) private var reducedMotion
  private var motionDisabled: Bool {
    reducedMotion || ProcessInfo.processInfo.arguments.contains("--reduce-motion")
  }
  private func phase(_ minutes: Double) -> Double {
    let args = ProcessInfo.processInfo.arguments
    if !motionDisabled, args.contains("--uitesting"), let index = args.firstIndex(of: "--fade-test-phase"),
       args.indices.contains(index+1), let value = Double(args[index+1]), value.isFinite {
      return ConicGradientModel.wrap(value)
    }
    return ConicGradientModel.phase(minutes: minutes, reducedMotion: motionDisabled)
  }
  private let rose = Color(red: 0.82, green: 0.65, blue: 0.64)
  var body: some View {
    let reading = ClockGeometry(date: model.clock, timeZone: model.displayTimeZone)
    ZStack {
      AngularGradient(gradient: Gradient(stops: ConicGradientModel.fadeStops.map {
        .init(color: Color(red: $0.color.x, green: $0.color.y, blue: $0.color.z), location: $0.location)
      }), center: .center,
      angle: .degrees(phase(reading.minutes) * 360 - 90))
      ForEach(0..<12) { n in
        Text("\(n == 0 ? 12 : n)").font(.system(size: 94, weight: .ultraLight))
          .foregroundStyle(rose)
          .shadow(color: .black.opacity(0.8), radius: 0.6, x: 0, y: -1.2)
          .shadow(color: .white.opacity(0.8), radius: 0.5, x: 0.8, y: 1.3)
          .opacity(reading.fadeOpacity(hour: n)).accessibilityHidden(true)
          .offset(y: -233).rotationEffect(.degrees(Double(n) * 30))
      }
      AnalogClock(
        date: model.clock, timeZone: model.displayTimeZone,
        tint: Color(red: 94.0 / 255, green: 48.0 / 255, blue: 44.0 / 255), numbered: false,
        showTicks: false, secondsColor: Color(red: 1, green: 0.3, blue: 0.76)
      )
      .shadow(color: .black.opacity(0.3), radius: 2, x: 2, y: 3).padding(22)
    }.accessibilityLabel("Fade clock, \(model.dateLabel("h:mm"))")
  }
}
struct NumeralsFace: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    ZStack {
      Color(red: 62.0 / 255, green: 147.0 / 255, blue: 92.0 / 255)
      Group {
        Text("12").font(.system(size: 335, weight: .light)).tracking(0).position(
          x: 278, y: 152)
        Text("9").font(.system(size: 337, weight: .light)).position(x: 120, y: 302)
        Text("3").font(.system(size: 337, weight: .light)).position(x: 475, y: 302)
        Text("6").font(.system(size: 317, weight: .light)).position(x: 300, y: 442)
      }.foregroundStyle(.black).accessibilityHidden(true)
      AnalogClock(
        date: model.clock, timeZone: model.displayTimeZone, tint: .white, numbered: false,
        showTicks: false)
      Text(model.dateLabel("EEE d").uppercased()).font(.system(size: 29, weight: .medium))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading).padding(43)
    }.clipped()
  }
}
struct LandscapeArt: View {
  var body: some View {
    GeometryReader { g in
      ZStack {
        LinearGradient(
          colors: [
            Color(red: 0.55, green: 0.75, blue: 0.87), Color(red: 0.97, green: 0.79, blue: 0.68),
          ], startPoint: .top, endPoint: .bottom)
        Circle().fill(.yellow.opacity(0.65)).frame(width: 110, height: 110).position(
          x: g.size.width * 0.74, y: g.size.height * 0.3)
        Path { p in
          p.move(to: .init(x: 0, y: g.size.height * 0.8))
          p.addLine(to: .init(x: g.size.width * 0.45, y: g.size.height * 0.3))
          p.addLine(to: .init(x: g.size.width, y: g.size.height))
          p.addLine(to: .init(x: 0, y: g.size.height))
          p.closeSubpath()
        }.fill(Color(red: 0.29, green: 0.42, blue: 0.4))
        Path { p in
          p.move(to: .init(x: 0, y: g.size.height))
          p.addLine(to: .init(x: g.size.width * 0.78, y: g.size.height * 0.52))
          p.addLine(to: .init(x: g.size.width, y: g.size.height * 0.75))
          p.addLine(to: .init(x: g.size.width, y: g.size.height))
          p.closeSubpath()
        }.fill(Color(red: 0.18, green: 0.29, blue: 0.27))
      }
    }
  }
}
struct PhotoFace: View {
  @Environment(AppModel.self) private var model
  private func layer(_ bytes: Data) -> some View {
    let composition = model.photoComposition
    let width = 600 * composition.destination.width / composition.crop.width
    let height = 600 * composition.destination.height / composition.crop.height
    return ImportedPhoto(data: bytes).frame(width: width, height: height)
      .position(x: 600 * composition.destination.x + width * (0.5-composition.crop.x),
                y: 600 * composition.destination.y + height * (0.5-composition.crop.y))
  }
  var body: some View {
    ZStack(alignment: .top) {
      Color.black
      if let bytes = model.photoData {
        layer(bytes)
      } else {
        LandscapeArt()
      }
      Text(model.clock, style: .time).environment(\.timeZone, model.displayTimeZone).font(
        .system(size: 181, weight: .semibold, design: .rounded)
      ).tracking(-10).lineLimit(1).minimumScaleFactor(0.65).frame(width: 540, height: 200).foregroundStyle(
        Color(red: 1, green: 0.82, blue: 0.84)
      ).position(x: 300, y: 600 * model.photoComposition.clock.centerY)
        .accessibilityIdentifier("photo.clock").accessibilityValue(model.photoComposition.clock.rawValue)
      // Foreground path deliberately occludes the time, matching the depth composition.
      if model.photoData == nil {
        Path { p in
          p.move(to: .init(x: 0, y: 600))
          p.addLine(to: .init(x: 280, y: 170))
          p.addLine(to: .init(x: 460, y: 600))
          p.closeSubpath()
        }.fill(
          LinearGradient(
            colors: [
              Color(red: 0.36, green: 0.48, blue: 0.44), Color(red: 0.18, green: 0.29, blue: 0.27),
            ], startPoint: .top, endPoint: .bottom))
      }
      if model.photoComposition.depthEnabled, let foreground = model.photoForegroundData {
        layer(foreground).allowsHitTesting(false)
      }
      if ProcessInfo.processInfo.arguments.contains("--uitesting") {
        Text("clock=\(model.photoComposition.clock.rawValue);full=\(model.photoComposition.destination != .full);depth=\(model.photoComposition.depthEnabled)")
          .font(.system(size: 1)).foregroundStyle(.clear).allowsHitTesting(false)
          .accessibilityIdentifier("photo.layout.test")
      }
      VStack {
        Spacer()
        Text(model.photoData == nil ? "LANDSCAPE · DEMO ALBUM" : model.photoCaption).font(
          .system(size: 12, weight: .semibold)
        ).tracking(2)
          .foregroundStyle(.white.opacity(0.7)).padding(28).accessibilityIdentifier("photo.index")
      }
    }.clipped().onTapGesture { model.nextPhoto() }
  }
}
struct WeatherFace: View {
  @Environment(AppModel.self) private var model
  var inApp = false
  var body: some View {
    MotionTimeline { phase in
    VStack(alignment: .leading, spacing: inApp ? 14 : 18) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 2) {
          Label(
            model.connections.weatherCondition.replacingOccurrences(of:" · Demo",with:""),
            systemImage: model.connections.weatherSymbol)
          Text(
            model.connections.weatherHighLow)
        }.font(.system(size: 28, weight: .medium))
        Spacer(minLength: 0)
        Text(model.clock, style: .time).font(.system(size: 47, weight: .semibold))
          .environment(\.timeZone, model.displayTimeZone)
      }
      WeatherGlassTemperature(value:model.connections.weatherTemperature,
        size:inApp ? 170 : model.data.far ? 260:236,phase:phase,
        cover:Float(WeatherBackdrop.cloudCover(model.connections.weather,demo:model.connections.weatherDemo)),
        night:model.connections.weather?.isDay == false ? 1:0)
        .padding(.top,-40)
      Spacer(minLength: 0)
      if !model.data.far {
        HStack(alignment: .top, spacing: 8) {
          detail("sunset", model.connections.weatherDemo ? "7:32 PM" : model.connections.weather?.sunsetLabel ?? "—", "Sunset")
          detail(
            "wind", model.connections.weatherUnits.wind(model.connections.weatherDemo ? 7 : model.connections.weather?.wind),
            "Wind")
          detail(
            "humidity", humidity,
            "Humidity")
          detail("aqi.medium", model.connections.weatherDemo ? "21":"—", "AQI")
        }.padding(.bottom, inApp ? 44 : 4)
      }
    }.padding(inApp ? 30 : 45).foregroundStyle(.white)
      .shadow(color:.black.opacity(0.18),radius:1,x:0,y:1).background(WeatherBackdrop(
      reading: model.connections.weather, demo: model.connections.weatherDemo,phase:phase))
    .overlay(alignment: .bottomLeading) {
      VStack(alignment: .leading, spacing: 2) {
        Text(model.connections.weatherSource(at: model.now)).accessibilityIdentifier("weather.source")
        if inApp && !model.connections.weatherDemo {
          HStack {
            Text("Sunrise \(model.connections.weather?.sunLabel(model.connections.weather?.sunrise) ?? "—") · AQI not supplied")
            Link("Open-Meteo", destination: URL(string: "https://open-meteo.com/")!)
          }
        }
      }.font(.system(size: 11)).foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal,60).padding(.bottom,inApp ? 18 : 10)
    }.coordinateSpace(name:"weather-face").contentShape(Rectangle()).onTapGesture { model.navigate(.weather) }
    }
  }
  private var humidity: String {
    guard let value = WeatherReading.valid(model.connections.weatherDemo ? 76 : model.connections.weather?.humidity, in: 0...100) else { return "—" }
    return "\(Int(value.rounded()))%"
  }
  private func detail(_ s: String, _ value: String, _ label: String) -> some View {
    VStack(spacing: 3) {
      Image(systemName: s).font(.system(size: inApp ? 32 : 40, weight: .light)).frame(height: inApp ? 40 : 52)
      Text(value).font(.system(size: inApp ? 22 : 27, weight: .medium)).lineLimit(1).minimumScaleFactor(0.7)
        .accessibilityIdentifier("weather.detail."+label)
      Text(label).font(.system(size: inApp ? 21 : 27)).lineLimit(1).minimumScaleFactor(0.7)
    }.frame(maxWidth: .infinity)
  }
}
/// Native illustration, not an extracted Apple weather animation.
struct WeatherBackdrop: View {
  let reading: WeatherReading?
  let demo: Bool
  var phase: Double? = nil
  static func cloudCover(_ reading:WeatherReading?,demo:Bool) -> Double {
    if demo { return 0.70 }
    let cloudy=["Partly Cloudy","Overcast","Fog","Rain","Snow","Thunderstorms"].contains(reading?.condition ?? "")
    return (WeatherReading.valid(reading?.cloudCover,in:0...100) ?? (cloudy ? 60:0))/100
  }
  @ViewBuilder var body: some View {
    if let phase { sky(at:phase) } else { MotionTimeline { sky(at:$0) } }
  }
  private func sky(at time:Double) -> some View {
      ZStack {
        GeometryReader { geometry in
          let cover=Self.cloudCover(reading,demo:demo)
          // Sky palette is shared with the glass in WeatherClouds.metal.
          Rectangle().fill(.white)
            .colorEffect(ShaderLibrary.weatherCloudField(
              .float2(Float(geometry.size.width),Float(geometry.size.height)),
              .float(Float(time)),.float(Float(cover)),.float(reading?.isDay == false ? 1:0)))
        }.allowsHitTesting(false).accessibilityHidden(true)
        if reading?.condition == "Rain" || reading?.condition == "Thunderstorms" || reading?.condition == "Snow" {
          Canvas { context, size in
            let snow = reading?.condition == "Snow"
            for i in 0..<35 {
              let x = (Double(i) * 83.7).truncatingRemainder(dividingBy: max(1,size.width))
              let y = (Double(i) * 47 + time * (snow ? 18 : 95)).truncatingRemainder(dividingBy: max(1,size.height))
              context.fill(Path(ellipseIn: CGRect(x: x,y: y,width: snow ? 4 : 1.5,height: snow ? 4 : 13)),
                with: .color(.white.opacity(0.20)))
            }
          }.allowsHitTesting(false).accessibilityHidden(true)
        }
        if let temperature = reading?.temperature, temperature <= 32 {
          RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.22),lineWidth: 10)
            .blur(radius: 7).allowsHitTesting(false).accessibilityHidden(true)
        }
      }
  }
}
struct CalendarFace: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    let month = model.monthLayout
    ZStack {
      Color(white: 0.92)
      FaceDateNumber(value: model.dateLabel("d"), size: 460)
        .foregroundStyle(Color(red: 1, green: 0.3, blue: 0.3)).position(x: 274, y: 339)
        .accessibilityHidden(true)
      VStack(spacing: 22) {
        HStack {
          Text(model.dateLabel("MMMM yyyy"))
          Spacer()
          Text(model.clock, style: .time).environment(\.timeZone, model.displayTimeZone)
        }.font(.system(size: 37, weight: .medium)).foregroundStyle(
          Color(red: 1, green: 0.3, blue: 0.3))
        VStack(spacing: 14) {
          HStack(spacing: 0) {
            ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) {
              _, day in
              Text(day).font(.system(size: 38, weight: .semibold)).frame(maxWidth: .infinity).frame(
                height: 42)
            }
          }
          LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 11
          ) {
            ForEach(0..<42, id: \.self) { i in
              let current = month.day(at: i) != nil
              let selected = month.day(at: i) == month.selectedDay
              Text("\(month.displayDay(at: i))").font(.system(size: 37, weight: .medium))
                .frame(width: 60, height: 53)
                .background(
                  selected ? Color(red: 0, green: 0.16, blue: 0.36) : .clear, in: Circle()
                )
                .foregroundStyle(
                  selected
                    ? .white : Color(red: 0, green: 0.36, blue: 1).opacity(current ? 1 : 0.27)
                )
                .accessibilityIdentifier(
                  selected ? "calendar.face.selected" : "calendar.face.cell.\(i)")
            }
          }
        }.padding(.top, 12).foregroundStyle(Color(red: 0, green: 0.36, blue: 1))
      }.padding(.horizontal, 48).padding(.top, 43).padding(.bottom, 42).frame(
        maxHeight: .infinity, alignment: .top)
    }.onTapGesture { model.navigate(.calendar) }
  }
}
// The reference's flat-ended, slightly rounded date-one is not SF Rounded's
// semicircular stem or the system face's short glyph. Reconstructed as a native
// vector from the UI01 silhouette proportions; other dates stay native text.
private struct FaceDateNumber: View {
  let value: String
  let size: CGFloat
  var body: some View {
    Group {
      if value == "1" {
        DateOneGlyph().frame(width: size * 0.315, height: size * 0.72)
      } else {
        Text(value).font(.system(size: size, weight: .medium, design: .rounded))
          .lineLimit(1).minimumScaleFactor(0.55)
      }
    }.accessibilityLabel(value)
  }
}
private struct DateOneGlyph: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: 0.68, y: 0))
    p.addLine(to: CGPoint(x: 0.94, y: 0))
    p.addQuadCurve(to: CGPoint(x: 1, y: 0.025), control: CGPoint(x: 1, y: 0))
    p.addLine(to: CGPoint(x: 1, y: 0.975))
    p.addQuadCurve(to: CGPoint(x: 0.94, y: 1), control: CGPoint(x: 1, y: 1))
    p.addLine(to: CGPoint(x: 0.65, y: 1))
    p.addQuadCurve(to: CGPoint(x: 0.60, y: 0.975), control: CGPoint(x: 0.60, y: 1))
    p.addLine(to: CGPoint(x: 0.60, y: 0.19))
    p.addLine(to: CGPoint(x: 0.07, y: 0.35))
    p.addQuadCurve(to: CGPoint(x: 0, y: 0.33), control: CGPoint(x: 0, y: 0.37))
    p.addLine(to: CGPoint(x: 0, y: 0.235))
    p.addQuadCurve(to: CGPoint(x: 0.035, y: 0.205), control: CGPoint(x: 0, y: 0.215))
    p.addLine(to: CGPoint(x: 0.61, y: 0.02))
    p.addQuadCurve(to: CGPoint(x: 0.68, y: 0), control: CGPoint(x: 0.65, y: 0))
    p.closeSubpath()
    return p.applying(CGAffineTransform(scaleX: rect.width, y: rect.height))
      .offsetBy(dx: rect.minX, dy: rect.minY)
  }
}
