import SwiftUI

extension AppPage {
  var color: Color {
    switch self {
    case .home, .intercom: .orange
    case .calendar, .reminders, .worldClock, .settings: .gray
    case .music: .pink
    case .faceTime, .messages, .findMy: .green
    case .timers, .alarms: .orange
    case .weather, .safari, .cameras: .blue
    case .podcasts: .purple
    default: .teal
    }
  }
}
struct PersonalView: View {
  @Environment(AppModel.self) private var model
  @State private var editingProfile: String?
  private var configuration: PersonalHomeConfiguration { model.data.personalHome(for:model.profile) }
  var body: some View {
    ZStack {
      FaceView(selection:model.data.face).blur(radius:22).overlay(.black.opacity(0.28))
        .allowsHitTesting(false).accessibilityHidden(true)
      VStack(alignment:.leading,spacing:configuration.layout == .photos ? 30:24) {
        header
        if configuration.layout != .photos {
          ScrollView {
            VStack(spacing:20) {
              HStack(alignment:.top,spacing:25) {
                appGrid(configuration.apps)
                if configuration.layout == .weather { weatherWidget }
                else { mediaWidget(podcast:true) }
              }
              if configuration.layout == .weather {
                LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:20),count:4),spacing:22) {
                  ForEach(weatherGridApps) { page in appButton(page) }
                }
              } else {
                HStack(alignment:.top,spacing:25) {
                  mediaWidget(podcast:false)
                  appGrid([.safari,.reminders,.timers,.alarms])
                }
              }
              allAppsButton
            }
          }.scrollIndicators(.hidden).accessibilityIdentifier(configuration.layout == .weather ? "personal.weather.layout":"personal.media.layout")
        } else {
          HStack(alignment:.top,spacing:25) {
            appGrid(configuration.apps)
            VStack(alignment:.leading,spacing:8) {
              LandscapeArt().frame(width:230,height:230).clipShape(RoundedRectangle(cornerRadius:26))
                .accessibilityLabel("Demo photo album")
              Text("Photos").font(.system(size:17,weight:.medium)).frame(maxWidth:.infinity)
            }.frame(width:230)
          }.accessibilityIdentifier("personal.photos.layout")
          if model.playing || model.connections.musicPlaying || model.podcastPlaying
            || model.data.timers.contains(where:{$0.remaining(at:model.now)>0}) { ActivityStrip() }
          Spacer(minLength:0)
          allAppsButton
        }
      }.padding(45)
    }.foregroundStyle(.white).buttonStyle(.plain)
      .sheet(isPresented:Binding(get:{editingProfile != nil},set:{if !$0 { editingProfile=nil }})) {
        if let profile=editingProfile { PersonalHomeEditor(profile:profile) }
      }
      .onChange(of:model.profile) { _,_ in editingProfile=nil }
  }
  private var allAppsButton: some View {
    Pill(title:"All Apps",symbol:"circle.grid.3x3.fill",tint:.white.opacity(0.18),textColor:.white) {
      model.route = .drawer
    }.accessibilityIdentifier("all.apps")
  }
  private var header: some View {
    HStack {
      VStack(alignment:.leading,spacing:4) {
        if configuration.layout != .photos {
          Text(model.dateLabel("EEEE, MMM d").uppercased()).font(.system(size:18,weight:.medium))
          Text(model.dateLabel("h:mm a")).font(.system(size:20,weight:.semibold))
        } else {
          Text("GOOD MORNING,").font(.system(size:20))
          Text((model.profile ?? "everyone").uppercased()).font(.system(size:22,weight:.semibold))
        }
      }
      Spacer()
      Menu {
        Button("Choose profile") { model.pendingPage=nil;model.route = .privacy }
        if let profile=model.profile {
          Button("Edit Home Screen") { editingProfile=profile }
            .accessibilityIdentifier("personal.edit")
        }
      } label: {
        Text(String(model.profile?.prefix(1) ?? "G")).font(.system(size:22,weight:.semibold))
          .frame(width:58,height:58).background(Color.lilac,in:Circle())
      } primaryAction: {
        model.pendingPage=nil;model.route = .privacy
      }
      .menuIndicator(.hidden)
      .accessibilityLabel("Choose profile").accessibilityIdentifier("personal.profile")
    }
  }
  private func appGrid(_ pages:[AppPage]) -> some View {
    LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:20) {
      ForEach(pages) { page in appButton(page) }
    }.frame(width:236)
  }
  private func appButton(_ page:AppPage) -> some View {
    Button { model.navigate(page) } label: {
      VStack(spacing:7) {
        AppIcon(page:page,edge:88)
        Text(page.rawValue).font(.system(size:17,weight:.medium)).lineLimit(1).minimumScaleFactor(0.8)
      }
    }.accessibilityIdentifier("app.\(page.rawValue)")
  }
  private var weatherGridApps:[AppPage] {
    let order:[AppPage] = [.calendar,.messages,.home,.intercom,.weather,.findMy,.reminders,.settings,.timers,.alarms,.worldClock,.music,.podcasts,.safari,.faceTime]
    return order.filter { !configuration.apps.contains($0) }
  }
  private var weatherWidget: some View {
    Button { model.navigate(.weather) } label: {
      VStack(alignment:.leading,spacing:3) {
        HStack {
          Text(model.connections.weatherCity.replacingOccurrences(of:" · Demo",with:""))
            .font(.system(size:19,weight:.semibold)).lineLimit(1).minimumScaleFactor(0.7)
          Image(systemName:"location.fill").font(.system(size:12))
        }
        Text(model.connections.weatherTemperature).font(.system(size:68,weight:.light))
          .accessibilityIdentifier("personal.weather.temperature")
        Spacer(minLength:4)
        Image(systemName:model.connections.weatherSymbol).symbolRenderingMode(.palette)
          .foregroundStyle(.white,.yellow).font(.system(size:25))
        Text(model.connections.weatherCondition.replacingOccurrences(of:" · Demo",with:""))
          .font(.system(size:17)).lineLimit(1).minimumScaleFactor(0.7)
        Text(model.connections.weatherHighLow).font(.system(size:17))
        Text(model.connections.weatherSource(at:model.now)).font(.system(size:9)).lineLimit(2)
          .accessibilityIdentifier("personal.weather.source").opacity(0.8)
      }.padding(18).frame(width:230,height:250,alignment:.leading)
        .background(LinearGradient(colors:[Color(red:0.18,green:0.55,blue:0.83),Color(red:0.43,green:0.73,blue:0.95)],startPoint:.top,endPoint:.bottom),in:RoundedRectangle(cornerRadius:26))
    }.accessibilityIdentifier("personal.weather.open")
  }
  private func mediaWidget(podcast:Bool) -> some View {
    let connectedMusic = !podcast && model.connections.enabled.contains(.music)
    return VStack(spacing:8) {
      VStack(alignment:.leading,spacing:podcast ? 12:8) {
        HStack(alignment:.top) {
          if podcast || connectedMusic {
            Image(systemName:podcast ? "mic.fill":"music.note").font(.system(size:32))
              .frame(width:70,height:70).background(.white.opacity(0.16),in:RoundedRectangle(cornerRadius:10))
          } else {
            DemoAlbumCover().frame(width:58,height:58)
              .clipShape(RoundedRectangle(cornerRadius:10))
          }
          Spacer()
          Image(systemName:podcast ? "mic.circle":"music.note").font(.system(size:27)).opacity(0.8)
        }
        if connectedMusic || podcast {
          Text(connectedMusic ? "Connected Music":"Demo episode")
            .font(.system(size:16,weight:.medium)).opacity(0.75)
        }
        Button { model.navigate(podcast ? .podcasts:.music) } label: {
          Text(connectedMusic ? "Open Music":podcast ? "A Quiet Morning":model.currentMusicTitle)
            .font(.system(size:20,weight:.medium)).lineLimit(2).frame(maxWidth:.infinity,alignment:.leading)
        }.accessibilityIdentifier(podcast ? "personal.podcast.open":"personal.music.open")
        if !podcast && !connectedMusic {
          Text(model.currentMusicArtist).font(.system(size:18)).lineLimit(1).opacity(0.8)
            .accessibilityIdentifier("personal.music.artist")
        }
        Button {
          if connectedMusic { model.navigate(.music) }
          else if podcast { model.togglePodcast() }
          else { model.togglePlayback() }
        } label: {
          Label(connectedMusic ? "Open":(podcast ? model.podcastPlaying:model.playing) ? "Pause":"Play",
            systemImage:connectedMusic ? "arrow.up.forward":(podcast ? model.podcastPlaying:model.playing) ? "pause.fill":"play.fill")
            .font(.system(size:19,weight:.semibold)).padding(.horizontal,14).padding(.vertical,6)
            .background(.white.opacity(0.16),in:Capsule())
        }.accessibilityIdentifier(podcast ? "personal.podcast.play":"personal.music.play")
        Spacer(minLength:0)
      }.padding(18).frame(width:230,height:230)
        .background(LinearGradient(colors:podcast ? [.purple,Color(red:0.18,green:0.12,blue:0.9)]:[.blue,Color(red:0.1,green:0.28,blue:0.8)],startPoint:.top,endPoint:.bottom),in:RoundedRectangle(cornerRadius:26))
      Text(podcast ? "Podcasts":"Music").font(.system(size:17,weight:.medium))
    }.frame(width:230)
  }
}

