import XCTest
@testable import HomeViewCore
#if canImport(Metal)
import Metal
#endif

private actor HeldFlowBackend:FlowComputeBackend {
  private let snapshot:FlowSimulation
  private var started=false
  private var startWaiter:CheckedContinuation<Void,Never>?
  private var releaseWaiter:CheckedContinuation<Void,Never>?
  private let fails:Bool
  init(_ snapshot:FlowSimulation,fails:Bool=false) { self.snapshot=snapshot;self.fails=fails }
  func step(time:Float,delta:Float,impulse:SIMD2<Float>) async throws -> FlowSimulation {
    started=true;startWaiter?.resume();startWaiter=nil
    await withCheckedContinuation { releaseWaiter=$0 }
    // Intentionally ignores cancellation to exercise late/hostile completion.
    if fails { throw FlowComputeError.command }
    var result=snapshot;result.step(time:time,delta:delta,impulse:impulse);return result
  }
  func waitUntilStarted() async {
    if started { return };await withCheckedContinuation {startWaiter=$0}
  }
  func release() { releaseWaiter?.resume();releaseWaiter=nil }
}
private actor FailingFlowBackend:FlowComputeBackend {
  func step(time:Float,delta:Float,impulse:SIMD2<Float>) async throws -> FlowSimulation {throw FlowComputeError.unavailable}
}
private final class FlowBackendSequence:@unchecked Sendable {
  private let lock=NSLock()
  private var entries:[any FlowComputeBackend]
  init(_ entries:[any FlowComputeBackend]) {self.entries=entries}
  func next()->any FlowComputeBackend {
    lock.lock();defer {lock.unlock()}
    precondition(!entries.isEmpty);return entries.removeFirst()
  }
}
final class FlowComputeTests:XCTestCase {
  func testSnapshotRestorationRejectsInvalidShapeAndNonfiniteFields() {
    let s=FlowSimulation(side:8)
    XCTAssertNotNil(FlowSimulation(side:8,velocity:s.velocity,dye:s.dye))
    XCTAssertNil(FlowSimulation(side:7,velocity:s.velocity,dye:s.dye))
    XCTAssertNil(FlowSimulation(side:129,velocity:s.velocity,dye:s.dye))
    XCTAssertNil(FlowSimulation(side:8,velocity:Array(s.velocity.dropLast()),dye:s.dye))
    var v=s.velocity;v[10].x = .nan
    XCTAssertNil(FlowSimulation(side:8,velocity:v,dye:s.dye))
    var d=s.dye;d[20].z = .infinity
    XCTAssertNil(FlowSimulation(side:8,velocity:s.velocity,dye:d))
  }
  @MainActor func testSessionInactiveInvalidAndPendingRequestsCannotAdvanceOrReplaceWork() async {
    let initial=FlowSimulation(side:8),held=HeldFlowBackend(FlowSimulation(side:8))
    let s=FlowComputeSession(snapshot:initial,factory:{_ in held})
    XCTAssertFalse(s.request(time:0,delta:0.05,impulse:.zero))
    s.activate()
    for (t,d,i):(Float,Float,SIMD2<Float>) in [(.nan,0.05,.zero),(0,.nan,.zero),(0,0,.zero),(0,-1,.zero),(0,0.05,SIMD2(.infinity,0))] {
      XCTAssertFalse(s.request(time:t,delta:d,impulse:i))
    }
    XCTAssertEqual(s.revision,0)
    XCTAssertTrue(s.request(time:0,delta:0.05,impulse:.zero))
    await held.waitUntilStarted()
    XCTAssertFalse(s.request(time:1,delta:0.05,impulse:.zero))
    await held.release();await s.waitForPendingStep()
    var expected=initial;expected.step(time:0,delta:0.05)
    XCTAssertEqual(s.simulation.velocity,expected.velocity);XCTAssertEqual(s.simulation.dye,expected.dye)
    XCTAssertEqual(s.revision,1)
    XCTAssertFalse(s.request(time:0,delta:0.05,impulse:.zero))
    s.deactivate();XCTAssertFalse(s.isWorking)
  }
  @MainActor func testLateSuccessAfterDeactivationCannotPublishAFrame() async {
    let initial=FlowSimulation(side:8),held=HeldFlowBackend(FlowSimulation(side:8))
    let s=FlowComputeSession(snapshot:initial,factory:{_ in held});s.activate()
    s.request(time:0,delta:0.05,impulse:.zero);await held.waitUntilStarted()
    let joined=s.pendingOperation
    s.deactivate();await held.release();await joined?.value
    XCTAssertEqual(s.revision,0);XCTAssertEqual(s.simulation.velocity,initial.velocity)
    XCTAssertFalse(s.active);XCTAssertFalse(s.isWorking)
  }
  @MainActor func testOldFailureAndCleanupCannotClearANewOwner() async {
    let initial=FlowSimulation(side:8)
    let old=HeldFlowBackend(initial,fails:true),new=HeldFlowBackend(initial)
    let sequence=FlowBackendSequence([old,new])
    let s=FlowComputeSession(snapshot:initial,factory:{_ in sequence.next()});s.activate()
    s.request(time:0,delta:0.05,impulse:.zero);await old.waitUntilStarted()
    let joined=s.pendingOperation
    s.deactivate();s.activate()
    XCTAssertTrue(s.request(time:1,delta:0.05,impulse:.zero));await new.waitUntilStarted()
    await old.release();await joined?.value
    XCTAssertTrue(s.active);XCTAssertTrue(s.isWorking);XCTAssertEqual(s.revision,0)
    XCTAssertFalse(s.usingCPUFallback)
    await new.release();await s.waitForPendingStep()
    var expected=initial;expected.step(time:1,delta:0.05)
    XCTAssertEqual(s.revision,1);XCTAssertFalse(s.isWorking)
    XCTAssertEqual(s.simulation.velocity,expected.velocity);s.deactivate()
  }
  @MainActor func testUnavailableBackendFallsBackFromExactAcceptedStateAndFreshOwnerRetries() async {
    let initial=FlowSimulation(side:8)
    let s=FlowComputeSession(snapshot:initial,factory:{_ in FailingFlowBackend()});s.activate()
    for step in 0..<3 {
      XCTAssertTrue(s.request(time:Float(step),delta:0.2,impulse:SIMD2(3,-7)))
      await s.waitForPendingStep()
    }
    var expected=initial
    for step in 0..<3 {expected.step(time:Float(step),delta:0.2,impulse:SIMD2(3,-7))}
    XCTAssertTrue(s.usingCPUFallback);XCTAssertEqual(s.revision,3)
    XCTAssertEqual(s.simulation.velocity,expected.velocity);XCTAssertEqual(s.simulation.dye,expected.dye)
    s.deactivate();s.activate();XCTAssertFalse(s.usingCPUFallback)
    XCTAssertTrue(s.request(time:3,delta:0.05,impulse:.zero));await s.waitForPendingStep()
    XCTAssertTrue(s.usingCPUFallback);XCTAssertEqual(s.revision,4);s.deactivate()
  }
  #if canImport(Metal)
  func testActualMetalEightFrozenNumericalCasesAgainstUnchangedCPUArithmetic() async throws {
    guard let device=MTLCreateSystemDefaultDevice() else {throw XCTSkip("Actual Metal device unavailable; no numerical PASS")}
    print("Actual Metal numerical device: "+device.name)
    for n in [8,16,40,128] {for seeded in [false,true] {
      var cpu=FlowSimulation(side:n)
      if seeded {
        let v=(0..<n*n).map {SIMD2<Float>(sin(Float($0)*0.37)*0.4,cos(Float($0)*0.23)*0.3)}
        let d=(0..<n*n).map {SIMD3<Float>(Float(($0*17)%101)/100,Float(($0*31)%103)/102,Float(($0*47)%107)/106)}
        cpu=FlowSimulation(side:n,velocity:v,dye:d)!
      }
      let gpu=FlowMetalSimulation(snapshot:cpu);var maxV:Float=0,maxD:Float=0
      for step in 0..<(n==40 ? 100:20) {
        let time=Float(step)/20,delta:Float=step%7==0 ? 0.2:0.05
        let impulse:SIMD2<Float>=step%3==0 ? SIMD2(3,-7):SIMD2(0.3,-0.2)
        cpu.step(time:time,delta:delta,impulse:impulse)
        let actual=try await gpu.step(time:time,delta:delta,impulse:impulse)
        for (a,b) in zip(cpu.velocity,actual.velocity) {maxV=max(maxV,max(abs(a.x-b.x),abs(a.y-b.y)))}
        for (a,b) in zip(cpu.dye,actual.dye) {maxD=max(maxD,max(abs(a.x-b.x),max(abs(a.y-b.y),abs(a.z-b.z))))}
        XCTAssertLessThanOrEqual(maxV,step<20 ? 0.0005:0.001,"velocity n=\(n) seed=\(seeded) step=\(step)")
        XCTAssertLessThanOrEqual(maxD,step<20 ? 0.0001:0.0002,"dye n=\(n) seed=\(seeded) step=\(step)")
      }
      let allocations=await gpu.textureAllocations;XCTAssertEqual(allocations,11)
      print("FROZEN_METAL n=\(n) seed=\(seeded) maxV=\(maxV) maxD=\(maxD)")
    }}
  }
  func testMetalPrecancelledAndInvalidInputAllocateNoTexturesOrCompletedSteps() async throws {
    let gpu=FlowMetalSimulation(snapshot:FlowSimulation(side:8))
    let t=Task { () throws -> Bool in
      withUnsafeCurrentTask {$0?.cancel()}
      _=try await gpu.step(time:0,delta:0.05,impulse:.zero);return true
    }
    do {_=try await t.value;XCTFail("cancelled step accepted")} catch is CancellationError {} catch {XCTFail("wrong cancellation")}
    _=try await gpu.step(time:.nan,delta:0.05,impulse:.zero)
    _=try await gpu.step(time:0,delta:0,impulse:.zero)
    let allocations=await gpu.textureAllocations,steps=await gpu.completedSteps
    XCTAssertEqual(allocations,0);XCTAssertEqual(steps,0)
  }
  #endif
}
