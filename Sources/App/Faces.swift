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
      tileComposition
    }.foregroundStyle(.white).buttonStyle(.plain)
  }
  @ViewBuilder private var tileComposition: some View {
    #if os(visionOS)
    tiles
    #else
    if #available(macOS 26.0, *) {
      tiles.environment(\.hostedHomeGlass,true)
        .backgroundPreferenceValue(HomeGlassAnchors.self) { surfaces in
          GeometryReader { geometry in
            GlassEffectContainer(spacing:0) {
              ZStack(alignment:.topLeading) {
                ForEach(Array(surfaces.enumerated()),id:\.offset) { entry in
                  let rect=geometry[entry.element.bounds]
                  entry.element.material.frame(width:rect.width,height:rect.height)
                    .position(x:rect.midX,y:rect.midY)
                }
              }.frame(width:geometry.size.width,height:geometry.size.height)
            }
          }.allowsHitTesting(false).accessibilityHidden(true)
        }
    } else { tiles }
    #endif
  }
  // Independent symbol drawing; retain the 62-point layout and explicitly fill its hit area.
  private func temperatureArrow(symbol:String, offsetX:CGFloat, label:String,
    action:@escaping () -> Void) -> some View {
    Button(action:action) {
      Image(systemName:symbol).font(.system(size:62 * 0.4,weight:.medium))
        .foregroundStyle(.white).scaleEffect(1.5).offset(x:offsetX,y:-2.25)
        .frame(width:62,height:62).background(Color.clear,in:Circle()).contentShape(Rectangle())
    }.buttonStyle(GlassPressStyle()).accessibilityLabel(label)
  }
  private var tiles: some View {
      VStack(spacing: 10) {
        HStack(spacing: 10) {
          Tile(glass: true) {
            VStack(spacing: 0) {
              Button {
                model.route = .thermostat
              } label: {
                Text("\(model.data.home.temperature)").font(
                  .system(size: 164, weight: .medium, design: .rounded)
                ).kerning(-2.125).scaleEffect(x:0.967,y:1)
                  .offset(x:1,y:13.5).frame(maxWidth: .infinity, maxHeight: .infinity)
                  .contentShape(Rectangle())
              }.accessibilityIdentifier("home.thermostat")
              HStack(alignment: .center) {
                temperatureArrow(
                  symbol:"chevron.down", offsetX:15,
                  label:"Decrease temperature"
                ) { model.command(.temperature(model.data.home.temperature - 1)) }
                .accessibilityIdentifier("temperature.decrease")
                Spacer(minLength: 0)
                VStack(spacing: 2) {
                  Text("Thermostat").fontWeight(.semibold)
                  Text("Living Room").opacity(0.7)
                }.font(.system(size: 20))
                Spacer(minLength: 0)
                temperatureArrow(
                  symbol:"chevron.up", offsetX:-13.5,
                  label:"Increase temperature"
                ) { model.command(.temperature(model.data.home.temperature + 1)) }
                .accessibilityIdentifier("temperature.increase")
              }.padding(.bottom, 24).padding(.horizontal, 10)
            }
          }.frame(width: 383)
          VStack(spacing: 10) {
            AnalogClock(
              date: model.clock, timeZone: model.displayTimeZone, tint: .white, numbered: false,
              embossedHands:true, minuteReach:0.96, majorTickLength:18, hollowHub:true
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
  }
  private func homeTile(
    _ icon: String, _ title: String, _ subtitle: String, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Tile(glass: true) {
        VStack(spacing: 16) {
          if icon == "waveform" {
            Image(systemName: icon).font(.system(size: 52, weight: .medium)).hidden()
              .overlay {
                IntercomMark().frame(width:44,height:44).clipShape(Circle())
                  .shadow(color:.black.opacity(0.20),radius:0.65,x:0,y:0.6)
                  .offset(x:2,y:-3).accessibilityHidden(true)
              }
          } else {
            Image(systemName: icon).font(.system(size: 52, weight: .medium))
          }
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
            .shadow(color: .white.opacity(0.35), radius: 0.65, x: 0, y: 0.2)
            .frame(width: 235, height: 190)
        }.frame(maxWidth: .infinity, alignment: .leading)
      }.buttonStyle(.plain)
    case "Clock":
      AnalogClock(date: model.clock, timeZone: model.displayTimeZone,
        embossedHands:true,lightEdgeInk:true).frame(maxWidth: .infinity)
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
            Text(model.connections.weatherDemo ? "San Francisco" : model.connections.weatherCity).font(
              .system(size: 27, weight: .semibold))
              .accessibilityIdentifier("modular.weather.city")
            Image(systemName: "location.fill").font(.system(size: 15))
          }.foregroundStyle(.white).accessibilityElement(children:.contain)
            .accessibilityIdentifier("modular.weather.cityRow")
            .offset(y:2)
          Text(model.connections.weatherTemperature).font(
            .system(size: 122, weight: .medium)
          ).tracking(-8)
            .shadow(color: .white.opacity(0.35), radius: 0.65, x: 0, y: 0.2)
            .scaleEffect(125.0/122,anchor:.topLeading).offset(y:-22)
            .accessibilityIdentifier("modular.weather.temperature")
          Image(systemName: model.connections.weatherSymbol).font(
            .system(size: 29)).scaleEffect(24.0/29,anchor:.topLeading).offset(y:-18)
          Text(model.connections.weatherCondition).font(.system(size: 23))
            .offset(y:-27)
            .accessibilityIdentifier("modular.weather.condition")
          Text(
            model.connections.weatherHighLow
          ).font(.system(size: 21)).offset(y:-28).accessibilityIdentifier("modular.weather.highlow")
        }.frame(maxWidth: .infinity, alignment: .leading).offset(x:10)
      }.buttonStyle(.plain).accessibilityIdentifier("modular.weather.widget")
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
        Text("\(n == 0 ? 12 : n)").font(.system(size: 101, weight: .thin))
          .foregroundStyle(rose)
          .shadow(color: .black.opacity(0.8), radius: 0.6, x: 0, y: -1.2)
          .shadow(color: .white.opacity(0.8), radius: 0.5, x: 0.8, y: 1.3)
          .opacity(reading.fadeOpacity(hour: n)).accessibilityHidden(true)
          .offset(y: -239).rotationEffect(.degrees(Double(n) * 30))
      }
      AnalogClock(
        date: model.clock, timeZone: model.displayTimeZone,
        tint: Color(red: 94.0 / 255, green: 48.0 / 255, blue: 44.0 / 255), numbered: false,
        showTicks: false, secondsColor: Color(red: 1, green: 0.3, blue: 0.76),
        embossedHands:true,minuteReach:1.01,secondsReach:1.04
      )
      .padding(22)
    }.accessibilityLabel("Fade clock, \(model.dateLabel("h:mm"))")
  }
}
struct NumeralsFace: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    ZStack {
      Color(red: 62.0 / 255, green: 147.0 / 255, blue: 92.0 / 255)
      Group {
        Text("12").font(.system(size: 335, weight: .light, design: .rounded)).tracking(0).scaleEffect(x:0.88,y:1).position(
          x: 286, y: 152)
        Text("9").font(.system(size: 337, weight: .light, design: .rounded)).position(x: 120, y: 296)
        Text("3").font(.system(size: 337, weight: .light, design: .rounded)).position(x: 475, y: 296)
        Text("6").font(.system(size: 341, weight: .light, design: .rounded)).position(x: 300, y: 442)
      }.foregroundStyle(.black).accessibilityHidden(true)
      AnalogClock(
        date: model.clock, timeZone: model.displayTimeZone, tint: .white, numbered: false,
        showTicks: false, embossedHands:true, minuteReach:0.94,secondsReach:0.98)
        .overlay { Circle().fill(Color(red:62.0/255,green:147.0/255,blue:92.0/255)).frame(width:12,height:12).accessibilityHidden(true) }
      Text(model.dateLabel("EEE d").uppercased()).font(.system(size: 34, weight: .medium))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading).padding(.horizontal,43).padding(.bottom,34)
    }.clipped()
  }
}
struct LandscapeArt: View {
  var body: some View {
    GeometryReader { geometry in
      Image(DemoPhotoAssets.landscape).resizable().scaledToFill()
        .frame(width:geometry.size.width,height:geometry.size.height).clipped()
    }.accessibilityLabel("AI-generated demo landscape")
  }
}
struct PhotoFace: View {
  @Environment(AppModel.self) private var model
  private var unoccludedTestControl: Bool {
    let args=ProcessInfo.processInfo.arguments
    return args.contains("--uitesting") && args.contains("--photo-depth-unoccluded-control")
  }
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
      } else if model.hasPhotoSelection {
        Color.black
        VStack(spacing:20) {
          Image(systemName:"photo.on.rectangle").font(.system(size:72))
          Text(model.photoSelectionStatus).font(.system(size:21)).multilineTextAlignment(.center)
        }.foregroundStyle(.gray).frame(width:440).position(x:300,y:330)
          .accessibilityIdentifier("photo.album.empty")
      } else {
        LandscapeArt()
      }
      if model.photoData == nil && model.hasPhotoSelection {
        Text(model.dateLabel("hh mm")).font(.system(size:181,weight:.regular,design:.rounded))
          .tracking(-10).foregroundStyle(.white).frame(width:540,height:200)
          .position(x:300,y:600*model.photoComposition.clock.centerY)
          .accessibilityIdentifier("photo.clock").accessibilityValue(model.photoComposition.clock.rawValue)
      } else {
      PhotoGlassClock(time: model.dateLabel("hh mm"), spokenTime: model.dateLabel("h:mm"),
        bytes: model.photoData, composition: model.photoComposition)
        .position(x: 300, y: 600 * (model.photoComposition.clockRect.y + model.photoComposition.clockRect.height/2))
      }
      // Depth uses the selected image's real segmentation, not a fabricated
      // foreground triangle over the fallback landscape.
      if model.photoComposition.depthEnabled, !unoccludedTestControl,
         let foreground = model.photoForegroundData {
        layer(foreground).allowsHitTesting(false)
      }
      if ProcessInfo.processInfo.arguments.contains("--uitesting") {
        Text(verbatim:"height=\(model.photoComposition.clockRect.height);y=\(model.photoComposition.clockRect.y);coverage=\(model.photoComposition.coverage)")
          .font(.system(size:1)).foregroundStyle(.clear).allowsHitTesting(false)
          .accessibilityIdentifier("photo.clock.geometry.test")
        Text(verbatim:"digits=\(model.dateLabel("hh mm"));revision=\(model.photoInkRevision);ink=\(model.photoComposition.clockInkCoverage?.overall ?? -1);maxDigit=\(model.photoComposition.clockInkCoverage?.perDigit.max() ?? -1)")
          .font(.system(size:1)).foregroundStyle(.clear).allowsHitTesting(false)
          .accessibilityIdentifier("photo.clock.ink.test")
      }
      if ProcessInfo.processInfo.arguments.contains("--uitesting") {
        let assetIDs=model.data.albumDisplay?.cache.map(\.assetID) ?? []
        Text(verbatim:"clock=\(model.photoComposition.clock.rawValue);full=\(model.photoComposition.destination != .full);depth=\(model.photoComposition.depthEnabled);foreground=\(model.photoForegroundData != nil);finished=\(model.photoAnalysisFinished);diagnostic=\(model.photoAnalysisDiagnostic);regions=\(model.photoProtectedRegionCount);protected=\(Int((model.photoComposition.protectedCoverage*1000).rounded()));selection=\(model.data.photoSelection.rawValue);album=\(model.data.albumDisplay?.album.id ?? "none");assets=\(assetIDs.isEmpty ? "none":assetIDs.joined(separator:","));picture=\(model.photoData != nil)")
          .font(.system(size: 1)).foregroundStyle(.clear).allowsHitTesting(false)
          .accessibilityIdentifier("photo.layout.test")
      }
      VStack {
        Spacer()
        Text(model.photoData == nil && !model.hasPhotoSelection ? "LANDSCAPE · DEMO ALBUM" : model.photoCaption).font(
          .system(size: 12, weight: .semibold)
        ).tracking(2).lineLimit(1).minimumScaleFactor(0.6)
          .foregroundStyle(.white.opacity(0.7)).padding(28).accessibilityIdentifier("photo.index")
      }
      if ProcessInfo.processInfo.arguments.contains("--uitesting") &&
         ProcessInfo.processInfo.arguments.contains("--photo-glyph-atlas") {
        PhotoTallGlyphAtlas()
      }
      if ProcessInfo.processInfo.arguments.contains("--uitesting") &&
         ProcessInfo.processInfo.arguments.contains("--photo-ink-raster-control"),
         let image = model.photoInkControlImage {
        Image(decorative:image,scale:1).resizable().interpolation(.none)
          .frame(width:600,height:600)
      }
    }.coordinateSpace(name: "photo-face").clipped().onTapGesture { model.nextPhoto() }
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
        }.font(.system(size: 28, weight: .medium)).offset(y: inApp ? 0 : -3)
        Spacer(minLength: 0)
        Text(model.clock, style: .time).font(.system(size: inApp ? 47 : 48, weight: .semibold))
          .environment(\.timeZone, model.displayTimeZone)
          .offset(x: inApp ? 0 : -4, y: inApp ? 0 : -12)
          .accessibilityIdentifier("weather.face.clock")
      }
      WeatherGlassTemperature(value:model.connections.weatherTemperature,
        size:inApp ? 170 : model.data.far ? 260:241,phase:phase,
        cover:Float(WeatherBackdrop.cloudCover(model.connections.weather,demo:model.connections.weatherDemo)),
        night:model.connections.weather?.isDay == false ? 1:0)
        .padding(.top,-40)
      Spacer(minLength: 0)
      if !model.data.far {
        HStack(alignment: .top, spacing: 8) {
          detail("sunset.fill", model.connections.weatherDemo ? "7:32 PM" : model.connections.weather?.sunsetLabel ?? "—", "Sunset")
          detail(
            "wind", model.connections.weatherUnits.wind(model.connections.weatherDemo ? 7 : model.connections.weather?.wind),
            "Wind")
          detail(
            "humidity.fill", humidity,
            "Humidity")
          detail("aqi.low", model.connections.weatherDemo ? "21":"—", "AQI")
        }.padding(.bottom, inApp ? 44 : 4)
          .padding(.leading, inApp ? 0 : -17).padding(.trailing, inApp ? 0 : -33)
          .offset(y: inApp ? 0 : 5)
      }
    }.padding(inApp ? 30 : 45).foregroundStyle(.white)
      .shadow(color:.black.opacity(0.18),radius:1,x:0,y:1).background(WeatherBackdrop(
      reading: model.connections.weather, demo: model.connections.weatherDemo,phase:phase))
    .overlay {
      let cover=Float(WeatherBackdrop.cloudCover(model.connections.weather,demo:model.connections.weatherDemo))
      if cover>0 && model.connections.weather?.isDay != false {
        GeometryReader { geometry in
          Rectangle().fill(.white).colorEffect(ShaderLibrary.weatherDaylightSpur(
            .float2(Float(geometry.size.width),Float(geometry.size.height)),.float(cover)))
        }.allowsHitTesting(false).accessibilityHidden(true)
      }
    }
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
      Image(systemName: s).font(.system(size: inApp ? 32 : 44, weight: .light)).frame(height: inApp ? 40 : 72).accessibilityHidden(true)
      Text(value).font(.system(size: inApp ? 22 : 27, weight: .medium)).lineLimit(1).minimumScaleFactor(0.7)
        .accessibilityIdentifier("weather.detail."+label)
      Text(label).font(.system(size: inApp ? 21 : 29)).lineLimit(1).minimumScaleFactor(0.7)
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
    let accent = Color(red: 0.992, green: 0.322, blue: 0.322)
    let dayColor = Color(red: 0, green: 0.4, blue: 1)
    ZStack {
      Color(white: 0.92)
      FaceDateNumber(value: model.dateLabel("d"), size: 460, calendarStyle: true)
        .foregroundStyle(accent).position(x: 274, y: 339)
        .accessibilityHidden(true)
      VStack(spacing: 22) {
        HStack {
          Text(model.dateLabel("MMMM yyyy"))
          Spacer()
          Text(model.clock, style: .time).environment(\.timeZone, model.displayTimeZone)
        }.padding(.horizontal, 5).font(.system(size: 37, weight: .medium)).foregroundStyle(
          accent)
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
                .background {
                  if selected {
                    Circle().fill(Color(red: 0, green: 0.141, blue: 0.322))
                      .frame(width: 64, height: 64)
                  }
                }
                .foregroundStyle(
                  selected
                    ? .white : dayColor.opacity(current ? 1 : 0.27)
                )
                .accessibilityIdentifier(
                  selected ? "calendar.face.selected" : "calendar.face.cell.\(i)")
                .accessibilityValue(selected ? "Today":"")
            }
          }
        }.padding(.top, 12).foregroundStyle(dayColor)
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
  var calendarStyle = false
  var body: some View {
    Group {
      if value == "1" {
        DateOneGlyph(calendarStyle: calendarStyle).frame(width: size * 0.315, height: size * 0.72)
      } else {
        Text(value).font(.system(size: size, weight: .medium, design: .rounded))
          .lineLimit(1).minimumScaleFactor(0.55)
      }
    }.accessibilityLabel(value)
  }
}
private struct DateOneGlyph: Shape {
  var calendarStyle = false
  func path(in rect: CGRect) -> Path {
    // UI08 uses a narrower stem and shallower shoulder than UI01. Keep the
    // existing Modular silhouette unchanged; these are own native primitives.
    if calendarStyle {
      var p = Path()
      p.move(to: CGPoint(x: 0.68, y: 0))
      p.addLine(to: CGPoint(x: 0.92, y: 0))
      p.addQuadCurve(to: CGPoint(x: 0.98, y: 0.025), control: CGPoint(x: 0.98, y: 0))
      p.addLine(to: CGPoint(x: 0.98, y: 0.975))
      p.addQuadCurve(to: CGPoint(x: 0.92, y: 1), control: CGPoint(x: 0.98, y: 1))
      p.addLine(to: CGPoint(x: 0.68, y: 1))
      p.addQuadCurve(to: CGPoint(x: 0.63, y: 0.975), control: CGPoint(x: 0.63, y: 1))
      p.addLine(to: CGPoint(x: 0.63, y: 0.16))
      p.addLine(to: CGPoint(x: 0.12, y: 0.31))
      p.addQuadCurve(to: CGPoint(x: 0.015, y: 0.275), control: CGPoint(x: 0.015, y: 0.31))
      p.addLine(to: CGPoint(x: 0.015, y: 0.235))
      p.addQuadCurve(to: CGPoint(x: 0.055, y: 0.19), control: CGPoint(x: 0.015, y: 0.21))
      p.addLine(to: CGPoint(x: 0.61, y: 0.02))
      p.addQuadCurve(to: CGPoint(x: 0.68, y: 0), control: CGPoint(x: 0.65, y: 0))
      p.closeSubpath()
      return p.applying(CGAffineTransform(scaleX: rect.width, y: rect.height))
        .offsetBy(dx: rect.minX, dy: rect.minY)
    }
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
