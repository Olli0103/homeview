import Combine
import SwiftUI

struct RootView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private var animate: Bool {
    let args = ProcessInfo.processInfo.arguments
    return !reduceMotion && !args.contains("--reduce-motion")
      && (!args.contains("--uitesting") || args.contains("--animation-test"))
  }
  private var screenTransition: AnyTransition {
    switch model.route {
    case .drawer, .personal: .move(edge: .bottom).combined(with: .opacity)
    case .assistant, .controlCenter: .move(edge: .top).combined(with: .opacity)
    default: .opacity.combined(with: .scale(scale: 0.975))
    }
  }
  private let pulse = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  var body: some View {
    GeometryReader { geo in
      let edge = max(150, min(geo.size.width - 24, geo.size.height - 64))
      VStack(spacing: 12) {
        Spacer(minLength: 0)
        ZStack {
          screen.id(String(describing: model.route))
          .allowsHitTesting(model.demoDoorbell.current == nil)
          .accessibilityHidden(model.demoDoorbell.current != nil)
          .transition(
            animate ? screenTransition : .identity
          )
          .animation(
            animate ? .spring(response: 0.43, dampingFraction: 0.92) : nil, value: model.route
          )
          if let bell = model.demoDoorbell.current {
            CameraDetail(index:bell.cameraIndex,doorbell:true,
              onClose:{ model.dismissDemoDoorbell() },
              onGrid:{ model.dismissDemoDoorbell();model.navigate(.cameras) })
              .transition(.opacity).accessibilityElement(children:.contain)
              .accessibilityIdentifier("doorbell.overlay")
          }
          if model.route == .face && model.demoDoorbell.current == nil
            && (model.playing || model.podcastPlaying || model.connections.musicPlaying
              || model.data.timers.contains(where: { $0.remaining(at: model.now) > 0 }))
          {
            VStack {
              ActivityStrip().frame(maxWidth: 300).background(.thinMaterial, in: Capsule())
              Spacer()
            }
            .padding(.top, 6).accessibilityIdentifier("compact.activity")
          }
          Color.black.opacity((1 - model.data.screenBrightness) * 0.45).allowsHitTesting(false)
          if !model.data.home.online {
            VStack {
              Text("Mock home offline").font(.system(size: 16, weight: .semibold)).padding(10)
                .background(.orange, in: Capsule())
              Spacer()
            }.padding(.top, 8).allowsHitTesting(false)
          }
          if let toast = model.toast {
            VStack {
              Spacer()
              Text(toast).font(.system(size: 18, weight: .medium)).padding(18).background(
                .ultraThinMaterial, in: Capsule()
              ).padding(30)
            }.allowsHitTesting(false)
          }
          #if !os(tvOS)
            if model.route != .face {
              VStack {
              Spacer()
              Color.clear.frame(height: 16).contentShape(Rectangle())
                .gesture(
                  DragGesture(minimumDistance: 20).onEnded { value in
                    if value.translation.height < -35 { model.homeGesture() }
                  })
              }
            }
          #endif
          if model.incomingCall { CallView(incoming: true) }
        }
        .frame(width: 600, height: 600)
        .background(.white).clipShape(RoundedRectangle(cornerRadius: 84, style: .continuous))
        // Night mode includes activity, status banners and toasts, not only the screen.
        .saturation(model.data.night ? 0 : 1).colorMultiply(model.data.night ? .red : .white)
        .environment(\.colorScheme, .light)
        .scaleEffect(edge / 600)
        .frame(width: edge, height: edge)
        .overlay {
          if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            NativeViewportMarker().frame(width: edge, height: edge).allowsHitTesting(false)
          }
        }
        #if !os(tvOS)
          // Faces have no scrolling content. Their drag must cancel underlying
          // tile taps; other screens keep normal scrolling and their bottom strip.
          .highPriorityGesture(viewportNavigation(edge: edge), including: model.route == .face ? .all : .subviews)
          .simultaneousGesture(viewportNavigation(edge: edge), including: model.route == .face ? .subviews : .all)
        #endif
        .simultaneousGesture(TapGesture().onEnded { model.interact() })
        HStack(spacing: 24) {
          Button {
            model.dismissDemoDoorbell()
            model.route = .face
          } label: {
            Image(systemName: "rectangle.on.rectangle")
          }.accessibilityLabel("Faces").accessibilityIdentifier("nav.faces")
          Button {
            model.homeGesture()
          } label: {
            Image(systemName: "circle.grid.3x3.fill")
          }.accessibilityLabel("Apps").accessibilityIdentifier("nav.apps")
          Text("MOCK HOME").font(.system(size: 10, weight: .semibold)).tracking(2).foregroundStyle(
            .gray
          ).accessibilityIdentifier("mock.badge")
          Button {
            model.dismissDemoDoorbell()
            model.route = .assistant
          } label: {
            Image(systemName: "waveform")
          }.accessibilityLabel("Assistant").accessibilityIdentifier("nav.assistant")
          Button {
            model.dismissDemoDoorbell()
            model.route = .controlCenter
          } label: {
            Image(systemName: "switch.2")
          }.accessibilityLabel("Control Center").accessibilityIdentifier("nav.controls")
        }.font(.system(size: 18)).foregroundStyle(.white.opacity(0.7)).buttonStyle(.plain).frame(
          height: 30)
        if ProcessInfo.processInfo.arguments.contains("--uitesting"),
           ProcessInfo.processInfo.arguments.contains("--doorbell-fixture") {
          VStack(spacing:2) {
          HStack {
            Button("Bell") { model.simulateDoorbell() }.accessibilityIdentifier("fixture.doorbell.new")
            Button("Repeat ID") { model.simulateDoorbell(repeatFixture:true) }.accessibilityIdentifier("fixture.doorbell.repeat")
            Button("Offline") { model.data.home.online = false }.accessibilityIdentifier("fixture.doorbell.offline")
            Button("Call") { model.incomingCall = true }.accessibilityIdentifier("fixture.doorbell.call")
            Button("Finish timer") { model.finishTimerForDoorbellFixture() }
              .accessibilityIdentifier("fixture.doorbell.finishTimer")
          }.font(.system(size:12)).foregroundStyle(.white)
          Text(verbatim:model.doorbellFixtureRoute).font(.system(size:1))
            .foregroundStyle(.clear).allowsHitTesting(false)
            .accessibilityIdentifier("fixture.doorbell.route")
          }
        }
        if model.storeReadOnly {
          Text("Read-only saved data · Changes are temporary")
            .font(.system(size: 12)).foregroundStyle(.orange)
            .accessibilityIdentifier("store.readOnly")
        }
        Spacer(minLength: 0)
      }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .overlay {
      if scenePhase != .active {
        ZStack {
          Color.black
          Label("HomeView locked", systemImage: "lock.shield")
            .font(.title2).foregroundStyle(.white)
        }.ignoresSafeArea().accessibilityIdentifier("privacy.snapshot.shield")
      }
    }
    .background(Color(white: 0.025)).preferredColorScheme(.dark)
    .task {
      model.setAlbumDisplayActive(scenePhase == .active)
      await model.connections.restore()
      model.reconcileSystemAlarms()
      model.display.apply(enabled: model.data.keepDisplayOn && scenePhase == .active)
    }
    .onReceive(pulse) { _ in model.tick() }
    .onChange(of: model.route) { _, route in if route == .privacy { model.lockPersonalAccess() } }
    .onChange(of:model.incomingCall) { _,incoming in if incoming { model.dismissDemoDoorbell() } }
    .onChange(of: model.data.keepDisplayOn) { _, enabled in
      model.display.apply(enabled: enabled && scenePhase == .active)
    }
    .onChange(of: model.connections.personalUnlocked) { _, unlocked in
      if !unlocked { model.albumCatalogue.invalidate() }
    }
    .onDisappear {
      model.dismissDemoDoorbell()
      model.display.apply(enabled: false)
      model.setAlbumDisplayActive(false)
    }
    .onChange(of: scenePhase) { _, phase in
      model.setAlbumDisplayActive(phase == .active)
      model.display.apply(enabled: model.data.keepDisplayOn && phase == .active)
      if phase == .active {
        model.reconcileSystemAlarms()
      } else if phase == .background {
        model.persist()
        model.lockPersonalAccess()
        if case .app(let page) = model.route, page.isPersonal {
          model.pendingPage = page
          model.route = .privacy
        }
      }
    }
    .alert(
      "HomeView",
      isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })
    ) {
      Button("OK") { model.error = nil }
    } message: {
      Text(model.error ?? "")
    }
    #if os(tvOS)
      .onExitCommand { model.homeGesture() }
      .onMoveCommand { direction in
        guard model.route == .face else { return }
        if direction == .left { model.nextFace(-1) }
        if direction == .right { model.nextFace(1) }
      }
      .onPlayPauseCommand { model.togglePlayback() }
    #endif
  }
  #if !os(tvOS)
    private func viewportNavigation(edge: Double) -> some Gesture {
      DragGesture(minimumDistance: 45).onEnded { value in
        model.interact()
        // One dominant axis owns each completed drag. Existing distances and
        // edge regions stay in the displayed square's coordinate system.
        switch ViewportNavigationIntent.choose(startX:value.startLocation.x,
          startY:value.startLocation.y,dx:value.translation.width,dy:value.translation.height,
          edge:edge,isFace:model.route == .face) {
        case .home: model.homeGesture()
        case .assistant: model.route = .assistant
        case .controlCenter: model.route = .controlCenter
        case .face(let direction):
          withAnimation(.easeInOut(duration: 0.3)) {
            model.nextFace(direction)
          }
        case nil: break
        }
      }
    }
  #endif
  @ViewBuilder private var screen: some View {
    switch model.route {
    case .face:
      FaceView(selection: model.data.face).id(model.data.face.id)
        .transition(
          animate
            ? .asymmetric(
              insertion: .move(edge: model.faceDirection > 0 ? .trailing : .leading),
              removal: .move(edge: model.faceDirection > 0 ? .leading : .trailing)) : .identity
        )
        .animation(
          animate ? .spring(response: 0.46, dampingFraction: 0.95) : nil, value: model.data.face
        )
        .highPriorityGesture(
          LongPressGesture(minimumDuration: 0.65).onEnded { _ in model.route = .editor })
    case .personal: PersonalView()
    case .drawer: AppDrawer()
    case .app(let page): AppContent(page: page)
    case .thermostat: ThermostatView()
    case .light: LightView()
    case .lock: LockView()
    case .camera(let index): CameraDetail(index: index)
    case .recipe: RecipeCover()
    case .ingredients: IngredientsView()
    case .cooking: CookingView()
    case .assistant: AssistantView()
    case .editor: FaceEditor()
    case .controlCenter: ControlCenterView()
    case .privacy: PrivacyView()
    case .deviceUnlock: DeviceUnlockView()
    case .call: CallView(incoming: false)
    }
  }
}
