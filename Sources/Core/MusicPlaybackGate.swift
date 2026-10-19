import Foundation

/// Serializes mutations of a single native player. A stale completion pauses
/// before the next queued operation starts, never after its successor starts.
@MainActor
final class MusicPlaybackGate {
  private let pauseBackend: @MainActor () -> Void
  private var generation = 0
  private var tailID = 0
  private var tail: Task<Void, Error>?
  init(pause: @escaping @MainActor () -> Void) { pauseBackend=pause }
  func run(_ action: @escaping @MainActor () async throws -> Void) async throws {
    try Task.checkCancellation()
    generation += 1
    let ticket=generation;let previous=tail
    let work=Task { @MainActor in
      if let previous { _ = try? await previous.value }
      guard generation==ticket,!Task.isCancelled else { throw CancellationError() }
      do { try await action() }
      catch {
        pauseBackend()
        if generation != ticket || Task.isCancelled { throw CancellationError() }
        throw error
      }
      guard generation==ticket,!Task.isCancelled else {
        pauseBackend();throw CancellationError()
      }
    }
    tailID=ticket;tail=work
    defer { if tailID==ticket { tail=nil } }
    try await withTaskCancellationHandler {
      try await work.value
    } onCancel: {
      work.cancel()
      Task { @MainActor [weak self] in
        guard let self,self.generation==ticket else { return }
        self.stop()
      }
    }
  }
  func stop() {
    generation += 1
    tail?.cancel()
    pauseBackend()
  }
}
