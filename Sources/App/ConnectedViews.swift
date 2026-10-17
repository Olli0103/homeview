import SwiftUI

struct ConnectionControls: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Connected services").font(.system(size: 24, weight: .semibold))
      Label("Apple Home stays disconnected", systemImage: "house.badge.exclamationmark")
        .font(.system(size: 19)).foregroundStyle(.gray).accessibilityIdentifier(
          "connections.home.locked")
      Text(
        "Calendar and reminders are protected by your device authentication. Other Apple apps' private history is not imported."
      )
      .font(.system(size: 17)).foregroundStyle(.gray)
      ForEach(DataConnection.allCases) { kind in
        VStack(alignment: .leading, spacing: 7) {
          HStack {
            Text(kind.rawValue).font(.system(size: 22, weight: .medium))
            Spacer()
            let on = model.connections.enabled.contains(kind)
            Button(on ? "Disconnect" : "Connect") {
              if on {
                model.connections.disconnect(kind)
              } else {
                Task { await model.connections.connect(kind, date: model.clock) }
              }
            }.disabled(model.connections.busy.contains(kind))
              .accessibilityIdentifier("connect.\(kind.rawValue)")
          }
          Text(model.connections.status[kind] ?? "Not connected").font(.system(size: 16))
            .foregroundStyle(.gray)
            .accessibilityIdentifier("connection.status.\(kind.rawValue)")
          if kind == .weather {
            TextField(
              "City",
              text: Binding(get: { model.connections.city }, set: { model.connections.city = $0 })
            )
            .textFieldStyle(.plain).padding(10).background(
              .gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 10)
            ).accessibilityIdentifier("weather.city")
            Link("Weather data by Open-Meteo", destination: URL(string: "https://open-meteo.com/")!)
              .font(.system(size: 15))
            if model.connections.enabled.contains(.weather) {
              Button("Update weather") { Task { await model.connections.connect(.weather) } }
            }
          }
        }
        Divider()
      }
    }
  }
}
struct DeviceUnlockView: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 24) {
      AppHeader(title: "Personal access")
      Spacer()
      Image(systemName: "lock.shield").font(.system(size: 76)).foregroundStyle(.blue)
      Text("Unlock personal data").font(.system(size: 33, weight: .semibold))
      Text("Use this device's authentication to view your connected calendar and reminders.")
        .font(.system(size: 22)).multilineTextAlignment(.center).foregroundStyle(.gray)
      Pill(
        title: "Unlock", symbol: "person.crop.circle.badge.checkmark", tint: .blue,
        textColor: .white
      ) {
        Task {
          if await model.connections.unlock() {
            if let page = model.pendingPage {
              model.route = .app(page)
              model.pendingPage = nil
            }
          } else {
            model.error = "Personal access was not unlocked."
          }
        }
      }.accessibilityIdentifier("device.unlock")
      Spacer()
    }.padding(.horizontal, 32).background(.white).foregroundStyle(.black)
  }
}
struct DeviceRemindersView: View {
  @Environment(AppModel.self) private var model
  @State private var title = ""
  @FocusState private var inputFocused: Bool
  var body: some View {
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
                    Text(item.title).strikethrough(item.completed)
                    Spacer()
                  }
                }.accessibilityIdentifier("device.reminder.\(item.title)")
                  .accessibilityValue(item.completed ? "Completed" : "Open")
                Button {
                  Task { await model.connections.removeReminder(item) }
                } label: {
                  Image(systemName: "minus.circle").foregroundStyle(.gray)
                }.accessibilityLabel("Delete \(item.title)")
              }.font(.system(size: 23)).padding(.vertical, 12)
              Divider()
            }
          }.padding(.horizontal, 32)
        }
        Text(model.connections.status[.reminders] ?? "").font(.system(size: 16)).foregroundStyle(
          .gray
        ).padding(.horizontal, 32)
        HStack {
          TextField("New reminder", text: $title).textFieldStyle(.plain).focused($inputFocused)
            .accessibilityIdentifier(
              "device.reminder.input")
          RoundButton(symbol: "plus", color: .orange.opacity(0.2), label: "Add reminder") {
            let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            inputFocused = false
            Task {
              await model.connections.addReminder(value)
              title = ""
            }
          }.accessibilityIdentifier("device.reminder.add")
        }.font(.system(size: 22)).padding(30)
          .disabled(model.connections.busy.contains(.reminders))
      }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
        .task { await model.connections.refreshReminders() }
    }
  }
}
struct DeviceMusicView: View {
  @Environment(AppModel.self) private var model
  @State private var query = ""
  @State private var browsing = true
  @FocusState private var queryFocused: Bool
  var body: some View {
    VStack(spacing: 12) {
      AppHeader(title: "Apple Music", light: true)
      if browsing || model.connections.currentTrack == nil {
        HStack {
          TextField("Search Apple Music", text: $query).textFieldStyle(.plain).focused(
            $queryFocused
          )
          .onSubmit { search() }
          .accessibilityIdentifier("music.search.input")
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
            Task { await model.connections.toggleMusic() }
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
      } else {
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
