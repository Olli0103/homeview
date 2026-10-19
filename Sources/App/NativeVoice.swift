import Foundation
import Observation

#if canImport(Speech) && (os(iOS) || os(macOS))
  @preconcurrency import Speech
  @preconcurrency import AVFoundation

  // The audio callback and endAudio are serialized by this tiny bridge. No model
  // or UI state is touched on the real-time audio thread.
  private final class SpeechAudioSink: @unchecked Sendable {
    let request = SFSpeechAudioBufferRecognitionRequest()
    private let lock = NSLock()
    private var accepting = true
    func append(_ buffer: AVAudioPCMBuffer) {
      lock.lock()
      defer { lock.unlock() }
      if accepting { request.append(buffer) }
    }
    func finish() {
      lock.lock()
      defer { lock.unlock() }
      if accepting {
        accepting = false
        request.endAudio()
      }
    }
  }

  // All capture lifecycle mutations belong to this queue. Permissions are asked
  // by the foreground controller before this object is constructed/started.
  private final class SpeechCapture: @unchecked Sendable {
    private static let queue = DispatchQueue(label: "org.example.homeview.speech")
    private var engine: AVAudioEngine?
    private var recognizer: SFSpeechRecognizer?
    private var task: SFSpeechRecognitionTask?
    private var sink: SpeechAudioSink?
    private var tapped = false
    private var audioSessionActive = false
    func start(locale: String, result: @escaping @Sendable (String, Bool, String?) -> Void) async
      -> String?
    {
      await withCheckedContinuation { continuation in
        Self.queue.async { [self] in
          cancelLocked()
          guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)),
            recognizer.isAvailable, recognizer.supportsOnDeviceRecognition
          else {
            continuation.resume(
              returning:
                "On-device speech is unavailable for this language. You can type a request.")
            return
          }
          do {
            #if os(iOS)
              let session = AVAudioSession.sharedInstance()
              try session.setCategory(
                .playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
              try session.setActive(true)
              audioSessionActive = true
            #endif
            let engine = AVAudioEngine()
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
              cancelLocked()
              continuation.resume(returning: "No microphone input is available.")
              return
            }
            let sink = SpeechAudioSink()
            sink.request.requiresOnDeviceRecognition = true
            sink.request.shouldReportPartialResults = true
            sink.request.taskHint = .confirmation
            self.engine = engine
            self.recognizer = recognizer
            self.sink = sink
            task = recognizer.recognitionTask(with: sink.request) { response, error in
              // Copy immutable values before crossing to the main actor.
              result(
                response?.bestTranscription.formattedString ?? "", response?.isFinal ?? false,
                error == nil
                  ? nil : "Speech recognition stopped.")
            }
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
              sink.append(buffer)
            }
            tapped = true
            engine.prepare()
            try engine.start()
            continuation.resume(returning: nil)
          } catch {
            cancelLocked()
            continuation.resume(
              returning: "The microphone could not be started. You can type a request.")
          }
        }
      }
    }
    private func stopAudioLocked() {
      if tapped {
        engine?.inputNode.removeTap(onBus: 0)
        tapped = false
      }
      engine?.stop()
      sink?.finish()
      #if os(iOS)
        if audioSessionActive {
          try? AVAudioSession.sharedInstance().setActive(
            false, options: [.notifyOthersOnDeactivation])
          audioSessionActive = false
        }
      #endif
    }
    private func cancelLocked() {
      stopAudioLocked()
      task?.cancel()
      task = nil
      sink = nil
      recognizer = nil
      engine = nil
    }
    func finish() { Self.queue.async { [self] in stopAudioLocked() } }
    func cancel() { Self.queue.async { [self] in cancelLocked() } }
  }
#endif

