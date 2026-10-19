import Foundation
import Observation

/// Owns the queued start as well as the controller. Cancel invalidates a queued
/// caller before it can begin a new capture, not only an existing recognizer.
@MainActor @Observable
final class AssistantVoiceSession {
  let voice=VoiceInputController()
  private(set) var starting=false
  private(set) var active=false
  private var generation=0
  @ObservationIgnored private var startTask:Task<Void,Never>?
  @ObservationIgnored private var current:(@MainActor ()->Bool)?
  @ObservationIgnored private var aborted:(@MainActor ()->Void)?
  @ObservationIgnored private var beforeStart:@MainActor () async ->Void = { await Task.yield() }
  var contextIsCurrent:Bool { active && current?() == true }
  var acceptsTranscript:Bool {
    contextIsCurrent && (voice.recording || voice.phase == .finishing || voice.phase == .ready)
  }
  var blocksSubmission:Bool { starting || voice.busy || (active && voice.phase == .failed) }
  func start(locale:String,isCurrent:@escaping @MainActor ()->Bool,
             onAborted:@escaping @MainActor ()->Void = {}) {
    guard !Task.isCancelled else { return }
    cancel()
    guard isCurrent() else { onAborted();return }
    generation+=1;let ticket=generation
    current=isCurrent;aborted=onAborted;starting=true;active=true
    startTask=Task { [weak self] in
      guard let self else { return }
      defer { if self.generation==ticket { self.starting=false;self.startTask=nil } }
      await self.beforeStart()
      guard self.generation==ticket else { return }
      guard !Task.isCancelled,self.current?() == true else { self.cancelAndRestore();return }
      await self.voice.start(locale:locale)
      guard self.generation==ticket else { return }
      guard !Task.isCancelled,self.current?() == true else { self.cancelAndRestore();return }
      if self.voice.phase == .failed { self.failureObserved() }
    }
  }
  func failureObserved() {
    guard active,voice.phase == .failed else { return }
    let restore=aborted
    generation+=1;startTask?.cancel();startTask=nil
    starting=false;active=false;current=nil;aborted=nil
    // Preserve the failure explanation; the controller has already stopped
    // capture and discarded incomplete/oversized recognition text.
    restore?()
  }
  func cancelAndRestore() {
    let restore=active ? aborted:nil
    cancel();restore?()
  }
  func cancel() {
    generation+=1;startTask?.cancel();startTask=nil
    starting=false;active=false;current=nil;aborted=nil
    voice.cancel()
  }
}
