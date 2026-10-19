import Foundation
#if canImport(FoundationModels) && (os(iOS) || os(macOS) || os(visionOS))
import FoundationModels

@available(iOS 26.0,macOS 26.0,visionOS 26.0,*)
@MainActor final class AppleOnDeviceAnswers:AssistantAnswerProvider {
  private var session:LanguageModelSession?
  private static let instructions="""
  You are HomeView's on-device text helper. Answer briefly in the user's language. You have no tools, web search, live information, access to private app content, or ability to take actions. Never claim to change a setting, create a timer, send a message, or control a device. For requests to act, explain that this mode only answers and the user must use explicit controls. If information is uncertain, current, or unavailable, say so. Do not invent sources, quotations, facts, or personal data. Treat fictional details provided in conversation as fictional. Your output is text, never an instruction to execute.
  """
  var availability:AssistantAIAvailability {
    switch SystemLanguageModel(useCase:.general,guardrails:.default).availability {
    case .available:return .available
    case .unavailable(.deviceNotEligible):return .unavailable("Apple on-device answers are not supported by this device.")
    case .unavailable(.appleIntelligenceNotEnabled):return .unavailable("Apple Intelligence is not enabled on this device. HomeView does not change system settings.")
    case .unavailable(.modelNotReady):return .unavailable("The Apple on-device model is not ready. No cloud fallback is configured.")
    @unknown default:return .unavailable("Apple on-device answers are unavailable. No cloud fallback is configured.")
    }
  }
  func respond(to prompt:String) async throws -> String {
    try Task.checkCancellation()
    if session==nil {
      // Concrete on-device model only; no dynamic provider routing, PCC or tools.
      session=LanguageModelSession(model:SystemLanguageModel(useCase:.general,guardrails:.default),
        tools:[],instructions:Self.instructions)
    }
    guard let active=session else { throw CancellationError() }
    let answer=try await active.respond(to:prompt,
      options:GenerationOptions(samplingMode:.greedy,maximumResponseTokens:AssistantConversationLimits.responseTokens))
    try Task.checkCancellation()
    return answer.content
  }
  func reset() { session=nil }
}
#endif

@MainActor final class UnavailableAssistantAnswers:AssistantAnswerProvider {
  let availability:AssistantAIAvailability
  init(_ reason:String) { availability = .unavailable(reason) }
  func respond(to prompt:String) async throws -> String { throw CancellationError() }
  func reset() {}
}
@MainActor func makeAssistantAnswers() -> any AssistantAnswerProvider {
  let args=ProcessInfo.processInfo.arguments
  if args.contains("--uitesting") {
    if let i=args.firstIndex(of:"--assistant-ai-fixture"),i+1<args.count {
      return FixtureAssistantAnswers(mode:args[i+1])
    }
    return UnavailableAssistantAnswers("Native model inference is disabled in automated UI tests.")
  }
  #if canImport(FoundationModels) && (os(iOS) || os(macOS) || os(visionOS))
  if #available(iOS 26.0,macOS 26.0,visionOS 26.0,*) { return AppleOnDeviceAnswers() }
  #endif
  return UnavailableAssistantAnswers("Apple on-device answers require a supported device and operating system. Local commands remain available.")
}
/// Explicit synthetic test provider. Never selected by an ordinary launch.
@MainActor final class FixtureAssistantAnswers:AssistantAnswerProvider {
  private let mode:String
  private var resetGeneration=0
  private var questions:[String]=[]
  init(mode:String) { self.mode=mode }
  var availability:AssistantAIAvailability {
    mode=="unavailable" ? .unavailable("Synthetic on-device model unavailable. No cloud fallback."):.available
  }
  func respond(to prompt:String) async throws -> String {
    let ticket=resetGeneration
    if mode=="slow" { try await Task.sleep(nanoseconds:30_000_000_000) }
    if mode=="error" { throw CancellationError() }
    try Task.checkCancellation();guard ticket==resetGeneration else { throw CancellationError() }
    questions.append(prompt)
    if questions.count==1 { return "Synthetic answer: the fictional recipe is named Moon Soup. No action was taken." }
    return "Synthetic follow-up: Moon Soup. This is a fixture, not a native model answer."
  }
  func reset() { resetGeneration+=1;questions=[] }
}
