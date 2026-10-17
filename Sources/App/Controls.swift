import SwiftUI

struct AppContent: View {
  @Environment(AppModel.self) private var model
  var page: AppPage
  var body: some View {
    switch page {
    case .home: HomeGrid()
    case .calendar: CalendarView()
    case .music:
      if model.connections.enabled.contains(.music) { DeviceMusicView() } else { MusicView() }
    case .weather:
      VStack(spacing: 0) {
        AppHeader(title: model.connections.weather?.city ?? "Weather", light: true).background(
          Color(red: 0.14, green: 0.36, blue: 0.6))
        WeatherFace()
      }
    case .timers: TimerView()
    case .reminders:
      if model.connections.requested.contains(.reminders) {
        DeviceRemindersView()
      } else {
        RemindersView()
      }
    case .recipes: RecipeLibraryView()
    case .cameras: CameraGrid()
    case .intercom: IntercomView()
    case .messages: MessagesView()
    case .faceTime: FaceTimeLanding()
    case .findMy: FindMyView()
    case .alarms: AlarmsView()
    case .worldClock: WorldClockView()
    case .safari: NativeBrowserView()
    case .podcasts: PodcastsView()
    case .mirror: NativeMirrorView()
    case .settings: SettingsView()
    }
  }
}
struct ControlCenterView: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 22) {
      AppHeader(title: "Control Center")
      HStack(spacing: 14) {
        control(
          "wifi", model.data.home.online ? "Mock Online" : "Mock Offline", model.data.home.online
        ) {
          model.data.home.online.toggle()
          model.persist()
        }.accessibilityIdentifier("controls.online")
        control("moon.fill", "Night Mode", model.data.night) {
          model.data.night.toggle()
          model.persist()
        }.accessibilityIdentifier("controls.night")
        control("person.fill.viewfinder", model.data.far ? "Far View" : "Near View", model.data.far)
        {
          model.data.far.toggle()
          model.persist()
        }
      }.frame(height: 125)
      ValueAdjuster(value: model.data.screenBrightness * 100, label: "Display dimming") {
        model.data.screenBrightness = $0 / 100
        model.persist()
      }
      ValueAdjuster(value: model.data.volume * 100, label: "Volume") {
        model.data.volume = $0 / 100
        model.audio.setVolume(Float(model.data.volume))
        model.persist()
      }
      HStack(spacing: 16) {
        Pill(title: "Mirror", symbol: "person.crop.rectangle") { model.navigate(.mirror) }
        Pill(title: "Settings", symbol: "gearshape") { model.navigate(.settings) }
          .accessibilityIdentifier("controls.settings")
      }
      Spacer(minLength: 0)
    }.padding(.horizontal, 30).background(Color(white: 0.95)).foregroundStyle(.black)
  }
  private func control(
    _ symbol: String, _ label: String, _ active: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(spacing: 15) {
        Image(systemName: symbol).font(.system(size: 33))
        Text(label).font(.system(size: 17, weight: .medium))
      }.frame(maxWidth: .infinity, maxHeight: .infinity).background(
        active ? .lilac : .white, in: RoundedRectangle(cornerRadius: 27))
    }.buttonStyle(.plain)
  }
}
struct SettingsView: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 12) {
      AppHeader(title: "Settings")
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          Label("Mock home only", systemImage: "shield.lefthalf.filled").font(
            .system(size: 27, weight: .semibold))
          Text(
            "Apple Home stays disconnected. Other services can be connected below. The system photo picker shares only chosen photos. Automated tests use synthetic data."
          ).font(.system(size: 18)).foregroundStyle(.gray)
          if model.display.supported {
            Button {
              model.data.keepDisplayOn.toggle()
              model.display.apply(enabled: model.data.keepDisplayOn)
              model.persist()
            } label: {
              HStack {
                Text("Keep Display On")
                Spacer()
                Image(systemName: model.display.active ? "checkmark.circle.fill" : "circle")
              }.font(.system(size: 23)).contentShape(Rectangle())
            }.accessibilityIdentifier("settings.keepawake").accessibilityValue(
              model.display.active ? "On" : "Off")
          }
          setting("Reference clock", model.referenceClock) { model.referenceClock.toggle() }
          setting("Night mode", model.data.night) {
            model.data.night.toggle()
            model.persist()
          }
          setting("Far-view layout", model.data.far) {
            model.data.far.toggle()
            model.persist()
          }
          setting("Profile present", model.simulatedPresence) {
            if model.authorized { model.signOut() } else { model.route = .privacy }
          }
          Button("Edit Faces") { model.route = .editor }.font(.system(size: 23))
            .accessibilityIdentifier("settings.faces")
          Button("Light & brightness") { model.route = .light }.font(.system(size: 23))
          ValueAdjuster(value: model.data.home.blinds, label: "Mock blinds") {
            model.command(.blinds($0))
          }
          ValueAdjuster(value: model.data.home.fanSpeed, label: "Mock fan speed") {
            model.command(.fanSpeed($0))
          }
          Button("Simulate doorbell") { model.route = .camera(0) }.font(.system(size: 23))
            .accessibilityIdentifier("settings.doorbell")
          Button("Simulate incoming call") { model.incomingCall = true }.font(.system(size: 23))
            .accessibilityIdentifier("settings.call")
          Button("Sign out demo profile") { model.signOut() }.font(.system(size: 23))
          Divider()
          Text("Native system features").font(.system(size: 24, weight: .semibold))
          Text(
            "Public system APIs can supply our own UI with calendars, reminders, photos, media and alarms. The original Clock/Home/FaceTime interfaces are not embeddable. Personal Siri, Messages history, HomePod Intercom and Find My are simulations here."
          ).font(.system(size: 18)).foregroundStyle(.gray)
          ConnectionControls()
          NativeAlarmControls()
          NativePhotoControls()
          Divider()
          Text("Mock command log").font(.system(size: 24, weight: .semibold))
          ForEach(Array(model.data.home.audit.suffix(12).enumerated()), id: \.offset) { _, entry in
            Text(entry).font(.system(size: 17, design: .monospaced)).foregroundStyle(.gray)
          }
          Text(
            "Original artwork reference: Apple HomeView, October 2026. This independent prototype is not an Apple product."
          ).font(.system(size: 15)).foregroundStyle(.gray)
        }.padding(32)
      }
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
  }
  private func setting(_ title: String, _ on: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack {
        Text(title)
        Spacer()
        Image(systemName: on ? "checkmark.circle.fill" : "circle").foregroundStyle(
          on ? .green : .gray)
      }.font(.system(size: 23)).contentShape(Rectangle())
    }
  }
}
struct AssistantView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.scenePhase) private var scenePhase
  @State private var text = ""
  @State private var draftBeforeVoice = ""
  @State private var language = "de-DE"
  @State private var voice = VoiceInputController()
  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
      AppHeader()
      Text(model.assistantReply).font(.system(size: 35, weight: .medium)).padding(.horizontal, 34)
        .frame(maxHeight: .infinity, alignment: .top).padding(.top, 24).accessibilityIdentifier(
          "assistant.reply")
      if VoiceInputController.supported {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Button {
              model.interact()
              if voice.recording {
                voice.finish()
              } else {
                draftBeforeVoice = text
                text = ""
                model.stopAudioForVoice()
                Task { await voice.start(locale: language) }
              }
            } label: {
              Label(
                voice.recording ? "Stop" : "Speak",
                systemImage: voice.recording ? "stop.circle.fill" : "mic.circle.fill")
            }.disabled(voice.busy && !voice.recording).accessibilityIdentifier("assistant.voice")
            if voice.busy || voice.phase == .ready {
              Button("Cancel") {
                voice.cancel()
                text = draftBeforeVoice
              }
              .accessibilityIdentifier("assistant.voice.cancel")
            }
            Spacer()
            Picker("Language", selection: $language) {
              Text("Deutsch").tag("de-DE")
              Text("English").tag("en-US")
            }.labelsHidden().disabled(voice.busy).frame(maxWidth: 150)
          }.font(.system(size: 21, weight: .medium))
          Text(voice.status).font(.system(size: 16)).foregroundStyle(voice.recording ? .red : .gray)
            .accessibilityIdentifier("assistant.voice.status")
        }.padding(.horizontal, 34)
      }
      HStack {
        TextField("Type a request", text: $text).textFieldStyle(.plain).font(.system(size: 25))
          .onSubmit { submitted() }.accessibilityIdentifier("assistant.input")
        RoundButton(symbol: "arrow.up", color: .blue, foreground: .white, label: "Send request") {
          submitted()
        }.disabled(voice.busy || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          .accessibilityIdentifier("assistant.send")
      }.padding(20).background(.gray.opacity(0.09), in: RoundedRectangle(cornerRadius: 28)).padding(
        .horizontal, 30)
      Text("Local demo assistant · Not connected to Siri AI").font(.system(size: 16))
        .foregroundStyle(.gray).padding(.horizontal, 34).padding(.bottom, 24)
    }.background(.white).foregroundStyle(.black)
      .onChange(of: voice.transcript) { _, value in if !value.isEmpty { text = value } }
      .onChange(of: scenePhase) { _, phase in
        if phase == .background || (phase != .active && voice.phase != .preparing) {
          voice.cancel()
        }
      }
      .onDisappear { voice.cancel() }
  }
  private func submitted() {
    guard !voice.busy, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    voice.cancel()
    model.assistantInput = text
    model.runAssistant()
    text = ""
  }
}
struct FaceTimeLanding: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 18) {
      AppHeader(title: "FaceTime")
      Image(systemName: "video.fill").font(.system(size: 60)).foregroundStyle(.green)
      Text("FaceTime").font(.system(size: 31, weight: .semibold))
      SystemFaceTimeAction().padding(.horizontal, 32)
      Text("Calls open in FaceTime. The video engine cannot be embedded here.")
        .font(.system(size: 18)).multilineTextAlignment(.center).foregroundStyle(.gray)
      Divider()
      Pill(title: "Simulate Incoming Call", symbol: "phone.fill", tint: .green, textColor: .white) {
        model.incomingCall = true
      }.accessibilityIdentifier("facetime.simulate")
      Spacer(minLength: 0)
    }.padding(.horizontal, 30).background(.white).foregroundStyle(.black)
  }
}
struct SafariLanding: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 20) {
      AppHeader(title: "Safari")
      Image(systemName: "safari").font(.system(size: 90)).foregroundStyle(.blue).padding(.top, 30)
      Text("Home Cookbook").font(.system(size: 36, weight: .bold))
      Text("A bundled recipe for offline testing. No network requests are made.").font(
        .system(size: 22)
      ).foregroundStyle(.gray).multilineTextAlignment(.center)
      Pill(title: "Butternut Squash Soup", symbol: "fork.knife") { model.route = .recipe }
        .accessibilityIdentifier("safari.recipe")
      Pill(title: model.data.pinnedRecipe ? "Pinned Recipe" : "Pin Recipe", symbol: "pin") {
        model.pinRecipe()
      }
      Spacer()
    }.padding(.horizontal, 30).background(.white).foregroundStyle(.black)
  }
}
struct PodcastsView: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 24) {
      AppHeader(title: "Podcasts")
      Image(systemName: "mic.circle.fill").font(.system(size: 135)).foregroundStyle(.purple)
        .padding(.top, 32)
      Text("A Quiet Morning").font(.system(size: 37, weight: .semibold))
      Text("Demo episode · Local audio").font(.system(size: 23)).foregroundStyle(.gray)
      Pill(
        title: model.podcastPlaying ? "Pause" : "Play Demo Episode",
        symbol: model.podcastPlaying ? "pause.fill" : "play.fill", tint: .purple, textColor: .white
      ) { model.togglePodcast() }.accessibilityIdentifier("podcast.play")
      Spacer()
    }.padding(.horizontal, 30).background(.white).foregroundStyle(.black)
  }
}
