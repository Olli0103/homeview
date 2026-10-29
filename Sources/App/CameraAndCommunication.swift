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
  @Environment(\.nativeCanvasScale) private var canvasScale
  @Environment(\.dynamicTypeSize) private var textSize
  @ScaledMetric(relativeTo:.headline) private var headerSize:CGFloat=23
  @ScaledMetric(relativeTo:.title2) private var clockSize:CGFloat=22
  @ScaledMetric(relativeTo:.body) private var toggleSize:CGFloat=18
  @ScaledMetric(relativeTo:.body) private var tileSize:CGFloat=19
  @ScaledMetric(relativeTo:.caption) private var smallTileSize:CGFloat=14
  var isFace = false
  @State private var nine = false
  private var minimumControl:CGFloat {ceil(44 / max(canvasScale,0.001))}
  private func cameraTile(_ i:Int,height:CGFloat)->some View {
        Button {
          model.route = .camera(i)
        } label: {
          ZStack(alignment: .bottomLeading) {
            MockCameraScene(index: i)
              .overlay(alignment: .topTrailing) { DemoCameraBadge().padding(9) }
            Text(["Front Door", "Back Yard", "Living Room", "Driveway"][i % 4]).font(
              .system(size:isFace ? (nine ? 14:19):(nine ? smallTileSize:tileSize),weight:.medium)
            ).foregroundStyle(.white).padding(12)
              .background(model.data.night ? Color.black.opacity(0.95):Color.clear).shadow(radius: 2)
          }.frame(height:height).clipped().contentShape(Rectangle())
        }.frame(height:height).clipShape(RoundedRectangle(cornerRadius:24))
          .accessibilityIdentifier("camera.\(i)")
  }
  private func tiles(height:CGFloat)->some View {
    LazyVGrid(columns:Array(repeating:GridItem(.flexible(),spacing:7),count:nine ? 3:2),spacing:7) {
      ForEach(0..<(nine ? 9:4),id:\.self) {i in cameraTile(i,height:height)}
    }
  }
  var body: some View {
    ZStack(alignment: .top) {
      Color.black
      VStack(spacing: 8) {
        if !isFace {
          AppHeader(title:"Cameras",light:true,closeSize:max(48,minimumControl),
            titleFontSize:headerSize,clockFontSize:clockSize,accessibilityLayout:textSize.isAccessibilitySize)
          Button {nine.toggle()} label: {
            Text(nine ? "Show 4":"Show 9").font(.system(size:toggleSize))
              .frame(minWidth:minimumControl,minHeight:minimumControl).contentShape(Rectangle())
          }.foregroundStyle(.white).accessibilityIdentifier("camera.grid.size")
        }
        if isFace {
          tiles(height:288).padding(8)
        } else if textSize.isAccessibilitySize {
          ScrollView {
            // This finite demo list keeps every named slot in the AX tree;
            // lazy offscreen rows are not available to named navigation yet.
            VStack(spacing:7) {
              ForEach(0..<(nine ? 9:4),id:\.self) {i in cameraTile(i,height:180)}
            }.padding(15)
          }.accessibilityIdentifier("camera.grid.accessible.content")
        } else {
          // Reserve the actual header/control height, then fit every demo slot
          // inside the remaining canvas, including the final row's bottom edge.
          GeometryReader { geometry in
            let rows:CGFloat=nine ? 3:2
            tiles(height:max(1,(geometry.size.height-30-(rows-1)*7)/rows)).padding(15)
          }
        }
        Spacer(minLength: 0)
      }
    }.buttonStyle(.plain)
  }
}
struct CameraDetail: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  @Environment(\.dynamicTypeSize) private var textSize
  @ScaledMetric(relativeTo:.title) private var titleSize:CGFloat=29
  @ScaledMetric(relativeTo:.body) private var statusSize:CGFloat=17
  @ScaledMetric(relativeTo:.title2) private var timeSize:CGFloat=22
  @ScaledMetric(relativeTo:.headline) private var unavailableSize:CGFloat=25
  private var controlSize:CGFloat {max(62,ceil(44 / max(canvasScale,0.001)))}
  var index: Int
  var doorbell = false
  var onClose: (() -> Void)?
  var onGrid: (() -> Void)?
  var body:some View {
    ZStack {
      MockCameraScene(index:index)
      Group {
        if textSize.isAccessibilitySize {
          VStack(spacing:0) {
            ScrollView {
              VStack(spacing:0) {
                heading
                if !model.data.home.online {unavailable.padding(.vertical,20)}
              }
            }.accessibilityIdentifier("camera.detail.accessible.content")
            actions
          }
        } else {
          VStack {
            heading
            Spacer()
            if !model.data.home.online {unavailable;Spacer()}
            actions
          }
        }
      }.foregroundStyle(.white)
    }.onDisappear {model.talking=false}
  }
  private var heading:some View {
        HStack(alignment:textSize.isAccessibilitySize ? .top:.center) {
          VStack(alignment: .leading, spacing: 6) {
            Text(["Front Door", "Back Yard", "Living Room", "Driveway"][index % 4]).font(
              .system(size:titleSize,weight:.semibold))
            if doorbell {
              Text("Doorbell · DEMO").font(.system(size:statusSize,weight:.semibold))
                .accessibilityIdentifier("doorbell.demo.label")
            }
            Label(model.data.home.online ? "Demo still" : "Offline · Demo still", systemImage: "circle.fill")
              .font(.system(size:statusSize)).foregroundStyle(model.data.home.online ? .white : .orange)
              .accessibilityElement(children: .ignore)
              .accessibilityLabel(model.data.home.online ? "Demo still" : "Offline · Demo still")
              .accessibilityIdentifier("camera.demo.status")
              .accessibilityRespondsToUserInteraction(false)
          }
          Spacer()
          Text(model.dateLabel("h:mm")).font(.system(size:timeSize))
            .fixedSize(horizontal:textSize.isAccessibilitySize,vertical:textSize.isAccessibilitySize)
            .accessibilityIdentifier("camera.time")
        }.padding(34).background(
          LinearGradient(
            colors: [.black.opacity(0.6), .clear], startPoint: .top, endPoint: .bottom))
  }
  private var unavailable:some View {
    Text("Mock camera unavailable").font(.system(size:unavailableSize,weight:.semibold)).padding()
      .fixedSize(horizontal:false,vertical:textSize.isAccessibilitySize)
      .multilineTextAlignment(textSize.isAccessibilitySize ? .center:.leading)
      .background(.black.opacity(0.5),in:Capsule())
  }
  private var actions:some View {
        HStack {
          RoundButton(
            symbol: "xmark", color: .red, foreground: .white, size:controlSize, label: "Close camera"
          ) {
            model.talking = false
            if let onClose { onClose() } else { model.route = .personal }
          }.accessibilityIdentifier(doorbell ? "doorbell.dismiss":"camera.close")
          Spacer()
          RoundButton(
            symbol: model.talking ? "mic.fill" : "mic.slash.fill", color: .yellow,
            foreground: .black, size:controlSize, label: "Toggle mock talkback"
          ) {
            model.talking.toggle()
            model.banner(
              model.talking ? "Mock talkback active · No microphone used" : "Mock talkback off")
          }.accessibilityIdentifier("camera.talk")
            .accessibilityValue(model.talking ? "On (demo)":"Off (demo)")
          Spacer()
          RoundButton(
            symbol: "square.grid.2x2.fill", color: .white.opacity(0.2), foreground: .white,
            size:controlSize, label: "Camera grid"
          ) {
            model.talking = false
            if let onGrid { onGrid() } else { model.navigate(.cameras) }
          }.accessibilityIdentifier("camera.grid")
        }.padding(32).background(
          LinearGradient(
            colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom))
  }
}
struct IntercomView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.scenePhase) private var phase
  @FocusState private var inputFocused:Bool
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
      ).accessibilityIdentifier("intercom.input").focused($inputFocused)
        .onChange(of:phase) { _,phase in if phase != .active { inputFocused=false } }
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
  @Environment(\.scenePhase) private var phase
  @FocusState private var inputFocused:Bool
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
        TextField("Demo message", text: $text).font(.system(size: 22)).textFieldStyle(.plain).focused($inputFocused)
        .onChange(of:phase) { _,phase in if phase != .active { inputFocused=false } }
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
  @Environment(\.openURL) private var openURL
  @State private var websiteStatus=""
  var body: some View {
    VStack(spacing: 14) {
      AppHeader(title: "Find My")
      Text("Local demo · No Apple location data")
        .font(.system(size:20,weight:.semibold)).multilineTextAlignment(.center)
        .accessibilityIdentifier("findmy.demo.scope")
      if !websiteStatus.isEmpty {
        Text(websiteStatus).font(.system(size:17)).multilineTextAlignment(.center)
          .padding(.horizontal,24).accessibilityIdentifier("findmy.website.status")
      }
      ScrollView {
        VStack(spacing:16) {
          ZStack {
            Color(red:0.86,green:0.91,blue:0.85)
            ForEach(0..<6) { i in
              Rectangle().fill(.white.opacity(0.7)).frame(height:12).rotationEffect(.degrees(-25))
                .offset(y:CGFloat(i)*68-180)
            }
            Image(systemName:"mappin.circle.fill").font(.system(size:65)).foregroundStyle(.green)
            VStack { Spacer();Text("SCHEMATIC DEMO · NOT LIVE")
              .font(.system(size:17,weight:.semibold)).padding(10)
              .background(.white.opacity(0.9),in:Capsule()).padding(12) }
          }.frame(height:180).clipShape(RoundedRectangle(cornerRadius:25))
            .accessibilityElement(children:.ignore)
            .accessibilityLabel("Schematic demo map. No live location.")
            .accessibilityIdentifier("findmy.demo.map")
          Text("Demo Keys").font(.system(size:30,weight:.semibold))
          Text("Simulated item · Living Room").font(.system(size:21)).foregroundStyle(.secondary)
          Pill(title:"Play local demo tone",symbol:"speaker.wave.2.fill") {
            model.playChime()
            model.banner("Local demo tone requested · No remote item contacted")
          }.accessibilityIdentifier("findmy.demo.sound")
          Text("The demo tone uses this device only, never an AirTag.")
            .font(.system(size:18)).foregroundStyle(.secondary)
          Divider()
          Text("This website is for Apple devices. Use Apple's Find My app for AirTags or shared people. It opens outside HomeView; no locations are imported here.")
            .font(.system(size:18)).foregroundStyle(.secondary)
            .accessibilityIdentifier("findmy.website.scope")
          Button("Open Apple's Find Devices website") { openFindDevices() }
            .font(.system(size:21,weight:.medium)).frame(maxWidth:.infinity,minHeight:72)
            .accessibilityIdentifier("findmy.apple.website")
        }.padding(.horizontal,30).padding(.bottom,96)
      }
    }.background(.white).foregroundStyle(.black)
  }
  private func openFindDevices() {
    guard !ProcessInfo.processInfo.arguments.contains("--uitesting") else {
      websiteStatus="Find Devices website not opened in tests";return
    }
    // Public Apple website, not a private native-app scheme or account API.
    openURL(URL(string:"https://www.icloud.com/find/")!) { accepted in
      websiteStatus=accepted
        ? "Website handoff accepted · No location data returned to HomeView"
        : "Find Devices website could not be opened."
    }
  }
}