/// Synthetic cover art, not a placeholder plus or a claimed Apple Music cover.
struct DemoAlbumCover: View {
  var body: some View {
    GeometryReader { geometry in
      let edge=min(geometry.size.width,geometry.size.height)
      ZStack {
        LinearGradient(colors:[.orange,.pink,Color(red:0.22,green:0.16,blue:0.55)],startPoint:.topLeading,endPoint:.bottomTrailing)
        Circle().fill(.white.opacity(0.25)).frame(width:edge*0.65,height:edge*0.65)
          .position(x:edge*0.70,y:edge*0.26)
        Path { path in
          path.move(to:CGPoint(x:-edge*0.1,y:edge*0.7))
          path.addCurve(to:CGPoint(x:edge*1.1,y:edge*0.48),
            control1:CGPoint(x:edge*0.3,y:edge*0.18),control2:CGPoint(x:edge*0.65,y:edge*1.1))
        }.stroke(.white.opacity(0.65),style:StrokeStyle(lineWidth:edge*0.045,lineCap:.round))
        VStack { Spacer();Text("DEMO").font(.system(size:edge*0.12,weight:.bold)).tracking(edge*0.025).padding(.bottom,edge*0.09) }
      }
    }.clipped().accessibilityLabel("Synthetic demo album artwork")
  }
}

