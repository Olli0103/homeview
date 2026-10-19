import AVFoundation
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
  @State private var assistantFocusRequest=0
  private var assistantShortcutRevision:UInt64 {
    #if os(iOS) || os(macOS) || os(visionOS)
      AssistantShortcutRequest.shared.revision
    #else
      0
    #endif
  }
  private func openAssistant() {
    model.dismissDemoDoorbell()
    model.route = .assistant
    assistantFocusRequest+=1
  }
  private func consumeAssistantShortcut() {
    #if os(iOS) || os(macOS) || os(visionOS)
      if scenePhase == .active,AssistantShortcutRequest.shared.consume() { openAssistant() }
    #endif
  }
  private let pulse = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  private var viewportContent: some View {
    GeometryReader { geo in
      let edge = max(150, min(geo.size.width - 24, geo.size.height - 64))
      // The assistant is an input surface, not a scaled clock face. Keep
      // native-sized controls above the keyboard, using available width.
      let assistantLayout = model.route == .assistant
      let contentWidth = assistantLayout ? max(150,min(796,geo.size.width-24)):600
      let contentHeight = assistantLayout ? max(150,min(796,geo.size.height-96)):600
      let displayedWidth = assistantLayout ? contentWidth:edge
      let displayedHeight = assistantLayout ? contentHeight:edge
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
            && (model.playing || model.podcastPlaying || model.musicIsPlaying
              || model.data.timers.contains(where: { $0.remaining(at: model.now) > 0 }))
          {
            VStack {
              ActivityStrip().frame(maxWidth: 300).background(.thinMaterial, in: Capsule())
              Spacer()
            }
            .padding(.top, 6).accessibilityElement(children:.contain).accessibilityIdentifier("compact.activity")
          }
          Color.black.opacity((1 - model.data.screenBrightness) * 0.45).allowsHitTesting(false)
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
        .frame(width: contentWidth, height: contentHeight)
        .background(.white).clipShape(RoundedRectangle(cornerRadius: 84, style: .continuous))
        // Night mode includes activity, status banners and toasts, not only the screen.
        .saturation(model.data.night ? 0 : 1)
        .colorMultiply(model.data.night ? Color(red: 1, green: 0, blue: 0) : .white)
        .environment(\.colorScheme, .light)
        .environment(\.nativeCanvasScale, assistantLayout ? 1:edge / 600)
        .scaleEffect(assistantLayout ? 1:edge / 600)
        .frame(width: displayedWidth, height: displayedHeight)
        .overlay {
          if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            NativeViewportMarker().frame(width: displayedWidth, height: displayedHeight).allowsHitTesting(false)
          }
        }
        #if !os(tvOS)
          // Faces have no scrolling content. Their drag must cancel underlying
          // tile taps; other screens keep normal scrolling and their bottom strip.
          .highPriorityGesture(viewportNavigation(width: displayedWidth,height: displayedHeight), including: model.route == .face ? .all : .subviews)
          .simultaneousGesture(viewportNavigation(width: displayedWidth,height: displayedHeight), including: model.route == .face ? .subviews : .all)
        #endif
        .simultaneousGesture(TapGesture().onEnded { model.interact() })
        HStack(spacing: 8) {
          Button {
            model.dismissDemoDoorbell()
            model.route = .face
          } label: {
            Image(systemName: "rectangle.on.rectangle")
              .frame(width:44,height:44).contentShape(Rectangle())
          }.accessibilityLabel("Faces").accessibilityIdentifier("nav.faces")
          Button {
            model.homeGesture()
          } label: {
            Image(systemName: "circle.grid.3x3.fill")
              .frame(width:44,height:44).contentShape(Rectangle())
          }.accessibilityLabel("Apps").accessibilityIdentifier("nav.apps")
          Text(model.data.home.online ? "MOCK HOME" : "MOCK OFFLINE")
            .font(.system(size: 10, weight: .semibold)).tracking(2).foregroundStyle(
            model.data.home.online ? Color.gray : Color.orange
          ).accessibilityIdentifier("mock.badge")
          Button {
            openAssistant()
          } label: {
            Image(systemName: "waveform")
              .frame(width:44,height:44).contentShape(Rectangle())
          }.accessibilityLabel("Assistant").accessibilityIdentifier("nav.assistant")
            #if !os(tvOS)
              .keyboardShortcut("s",modifiers:[.command,.shift])
            #endif
          Button {
            model.dismissDemoDoorbell()
            model.route = .controlCenter
          } label: {
            Image(systemName: "switch.2")
              .frame(width:44,height:44).contentShape(Rectangle())
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
  }
  var body: some View {
    viewportContent
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

    .sheet(isPresented:Binding(get:{model.showingLocalReset},set:{ if !$0 { model.cancelLocalReset() } })) {
      LocalResetView()
    }
    .sheet(isPresented:Binding(get:{model.showingIntroduction},set:{model.showingIntroduction=$0})) {
      SetupIntroductionView()
    }
    .task {
      model.setTimerActivityForeground(scenePhase == .active)
      model.localResetForeground=scenePhase == .active
      model.presentIntroductionOnLaunch()
      model.setAnswerSpeechForeground(scenePhase == .active)
      consumeAssistantShortcut()
      model.installRecipeHandoffFixture()
      model.setAlbumDisplayActive(scenePhase == .active)
      await model.connections.restore(allowed:model.data.connectionConsent)
      model.reconcileSystemAlarms()
      model.display.apply(enabled: model.data.keepDisplayOn && scenePhase == .active)
    }
    .onContinueUserActivity(RecipeContinuity.activityType) { activity in
      model.receiveRecipeHandoff(type:activity.activityType,data:activity.userInfo?["payload"] as? Data ?? Data())
    }
    .onChange(of:model.cookingStep) { _,step in model.recipeHandoff.update(recipe:model.recipe,step:step) }
    .onChange(of:assistantShortcutRevision) { _,_ in consumeAssistantShortcut() }
    .onChange(of:model.cookingInProgress) { _,active in if !active { model.recipeHandoff.stop() } }
    .onChange(of:model.route) { old,new in
      if old == .handoff,new != .handoff { model.recipeHandoff.cancelPending() }
    }
    // Disconnect the timer subscription while inactive; dropping its callback
    // alone would still leave the periodic publisher running.
    .onReceive(scenePhase == .active ? pulse.eraseToAnyPublisher()
      : Empty<Date,Never>().eraseToAnyPublisher()) { _ in
      model.tick();model.synchronizeTimerActivity()
    }
    #if os(iOS) || os(tvOS) || os(visionOS)
      .onReceive(NotificationCenter.default.publisher(for:AVAudioSession.interruptionNotification)) { _ in
        model.stopAnswerSpeech();model.pauseFeedPodcast()
      }
      .onReceive(NotificationCenter.default.publisher(for:AVAudioSession.routeChangeNotification)) { note in
        if (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt)==AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue { model.stopAnswerSpeech();model.pauseFeedPodcast() }
      }
    #endif
    .onChange(of: model.route) { _, route in if route == .privacy { model.lockPersonalAccess() } }
    .onChange(of:model.incomingCall) { _,incoming in if incoming { model.stopAnswerSpeech();model.dismissDemoDoorbell();model.pauseFeedPodcast() } }
    .onChange(of: model.data.keepDisplayOn) { _, enabled in
      model.display.apply(enabled: enabled && scenePhase == .active)
    }
    .onChange(of: model.connections.personalUnlocked) { _, unlocked in
      if !unlocked { model.stopAnswerSpeech();model.albumCatalogue.invalidate();model.recipeHandoff.stop() }
    }
    .onDisappear {
      model.setTimerActivityForeground(false)
      model.localResetForeground=false
      model.setAnswerSpeechForeground(false)
      model.connections.endGuestMusicSession()
      model.recipeHandoff.stop()
      model.dismissDemoDoorbell()
      model.pauseFeedPodcast()
      model.display.apply(enabled: false)
      model.setAlbumDisplayActive(false)
      model.lockPersonalAccess()
      if case .app(let page) = model.route, page.isPersonal {
        model.pendingPage = page
        model.route = .privacy
      }
    }
    .onChange(of: scenePhase) { _, phase in
      model.setTimerActivityForeground(phase == .active)
      model.localResetForeground=phase == .active
      model.setAnswerSpeechForeground(phase == .active)
      if phase != .active { model.recipeHandoff.stopOffering() }
      model.setAlbumDisplayActive(phase == .active)
      model.display.apply(enabled: model.data.keepDisplayOn && phase == .active)
      if phase == .active {
        consumeAssistantShortcut()
        // Deadlines use wall time, so reconcile once before the next pulse.
        model.tick();model.synchronizeTimerActivity()
        model.reconcileSystemAlarms()
      } else if phase == .background {
        model.connections.endGuestMusicSession()
        model.recipeHandoff.stop()
        model.pauseFeedPodcast()
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
    private func viewportNavigation(width: Double,height: Double) -> some Gesture {
      DragGesture(minimumDistance: 45).onEnded { value in
        model.interact()
        // One dominant axis owns each completed drag. Existing distances and
        // edge regions stay in the displayed viewport's coordinate system.
        switch ViewportNavigationIntent.choose(startX:value.startLocation.x,
          startY:value.startLocation.y,dx:value.translation.width,dy:value.translation.height,
          width:width,height:height,isFace:model.route == .face) {
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
    case .handoff: RecipeHandoffView()
    case .assistant: AssistantView(focusRequest:assistantFocusRequest)
    case .editor: FaceEditor()
    case .controlCenter: ControlCenterView()
    case .privacy: PrivacyView()
    case .deviceUnlock: DeviceUnlockView()
    case .call: CallView(incoming: false)
    }
  }
}
