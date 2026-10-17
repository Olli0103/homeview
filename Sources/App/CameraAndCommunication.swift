import SwiftUI

struct MockCameraScene: View {
  var index: Int
  var body: some View {
    GeometryReader { g in
      ZStack {
        LinearGradient(
          colors: [
            Color(red: 0.75, green: 0.78, blue: 0.72), Color(red: 0.35, green: 0.44, blue: 0.35),
          ], startPoint: .top, endPoint: .bottom)
        Canvas { c, s in
          let wall = CGRect(
            x: s.width * 0.12, y: s.height * 0.08, width: s.width * 0.75, height: s.height * 0.67)
          c.fill(Path(wall), with: .color(Color(red: 0.8, green: 0.76, blue: 0.65)))
          c.fill(
            Path(
              CGRect(
                x: s.width * 0.43, y: s.height * 0.25, width: s.width * 0.22, height: s.height * 0.5
              )), with: .color(Color(red: 0.24, green: 0.29, blue: 0.28)))
          c.fill(
            Path(
              CGRect(
                x: s.width * 0.19, y: s.height * 0.23, width: s.width * 0.17,
                height: s.height * 0.22)), with: .color(.cyan.opacity(0.3)))
          var path = Path()
          path.move(to: .init(x: 0, y: s.height))
          path.addLine(to: .init(x: s.width * 0.42, y: s.height * 0.73))
          path.addLine(to: .init(x: s.width * 0.67, y: s.height * 0.73))
          path.addLine(to: .init(x: s.width, y: s.height))
          path.closeSubpath()
          c.fill(path, with: .color(.gray.opacity(0.7)))
        }
        Image(systemName: index == 1 ? "tree.fill" : "leaf.fill").font(
          .system(size: g.size.width * 0.25)
        ).foregroundStyle(Color(red: 0.21, green: 0.37, blue: 0.23)).position(
          x: g.size.width * 0.84, y: g.size.height * 0.58)
        Text("MOCK FEED \(index+1)").font(
          .system(size: max(9, g.size.width * 0.025), weight: .semibold, design: .monospaced)
        ).foregroundStyle(.white.opacity(0.6)).position(
          x: g.size.width * 0.23, y: g.size.height * 0.94)
      }
    }.clipped().accessibilityLabel("Synthetic camera image, no camera access")
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
            .foregroundStyle(.white)
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
  var body: some View {
    ZStack {
      MockCameraScene(index: index)
      VStack {
        HStack {
          VStack(alignment: .leading, spacing: 6) {
            Text(["Front Door", "Back Yard", "Living Room", "Driveway"][index % 4]).font(
              .system(size: 29, weight: .semibold))
            Label(model.data.home.online ? "Mock Live" : "Offline", systemImage: "circle.fill")
              .font(.system(size: 17)).foregroundStyle(model.data.home.online ? .white : .orange)
          }
          Spacer()
          Text(model.clock, style: .time).font(.system(size: 22))
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
          ) { model.route = .personal }
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
          ) { model.navigate(.cameras) }.accessibilityIdentifier("camera.grid")
        }.padding(32).background(
          LinearGradient(
            colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
      }.foregroundStyle(.white)
    }
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
          if !text.isEmpty {
            model.messages.append(text)
            text = ""
          }
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
        Text(incoming ? "Jamie" : "Demo call with Jamie").font(.system(size: 36, weight: .semibold))
          .padding(.top, 50)
        Text(
          incoming ? "Incoming simulated FaceTime call" : "Local call simulation · No connection"
        ).font(.system(size: 19)).opacity(0.65)
        Spacer()
        Image(systemName: "person.crop.circle.fill").font(.system(size: 175)).foregroundStyle(
          .white.opacity(0.45))
        Spacer()
        HStack(spacing: 60) {
          if !incoming {
            RoundButton(
              symbol: model.muted ? "mic.slash.fill" : "mic.fill", color: .white.opacity(0.2),
              foreground: .white, size: 65, label: "Toggle microphone"
            ) { model.muted.toggle() }
            RoundButton(
              symbol: model.videoEnabled ? "video.fill" : "video.slash.fill",
              color: .white.opacity(0.2), foreground: .white, size: 65, label: "Toggle video"
            ) { model.videoEnabled.toggle() }
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
