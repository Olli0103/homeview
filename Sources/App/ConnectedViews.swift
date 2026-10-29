import SwiftUI

struct ConnectionControls: View {
  var revealWeatherCity: () -> Void = {}
  @Environment(AppModel.self) private var model
  @ScaledMetric(relativeTo:.headline) private var sectionSize:CGFloat=24
  @ScaledMetric(relativeTo:.body) private var homeSize:CGFloat=19
  @ScaledMetric(relativeTo:.body) private var policySize:CGFloat=17
  @ScaledMetric(relativeTo:.body) private var detailSize:CGFloat=16
  @ScaledMetric(relativeTo:.headline) private var serviceSize:CGFloat=22
  @ScaledMetric(relativeTo:.caption) private var captionSize:CGFloat=15
  @Environment(\.scenePhase) private var phase
  @Environment(\.nativeCanvasScale) private var canvasScale
  @FocusState private var weatherCityFocused: Bool
  private var minimumHitSide: CGFloat { (44 / max(0.01, canvasScale)).rounded(.up) }
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Connected services").font(.system(size: sectionSize, weight: .semibold))
      Label("Apple Home stays disconnected", systemImage: "house.badge.exclamationmark")
        .font(.system(size: homeSize)).foregroundStyle(.black.opacity(0.65)).accessibilityIdentifier(
          "connections.home.locked")
      Text(
        "Calendar and reminders are protected by your device authentication. Other Apple apps' private history is not imported."
      )
      .font(.system(size: policySize)).foregroundStyle(.black.opacity(0.65))
      Text("Guests can use public weather, local timers, bundled media and public podcast feeds. Apple Music stays private unless an authenticated device holder explicitly shares the current queue. Sharing ends on background, new search, reconnect or app restart.")
        .font(.system(size:detailSize)).foregroundStyle(.black.opacity(0.65)).accessibilityIdentifier("guest.policy.summary")
      SharedPanelControls()
      ForEach(DataConnection.allCases) { kind in
        VStack(alignment: .leading, spacing: 7) {
          HStack {
            Text(kind.rawValue).font(.system(size: serviceSize, weight: .medium))
            Spacer()
            let on = model.connections.enabled.contains(kind)
            Button(on ? "Disconnect" : "Connect") {
              if on {
                _ = model.disconnectService(kind)
              } else if kind == .music && !model.connections.personalUnlocked {
                model.pendingPage = .settings;model.route = .deviceUnlock
              } else {
                let reset=model.localResetGeneration
                Task { await model.connectService(kind,expectedResetGeneration:reset) }
              }
            }.disabled(model.connections.busy.contains(kind))
              .accessibilityLabel("\(on ? "Disconnect":"Connect") \(kind.rawValue)")
              .accessibilityIdentifier("connect.\(kind.rawValue)")
          }
          Text(model.connections.status[kind] ?? "Not connected").font(.system(size: detailSize))
            .foregroundStyle(.black.opacity(0.65))
            .accessibilityIdentifier("connection.status.\(kind.rawValue)")
          if model.connections.requested.contains(kind), !model.connections.enabled.contains(kind) {
            Button("Disconnect") { _ = model.disconnectService(kind) }
              .accessibilityIdentifier("connection.forget.\(kind.rawValue)")
          }
          if kind == .music,model.connections.enabled.contains(.music) {
            if model.connections.guestMusicShared {
              Button("Continue as guest") { model.beginGuestMusicUse() }
                .accessibilityIdentifier("guest.music.use")
            }
            Text(model.connections.guestMusicShared ? "Current queue shared · Search remains private":"Guest music sharing is off")
              .font(.system(size:captionSize)).accessibilityIdentifier("guest.music.status")
            if model.connections.personalUnlocked {
              Button(model.connections.guestMusicShared ? "Stop guest sharing":"Share current queue with guests") {
                _ = model.connections.setGuestMusicSharing(!model.connections.guestMusicShared)
              }.accessibilityIdentifier("guest.music.share")
            } else {
              Button("Authenticate to manage sharing") {
                model.pendingPage = .settings;model.route = .deviceUnlock
              }.accessibilityIdentifier("guest.music.authenticate")
            }
          }
          if kind == .weather {
            TextField(
              "City",
              text: Binding(get: { model.connections.city }, set: { model.connections.city = $0 })
            )
            .textFieldStyle(.plain).focused($weatherCityFocused)
              .frame(minHeight:max(0,minimumHitSide-20)).padding(10).background(
              .gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10)
            ).contentShape(Rectangle()).onTapGesture { weatherCityFocused=true }
              .accessibilityIdentifier("weather.city")
              .onChange(of:phase) { _,phase in if phase != .active { weatherCityFocused=false } }
              .id("settings.weather.city")
              .onChange(of:weatherCityFocused) { _,focused in
                if focused { revealWeatherCity() }
              }
              .onChange(of:canvasScale) { _,_ in
                if weatherCityFocused { revealWeatherCity() }
              }
            WeatherUnitsPicker(selection:Binding(get:{model.connections.weatherUnits},
              set:{model.connections.weatherUnits=$0}),minimumHeight:minimumHitSide)
            Link("Weather data by Open-Meteo", destination: URL(string: "https://open-meteo.com/")!)
              .font(.system(size: captionSize))
            if model.connections.requested.contains(.weather) {
              Button("Update weather") {
                let reset=model.localResetGeneration
                Task { await model.connectService(.weather,expectedResetGeneration:reset) }
              }
                .disabled(model.connections.busy.contains(.weather)).accessibilityIdentifier("weather.update")
            }
          }
        }
        Divider()
      }
    }
  }
}
// Scaled settings supply a canvas-adjusted height; unscaled forms supply
// native points. Both retain the standard public segmented control.
struct WeatherUnitsPicker: View {
  @Binding var selection: WeatherUnits
  var minimumHeight: CGFloat
  var identifier = "weather.units"
  var body: some View {
    #if os(iOS) || os(visionOS)
      NativeWeatherUnitsPicker(selection:$selection,minimumHeight:minimumHeight,identifier:identifier)
        .frame(height:minimumHeight)
    #else
      Picker("Weather units",selection:$selection) {
        ForEach(WeatherUnits.allCases,id:\.self) { Text($0.rawValue).tag($0) }
      }.pickerStyle(.segmented).accessibilityIdentifier(identifier)
    #endif
  }
}
#if os(iOS) || os(visionOS)
private struct NativeWeatherUnitsPicker: UIViewRepresentable {
  @Binding var selection: WeatherUnits
  var minimumHeight: CGFloat
  var identifier: String
  func makeCoordinator() -> Coordinator { Coordinator(selection:$selection) }
  func makeUIView(context:Context) -> UISegmentedControl {
    let control=UISegmentedControl(items:WeatherUnits.allCases.map(\.rawValue))
    control.accessibilityIdentifier=identifier
    control.accessibilityLabel="Weather units"
    control.addTarget(context.coordinator,action:#selector(Coordinator.changed(_:)),for:.valueChanged)
    return control
  }
  func updateUIView(_ control:UISegmentedControl,context:Context) {
    context.coordinator.selection=$selection
    control.accessibilityIdentifier=identifier
    control.selectedSegmentIndex=WeatherUnits.allCases.firstIndex(of:selection) ?? 0
  }
  func sizeThatFits(_ proposal:ProposedViewSize,uiView:UISegmentedControl,context:Context) -> CGSize? {
    CGSize(width:proposal.width ?? uiView.intrinsicContentSize.width,height:minimumHeight)
  }
  @MainActor final class Coordinator: NSObject {
    var selection: Binding<WeatherUnits>
    init(selection:Binding<WeatherUnits>) {self.selection=selection}
    @objc func changed(_ control:UISegmentedControl) {
      guard WeatherUnits.allCases.indices.contains(control.selectedSegmentIndex) else {return}
      selection.wrappedValue=WeatherUnits.allCases[control.selectedSegmentIndex]
    }
  }
}
#endif
struct SharedPanelControls: View {
  @Environment(AppModel.self) private var model
  @ScaledMetric(relativeTo:.headline) private var sectionSize:CGFloat=22
  @ScaledMetric(relativeTo:.body) private var policySize:CGFloat=16
  var body: some View {
    VStack(alignment:.leading,spacing:10) {
      Text("Shared faces").font(.system(size:sectionSize,weight:.semibold))
      Text("Connecting or unlocking never publishes private contents. In Calendar, share one selected event per display label (up to four). Only title, time and calendar source are published as a snapshot. Demo labels are not household identities. Publications stay in memory until revoked, disconnected, backgrounded or restarted.")
        .font(.system(size:policySize)).foregroundStyle(.black.opacity(0.65))
      if model.connections.sharedCalendarCards.isEmpty {
        Text("No calendar cards shared").accessibilityIdentifier("shared.calendar.empty")
      }
      ForEach(model.connections.sharedCalendarCards) { card in
        VStack(alignment:.leading,spacing:4) {
          Text(card.title).font(.system(size:20,weight:.semibold))
          Text(card.label+" · "+card.calendar+" · Snapshot").font(.system(size:15))
          Button("Stop sharing "+card.label) { model.connections.revokeSharedCalendar(card.id) }
            .frame(minHeight:48).accessibilityIdentifier("shared.calendar.revoke."+card.label)
        }
      }
    }.accessibilityElement(children:.contain).accessibilityIdentifier("shared.panel.controls")
  }
}
struct DeviceUnlockView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.dynamicTypeSize) private var textSize
  @Environment(\.nativeCanvasScale) private var canvasScale
  @ScaledMetric(relativeTo:.headline) private var headerSize:CGFloat=23
  @ScaledMetric(relativeTo:.title2) private var clockSize:CGFloat=22
  @ScaledMetric(relativeTo:.largeTitle) private var titleSize:CGFloat=33
  @ScaledMetric(relativeTo:.body) private var policySize:CGFloat=22
  @ScaledMetric(relativeTo:.headline) private var actionSize:CGFloat=21
  @State private var unlockTask: Task<Void, Never>?
  private var minimumHitSide:CGFloat {ceil(44/max(0.01,canvasScale))}
  private func cancelUnlock() {
    unlockTask?.cancel()
    unlockTask = nil
  }
  var body:some View {
    Group {
      if textSize.isAccessibilitySize {
        VStack(spacing:24) {
          header
          ScrollView {
            VStack(spacing:24) {symbol;title;policy;unlockAction}.padding(.vertical,32)
          }.accessibilityIdentifier("device.unlock.accessible.content")
        }
      } else {
        VStack(spacing:24) {header;Spacer();symbol;title;policy;unlockAction;Spacer()}
      }
    }.padding(.horizontal,32).background(.white).foregroundStyle(.black)
      .onDisappear {cancelUnlock()}
      .onChange(of:scenePhase) {_,phase in
        // A system authentication prompt may make the scene inactive.
        if phase == .background {cancelUnlock()}
      }
  }
  private var header:some View {
    AppHeader(title:"Personal access",closeSize:textSize.isAccessibilitySize ? max(48,minimumHitSide):48,
      titleFontSize:headerSize,clockFontSize:clockSize,accessibilityLayout:textSize.isAccessibilitySize)
  }
  private var symbol:some View {
    Image(systemName:"lock.shield").font(.system(size:76)).foregroundStyle(.blue)
  }
  private var title:some View {
    Text("Unlock personal data").font(.system(size:titleSize,weight:.semibold))
  }
  private var policy:some View {
    Text("Use this device's authentication for connected personal content and shared album choices.")
      .font(.system(size:policySize)).multilineTextAlignment(.center).foregroundStyle(.black.opacity(0.65))
  }
  private var unlockAction:some View {
    Pill(title:"Unlock",symbol:"person.crop.circle.badge.checkmark",tint:.blue,textColor:.white,
      fontSize:actionSize,minimumHeight:textSize.isAccessibilitySize ? minimumHitSide:0) {
        cancelUnlock()
        unlockTask = Task {
          guard !Task.isCancelled else { return }
          let granted = await model.connections.unlock()
          guard !Task.isCancelled, model.route == .deviceUnlock else { return }
          if granted {
            if let page = model.pendingPage {
              model.route = .app(page)
              model.pendingPage = nil
            }
          } else {
            model.error = "Personal access was not unlocked."
          }
        }
      }.accessibilityIdentifier("device.unlock")
  }
}
struct DeviceRemindersView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.scenePhase) private var phase
  @State private var title = ""
  @FocusState private var inputFocused: Bool
  var body: some View {
    Group {
    if !model.connections.personalUnlocked {
      DeviceUnlockView()
    } else {
      VStack(alignment: .leading, spacing: 15) {
        AppHeader(title: "Reminders")
        Text("Your reminders").font(.system(size: 35, weight: .bold)).padding(.horizontal, 32)
        ScrollView {
          VStack(spacing: 8) {
            if model.connections.reminders.isEmpty {
              Text("No reminders").foregroundStyle(.gray).padding(24)
            }
            ForEach(model.connections.reminders) { item in
              HStack {
                Button {
                  Task { await model.connections.completeReminder(item) }
                } label: {
                  HStack {
                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                      .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                      Text(item.title).strikethrough(item.completed)
                      Text(item.listTitle + (item.writable ? "" : " · Read-only"))
                        .font(.system(size: 13)).foregroundStyle(.gray)
                    }
                    Spacer()
                  }.contentShape(Rectangle())
                }.disabled(!item.writable || model.connections.busy.contains(.reminders))
                  .accessibilityIdentifier("device.reminder.\(item.title)")
                  .accessibilityValue(!item.writable ? "Read-only" : item.completed ? "Completed" : "Open")
                Button {
                  Task { await model.connections.removeReminder(item) }
                } label: {
                  Image(systemName: "minus.circle").foregroundStyle(.gray)
                }.disabled(!item.writable || model.connections.busy.contains(.reminders))
                  .accessibilityLabel("Delete \(item.title)")
              }.font(.system(size: 23)).padding(.vertical, 12)
              Divider()
            }
          }.padding(.horizontal, 32)
        }
        Text(model.connections.status[.reminders] ?? "").font(.system(size: 16)).foregroundStyle(
          .gray
        ).padding(.horizontal, 32).accessibilityIdentifier("device.reminder.status")
        HStack {
          TextField("New reminder", text: $title).textFieldStyle(.plain).focused($inputFocused)
            .accessibilityIdentifier(
              "device.reminder.input")
          RoundButton(symbol: "plus", color: .orange.opacity(0.2), label: "Add reminder") {
            let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            inputFocused = false
            Task {
              if await model.connections.addReminder(value) { title = "" }
            }
          }.accessibilityIdentifier("device.reminder.add")
        }.font(.system(size: 22)).padding(30)
          .disabled(model.connections.busy.contains(.reminders))
      }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
        .task { await model.connections.refreshReminders() }
    }
    }.onChange(of: model.connections.personalUnlocked) { _, unlocked in
      if !unlocked { title = ""; inputFocused = false }
    }
    .onChange(of:phase) { _,value in if value != .active { inputFocused=false } }
  }
}
struct DeviceMusicView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.scenePhase) private var phase
  @State private var query = ""
  @State private var browsing = false
  @FocusState private var queryFocused: Bool
  var body: some View {
    Group {
    if !model.connections.musicAccessAllowed {
      if model.connections.personalUnlocked {
        VStack(spacing:20) {
          AppHeader(title:"Apple Music")
          Text("Music source access is unavailable. Reconnect explicitly in Settings.")
          Button("Open Settings") { model.navigate(.settings) }
        }.padding(24)
      } else { DeviceUnlockView() }
    } else {
    VStack(spacing: 12) {
      AppHeader(title: "Apple Music", light: true)
      if model.connections.personalUnlocked && (browsing || model.connections.currentTrack == nil) {
        HStack {
          TextField("Search Apple Music", text: $query).textFieldStyle(.plain).focused(
            $queryFocused
          )
          .onSubmit { search() }
          .accessibilityIdentifier("music.search.input")
          .onChange(of:phase) { _,phase in if phase != .active { queryFocused=false } }
          Button("Search") { search() }.accessibilityIdentifier("music.search")
        }.font(.system(size: 22)).padding(18).background(.white.opacity(0.12), in: Capsule())
          .padding(
            .horizontal, 28)
      }
      if !browsing, let index = model.connections.currentTrack,
        model.connections.tracks.indices.contains(index)
      {
        let song = model.connections.tracks[index]
        artwork(song.artwork).frame(width: 200, height: 200).clipShape(
          RoundedRectangle(cornerRadius: 20))
          .overlay(alignment: .bottomTrailing) { MusicArtworkInfoButton(source: .catalog) }
        Text(song.title).font(.system(size: 27, weight: .semibold)).lineLimit(1)
          .accessibilityIdentifier("music.current.title")
        Text(song.artist).font(.system(size: 20)).opacity(0.7)
        HStack(spacing: 40) {
          Button {
            play(max(0, index - 1))
          } label: {
            Image(systemName: "backward.fill")
          }
          Button {
            model.togglePlayback()
          } label: {
            Image(systemName: model.connections.musicPlaying ? "pause.fill" : "play.fill")
          }.accessibilityIdentifier("music.connected.play").accessibilityLabel(
            model.connections.musicPlaying ? "Pause" : "Play")
          Button {
            play(min(model.connections.tracks.count - 1, index + 1))
          } label: {
            Image(systemName: "forward.fill")
          }
        }.font(.system(size: 32))
      }
      if browsing || model.connections.currentTrack == nil {
        ScrollView {
          VStack(spacing: 10) {
            ForEach(Array(model.connections.tracks.enumerated()), id: \.element.id) {
              index, track in
              Button {
                play(index)
              } label: {
                HStack(spacing: 16) {
                  artwork(track.artwork).frame(width: 52, height: 52).clipShape(
                    RoundedRectangle(cornerRadius: 9))
                  VStack(alignment: .leading) {
                    Text(track.title)
                    Text(track.artist).font(.system(size: 15)).opacity(0.6)
                  }
                  Spacer()
                  Image(systemName: "play.fill")
                }.font(.system(size: 21)).padding(.horizontal, 32)
              }.accessibilityIdentifier("music.result.\(index)")
            }
          }
        }
      } else if model.connections.personalUnlocked {
        Button("Browse Music") { browsing = true }.font(.system(size: 20))
          .accessibilityIdentifier("music.browse")
      }
      Text(model.connections.status[.music] ?? "Search for a song").font(.system(size: 16)).opacity(
        0.7
      ).padding(.bottom, 20)
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .foregroundStyle(.white).background(
        LinearGradient(
          colors: [.indigo, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
      ).buttonStyle(.plain)
    }
    }.onChange(of:model.connections.personalUnlocked) { _,unlocked in
      if !unlocked { query="";queryFocused=false;browsing=false }
    }
  }
  private func search() {
    queryFocused = false
    Task { await model.connections.searchMusic(query) }
  }
  private func play(_ index: Int) {
    model.stopAudioForVoice()
    browsing = false
    Task { await model.connections.playMusic(index) }
  }
  @ViewBuilder private func artwork(_ url: URL?) -> some View {
    if let url {
      AsyncImage(url: url) { phase in
        if let image = phase.image {
          image.resizable().scaledToFill()
        } else {
          Image(systemName: "music.note").font(.largeTitle)
        }
      }
    } else {
      Image(systemName: "music.note").resizable().scaledToFit().padding(12).background(
        .white.opacity(0.1))
    }
  }
}
