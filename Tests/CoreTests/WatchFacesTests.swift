import CoreGraphics
import XCTest

@testable import HomeViewCore

final class WatchFacesTests: XCTestCase {
  func testOldSnapshotMigratesWidgetsWithoutLosingState() throws {
    var legacy = Snapshot()
    legacy.widgets = ["Weather", "Date", "Timer", "Clock"]
    legacy.home.temperature = 73
    var json =
      try JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as! [String: Any]
    json.removeValue(forKey: "faceConfigurations")
    let restored = try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject: json))
    XCTAssertEqual(restored.home.temperature, 73)
    XCTAssertEqual(restored.complication(for: .modular, slot: Face.modular.slots[0]), .weather)
  }
  func testPerFaceRoundTripAndFamilyValidation() throws {
    var state = Snapshot()
    let top = Face.watchModular.slots[0]
    let middle = Face.watchModular.slots[1]
    state.setComplication(.weather, for: .watchModular, slot: top)
    state.setComplication(.calendar, for: .watchModular, slot: top)  // invalid small family
    state.setComplication(.music, for: .watchModular, slot: middle)
    state.editConfiguration(for: .watchModular) { $0.theme = 1 }
    state.editConfiguration(for: .flow) {
      $0.flowBackground = false
      $0.flowTypeface = 1
    }
    let restored = try Snapshot.decodeMigrating(JSONEncoder().encode(state))
    XCTAssertEqual(restored.complication(for: .watchModular, slot: top), .weather)
    XCTAssertEqual(restored.complication(for: .watchModular, slot: middle), .music)
    XCTAssertEqual(restored.complication(for: .modular, slot: Face.modular.slots[0]), .date)
    XCTAssertEqual(restored.configuration(for: .watchModular).theme, 1)
    XCTAssertEqual(restored.configuration(for: .modular).theme, 0)
    XCTAssertFalse(restored.configuration(for: .flow).flowBackground)
    XCTAssertEqual(restored.configuration(for: .flow).flowTypeface, 1)
  }
  func testLayoutContractsAndInvalidSlotsCannotCrashOrWrite() throws {
    let counts: [Face: Int] = [
      .modular: 4, .watchModular: 5, .infographModular: 6, .modularDuo: 3, .modularCompact: 3,
    ]
    var state = Snapshot()
    state.theme = 1
    XCTAssertEqual(state.configuration(for: .modularDuo).theme, 0)
    XCTAssertEqual(state.configuration(for: .modular).theme, 1)
    for (face, count) in counts {
      XCTAssertEqual(face.slots.count, count)
      XCTAssertEqual(Set(face.slots.map(\.id)).count, count)
      for p in face.definition.placements {
        XCTAssertTrue(CGRect(x: 0, y: 0, width: 600, height: 600).contains(p.rect))
        XCTAssertTrue(p.slot.choices.contains(state.complication(for: face, slot: p.slot)))
      }
    }
    let unknown = FaceSlot(id: "not-a-slot", title: "Invalid", family: .panel)
    state.setComplication(.music, for: .infographModular, slot: unknown)
    XCTAssertEqual(state.complication(for: .infographModular, slot: unknown), .none)
    XCTAssertTrue(state.faceConfigurations.isEmpty)
    let date = Face.infographModular.slots[1]
    state.setComplication(.music, for: .infographModular, slot: date)
    XCTAssertEqual(state.complication(for: .infographModular, slot: date), .date)
    state.setComplication(.none, for: .infographModular, slot: date)
    state.setComplication(.music, for: .modularDuo, slot: Face.modularDuo.slots[1])
    state.face = .modularDuo
    let restored = try Snapshot.decodeMigrating(JSONEncoder().encode(state))
    XCTAssertEqual(restored.face, .modularDuo)
    XCTAssertEqual(restored.complication(for: .infographModular, slot: date), .none)
    XCTAssertEqual(restored.complication(for: .modularDuo, slot: Face.modularDuo.slots[1]), .music)
    XCTAssertEqual(
      restored.complication(for: .watchModular, slot: Face.watchModular.slots[1]), .calendar)
  }
  func testStoredIncompatibleFamilyFallsBackWithoutOverwritingOtherFaces() {
    var state = Snapshot()
    state.editConfiguration(for: .modularDuo) { $0.complications["topLeft"] = .music }
    XCTAssertEqual(state.complication(for: .modularDuo, slot: Face.modularDuo.slots[0]), .none)
    // A forged family with a genuine slot id must not bypass the schema.
    let forged = FaceSlot(id: "topLeft", title: "Top left", family: .panel)
    state.setComplication(.calendar, for: .modularDuo, slot: forged)
    XCTAssertEqual(state.configuration(for: .modularDuo).complications["topLeft"], .music)
    XCTAssertEqual(state.complication(for: .watchModular, slot: Face.watchModular.slots[0]), .date)
  }
  func testRecoveredDivergenceAndGradientAgainstAnalyticFields() {
    let n = 8
    let velocity = (0..<n * n).map { SIMD2<Float>(Float($0 % n), Float($0 / n)) }
    let div = FlowSimulation.divergence(velocity, side: n)
    XCTAssertEqual(div[3 * n + 3], 2, accuracy: 0.00001)
    let pressure = (0..<n * n).map { Float($0 % n) * 2 + Float($0 / n) * 3 }
    let corrected = FlowSimulation.subtractGradient(
      pressure, from: .init(repeating: .zero, count: n * n), side: n)
    XCTAssertEqual(corrected[3 * n + 3].x, -2, accuracy: 0.00001)
    XCTAssertEqual(corrected[3 * n + 3].y, -3, accuracy: 0.00001)
  }
  func testJacobiSingleSourceAndProjectionReducesDivergence() {
    let n = 16
    var source = [Float](repeating: 0, count: n * n)
    source[8 * n + 8] = 4
    XCTAssertEqual(FlowSimulation.pressure(for: source, side: n, iterations: 1)[8 * n + 8], -1)
    let velocity = (0..<n * n).map { i in
      SIMD2<Float>(sin(Float(i % n) * 0.4), cos(Float(i / n) * 0.4))
    }
    let before = FlowSimulation.divergence(velocity, side: n)
    let p = FlowSimulation.pressure(for: before, side: n, iterations: 80)
    let after = FlowSimulation.divergence(
      FlowSimulation.subtractGradient(p, from: velocity, side: n), side: n)
    func energy(_ d: [Float]) -> Float { d.reduce(0) { $0 + $1 * $1 } }
    XCTAssertLessThan(energy(after), energy(before) * 0.7)
  }
  func testVorticityAndConfinementMatchAnalyticRotationAndMagnitudeGradient() {
    let n = 8
    let rotation = (0..<n * n).map { SIMD2<Float>(-Float($0 / n), Float($0 % n)) }
    let curl = FlowSimulation.vorticity(rotation, side: n)
    XCTAssertEqual(curl[3 * n + 3], 2, accuracy: 0.00001)
    let constant = [Float](repeating: 2, count: n * n)
    XCTAssertEqual(
      FlowSimulation.confine(rotation, curl: constant, side: n, strength: 2, delta: 0.1), rotation)
    let ramp = (0..<n * n).map { Float($0 / n) + 2 }
    let forced = FlowSimulation.confine(
      .init(repeating: .zero, count: n * n), curl: ramp,
      side: n, strength: 2, delta: 0.1)
    XCTAssertEqual(forced[3 * n + 3].x, 1 / 1.0001, accuracy: 0.00001)
    XCTAssertEqual(forced[3 * n + 3].y, 0, accuracy: 0.00001)
    XCTAssertEqual(
      FlowSimulation.confine(rotation, curl: ramp, side: n, strength: 2, delta: 0), rotation)
  }
  func testBoundaryReflectsOnlyNormalVelocityAndCopiesNeighborPressure() {
    let n = 8
    let v = FlowSimulation.velocityBoundary(.init(repeating: SIMD2(2, 3), count: n * n), side: n)
    XCTAssertEqual(v[3 * n], SIMD2(-2, 3))
    XCTAssertEqual(v[3 * n + 7], SIMD2(-2, 3))
    XCTAssertEqual(v[3], SIMD2(2, -3))
    XCTAssertEqual(v[7 * n + 3], SIMD2(2, -3))
    XCTAssertEqual(v[0], .zero)
    XCTAssertEqual(v[3 * n + 3], SIMD2(2, 3))
    let field = (0..<n * n).map { Float($0 % n + 3 * ($0 / n)) }
    let p = FlowSimulation.pressureBoundary(field, side: n)
    XCTAssertEqual(p[3 * n], field[3 * n + 1])
    XCTAssertEqual(p[0], field[n + 1])
    XCTAssertEqual(p[3 * n + 3], field[3 * n + 3])
    let solved = FlowSimulation.pressure(for: field, side: n, iterations: 16, boundaries: true)
    XCTAssertEqual(solved, FlowSimulation.pressureBoundary(solved, side: n))
  }
  func testBoundedTouchAndWallConditionsSurviveLongFluidRun() {
    var sim = FlowSimulation(side: 16)
    for i in 0..<1200 {
      let sign: Float = i % 120 < 60 ? 1 : -1
      sim.step(
        time: Float(i) / 20, delta: 0.05,
        impulse: SIMD2(sign * Float.greatestFiniteMagnitude, -sign * Float.greatestFiniteMagnitude))
    }
    XCTAssertTrue(sim.velocity.allSatisfy { $0.x.isFinite && $0.y.isFinite })
    XCTAssertEqual(sim.velocity, FlowSimulation.velocityBoundary(sim.velocity, side: sim.side))
    XCTAssertTrue(
      sim.dye.allSatisfy {
        (0...1).contains($0.x) && (0...1).contains($0.y) && (0...1).contains($0.z)
      })
    let before = sim.dye
    sim.step(time: .nan, delta: 0.05)
    sim.step(time: 0, delta: .infinity)
    XCTAssertEqual(sim.dye, before)
  }
  func testFluidRemainsFiniteMovesAndHonorsZeroDelta() {
    var sim = FlowSimulation(side: 16)
    let initial = sim.dye
    sim.step(time: 0, delta: 0)
    XCTAssertEqual(initial, sim.dye)
    for i in 0..<600 { sim.step(time: Float(i) / 20, delta: 1.0 / 20, impulse: SIMD2(0.4, -0.2)) }
    XCTAssertNotEqual(initial, sim.dye)
    let red = sim.dye.map(\.x)
    let green = sim.dye.map(\.y)
    XCTAssertGreaterThan(
      red.max()! - red.min()!, 0.25, "Dye must not collapse to a uniform color after 30 seconds")
    XCTAssertGreaterThan(green.max()! - green.min()!, 0.25)
    XCTAssertTrue(sim.dye.allSatisfy { $0.x.isFinite && $0.y.isFinite && $0.z.isFinite })
    XCTAssertTrue(
      sim.dye.allSatisfy {
        (0...1).contains($0.x) && (0...1).contains($0.y) && (0...1).contains($0.z)
      })
  }
}