private struct PersonalHomeEditor: View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  let profile:String
  private var configuration:PersonalHomeConfiguration { model.data.personalHome(for:profile) }
  private func update(_ edit:(inout PersonalHomeConfiguration)->Void) {
    guard model.profile==profile else { dismiss();return }
    var value=configuration;edit(&value)
    guard model.data.setPersonalHome(value,for:profile) else { return }
    model.persist()
  }
  var body: some View {
    VStack(alignment:.leading,spacing:20) {
      HStack {
        Text("Home Screen · \(profile)").font(.title2.bold())
        Spacer()
        Button("Done") { dismiss() }.accessibilityIdentifier("personal.editor.done")
      }
      Text("Layout").font(.headline)
      VStack(alignment:.leading,spacing:8) {
        ForEach(PersonalHomeLayout.allCases,id:\.self) { layout in
          Button(layout.title) { update { $0.usePreset(layout) } }
            .buttonStyle(.bordered).accessibilityValue(configuration.layout==layout ? "Selected":"")
            .accessibilityIdentifier("personal.layout."+layout.rawValue)
        }
      }
      Text("Favorite apps").font(.headline)
      ForEach(0..<4) { index in
        Picker("Position \(index+1)",selection:Binding(get:{configuration.apps[index].rawValue},set:{raw in
          if let page=AppPage(rawValue:raw) { update { $0.select(page,at:index) } }
        })) {
          ForEach(AppPage.allCases) { page in Text(page.rawValue).tag(page.rawValue) }
        }.accessibilityIdentifier("personal.favorite.\(index)")
      }
      Text("Layout choices are saved for this demo profile. They do not unlock personal accounts.")
        .font(.callout).foregroundStyle(.secondary)
      Spacer(minLength:0)
    }.padding(28).frame(minWidth:300,minHeight:420)
      .onChange(of:model.profile) { _,value in if value != profile { dismiss() } }
  }
}
struct ActivityStrip: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    HStack {
      if model.connections.musicPlaying, let index = model.connections.currentTrack,
        model.connections.tracks.indices.contains(index)
      {
        Button {
          model.navigate(.music)
        } label: {
          Label(model.connections.tracks[index].title, systemImage: "waveform").lineLimit(1)
        }
        Spacer()
        Button {
          Task { await model.connections.toggleMusic() }
        } label: {
          Image(systemName: "pause.fill")
        }
        .accessibilityLabel("Pause music")
      } else if model.playing {
        Button {
          model.navigate(.music)
        } label: {
          Label(Fixtures.songs[model.song], systemImage: "waveform").lineLimit(1)
        }
        Spacer()
        Button {
          model.togglePlayback()
        } label: {
          Image(systemName: "pause.fill")
        }.accessibilityLabel("Pause activity")
      } else if model.podcastPlaying {
        Button {
          model.navigate(.podcasts)
        } label: {
          Label("A Quiet Morning", systemImage: "mic.circle.fill")
        }.accessibilityIdentifier("activity.podcast")
        Spacer()
        Button {
          model.togglePodcast()
        } label: {
          Image(systemName: "pause.fill")
        }.accessibilityLabel("Pause podcast")
      } else if let t = model.data.timers.first(where: { $0.remaining(at: model.now) > 0 }) {
        Button {
          model.selectedTimer = t.id
          model.navigate(.timers)
        } label: {
          Label(t.display(at: model.now), systemImage: "timer").monospacedDigit()
        }
      }
    }.font(.system(size: 18, weight: .medium)).padding(15).background(
      .black.opacity(0.07), in: Capsule())
  }
}
struct AppDrawer: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Apps").font(.system(size: 34, weight: .bold))
        Spacer()
        RoundButton(symbol: "person.crop.circle", label: "Choose profile") {
          model.route = .privacy
        }
        RoundButton(symbol: "xmark", label: "Close apps") { model.route = .face }
      }.padding(.horizontal, 34).padding(.top, 26).padding(.bottom, 16)
      ScrollView {
        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 4), spacing: 26
        ) {
          ForEach(AppPage.allCases) { page in
            Button {
              if page == .recipes { model.route = .recipe } else { model.navigate(page) }
            } label: {
              VStack(spacing: 8) {
                AppIcon(page: page, edge: 86)
                Text(page.rawValue).font(.system(size: 16, weight: .medium)).lineLimit(1)
              }
            }.accessibilityIdentifier("app.\(page.rawValue)")
          }
        }.padding(.horizontal, 28).padding(.bottom, 24)
      }
    }.background {
      FaceView(selection: model.data.face).blur(radius: 22).overlay(.black.opacity(0.35))
        .allowsHitTesting(false).accessibilityHidden(true)
    }
    .foregroundStyle(.white).buttonStyle(.plain)
  }
}
struct HomeGrid: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 10) {
      HStack(spacing: 10) {
        Button {
          model.route = .thermostat
        } label: {
          AnalogClock(
            date: model.clock, timeZone: model.displayTimeZone, tint: .violetInk, handColor: .black,
            secondsColor: .violetInk, embossedHands: true, hourReach: 0.5, minuteReach: 0.94)
        }.accessibilityLabel("Thermostat").accessibilityIdentifier("grid.thermostat")
        tile("lamp.ceiling.fill", "Lights", "Entryway", model.data.home.entryLight) {
          model.command(.entryLight)
        }.accessibilityIdentifier("grid.entrylight")
        tile("waveform", "Intercom", "Everywhere", false) { model.navigate(.intercom) }
      }
      HStack(spacing: 10) {
        Button {
          model.route = .camera(0)
        } label: {
          MockCameraScene(index: 0).clipShape(RoundedRectangle(cornerRadius: 34))
        }.accessibilityLabel("Front door camera").accessibilityIdentifier("grid.camera")
        tile("homekit", "", "", false) { model.route = .personal }
        tile("sun.max.fill", "Good Morning", "Scene", model.data.home.lastScene == "Good Morning") {
          model.command(.scene("Good Morning"))
          model.banner("Good Morning · Mock scene applied")
        }.accessibilityIdentifier("scene.goodmorning")
      }
      HStack(spacing: 10) {
        tile("lightbulb.fill", "Lights", "Bedroom", model.data.home.bedroomLight) {
          model.command(.bedroomLight)
        }.accessibilityIdentifier("grid.bedroomlight")
        tile("fan.desk", "Fan", "Office", model.data.home.fan) { model.command(.fan) }
          .accessibilityIdentifier("grid.fan")
        tile(
          model.data.home.locked ? "lock.fill" : "lock.open.fill", "Door Lock", "Front Door",
          !model.data.home.locked
        ) { model.route = .lock }.accessibilityIdentifier("grid.lock")
      }
    }.padding(12).background(.white).buttonStyle(.plain).foregroundStyle(.gray)
  }
  private func tile(
    _ icon: String, _ title: String, _ sub: String, _ active: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Tile(active: active) {
        VStack(spacing: 17) {
          Image(systemName: icon).font(.system(size: 53, weight: .medium))
          if !title.isEmpty {
            VStack(spacing: 4) {
              Text(title).font(.system(size: 21, weight: .semibold))
              Text(sub).font(.system(size: 20)).opacity(0.6)
            }
          }
        }.foregroundStyle(active ? Color.violetInk : .gray)
      }
    }.frame(maxWidth: .infinity)
  }
}