@MainActor @Observable
final class VoiceInputController {
  enum Phase { case idle, preparing, listening, finishing, ready, failed }
  private(set) var phase = Phase.idle
  private(set) var transcript = ""
  private(set) var status = "Tap to speak · On-device only"
  var busy: Bool { phase == .preparing || phase == .listening || phase == .finishing }
  var recording: Bool { phase == .listening }
  private var generation = 0
  private var deadline: Task<Void, Never>?
  private let synthetic = ProcessInfo.processInfo.arguments.contains("--uitesting")
  #if canImport(Speech) && (os(iOS) || os(macOS))
    private var capture: SpeechCapture?
  #endif
  static var supported: Bool {
    #if canImport(Speech) && (os(iOS) || os(macOS))
      true
    #else
      false
    #endif
  }
  func start(locale: String) async {
    // An already-cancelled old caller must not clear or replace a newer capture.
    guard !Task.isCancelled else { return }
    cancel()
    let ticket = generation
    phase = .preparing
    transcript = ""
    status = "Preparing voice input…"
    if synthetic {
      // No recognizer, audio engine, permission prompt or microphone in UI tests.
      if ProcessInfo.processInfo.arguments.contains("--voice-denied") {
        phase = .failed
        status = "Microphone permission was not granted. You can type a request."
        return
      }
      phase = .listening
      status = "Synthetic voice input · No microphone used"
      let args=ProcessInfo.processInfo.arguments
      let index=args.firstIndex(of:"--voice-transcript")
      let text=index.flatMap { args.indices.contains($0+1) ? args[$0+1]:nil } ?? "temperature 72"
      receive(text:text,final:false,problem:nil,ticket:ticket)
      if phase == .listening { armDeadline(ticket:ticket) }
      return
    }
    #if canImport(Speech) && (os(iOS) || os(macOS))
      let speechAllowed = await withCheckedContinuation { continuation in
        SFSpeechRecognizer.requestAuthorization {
          continuation.resume(returning: $0 == .authorized)
        }
      }
      guard generation == ticket else { return }
      guard !Task.isCancelled else { cancel();return }
      guard speechAllowed else {
        fail("Speech permission was not granted. You can type a request.")
        return
      }
      let micAllowed: Bool
      #if os(iOS)
        micAllowed = await AVAudioApplication.requestRecordPermission()
      #else
        micAllowed = await AVCaptureDevice.requestAccess(for: .audio)
      #endif
      guard generation == ticket else { return }
      guard !Task.isCancelled else { cancel();return }
      guard micAllowed else {
        fail("Microphone permission was not granted. You can type a request.")
        return
      }
      let capture = SpeechCapture()
      self.capture = capture
      let problem = await capture.start(locale: locale) { [weak self] text, final, problem in
        Task { @MainActor [weak self] in
          self?.receive(text:text,final:final,problem:problem,ticket:ticket)
        }
      }
      guard generation == ticket else {
        capture.cancel()
        return
      }
      guard !Task.isCancelled else { cancel();return }
      if let problem {
        fail(problem)
        return
      }
      // A very short recognition can finish while capture.start is returning.
      guard phase == .preparing else { return }
      phase = .listening
      status = "Listening… Tap Stop when finished."
      armDeadline(ticket:ticket)
    #else
      fail("Voice input is unavailable on this target. You can type a request.")
    #endif
  }
  private func armDeadline(ticket:Int) {
    deadline?.cancel()
    deadline=Task { [weak self] in
      do { try await Task.sleep(for:.seconds(AssistantLimits.recordingSeconds)) } catch { return }
      guard let self,self.generation==ticket else { return }
      self.finish()
    }
  }
  private func receive(text:String,final:Bool,problem:String?,ticket:Int) {
    guard generation==ticket,phase == .preparing || phase == .listening || phase == .finishing else { return }
    if let problem { fail(problem+" No speech draft was retained. Type a request or try again.");return }
    guard text.count<=AssistantLimits.transcriptCharacters else {
      fail("Voice input exceeded \(AssistantLimits.transcriptCharacters) characters. No speech draft was retained. Type a request or try again.");return
    }
    if final,text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty {
      fail("No final speech text was received. Type a request or try again.");return
    }
    if !text.isEmpty { transcript=text }
    if final {
      deadline?.cancel();deadline=nil
      #if canImport(Speech) && (os(iOS) || os(macOS))
        capture?.cancel();capture=nil
      #endif
      if transcript.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty {
        fail("No speech detected. Try again or type a request.")
      } else { phase = .ready;status="Review the text, then tap Send." }
    }
  }
  func finish() {
    guard recording else { return }
    deadline?.cancel()
    if synthetic {
      let problem=ProcessInfo.processInfo.arguments.contains("--voice-recognition-error")
        ? "Speech recognition stopped.":nil
      receive(text:transcript,final:true,problem:problem,ticket:generation)
      return
    }
    phase = .finishing
    status = "Finishing…"
    #if canImport(Speech) && (os(iOS) || os(macOS))
      capture?.finish()
    #endif
    let ticket = generation
    deadline = Task { [weak self] in
      do { try await Task.sleep(for: .seconds(6)) } catch { return }
      guard let self, self.generation == ticket else { return }
      self.fail("Voice input did not finish. No speech draft was retained. Type a request or try again.")
    }
  }
  private func fail(_ message: String) {
    deadline?.cancel();deadline=nil;transcript=""
    #if canImport(Speech) && (os(iOS) || os(macOS))
      capture?.cancel()
      capture = nil
    #endif
    phase = .failed
    status = message
  }
  func cancel() {
    generation += 1
    deadline?.cancel()
    deadline = nil
    #if canImport(Speech) && (os(iOS) || os(macOS))
      capture?.cancel()
      capture = nil
    #endif
    phase = .idle
    transcript = ""
    status = "Tap to speak · On-device only"
  }
}
