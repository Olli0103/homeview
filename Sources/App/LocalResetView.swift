import SwiftUI
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

@MainActor func authenticateLocalResetOwner() async -> Bool {
  guard !Task.isCancelled else { return false }
  let args=ProcessInfo.processInfo.arguments
  if args.contains("--uitesting") { return !args.contains("--device-unlock-denied") }
  #if canImport(LocalAuthentication) && !os(tvOS)
    let context=LAContext()
    return (try? await context.evaluatePolicy(.deviceOwnerAuthentication,
      localizedReason:"Authenticate before separately confirming a reset of HomeView’s local app content.")) == true
  #else
    return false
  #endif
}

struct LocalResetView:View {
  @Environment(AppModel.self) private var model
  @Environment(\.scenePhase) private var phase
  @State private var confirmation=""
  @FocusState private var confirming:Bool
  private var disclosedStatus:String {
    if !model.localResetAuthorized,model.localResetStatus.hasPrefix("Authenticated.") {
      return "Authentication expired or was cleared. Authenticate again before resetting or retrying cleanup."
    }
    return model.localResetStatus
  }
  var body:some View {
    VStack(spacing:0) {
      HStack {
        Text("Reset local app content").font(.title2.bold());Spacer()
        Button("Cancel") { model.cancelLocalReset() }.accessibilityIdentifier("reset.cancel")
      }.padding(24)
      ScrollView {
        VStack(alignment:.leading,spacing:20) {
          Text("This removes this app’s local demo profiles/messages/reminders, timers, recipes, feed progress, face settings, imported photo copies and app-owned recovery copies. The introduction returns to its initial state. It is not secure erasure of OS caches or physical storage.")
            .accessibilityIdentifier("reset.scope")
          Text("Source calendars, reminder lists, photo libraries, Apple Music and cloud accounts are not deleted. OS permissions remain. The non-content identifier for this app’s own source reminder list remains, avoiding duplicate lists on a later connection. Apple Home stays disconnected.")
            .accessibilityIdentifier("reset.source")
          Text("Registered, active or pending app system alarms must be resolved before reset; reset never silently cancels or forgets them. A read-only/newer state or unverifiable alarm access blocks reset. If old file cleanup fails after replacement, the new state is active and the leftover cleanup is reported explicitly.")
            .accessibilityIdentifier("reset.limits")
          if model.localResetCleanupPending {
            Text("Retry removes only the retired app files from the previous reset. It does not reset the current app content again.")
              .accessibilityIdentifier("reset.cleanup.scope")
          }
          Text("Authentication expires after 60 seconds and is revoked on background, lock or profile change.")
            .font(.callout).foregroundStyle(.gray)
          Text(disclosedStatus).accessibilityIdentifier("reset.status")
          if model.localResetAuthorized {
            TextField("Type RESET exactly",text:$confirmation)
              .focused($confirming).submitLabel(.done).onSubmit { confirming=false }
              .textFieldStyle(.plain).padding(12).background(.gray.opacity(0.08))
              .accessibilityIdentifier("reset.confirmation")
            if model.localResetCleanupPending {
              Button("Retry old reset file cleanup",role:.destructive) {
                _ = model.retryLocalResetCleanup(confirmation:confirmation)
              }.disabled(confirmation != "RESET" || !model.localResetForeground)
                .accessibilityIdentifier("reset.cleanup")
            } else {
              Button("Reset local app content now",role:.destructive) {
                _ = model.resetLocalAppData(confirmation:confirmation)
              }.disabled(confirmation != "RESET" || !model.localResetForeground)
                .accessibilityIdentifier("reset.confirm")
            }
          } else {
            Button(model.localResetAuthorizing ? "Authenticating…":"Authenticate for reset") {
              let attempt=model.localResetRequestGeneration
              Task { await model.authorizeLocalReset(expectedAttempt:attempt) }
            }.disabled(model.localResetAuthorizing).accessibilityIdentifier("reset.authenticate")
          }
        }.frame(maxWidth:.infinity,alignment:.leading).padding(24)
      }
    }.frame(minWidth:300,minHeight:400).background(.white).foregroundStyle(.black)
      .onChange(of:phase) { _,phase in if phase != .active { confirming=false } }
      .onChange(of:model.localResetRequestGeneration) { _,_ in confirmation="" }
    #if !os(tvOS)
      .interactiveDismissDisabled()
    #endif
  }
}
