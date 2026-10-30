import SwiftUI
import Combine

#if os(watchOS)
  struct WatchRoot: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    private let pulse = Timer.publish(every:1,on:.main,in:.common).autoconnect()
    var body: some View {
      NavigationStack {
        List {
          Section("Mock Home") {
            HStack {
              Image(systemName: "thermometer.medium")
              Text("\(model.observedHome.temperature)°")
              Spacer()
              Button { model.stepHomeControl(.temperature,direction:-1) } label: {
                Text("−").frame(width:44,height:44).contentShape(Rectangle())
              }
              Button { model.stepHomeControl(.temperature,direction:1) } label: {
                Text("+").frame(width:44,height:44).contentShape(Rectangle())
              }
            }
            // Automatic List-row buttons otherwise execute both actions.
            // Explicit per-button hit regions keep each tap independent.
            .buttonStyle(.plain)
            Button(model.observedHome.entryLight ? "Lights On" : "Lights Off") {
              model.command(.entryLight)
            }
            Button("Good Night") { model.command(.scene("Good Night")) }
            Button("Good Morning") { model.command(.scene("Good Morning")) }
          }
          if let error=model.error { Text(error).foregroundStyle(.orange) }
          Section("Timers") {
            Button("5-minute timer") { model.addTimer(seconds: 300) }
            ForEach(model.data.timers) { t in Text(t.display(at: model.now)) }
          }
          Section("World Clock") { Text(model.clock, style: .time) }
        }.navigationTitle("HomeView")
      }
      .onReceive(scenePhase == .active ? pulse.eraseToAnyPublisher()
        : Empty<Date,Never>().eraseToAnyPublisher()) { _ in model.tick() }
      .onChange(of:scenePhase) { _,phase in
        model.setHomeControlsForeground(phase == .active)
        // Absolute deadlines must catch up when the watch surface resumes.
        if phase == .active { model.tick() }
      }
      .task {model.setHomeControlsForeground(scenePhase == .active)}
      .onDisappear {model.setHomeControlsForeground(false)}
    }
  }
#endif
