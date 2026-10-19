import SwiftUI

struct AnswerSpeechSettingsView:View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  var body:some View {
    VStack(spacing:0) {
      HStack {
        Text("Answer readout").font(.title2.bold());Spacer()
        Button("Done") { dismiss() }.accessibilityIdentifier("answer.speech.settings.done")
      }.padding(24)
      ScrollView {
        VStack(alignment:.leading,spacing:20) {
          Text("System speech only. No Siri voice identity, Personal Voice clone or external TTS provider. Nothing is spoken automatically. First unlock this device, then tap Read explicitly.")
          if !model.answerSpeech.voices.isEmpty {
          Picker("Language",selection:Binding(get:{model.answerSpeech.language},set:{model.answerSpeech.chooseLanguage($0)})) {
            ForEach(model.answerSpeech.languages,id:\.self) { Text($0).tag($0) }
          }.accessibilityIdentifier("answer.speech.language")
          Picker("Voice",selection:Binding(get:{model.answerSpeech.voiceID ?? ""},set:{model.answerSpeech.chooseVoice($0)})) {
            ForEach(model.answerSpeech.languageVoices) { voice in Text(voice.name).tag(voice.id) }
          }.accessibilityIdentifier("answer.speech.voice")
          }
          VStack(alignment:.leading) {
            Text("Speech rate: \(model.answerSpeech.rate,format:.number.precision(.fractionLength(2)))")
              .accessibilityIdentifier("answer.speech.rate.label")
            #if !os(tvOS)
              Slider(value:Binding(get:{Double(model.answerSpeech.rate)},set:{model.answerSpeech.setRate(Float($0))}),in:0.35...0.65)
                .accessibilityIdentifier("answer.speech.rate")
            #else
              Text("Answer readout is unavailable on this platform.")
            #endif
          }
          Toggle("Mute answer readout",isOn:Binding(get:{model.answerSpeech.muted},set:{model.answerSpeech.setMuted($0)}))
            .accessibilityIdentifier("answer.speech.mute")
          Text(model.answerSpeech.status).accessibilityIdentifier("answer.speech.settings.status")
          Text("Changing voice, language, rate or mute stops the current readout. Unmuting does not replay it. Timer chimes have priority; music, podcasts, microphone capture, calls, navigation, lock and background stop readout. Nothing resumes automatically. Your OS controls which ordinary system voices are available.")
            .font(.callout).foregroundStyle(.gray)
          Text("Up to 4000 characters from the latest answer. Voice choice and rate are kept only for this app process. HomeView does not download voice packs or request Personal Voice authorization.")
            .font(.callout).foregroundStyle(.gray)
        }.padding(24)
      }
    }.frame(minWidth:300,minHeight:400).background(.white).foregroundStyle(.black)
      .onAppear { model.answerSpeech.loadVoices() }
  }
}
