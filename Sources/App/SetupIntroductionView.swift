import SwiftUI

struct SetupIntroductionView:View {
  @Environment(AppModel.self) private var model
  @State private var step=0
  var body:some View {
    VStack(spacing:0) {
      HStack {
        Text("Welcome to HomeView").font(.title2.bold());Spacer()
        Button("Not now") { _ = model.endIntroduction(deferred:true) }
          .accessibilityIdentifier("setup.later")
      }.padding(24)
      ScrollView {
        VStack(alignment:.leading,spacing:20) {
          if model.localResetCleanupPending {
            Text("Old reset cleanup is incomplete. Open Settings → Reset to retry that cleanup without resetting new content.")
              .foregroundStyle(.orange).accessibilityIdentifier("setup.cleanup.pending")
          }
          Text("Step \(step+1) of 3").font(.callout).foregroundStyle(.gray)
            .accessibilityIdentifier("setup.step")
          if step==0 {
            Text("This device and the demo").font(.title2.bold())
            Text("HomeView is an independent prototype, not Apple HomeView or a system replacement. It starts with synthetic demo content. Apple Home stays disconnected; this setup cannot discover or control your home.")
              .accessibilityIdentifier("setup.scope")
            Text("Device and OS support differ. On-device answers, voice input, camera, alarms and other native services can be unavailable. Adapter adequacy is not measured. A successful setup does not enable missing system features.")
              .accessibilityIdentifier("setup.capabilities")
            Text("There is no app store here. HomeView cannot install arbitrary third-party apps. Only the built-in views and explicitly connected services are offered.")
              .accessibilityIdentifier("setup.nostore")
          } else if step==1 {
            Text("Owner, profiles and privacy").font(.title2.bold())
            Text("The app runs in your current system user’s app storage. It does not create an owner account or pair another device. The six named display profiles contain demo content; selecting one is not authentication or proof of who is present.")
              .accessibilityIdentifier("setup.owner")
            Text("Real calendar and reminder content requires an explicit connection and device authentication before display. Background, lock and profile changes clear protected views. Displaying an approved photo album is separate consent to show it on this screen.")
              .accessibilityIdentifier("setup.privacy")
            Text("There is no Siri history import or conversation sync. Optional on-device answers use only text you send and a temporary local conversation. No cloud AI subscription or API key is configured.")
              .accessibilityIdentifier("setup.assistant")
          } else {
            Text("Choose services later").font(.title2.bold())
            Text("Nothing on this page requests permission or connects an account. You can use the demo now, then open Settings when you choose to connect. Denying access keeps the demo usable and you can try again later.")
              .accessibilityIdentifier("setup.permission")
            Text("Calendar and Reminders: system permission plus device authentication. Photos: choose images in the system picker, or explicitly approve an album for display. Apple Music: system authorization and an eligible account/subscription may be required; HomeView makes no purchase. Weather and public podcast feeds: optional network access, not an Apple account import.")
              .accessibilityIdentifier("setup.services")
            Text("Settings offers Connect and Disconnect for supported data services. Disconnect clears the app’s cached view and future automatic reconnection; it does not revoke OS permission or delete your source calendar, reminders, library or cloud account. System permissions can be changed in system settings.")
              .accessibilityIdentifier("setup.disconnect")
          }
          if let error=model.error {
            Text(error).foregroundStyle(.red).accessibilityIdentifier("setup.error")
          }
        }.frame(maxWidth:.infinity,alignment:.leading).padding(24)
      }
      HStack(spacing:20) {
        if step>0 { Button("Back") { step-=1 }.accessibilityIdentifier("setup.back") }
        Spacer()
        if step<2 {
          Button("Next") { step+=1 }.accessibilityIdentifier("setup.next")
        } else {
          Button("Use the demo") { _ = model.endIntroduction(deferred:false) }
            .accessibilityIdentifier("setup.finish")
          Button("Open Settings") { _ = model.endIntroduction(deferred:false,openConnections:true) }
            .accessibilityIdentifier("setup.settings")
        }
      }.padding(24)
    }.frame(minWidth:300,minHeight:400).background(.white).foregroundStyle(.black)
    #if !os(tvOS)
      .interactiveDismissDisabled()
    #endif
  }
}
