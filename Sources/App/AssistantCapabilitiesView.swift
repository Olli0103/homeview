import SwiftUI

struct AssistantCapabilitiesView: View {
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    VStack(spacing:0) {
      HStack {
        Text("Assistant capabilities").font(.title2.bold())
        Spacer()
        Button("Done") { dismiss() }.accessibilityIdentifier("assistant.capabilities.done")
      }.padding(24)
      ScrollView {
        VStack(alignment:.leading,spacing:22) {
          entry("Local commands · Available",
            "A limited command parser, not a conversational AI. No Siri AI or cloud AI provider is connected.",id:"service")
          entry("Languages",
            "Selected German and English timer and cooking-step commands. Other actions use limited keywords. Replies are currently English. This is not general German or English conversation support.",id:"languages")
          entry("Try these commands",
            "Timer auf 90 Sekunden · set a timer for 5 minutes\nNächster Schritt · next step (after starting a recipe)",id:"examples")
          entry("Voice input",
            VoiceInputController.supported
              ? "Deutsch (de-DE) or English (en-US). On-device recognition only. Availability depends on this device and its installed language support. Speak requests permission and checks availability; typing remains available."
              : "Voice input is unavailable on this platform. Type a request instead.",id:"voice")
          entry("Input limits",
            "Voice capture: up to \(AssistantLimits.recordingSeconds) seconds; transcript: \(AssistantLimits.transcriptCharacters) characters. Recording only creates a draft. Review it and tap Send to act.",id:"limits")
          entry("Timer limits",
            "One explicit duration, 1 second to \(AssistantLimits.timerSeconds/3600) hours, whole seconds. Timer request: up to \(AssistantLimits.timerRequestCharacters) characters. Ambiguous or unsupported wording needs clarification.",id:"timers")
          entry("Services and subscriptions",
            "No cloud AI quota or subscription is configured. Apple Siri availability, daily limits and future pricing do not describe this local assistant. Apple Home is not connected.",id:"subscriptions")
        }.padding(24)
      }
    }.frame(minWidth:300,minHeight:400).background(.white).foregroundStyle(.black)
  }
  private func entry(_ title:String,_ detail:String,id:String) -> some View {
    VStack(alignment:.leading,spacing:8) {
      Text(title).font(.headline)
      Text(detail).font(.body).fixedSize(horizontal:false,vertical:true)
        .accessibilityIdentifier("assistant.capabilities."+id)
    }.frame(maxWidth:.infinity,alignment:.leading)
  }
}
