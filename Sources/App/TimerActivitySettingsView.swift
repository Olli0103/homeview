import SwiftUI
struct TimerActivitySettingsView:View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  var body:some View {
    NavigationStack {
      Form {
        Section {
          Toggle("Own timer activity",isOn:Binding(get:{model.timerActivitiesEnabled},set:{model.setTimerLiveActivities($0)}))
            .accessibilityIdentifier("timer.activity.enabled")
          Text("Shows timer counts and the next countdown outside HomeView. No timer titles, profiles, or other personal content are shared.")
          Button("Show timer activity") {model.showTimerLiveActivity()}
            .disabled(!model.timerActivitiesEnabled)
            .accessibilityIdentifier("timer.activity.show")
          Text(model.timerLiveActivity.status).accessibilityIdentifier("timer.activity.status")
          if model.timerLiveActivity.busy {ProgressView("Updating timer activity")}
          if let report=timerActivitySystemFixtureReport() {
            Text(report).accessibilityIdentifier("timer.activity.system-report")
          }
          if model.timerActivityPreferenceSavePending {
            Text("Off for this app session. The preference could not be saved.")
            Button("Retry saving off preference") {model.setTimerLiveActivities(false)}
              .accessibilityIdentifier("timer.activity.retry-off")
          }
        }
        Section("Limits") {
          Text("This is a timer display, not an alarm. It does not add sound or guarantee a background alert.")
          Text("The system controls visibility and duration. If a countdown becomes stale while HomeView is suspended, open the app to refresh or remove it.")
          Text("Turning this off ends only HomeView's own timer activity. Other apps and system activities are not controlled.")
        }
      }.navigationTitle("Timer Live Activities")
        .toolbar {ToolbarItem(placement:.confirmationAction) {Button("Done") {dismiss()}.accessibilityIdentifier("timer.activity.done")}}
    }.environment(\.colorScheme,.light).preferredColorScheme(.light)
  }
}
