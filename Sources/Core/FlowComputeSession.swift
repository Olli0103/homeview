import Foundation
import Observation

/// Serial CPU fallback starts from the last accepted snapshot, never an in-flight texture.
actor FlowCPUBackend: FlowComputeBackend {
  private var snapshot:FlowSimulation
  init(snapshot:FlowSimulation) { self.snapshot=snapshot }
  func step(time:Float,delta:Float,impulse:SIMD2<Float>) async throws -> FlowSimulation {
    try Task.checkCancellation()
    var next=snapshot
    next.step(time:time,delta:delta,impulse:impulse)
    try Task.checkCancellation()
    snapshot=next
    return next
  }
}

func makeFlowComputeBackend(_ snapshot:FlowSimulation) -> any FlowComputeBackend {
  #if canImport(Metal) && !os(watchOS)
  FlowMetalSimulation(snapshot:snapshot)
  #else
  FlowCPUBackend(snapshot:snapshot)
  #endif
}

/// One pending frame per owner. Revocation rejects late success and cleanup alike.
@MainActor @Observable final class FlowComputeSession {
  private(set) var simulation:FlowSimulation
  private(set) var revision:UInt64=0
  private(set) var isWorking=false
  private(set) var active=false
  private(set) var usingCPUFallback=false
  @ObservationIgnored private var generation:UInt64=0
  @ObservationIgnored private var task:Task<Void,Never>?
  @ObservationIgnored private var backend:(any FlowComputeBackend)?
  @ObservationIgnored private var lastRequestedTime:Float?
  @ObservationIgnored private let factory:@Sendable (FlowSimulation)->any FlowComputeBackend

  init(snapshot:FlowSimulation=FlowSimulation(),
       factory:@escaping @Sendable (FlowSimulation)->any FlowComputeBackend=makeFlowComputeBackend) {
    simulation=snapshot;self.factory=factory
  }
  func activate() {
    guard !active else { return }
    active=true
    lastRequestedTime=nil
    usingCPUFallback=false
  }
  func deactivate() {
    active=false;generation &+= 1
    task?.cancel();task=nil;backend=nil;isWorking=false
    lastRequestedTime=nil
  }
  @discardableResult func request(time:Float,delta:Float,impulse:SIMD2<Float>) -> Bool {
    guard active,!isWorking,time.isFinite,delta.isFinite,delta>0,
      impulse.x.isFinite,impulse.y.isFinite,time != lastRequestedTime else { return false }
    let token=generation,start=simulation
    let selected=backend ?? factory(start)
    backend=selected;lastRequestedTime=time;isWorking=true
    task=Task { [weak self] in
      do {
        let result=try await selected.step(time:time,delta:delta,impulse:impulse)
        guard !Task.isCancelled,let self,self.active,self.generation==token else { return }
        self.simulation=result;self.revision &+= 1;self.isWorking=false;self.task=nil
      } catch {
        guard !Task.isCancelled,let self,self.active,self.generation==token else { return }
        // A backend failure changes only this active owner's backend, not its
        // accepted field. A fresh activation may retry Metal from that field.
        let fallback=FlowCPUBackend(snapshot:start)
        do {
          let result=try await fallback.step(time:time,delta:delta,impulse:impulse)
          guard !Task.isCancelled,self.active,self.generation==token else { return }
          self.backend=fallback;self.usingCPUFallback=true
          self.simulation=result;self.revision &+= 1;self.isWorking=false;self.task=nil
        } catch {
          guard !Task.isCancelled,self.active,self.generation==token else { return }
          self.backend=nil;self.isWorking=false;self.task=nil;self.lastRequestedTime=nil
        }
      }
    }
    return true
  }
  // Capture/await one operation independently of any later owner replacement.
  var pendingOperation:Task<Void,Never>? { task }
  // Await the exact current owner task; useful for deterministic native tests.
  func waitForPendingStep() async { await task?.value }
}
