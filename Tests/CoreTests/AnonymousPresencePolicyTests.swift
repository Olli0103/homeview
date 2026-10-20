import XCTest
@testable import HomeViewCore

final class AnonymousPresencePolicyTests: XCTestCase {
  private func frame(_ sequence:UInt64,_ time:Double,_ meters:[Float]=[2.5],
                     confidence:Float=0.95,motion:SIMD2<Float> = .zero,
                     detected:Int?=nil)->SyntheticPresenceFrame {
    .init(sequence:sequence,capturedAt:time,detectedPeople:detected ?? meters.count,
          distances:meters.map { .init(meters:$0,confidence:confidence) },normalizedMotion:motion)
  }
  private func farPolicy() throws -> (AnonymousPresencePolicy,AnonymousPresencePolicy.SourceToken) {
    var p=AnonymousPresencePolicy();let token=try XCTUnwrap(p.beginSyntheticSource(at:0))
    for i in 0...2 {XCTAssertTrue(p.receive(frame(UInt64(i+1),Double(i)/2),from:token,at:Double(i)/2))}
    XCTAssertEqual(p.decision.band,.far)
    return(p,token)
  }

  func testManualDefaultHasNoImplicitSourceOrMotion() throws {
    var p=AnonymousPresencePolicy(),other=AnonymousPresencePolicy()
    let foreign=try XCTUnwrap(other.beginSyntheticSource(at:0)),before=p.decision
    XCTAssertFalse(p.receive(frame(1,0),from:foreign,at:0));p.tick(at:1000)
    XCTAssertEqual(p.decision,before);XCTAssertEqual(p.decision.band,.near)
    XCTAssertEqual(p.decision.origin,.manual);XCTAssertEqual(p.decision.condition,.selected)
    XCTAssertEqual(p.decision.flowImpulse,.zero);XCTAssertNil(p.decision.farthestSuppliedDistance)
  }
  func testFarTransitionRequiresDwellAndThreeUniqueFrames() throws {
    var p=AnonymousPresencePolicy();let t=try XCTUnwrap(p.beginSyntheticSource(at:0))
    XCTAssertEqual(p.decision.condition,.waiting)
    for i in 0...2 {
      XCTAssertTrue(p.receive(frame(UInt64(i+1),Double(i)/2),from:t,at:Double(i)/2))
      XCTAssertEqual(p.decision.band,i==2 ? .far:.near)
    }
    XCTAssertEqual(p.decision.origin,.synthetic);XCTAssertEqual(p.decision.condition,.tracking)
  }
  func testNearTransitionRetainsManualFarUntilSustained() throws {
    var p=AnonymousPresencePolicy(manualBand:.far);let t=try XCTUnwrap(p.beginSyntheticSource(at:0))
    for i in 0...2 {
      XCTAssertTrue(p.receive(frame(UInt64(i+1),Double(i)/2,[1]),from:t,at:Double(i)/2))
      XCTAssertEqual(p.decision.band,i==2 ? .near:.far)
    }
  }
  func testHysteresisBandAndInterruptedExcursionDoNotFlap() throws {
    var p=AnonymousPresencePolicy();let t=try XCTUnwrap(p.beginSyntheticSource(at:0))
    for i in 0..<10 {
      let at=Double(i)/2
      XCTAssertTrue(p.receive(frame(UInt64(i+1),at,[i.isMultiple(of:2) ? 1.3:1.9]),from:t,at:at))
      XCTAssertEqual(p.decision.band,.near)
    }
    p.receive(frame(11,5),from:t,at:5)
    p.receive(frame(12,5.5,[1.9]),from:t,at:5.5)
    p.receive(frame(13,6),from:t,at:6);p.receive(frame(14,6.5),from:t,at:6.5)
    XCTAssertEqual(p.decision.band,.near)
    p.receive(frame(15,7),from:t,at:7);XCTAssertEqual(p.decision.band,.far)
  }
  func testDuplicatesAndOutOfOrderFramesCannotAdvanceClockOrDwell() throws {
    var p=AnonymousPresencePolicy();let t=try XCTUnwrap(p.beginSyntheticSource(at:0))
    p.receive(frame(1,0),from:t,at:0)
    XCTAssertFalse(p.receive(frame(1,9999),from:t,at:9999))
    XCTAssertTrue(p.receive(frame(2,0.5),from:t,at:0.5))
    XCTAssertFalse(p.receive(frame(2,0.5),from:t,at:0.6))
    XCTAssertEqual(p.decision.band,.near)
    XCTAssertTrue(p.receive(frame(3,1),from:t,at:1));XCTAssertEqual(p.decision.band,.far)
    let before=p.decision
    XCTAssertFalse(p.receive(frame(4,0.75),from:t,at:1.2));XCTAssertEqual(p.decision,before)
    XCTAssertTrue(p.receive(frame(4,1.5),from:t,at:1.5))
  }
  func testGapDoesNotCountAsContinuousDwell() throws {
    var p=AnonymousPresencePolicy();let t=try XCTUnwrap(p.beginSyntheticSource(at:0))
    p.receive(frame(1,0),from:t,at:0);p.receive(frame(2,0.75),from:t,at:0.75)
    p.receive(frame(3,1.25),from:t,at:1.25);XCTAssertEqual(p.decision.band,.near)
    p.receive(frame(4,1.75),from:t,at:1.75);XCTAssertEqual(p.decision.band,.far)
  }
  func testSilenceFallsBackAndRecoveryNeedsFreshDwell() throws {
    var(p,t)=try farPolicy();p.tick(at:3.999);XCTAssertEqual(p.decision.band,.far)
    p.tick(at:4);XCTAssertEqual(p.decision.band,.near);XCTAssertEqual(p.decision.origin,.manual)
    XCTAssertEqual(p.decision.condition,.stale);XCTAssertEqual(p.decision.flowImpulse,.zero)
    p.receive(frame(4,5),from:t,at:5);p.receive(frame(5,5.5),from:t,at:5.5)
    XCTAssertEqual(p.decision.band,.near)
    p.receive(frame(6,6),from:t,at:6);XCTAssertEqual(p.decision.band,.far)
  }
  func testEmptyFrameIsUnknownNotAnAbsenceOrNewSource() throws {
    var(p,t)=try farPolicy();XCTAssertFalse(p.receive(frame(4,1.5,[]),from:t,at:1.5))
    XCTAssertEqual(p.decision.band,.near);XCTAssertEqual(p.decision.origin,.manual)
    XCTAssertEqual(p.decision.condition,.unusable);XCTAssertNil(p.decision.farthestSuppliedDistance)
  }
  func testFarthestSuppliedPersonAndIncompleteFramePolicy() throws {
    var p=AnonymousPresencePolicy();let t=try XCTUnwrap(p.beginSyntheticSource(at:0))
    for i in 0...2 {p.receive(frame(UInt64(i+1),Double(i)/2,[0.8,2.5]),from:t,at:Double(i)/2)}
    XCTAssertEqual(p.decision.band,.far);XCTAssertEqual(p.decision.farthestSuppliedDistance,2.5)
    XCTAssertFalse(p.receive(frame(4,1.5,[0.8,2.5],detected:3),from:t,at:1.5))
    XCTAssertEqual(p.decision.origin,.manual);XCTAssertEqual(p.decision.condition,.unusable)
  }
  func testInvalidDistanceNeverLeavesSyntheticDensityOrMotion() throws {
    for invalid:Float in [0,0.249,10.01,-1,.nan,.infinity,-.infinity] {
      var(p,t)=try farPolicy();XCTAssertFalse(p.receive(frame(4,1.5,[invalid]),from:t,at:1.5))
      XCTAssertEqual(p.decision.band,.near);XCTAssertEqual(p.decision.origin,.manual)
      XCTAssertEqual(p.decision.flowImpulse,.zero)
    }
  }
  func testInvalidConfidenceAndOversizedCoverageFallBack() throws {
    for invalid:Float in [-1,0.749,1.001,.nan,.infinity] {
      var(p,t)=try farPolicy();XCTAssertFalse(p.receive(frame(4,1.5,[1],confidence:invalid),from:t,at:1.5))
      XCTAssertEqual(p.decision.origin,.manual);XCTAssertEqual(p.decision.condition,.unusable)
    }
    var(p,t)=try farPolicy()
    XCTAssertFalse(p.receive(frame(4,1.5,Array(repeating:2,count:17)),from:t,at:1.5))
    XCTAssertEqual(p.decision.origin,.manual)
  }
  func testCaptureAgeFutureNonfiniteAndNegativeTimeAreNotFreshSamples() throws {
    for capture in [1.25,2.1,Double.nan,Double.infinity,-1] {
      var(p,t)=try farPolicy();var f=frame(4,capture)
      f.detectedPeople=1
      XCTAssertFalse(p.receive(f,from:t,at:2))
      XCTAssertEqual(p.decision.origin,.manual);XCTAssertEqual(p.decision.condition,.unusable)
    }
  }
  func testOldSourceCannotMutateNewSourceOrPoisonItsClock() throws {
    var(p,old)=try farPolicy();let fresh=try XCTUnwrap(p.beginSyntheticSource(at:2))
    XCTAssertNotEqual(fresh,old);let before=p.decision
    XCTAssertFalse(p.receive(frame(999,9999),from:old,at:9999));XCTAssertEqual(p.decision,before)
    for i in 0...2 {XCTAssertTrue(p.receive(frame(UInt64(i+1),2+Double(i)/2),from:fresh,at:2+Double(i)/2))}
    XCTAssertEqual(p.decision.band,.far)
  }
  func testManualOverrideInvalidatesEveryLateSyntheticResult() throws {
    var(p,old)=try farPolicy();p.selectManual(.far);let before=p.decision
    XCTAssertFalse(p.receive(frame(99,9999,[1]),from:old,at:9999));p.tick(at:10000)
    XCTAssertEqual(p.decision,before);XCTAssertEqual(p.decision.origin,.manual)
    XCTAssertEqual(p.decision.condition,.selected)
    XCTAssertNotNil(p.beginSyntheticSource(at:0))
  }
  func testNormalizedMotionIsBoundedSmoothedAndResetAfterGapOrInvalidInput() throws {
    var p=AnonymousPresencePolicy();let t=try XCTUnwrap(p.beginSyntheticSource(at:0))
    p.receive(frame(1,0,motion:SIMD2(100,-100)),from:t,at:0)
    XCTAssertEqual(p.decision.flowImpulse,.zero)
    p.receive(frame(2,0.25,motion:SIMD2(100,-100)),from:t,at:0.25)
    let first=p.decision.flowImpulse
    XCTAssertGreaterThan(first.x,0);XCTAssertLessThan(first.x,1);XCTAssertEqual(first.x,-first.y)
    p.receive(frame(3,0.5,motion:SIMD2(100,-100)),from:t,at:0.5)
    XCTAssertGreaterThan(p.decision.flowImpulse.x,first.x);XCTAssertLessThanOrEqual(p.decision.flowImpulse.x,1)
    p.receive(frame(4,1.25,motion:SIMD2(1,1)),from:t,at:1.25);XCTAssertEqual(p.decision.flowImpulse,.zero)
    XCTAssertFalse(p.receive(frame(5,1.5,motion:SIMD2(.nan,0)),from:t,at:1.5))
    XCTAssertEqual(p.decision.origin,.manual);XCTAssertEqual(p.decision.flowImpulse,.zero)
  }
  func testReceiptClockRejectsInvalidEventsWithoutResettingCurrentSource() throws {
    var(p,t)=try farPolicy();let before=p.decision
    for invalid in [-1,Double.nan,Double.infinity,0.9] {
      XCTAssertFalse(p.receive(frame(4,1.5),from:t,at:invalid));p.tick(at:invalid)
      XCTAssertNil(p.beginSyntheticSource(at:invalid));XCTAssertEqual(p.decision,before)
    }
    XCTAssertTrue(p.receive(frame(4,1.5),from:t,at:1.5))
  }
  func testExactConfidenceDistanceAgeAndGapBoundariesAreAccepted() throws {
    var p=AnonymousPresencePolicy();let t=try XCTUnwrap(p.beginSyntheticSource(at:0))
    for i in 0...2 {
      let capture=Double(i)/2
      XCTAssertTrue(p.receive(frame(UInt64(i+1),capture,[0.25,10],confidence:0.75),from:t,at:capture+0.5))
    }
    XCTAssertEqual(p.decision.band,.far)
    p.tick(at:4);XCTAssertEqual(p.decision.origin,.manual);XCTAssertEqual(p.decision.condition,.stale)
  }
}
