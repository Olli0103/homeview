import SwiftUI

struct AssistantCapabilitiesView: View {
  @Environment(AppModel.self) private var model
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
          VStack(alignment:.leading,spacing:12) {
            Text("Choose how Send works").font(.headline)
            Text("Commands can act on the local demo. On-device answers only generate text, never actions. Selection does not send your draft or save a conversation.")
            Button(model.assistantUsesAI ? "Use local commands":"Local commands selected") {
              model.selectAssistantAnswers(false)
            }.accessibilityIdentifier("assistant.provider.local")
            Button(model.assistantUsesAI ? "Check on-device availability again":"Use Apple on-device answers") {
              model.selectAssistantAnswers(true)
            }.accessibilityIdentifier("assistant.provider.ondevice")
            Text(model.assistantAI.availability.message).accessibilityIdentifier("assistant.provider.availability")
          }
          entry("Siri and wakewords · Not connected",
            "HomeView does not listen for Siri, Hey Siri or a custom wakeword. Opening the app or Assistant does not start a recording. Tap Speak to start voice input, then review the draft and tap Send. There is no automatic wakeword or background listener.",id:"activation")
          entry("Apple on-device answers · Optional",
            "Uses this device’s SystemLanguageModel only. No cloud fallback, API key, subscription, web search or app-data access. Only your explicitly sent text and this temporary conversation enter the model. Answers can be wrong or outdated; verify important facts. Requires a supported device, OS and ready Apple Intelligence model. HomeView does not enable it or download a model.",id:"ondevice")
          entry("Conversation limits",
            "Up to 4 exchanges and 6000 characters in total; 1000 per question, 4000 per answer, up to 400 generated tokens and 45 seconds per response. The system context may fill sooner. Stop, New, leaving the assistant, background, lock and profile changes discard the entire conversation. Nothing is saved. No automatic retry or cloud fallback.",id:"context")
          entry("History and device continuation · Not available",
            "This is HomeView’s temporary on-device conversation, not your Siri history. Nothing is saved or synced to iCloud or another device. New clears this conversation; Stop also discards a pending reply. Leaving the assistant, background, lock and profile changes clear it too. A new app launch starts empty. HomeView cannot read or delete your Siri history.",id:"history")
          entry("Local commands · Available",
            "A limited command parser, not a conversational AI. No Siri AI or cloud AI provider is connected. On-device answers are a separate optional mode.",id:"service")
          entry("Confirmed local demo plans",
            "Start with ‘plan:’ and separate 2–6 steps with semicolons, for example ‘plan: temperature 72; brightness 30; timer for 90 seconds’. Only mock temperature/brightness and foreground demo timers are supported. Sending shows a preview; Run demo plan confirms it separately. Every step depends on confirmed read-back of its predecessor. Plans are not atomic and are not resumed after restart. No system-alarm scheduling, personal accounts, messages, calls, scenes or security actions.",id:"plans")
          entry("Languages",
            "Selected German and English timer and cooking-step commands. Other actions use explicit limited phrases, not arbitrary keywords. Replies are currently English in command mode. On-device answer languages depend on the system model; this is not Siri.",id:"languages")
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
