import Foundation
import FoundationModels

// Type-check ONLY. No main, no top-level initialization, no model construction,
// no entitlement change, no session/request execution and no quota consultation.
@available(iOS 27.0,macOS 27.0,visionOS 27.0,watchOS 27.0,*)
func declaredPCCSurface(_ supplied:PrivateCloudComputeLanguageModel)
 -> (PrivateCloudComputeLanguageModel.Availability,PrivateCloudComputeLanguageModel.QuotaUsage) {
  (supplied.availability,supplied.quotaUsage)
}
@available(iOS 27.0,macOS 27.0,visionOS 27.0,watchOS 27.0,*)
func declaredPCCSession(_ supplied:PrivateCloudComputeLanguageModel) -> LanguageModelSession {
  LanguageModelSession(model:supplied,tools:[],instructions:"Synthetic compile-only declaration; never executed.")
}
@available(iOS 27.0,macOS 27.0,visionOS 27.0,watchOS 27.0,*)
func declaredPCCFailure(_ failure:PrivateCloudComputeLanguageModel.Error) -> String {
  switch failure {
  case .networkFailure:return "network unavailable"
  case .quotaLimitReached(let quota):return quota.resetDate == nil ? "limit, reset unknown":"limit, reset known"
  case .serviceUnavailable:return "service unavailable"
  @unknown default:return "unknown"
  }
}
