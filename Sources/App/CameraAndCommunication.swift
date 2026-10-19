import SwiftUI

/// Bundled generated stills only. This view never opens a camera or a stream.
struct MockCameraScene: View {
  var index: Int
  private var asset: String {
    ["DemoCameraFrontDoorV1", "DemoCameraBackYardV1", "DemoCameraLivingRoomV1", "DemoCameraDrivewayV1"][(index % 4 + 4) % 4]
  }
  var body: some View {
    GeometryReader { geometry in
      Image(asset).resizable().scaledToFill()
        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("AI-generated demo still, no camera access")
  }
}
struct DemoCameraBadge: View {
  var body: some View {
    Text("DEMO").font(.system(size: 9, weight: .semibold))
      .foregroundStyle(.white).padding(.horizontal, 6).padding(.vertical, 3)
      .background(.black.opacity(0.55), in: Capsule()).accessibilityHidden(true)
  }
}
struct CameraGrid: View {
  @Environment(AppModel.self) private var model
  var isFace = false
  @State private var nine = false
  var body: some View {
    ZStack(alignment: .top) {
      Color.black
      VStack(spacing: 8) {
        if !isFace {
          AppHeader(title: "Cameras", light: true)
          Button(nine ? "Show 4" : "Show 9") { nine.toggle() }.font(.system(size: 18))
            .foregroundStyle(.white).accessibilityIdentifier("camera.grid.size")
        }
        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: nine ? 3 : 2),
          spacing: 7
        ) {
          ForEach(0..<(nine ? 9 : 4), id: \.self) { i in
            Button {
              model.route = .camera(i)
            } label: {
              ZStack(alignment: .bottomLeading) {
                MockCameraScene(index: i)
                  .overlay(alignment: .topTrailing) { DemoCameraBadge().padding(9) }
                Text(["Front Door", "Back Yard", "Living Room", "Driveway"][i % 4]).font(
                  .system(size: nine ? 14 : 19, weight: .medium)
                ).foregroundStyle(.white).padding(12).shadow(radius: 2)
              }
            }.frame(height: nine ? 150 : (isFace ? 288 : 225)).clipShape(
              RoundedRectangle(cornerRadius: 24)
            ).accessibilityIdentifier("camera.\(i)")
          }
        }.padding(isFace ? 8 : 15)
        Spacer(minLength: 0)
      }
    }.buttonStyle(.plain)
  }
}
struct CameraDetail: View {
  @Environment(AppModel.self) private var model
  var index: Int
  var doorbell = false
  var onClose: (() -> Void)?
  var onGrid: (() -> Void)?
  var body: some View {
    ZStack {
      MockCameraScene(index: index)
      VStack {
        HStack {
          VStack(alignment: .leading, spacing: 6) {
            Text(["Front Door", "Back Yard", "Living Room", "Driveway"][index % 4]).font(
              .system(size: 29, weight: .semibold))
            if doorbell {
              Text("Doorbell · DEMO").font(.system(size:17,weight:.semibold))
                .accessibilityIdentifier("doorbell.demo.label")
            }
            Label(model.data.home.online ? "Demo still" : "Offline · Demo still", systemImage: "circle.fill")
              .font(.system(size: 17)).foregroundStyle(model.data.home.online ? .white : .orange)
              .accessibilityElement(children: .ignore)
              .accessibilityLabel(model.data.home.online ? "Demo still" : "Offline · Demo still")
              .accessibilityIdentifier("camera.demo.status")
          }
          Spacer()
          Text(model.dateLabel("h:mm")).font(.system(size: 22))
            .accessibilityIdentifier("camera.time")
        }.padding(34).background(
          LinearGradient(
            colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))
        Spacer()
        if !model.data.home.online {
          Text("Mock camera unavailable").font(.system(size: 25, weight: .semibold)).padding()
            .background(.black.opacity(0.5), in: Capsule())
          Spacer()
        }
        HStack {
          RoundButton(
            symbol: "xmark", color: .red, foreground: .white, size: 62, label: "Close camera"
          ) {
            model.talking = false
            if let onClose { onClose() } else { model.route = .personal }
          }.accessibilityIdentifier(doorbell ? "doorbell.dismiss":"camera.close")
          Spacer()
          RoundButton(
            symbol: model.talking ? "mic.fill" : "mic.slash.fill", color: .yellow,
            foreground: .black, size: 62, label: "Toggle mock talkback"
          ) {
            model.talking.toggle()
            model.banner(
              model.talking ? "Mock talkback active · No microphone used" : "Mock talkback off")
          }.accessibilityIdentifier("camera.talk")
          Spacer()
          RoundButton(
            symbol: "square.grid.2x2.fill", color: .white.opacity(0.2), foreground: .white,
            size: 62, label: "Camera grid"
          ) {
            model.talking = false
            if let onGrid { onGrid() } else { model.navigate(.cameras) }
          }.accessibilityIdentifier("camera.grid")
        }.padding(32).background(
          LinearGradient(
            colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
      }.foregroundStyle(.white)
    }.onDisappear { model.talking = false }
  }
}
struct IntercomView: View {
  @Environment(AppModel.self) private var model
  @State private var text = "Dinner is ready!"
  var body: some View {
    VStack(spacing: 22) {
      AppHeader(title: "Intercom")
      Image(systemName: "waveform").font(.system(size: 76)).foregroundStyle(.orange).padding(
        .top, 20)
      Text("Everywhere").font(.system(size: 34, weight: .semibold))
      TextField("Announcement", text: $text).textFieldStyle(.plain).font(.system(size: 25)).padding(
        20
      ).background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 20)).padding(
        .horizontal, 32
      ).accessibilityIdentifier("intercom.input")
      Pill(
        title: "Send Demo Announcement", symbol: "paperplane.fill", tint: .orange, textColor: .white
      ) {
        if !text.isEmpty {
          model.intercomHistory.insert(text, at: 0)
          model.banner("Sent to simulated rooms only")
        }
      }.padding(.horizontal, 32).accessibilityIdentifier("intercom.send")
      ScrollView {
        ForEach(model.intercomHistory, id: \.self) { item in
          Text(item).font(.system(size: 20)).frame(maxWidth: .infinity, alignment: .leading)
            .padding(16).background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
            .padding(.horizontal, 32)
        }
      }
      Text("Local simulation. Not connected to HomePod Intercom.").font(.system(size: 16))
        .foregroundStyle(.gray).padding(.bottom, 24)
    }.background(.white).foregroundStyle(.black)
  }
}
struct MessagesView: View {
  @Environment(AppModel.self) private var model
  @State private var text = ""
  var body: some View {
    VStack(spacing: 18) {
      AppHeader(title: "Jamie · Demo")
      ScrollView {
        VStack(spacing: 15) {
          ForEach(Array(model.messages.enumerated()), id: \.offset) { i, message in
            HStack {
              if i % 2 == 1 { Spacer(minLength: 65) }
              Text(message).font(.system(size: 25)).padding(18).background(
                i % 2 == 1 ? Color.blue : Color(white: 0.9), in: RoundedRectangle(cornerRadius: 25)
              ).foregroundStyle(i % 2 == 1 ? .white : .black)
              if i % 2 == 0 { Spacer(minLength: 65) }
            }
          }
        }.padding(.horizontal, 30)
      }
      HStack {
        TextField("Demo message", text: $text).font(.system(size: 22)).textFieldStyle(.plain)
        RoundButton(
          symbol: "arrow.up", color: .blue, foreground: .white, label: "Send demo message"
        ) {
          if !text.isEmpty,model.appendLocalMessage(text) { text = "" }
        }
      }.padding(30)
      SystemMessageButton(draft: text)
      Text("Local mock conversation. No Messages history access.").font(.system(size: 15))
        .foregroundStyle(.gray).padding(.bottom, 20)
    }.background(.white).foregroundStyle(.black)
  }
}
struct CallView: View {
  @Environment(AppModel.self) private var model
  var incoming: Bool
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [.teal, Color(red: 0.1, green: 0.25, blue: 0.3)], startPoint: .topLeading,
        endPoint: .bottomTrailing)
      VStack(spacing: 20) {
        Text(incoming ? "Jamie · Demo" : "Demo call with Jamie").font(.system(size: 36, weight: .semibold))
          .padding(.top, 50)
        Text(
          incoming ? "Incoming local demo · No connection" : "Local call simulation · No connection"
        ).font(.system(size: 19)).opacity(0.65)
        Spacer()
        Image(systemName: "person.crop.circle.fill").font(.system(size: 175)).foregroundStyle(
          .white.opacity(0.45))
        Spacer()
        HStack(spacing: 60) {
          if !incoming {
            RoundButton(
              symbol: model.muted ? "mic.slash.fill" : "mic.fill", color: .white.opacity(0.2),
              foreground: .white, size: 65, label: "Toggle demo microphone"
            ) { model.muted.toggle() }
              .accessibilityIdentifier("call.demo.microphone")
              .accessibilityValue(model.muted ? "Muted (demo)":"On (demo)")
            RoundButton(
              symbol: model.videoEnabled ? "video.fill" : "video.slash.fill",
              color: .white.opacity(0.2), foreground: .white, size: 65, label: "Toggle demo video"
            ) { model.videoEnabled.toggle() }
              .accessibilityIdentifier("call.demo.video")
              .accessibilityValue(model.videoEnabled ? "On (demo)":"Off (demo)")
          }
          RoundButton(
            symbol: "phone.down.fill", color: .red, foreground: .white, size: 65,
            label: incoming ? "Decline demo call" : "End demo call"
          ) {
            model.incomingCall = false
            model.route = .personal
          }.accessibilityIdentifier("call.end")
          if incoming {
            RoundButton(
              symbol: "phone.fill", color: .green, foreground: .white, size: 65,
              label: "Accept demo call"
            ) {
              model.incomingCall = false
              model.route = .call
            }.accessibilityIdentifier("call.accept")
          }
        }.padding(.bottom, 40)
      }
    }.foregroundStyle(.white)
  }
}
struct FindMyView: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    VStack(spacing: 20) {
      AppHeader(title: "Find My")
      ZStack {
        Color(red: 0.86, green: 0.91, blue: 0.85)
        ForEach(0..<6) { i in
          Rectangle().fill(.white.opacity(0.7)).frame(height: 12).rotationEffect(.degrees(-25))
            .offset(y: CGFloat(i) * 68 - 180)
        }
        Image(systemName: "mappin.circle.fill").font(.system(size: 75)).foregroundStyle(.green)
      }.frame(height: 240).clipShape(RoundedRectangle(cornerRadius: 25)).padding(.horizontal, 30)
      Text("Demo Keys").font(.system(size: 33, weight: .semibold))
      Text("Simulated item · Living Room").font(.system(size: 21)).foregroundStyle(.gray)
      Pill(title: "Play Demo Sound", symbol: "speaker.wave.2.fill") {
        model.playChime()
        model.banner("Sound played on this device only")
      }.padding(.horizontal, 32)
      Text("No access to real AirTags, devices or people.").font(.system(size: 16)).foregroundStyle(
        .gray)
      Spacer()
    }.background(.white).foregroundStyle(.black)
  }
}
