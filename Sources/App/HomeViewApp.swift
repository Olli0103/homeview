import SwiftUI

@main
struct HomeViewReplicaApp: App {
  @State private var model = AppModel()
  var body: some Scene {
    WindowGroup {
      #if os(watchOS)
        WatchRoot().environment(model)
      #else
        RootView().environment(model)
          #if os(macOS)
            .frame(minWidth: 440, minHeight: 460)
          #endif
      #endif
    }
    #if os(macOS)
      .defaultSize(width: 740, height: 760)
      .commands {
        CommandGroup(after: .appInfo) {
          Button("HomeView Faces") { model.route = .face }.keyboardShortcut(
            "h", modifiers: [.command])
          Button("All Apps") { model.route = .drawer }.keyboardShortcut("a", modifiers: [.command])
          Button("Control Center") { model.route = .controlCenter }.keyboardShortcut(
            ",", modifiers: [.command])
        }
      }
    #endif
  }
}
