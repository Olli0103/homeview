import Foundation
import CloudKit
import Intents
// Typecheck only. These functions are never called; no container/account/donation request.
func ownContainer(_ container:CKContainer)->CKDatabase { container.privateCloudDatabase }
func ownInteraction(_ interaction:INInteraction)->INIntent { interaction.intent }
#if canImport(FoundationModels) && !os(tvOS)
import FoundationModels
@available(iOS 26.0,macOS 26.0,visionOS 26.0,watchOS 27.0,*)
func ownTranscript(_ session:LanguageModelSession) throws -> Data {
  try JSONEncoder().encode(session.transcript)
}
#endif