struct ThermostatView: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    ZStack {
      Color(red: 0.08, green: 0.58, blue: 0.82)
      VStack {
        AppHeader(title: "Thermostat", light: true)
        Spacer()
        Text("Cooling to").font(.system(size: 27, weight: .regular))
        HStack(spacing: 0) {
          RoundButton(
            symbol: "chevron.down", color: .clear, foreground: .white, size: 76,
            label: "Decrease temperature"
          ) { model.command(.temperature(model.data.home.temperature - 1)) }
          .accessibilityIdentifier("thermostat.down")
          Spacer(minLength: 0)
          Text("\(model.data.home.temperature)").font(.system(size: 170, weight: .light))
            .monospacedDigit().accessibilityLabel("\(model.data.home.temperature)°")
            .accessibilityIdentifier("thermostat.value")
          Spacer(minLength: 0)
          RoundButton(
            symbol: "chevron.up", color: .clear, foreground: .white, size: 76,
            label: "Increase temperature"
          ) { model.command(.temperature(model.data.home.temperature + 1)) }
          .accessibilityIdentifier("thermostat.up")
        }.padding(.horizontal, 28)
        HStack(spacing: 10) {
          Label("70°", systemImage: "thermometer.medium")
          Label("30%", systemImage: "humidity")
        }.font(.system(size: 23)).opacity(0.65)
        Spacer()
        HStack {
          Spacer()
          RoundButton(
            symbol: "thermometer.medium", color: .white.opacity(0.12), foreground: .white, size: 60,
            label: "Cooling mode"
          ) { model.banner("Cool mode · Mock thermostat") }
        }.padding(.horizontal, 28).padding(.bottom, 26)
      }
    }.foregroundStyle(.white)
  }
}
struct LightView: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 25) {
      AppHeader(title: "Entryway")
      Spacer()
      Image(systemName: model.data.home.entryLight ? "lightbulb.fill" : "lightbulb").font(
        .system(size: 110)
      ).foregroundStyle(model.data.home.entryLight ? .orange : .gray)
      Text(model.data.home.entryLight ? "On" : "Off").font(.system(size: 45, weight: .semibold))
      Pill(title: model.data.home.entryLight ? "Turn Off" : "Turn On", symbol: "power") {
        model.command(.entryLight)
      }
      ValueAdjuster(value: model.data.home.brightness, label: "Brightness") {
        model.command(.brightness($0))
      }
      Spacer()
    }.padding(.horizontal, 30).background(.white).foregroundStyle(.black)
  }
}
struct LockView: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 25) {
      AppHeader(title: "Front Door")
      Spacer()
      Image(systemName: model.data.home.locked ? "lock.fill" : "lock.open.fill").font(
        .system(size: 112)
      ).foregroundStyle(model.data.home.locked ? .green : .orange)
      Text(model.data.home.locked ? "Locked" : "Unlocked").font(
        .system(size: 45, weight: .semibold)
      ).accessibilityIdentifier("lock.state")
      Text("Mock lock · Demo profile required").font(.system(size: 20)).foregroundStyle(.gray)
      Pill(
        title: model.authorized
          ? (model.data.home.locked ? "Unlock" : "Lock") : "Choose Demo Profile",
        symbol: model.authorized ? "lock.open" : "person.crop.circle"
      ) {
        if model.authorized {
          model.command(.lock)
        } else {
          model.pendingPage = .home
          model.route = .privacy
        }
      }.accessibilityIdentifier("lock.action")
      Spacer()
    }.padding(.horizontal, 30).background(.white).foregroundStyle(.black)
  }
}
struct PrivacyView: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 18) {
      AppHeader()
      Image(systemName: "person.crop.circle.badge.checkmark").font(.system(size: 66))
        .foregroundStyle(.gray)
      Text("Recognizing…").font(.system(size: 37, weight: .semibold))
      Text("Choose a demo profile to continue.\nNo camera or biometric recognition is used.").font(
        .system(size: 21)
      ).multilineTextAlignment(.center).foregroundStyle(.gray)
      LazyVGrid(
        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14
      ) {
        ForEach(Fixtures.profiles, id: \.self) { name in
          Button {
            model.signIn(name)
          } label: {
            VStack(spacing: 7) {
              Text(String(name.prefix(1))).font(.system(size: 26, weight: .medium)).frame(
                width: 57, height: 57
              ).background(Color.lilac, in: Circle())
              Text(name).font(.system(size: 17))
            }
          }.accessibilityIdentifier("profile.\(name)")
        }
      }.padding(.horizontal, 45)
      Spacer(minLength: 0)
      Button("Use Guest Mode") {
        model.profile = nil
        model.pendingPage = nil
        model.route = .personal
      }.font(.system(size: 20, weight: .medium)).padding(.bottom, 28).accessibilityIdentifier(
        "profile.guest")
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
  }
}
