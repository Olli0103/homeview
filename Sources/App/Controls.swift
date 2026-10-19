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
      WeatherScreen()
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
          model.updateLocalControls { $0.home.online.toggle() }
        }.accessibilityIdentifier("controls.online")
        control("moon.fill", "Night Mode", model.data.night) {
          model.updateLocalControls { $0.night.toggle() }
        }.accessibilityIdentifier("controls.night")
        control("person.fill.viewfinder", model.data.far ? "Far View" : "Near View", model.data.far)
        {
          model.updateLocalControls { $0.far.toggle() }
        }.accessibilityIdentifier("controls.distance")
      }.frame(height: 125)
      ValueAdjuster(value: model.data.screenBrightness * 100, label: "Display dimming") {
        let value = $0 / 100
        model.updateLocalControls { $0.screenBrightness = value }
      }
      ValueAdjuster(value: model.data.volume * 100, label: "Demo audio") {
        let value = $0 / 100
        model.updateLocalControls { $0.volume = value }
      }
      HStack(spacing: 16) {
        Pill(title: "Mirror", symbol: "person.crop.rectangle") { model.navigate(.mirror) }
        Pill(title: "Settings", symbol: "gearshape") { model.navigate(.settings) }
          .accessibilityIdentifier("controls.settings")
      }
      Text("App-only dimming and demo audio. Wi-Fi, screen brightness and system volume are unchanged.")
        .font(.system(size: 15)).foregroundStyle(.secondary)
        .accessibilityIdentifier("controls.scope")
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
    }.buttonStyle(.plain).accessibilityValue(active ? "On" : "Off")
  }
}
struct SettingsView: View {
  @Environment(AppModel.self) private var model
  @State private var showingPowerCapabilities=false
  var body: some View {
    VStack(spacing: 12) {
      AppHeader(title: "Settings")
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          if let note = model.storeRecoveryNote {
            Text(note).font(.system(size: 17)).foregroundStyle(.orange)
              .accessibilityIdentifier("store.recovery")
          }
          Label("Mock home only", systemImage: "shield.lefthalf.filled").font(
            .system(size: 27, weight: .semibold))
          Text(
            "Apple Home stays disconnected. Other services can be connected below. The system photo picker shares only chosen photos. Automated tests use synthetic data."
          ).font(.system(size: 18)).foregroundStyle(.gray)
          if model.display.supported {
            Button {
              model.updateLocalControls { $0.keepDisplayOn.toggle() }
            } label: {
              HStack {
                Text("Keep Display On")
                Spacer()
                Image(systemName: model.display.active ? "checkmark.circle.fill" : "circle")
              }.font(.system(size: 23)).contentShape(Rectangle())
            }.accessibilityIdentifier("settings.keepawake").accessibilityValue(
              model.display.active ? "On" : "Off")
          }
          Button("Reset local app content") { model.presentLocalReset() }
            .font(.system(size:23)).accessibilityIdentifier("settings.reset")
          Text(model.localResetStatus).font(.system(size:15)).foregroundStyle(.gray)
            .accessibilityIdentifier("settings.reset.status")
          Button("Welcome and service overview") { model.showingIntroduction=true }
            .font(.system(size:23)).accessibilityIdentifier("settings.introduction")
          Button("Power adapter information") { showingPowerCapabilities=true }
            .font(.system(size:23)).accessibilityIdentifier("settings.power")
          setting("Reference clock", model.referenceClock) { model.referenceClock.toggle() }
          setting("Night mode", model.data.night) {
            model.updateLocalControls { $0.night.toggle() }
          }
          setting("Far-view layout", model.data.far) {
            model.updateLocalControls { $0.far.toggle() }
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
          Button("Simulate doorbell") { model.simulateDoorbell() }.font(.system(size: 23))
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
      .sheet(isPresented:$showingPowerCapabilities) { PowerCapabilitiesView() }
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
  var focusRequest=0
  @Environment(AppModel.self) private var model
  @Environment(\.scenePhase) private var scenePhase
  private var text: String {
    get { model.assistantInput }
    nonmutating set { model.assistantInput = newValue }
  }
  @FocusState private var typing:Bool
  private var canEdit:Bool {
    scenePhase == .active && model.route == .assistant
      && model.demoDoorbell.current == nil && !model.incomingCall
  }
  @State private var voiceDraftGeneration = 0
  @State private var draftBeforeVoice = ""
  @State private var language = "de-DE"
  @State private var showingCapabilities = false
  @State private var showingAnswerSpeechSettings=false
  @State private var voiceInitiating=false
  @State private var voice = VoiceInputController()
  var body: some View {
    VStack(alignment: .leading, spacing:12) {
      ScrollViewReader { reader in
      ScrollView {
      VStack(alignment: .leading, spacing:model.assistantUsesAI ? 8:22) {
      AppHeader()
      HStack(spacing:12) {
        Button("Capabilities and limits") { showingCapabilities=true }
          .disabled(voice.busy || voiceInitiating).accessibilityIdentifier("assistant.capabilities")
        Spacer(minLength:0)
        Button(model.answerSpeech.speaking ? "Stop":model.connections.personalUnlocked ? "Read":"Unlock readout") {
          if model.answerSpeech.speaking { model.stopAnswerSpeech() }
          else { Task { await model.readAssistantAnswer() } }
        }.disabled(voice.busy || voiceInitiating || model.preparingAnswerSpeech || model.assistantAI.busy)
          .accessibilityIdentifier("answer.speech.read")
        Button { showingAnswerSpeechSettings=true } label: { Image(systemName:"speaker.wave.2") }
          .accessibilityLabel("Answer voice settings").accessibilityIdentifier("answer.speech.settings")
          .disabled(voice.busy || voiceInitiating || model.preparingAnswerSpeech)
      }.font(.system(size:15)).padding(.horizontal,34)
      if model.showAnswerSpeechStatus {
        Text(model.answerSpeech.status).font(.system(size:12)).foregroundStyle(.gray)
          .padding(.horizontal,34).accessibilityIdentifier("answer.speech.status")
      }
      if model.assistantUsesAI {
        VStack(alignment:.leading,spacing:8) {
          HStack {
            Text("On-device answers · No actions").font(.system(size:17,weight:.semibold))
            Spacer()
            Button(model.assistantAI.busy ? "Stop":"New") {
              model.stopAnswerSpeech()
              model.assistantAI.clear(status:model.assistantAI.busy
                ? "Stopped. Conversation cleared; no action was taken.":"Conversation cleared. Nothing is saved.")
            }.accessibilityIdentifier("assistant.ai.reset")
          }
          Text("Temporary · Not Siri history · No device sync")
            .font(.system(size:12)).foregroundStyle(.gray)
            .accessibilityIdentifier("assistant.ai.history.scope")
          Text(model.assistantAI.status).font(.system(size:14)).foregroundStyle(.gray)
            .accessibilityIdentifier("assistant.ai.status")
        }.padding(.horizontal,34)
            VStack(alignment:.leading,spacing:18) {
              ForEach(Array(model.assistantAI.exchanges.enumerated()),id:\.element.id) { index,exchange in
                VStack(alignment:.leading,spacing:8) {
                  Text(exchange.question).font(.system(size:19,weight:.semibold))
                    .accessibilityIdentifier("assistant.ai.question.\(index)")
                  Text(exchange.answer).font(.system(size:24))
                    .accessibilityIdentifier("assistant.ai.answer.\(index)")
                }.frame(maxWidth:.infinity,alignment:.leading).id(exchange.id)
              }
              if let question=model.assistantAI.pendingQuestion {
                Text(question).font(.system(size:19,weight:.semibold))
                ProgressView().accessibilityIdentifier("assistant.ai.thinking")
              }
            }.padding(.horizontal,34).padding(.vertical,8)
      } else {
          Text(model.assistantReply).font(.system(size:35,weight:.medium))
            .frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,34)
            .padding(.top,24).accessibilityIdentifier("assistant.reply")
      }
      if model.demoPlan != nil { AssistantPlanView() }
      if VoiceInputController.supported {
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Button {
              model.interact()
              if voice.recording {
                voice.finish()
              } else {
                typing=false
                draftBeforeVoice = text
                voiceDraftGeneration = model.personalSessionGeneration
                text = ""
                model.stopAudioForVoice()
                voiceInitiating=true
                Task { await voice.start(locale:language);voiceInitiating=false }
              }
            } label: {
              Label(
                voice.recording ? "Stop" : "Speak",
                systemImage: voice.recording ? "stop.circle.fill" : "mic.circle.fill")
            }.disabled((voice.busy && !voice.recording) || model.assistantAI.busy || model.demoPlanBusy).accessibilityIdentifier("assistant.voice")
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
      }
      }.accessibilityIdentifier("assistant.content")
        .onChange(of:model.assistantAI.exchanges.count) { _,_ in
          if let id=model.assistantAI.exchanges.last?.id { reader.scrollTo(id,anchor:.bottom) }
        }
      }
      HStack {
        TextField("Type a request", text: Binding(get: { text }, set: { if canEdit { text = $0 } })).textFieldStyle(.plain).font(.system(size: 25))
          .focused($typing).submitLabel(.send)
          .onSubmit { submitted() }.accessibilityIdentifier("assistant.input")
          .frame(minHeight:44)
        if typing {
          Button { typing=false } label: { Image(systemName:"keyboard.chevron.compact.down").frame(width:44,height:44) }
            .buttonStyle(.plain).accessibilityLabel("Dismiss keyboard")
            .accessibilityIdentifier("assistant.keyboard.dismiss")
        }
        RoundButton(symbol: "arrow.up", color: .blue, foreground: .white, label: "Send request") {
          submitted()
        }.disabled(voice.busy || model.assistantAI.busy || model.demoPlanBusy || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          .accessibilityIdentifier("assistant.send")
      }.padding(20).background(.gray.opacity(0.09), in: RoundedRectangle(cornerRadius: 28)).padding(
        .horizontal, 30)
      Text(model.assistantUsesAI ? "Apple on-device text · Not Siri · No cloud fallback":"Local demo assistant · Not connected to Siri AI").font(.system(size: 16))
        .foregroundStyle(.gray).padding(.horizontal, 34).padding(.bottom, 24)
    }.background(.white).foregroundStyle(.black)
      .onAppear { typing=true }
      .onChange(of:focusRequest) { _,_ in typing=true }
      .sheet(isPresented:$showingCapabilities) { AssistantCapabilitiesView() }
      .sheet(isPresented:$showingAnswerSpeechSettings) { AnswerSpeechSettingsView() }
      .onChange(of: voice.transcript) { _, value in if !value.isEmpty { text = value } }
      .onChange(of: scenePhase) { _, phase in
        if phase == .background || (phase != .active && voice.phase != .preparing) {
          voice.cancel()
        }
      }
      .onDisappear {
        let restore = voice.busy && scenePhase == .active
          && voiceDraftGeneration == model.personalSessionGeneration
        voice.cancel()
        if restore { text = draftBeforeVoice }
        model.assistantAI.clear()
        model.stopAnswerSpeech()
      }
  }
  private func submitted() {
    guard canEdit,!voice.busy,!model.assistantAI.busy,!model.demoPlanBusy, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    voice.cancel()
    model.assistantInput = text
    model.runAssistant()
    if model.demoPlan?.phase == .preview { typing=false }
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
  @State private var feeds = false
  @State private var address = ""
  @FocusState private var typing: Bool
  var body: some View {
    VStack(spacing:12) {
      AppHeader(title:"Podcasts")
      HStack {
        Button(feeds ? "Player":"RSS feeds") { feeds.toggle() }
          .accessibilityIdentifier("podcast.feeds")
        Spacer()
        if model.data.podcasts.selectedEpisode != nil {
          Button("Demo") { model.usePodcastDemo() }.accessibilityIdentifier("podcast.demo")
        }
      }.font(.system(size:19)).padding(.horizontal,30)
      ScrollView {
        VStack(spacing:20) {
          if feeds { feedControls }
          else if let episode=model.data.podcasts.selectedEpisode {
            Image(systemName:"mic.circle.fill").font(.system(size:72)).foregroundStyle(.purple)
            Text(episode.title).font(.system(size:30,weight:.semibold)).multilineTextAlignment(.center)
              .accessibilityIdentifier("podcast.title")
            Text(model.currentPodcastSource).font(.system(size:18)).foregroundStyle(.secondary)
            Text("Public RSS · Not Apple Podcasts account sync").font(.system(size:15)).foregroundStyle(.secondary)
            Text(positionLabel).font(.system(size:23,design:.monospaced))
              .accessibilityIdentifier("podcast.position")
            HStack(spacing:24) {
              Button { model.seekPodcast(by:-15) } label: { Image(systemName:"gobackward.15") }
                .accessibilityLabel("Back 15 seconds").accessibilityIdentifier("podcast.back")
              Button { model.togglePodcast() } label: {
                Label(model.podcastRequested ? "Pause":"Play",systemImage:model.podcastRequested ? "pause.fill":"play.fill")
              }.accessibilityIdentifier("podcast.play")
              Button { model.seekPodcast(by:15) } label: { Image(systemName:"goforward.15") }
                .accessibilityLabel("Forward 15 seconds").accessibilityIdentifier("podcast.forward")
            }.font(.system(size:28)).padding(.vertical,12)
            Text(model.podcastPlayer.episodeID==episode.id ? model.podcastPlayer.status:"Paused · Saved position")
              .font(.system(size:17)).foregroundStyle(.secondary).accessibilityIdentifier("podcast.status")
          } else {
            Image(systemName:"mic.circle.fill").font(.system(size:100)).foregroundStyle(.purple)
            Text("A Quiet Morning").font(.system(size:34,weight:.semibold))
            Text("Demo episode · Local audio").font(.system(size:21)).foregroundStyle(.secondary)
            Pill(title:model.podcastPlaying ? "Pause":"Play Demo Episode",
              symbol:model.podcastPlaying ? "pause.fill":"play.fill",tint:.purple,textColor:.white) {
              model.togglePodcast()
            }.accessibilityIdentifier("podcast.play")
          }
        }.padding(30).frame(maxWidth:.infinity)
      }
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
  }
  private var positionLabel: String {
    guard let episode=model.data.podcasts.selectedEpisode else { return "" }
    let position=model.podcastPlayer.episodeID==episode.id ? model.podcastPlayer.position:model.data.podcasts.positions[episode.id] ?? 0
    let duration=model.podcastPlayer.episodeID==episode.id ? model.podcastPlayer.duration:episode.duration
    return time(position)+" / "+(duration.map(time) ?? "Duration not supplied")
  }
  private func time(_ value:Double) -> String {
    let n=Int(max(0,min(604800,value.isFinite ? value:0)));return String(format:"%d:%02d",n/60,n%60)
  }
  private var feedControls: some View {
    VStack(alignment:.leading,spacing:18) {
      Text("Public RSS feeds").font(.system(size:27,weight:.semibold))
      Text("Add a feed URL yourself. No private subscriptions are imported. Selecting an episode never starts playback automatically.")
        .font(.system(size:17)).foregroundStyle(.secondary)
      TextField("https://…/podcast.xml",text:$address).textFieldStyle(.plain)
        .focused($typing).onSubmit { typing=false }
        .padding(12).background(.gray.opacity(0.08),in:RoundedRectangle(cornerRadius:12))
        .accessibilityIdentifier("podcast.feed.url")
      Button("Load feed") { typing=false;Task { await model.importPodcastFeed(address) } }
        .disabled(model.podcastLoading).accessibilityIdentifier("podcast.feed.load")
      if ProcessInfo.processInfo.arguments.contains("--uitesting"),ProcessInfo.processInfo.arguments.contains("--podcast-fixture") {
        Button("Load own test feed") { Task { await model.importPodcastFeed(PodcastFixture.feedURL.absoluteString) } }
          .accessibilityIdentifier("podcast.feed.fixture")
      }
      Text(model.podcastStatus).font(.system(size:16)).foregroundStyle(.secondary)
        .accessibilityIdentifier("podcast.feed.status")
      ForEach(model.data.podcasts.feeds) { feed in
        VStack(alignment:.leading,spacing:12) {
          HStack {
            Text(feed.title).font(.system(size:22,weight:.semibold))
            Spacer()
            Button("Remove") { model.removePodcastFeed(feed.id) }
              .accessibilityIdentifier("podcast.feed.remove")
          }
          Text(feed.url.host ?? "RSS").font(.system(size:14)).foregroundStyle(.secondary)
          ForEach(Array(feed.episodes.enumerated()),id:\.element.id) { index,episode in
            Button {
              model.selectPodcastEpisode(episode.id);feeds=false
            } label: {
              VStack(alignment:.leading,spacing:5) {
                Text(episode.title).font(.system(size:21))
                Text(episode.duration.map(time) ?? "Duration not supplied").font(.system(size:15)).foregroundStyle(.secondary)
              }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,8).contentShape(Rectangle())
            }.accessibilityIdentifier("podcast.episode."+String(index))
          }
        }
        Divider()
      }
    }
  }
}
