import Foundation
import Observation

enum AssistantAIAvailability:Equatable,Sendable {
  case notSelected,available,unavailable(String)
  var message:String {
    switch self {
    case .notSelected:"Not selected. Availability is checked only when you choose on-device answers."
    case .available:"Apple on-device answers are available. No cloud provider or web search."
    case .unavailable(let reason):reason
    }
  }
}
@MainActor protocol AssistantAnswerProvider:AnyObject {
  var availability:AssistantAIAvailability { get }
  func respond(to prompt:String) async throws -> String
  /// Discard the entire provider conversation, not just its visible answer.
  func reset()
}
struct AssistantExchange:Identifiable,Equatable,Sendable {
  let id=UUID()
  let question:String
  let answer:String
}
enum AssistantConversationLimits {
  static let requestCharacters=1000
  static let replyCharacters=4000
  static let conversationCharacters=6000
  static let exchanges=4
  static let responseTokens=400
  static let timeoutNanoseconds:UInt64=45_000_000_000
}
@MainActor @Observable
final class AssistantConversation {
  private let provider:any AssistantAnswerProvider
  private let timeoutNanoseconds:UInt64
  private var task:Task<Void,Never>?
  private var timeoutTask:Task<Void,Never>?
  private var generation=0
  private(set) var availability=AssistantAIAvailability.notSelected
  private(set) var exchanges:[AssistantExchange]=[]
  private(set) var pendingQuestion:String?
  private(set) var busy=false
  private(set) var status="Choose on-device answers explicitly. Only the questions you send are used."
  init(provider:any AssistantAnswerProvider,timeoutNanoseconds:UInt64=AssistantConversationLimits.timeoutNanoseconds) {
    self.provider=provider;self.timeoutNanoseconds=timeoutNanoseconds
  }
  func select() { clear();availability=provider.availability;status=availability.message }
  func deselect() { clear();availability = .notSelected }
  func clear(status:String="Conversation cleared. Nothing is saved.") {
    generation+=1;task?.cancel();timeoutTask?.cancel();task=nil;timeoutTask=nil
    provider.reset();exchanges=[];pendingQuestion=nil;busy=false;self.status=status
  }
  @discardableResult
  func ask(_ input:String) -> Bool {
    guard !Task.isCancelled,!busy else { return false }
    guard availability != .notSelected else { status=availability.message;return false }
    let prompt=input.trimmingCharacters(in:.whitespacesAndNewlines)
    guard !prompt.isEmpty,prompt.count<=AssistantConversationLimits.requestCharacters else {
      status="Use a question of 1 to \(AssistantConversationLimits.requestCharacters) characters.";return false
    }
    availability=provider.availability
    guard availability == .available else { status=availability.message;return false }
    let used=exchanges.reduce(0) { $0+$1.question.count+$1.answer.count }
    guard exchanges.count<AssistantConversationLimits.exchanges,
      used+prompt.count<=AssistantConversationLimits.conversationCharacters else {
      status="Conversation limit reached. Start a new conversation before sending more.";return false
    }
    generation+=1;let ticket=generation
    let deadline=ContinuousClock.now.advanced(by:.nanoseconds(Int64(clamping:timeoutNanoseconds)))
    pendingQuestion=prompt;busy=true;status="Thinking on this device…"
    timeoutTask=Task { [weak self] in
      do { try await Task.sleep(nanoseconds:self?.timeoutNanoseconds ?? 0) } catch { return }
      guard let self,self.generation==ticket,!Task.isCancelled else { return }
      self.clear(status:"The local response timed out. Conversation cleared; try a new question.")
    }
    task=Task { [weak self] in
      guard let self else { return }
      do {
        try Task.checkCancellation()
        let answer=try await self.provider.respond(to:prompt)
        guard !Task.isCancelled,self.generation==ticket else { return }
        guard ContinuousClock.now<deadline else {
          self.clear(status:"The local response timed out. Conversation cleared; try a new question.");return
        }
        let clean=answer.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !clean.isEmpty,clean.count<=AssistantConversationLimits.replyCharacters,
          used+prompt.count+clean.count<=AssistantConversationLimits.conversationCharacters else {
          self.clear(status:"The response exceeded the local conversation limit. Conversation cleared.");return
        }
        self.timeoutTask?.cancel();self.timeoutTask=nil;self.task=nil
        self.exchanges.append(AssistantExchange(question:prompt,answer:clean))
        self.pendingQuestion=nil;self.busy=false
        self.status="On-device answer · May be wrong or outdated. No web search or actions."
      } catch {
        guard !Task.isCancelled,self.generation==ticket else { return }
        self.clear(status:"The local model could not answer. It may be unavailable, out of context or decline the request. Conversation cleared; no action was taken.")
      }
    }
    return true
  }
}
