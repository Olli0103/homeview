import Foundation
import Observation

#if canImport(UIKit) && (os(iOS) || os(tvOS))
  import UIKit
#endif

@MainActor @Observable
final class DisplayWakeController {
  private(set) var active = false
  @ObservationIgnored private var refreshTask: Task<Void, Never>?
  #if os(macOS)
    @ObservationIgnored private var activity: NSObjectProtocol?
  #endif
  var supported: Bool {
    #if os(iOS) || os(tvOS) || os(macOS)
      true
    #else
      false
    #endif
  }
  func apply(enabled: Bool) {
    #if canImport(UIKit) && (os(iOS) || os(tvOS))
      refreshTask?.cancel()
      UIApplication.shared.isIdleTimerDisabled = enabled
      active = UIApplication.shared.isIdleTimerDisabled
      // UIKit applies the scene idle-timer assertion asynchronously.
      refreshTask = Task { [weak self] in
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else { return }
        self?.active = UIApplication.shared.isIdleTimerDisabled
      }
    #elseif os(macOS)
      if enabled, activity == nil {
        activity = ProcessInfo.processInfo.beginActivity(
          options: [.idleDisplaySleepDisabled, .idleSystemSleepDisabled],
          reason: "HomeView foreground display")
      }
      if !enabled, let token = activity {
        ProcessInfo.processInfo.endActivity(token)
        activity = nil
      }
      active = activity != nil
    #else
      active = false
    #endif
  }
}
