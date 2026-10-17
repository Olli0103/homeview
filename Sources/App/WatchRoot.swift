import SwiftUI

#if os(watchOS)
  struct WatchRoot: View {
    @Environment(AppModel.self) private var model
    var body: some View {
      NavigationStack {
        List {
          Section("Mock Home") {
            HStack {
              Image(systemName: "thermometer.medium")
              Text("\(model.data.home.temperature)°")
              Spacer()
              Button("−") { model.command(.temperature(model.data.home.temperature - 1)) }
              Button("+") { model.command(.temperature(model.data.home.temperature + 1)) }
            }
            Button(model.data.home.entryLight ? "Lights On" : "Lights Off") {
              model.command(.entryLight)
            }
            Button("Good Night") { model.command(.scene("Good Night")) }
            Button("Good Morning") { model.command(.scene("Good Morning")) }
          }
          Section("Timers") {
            Button("5-minute timer") { model.addTimer(seconds: 300) }
            ForEach(model.data.timers) { t in Text(t.display(at: model.now)) }
          }
          Section("World Clock") { Text(model.clock, style: .time) }
        }.navigationTitle("HomeView")
      }.onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in model.tick()
      }
    }
  }
#endif
