/// Limits enforced by the local command and voice-input implementations.
enum AssistantLimits {
  static let recordingSeconds = 30
  static let transcriptCharacters = 1000
  static let timerRequestCharacters = 300
  static let timerSeconds = 86400
}
