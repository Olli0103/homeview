import Foundation

#if !os(watchOS)
/// Only the existing local MockHome. Never constructs a HomeKit manager or touches a real lock.
@MainActor final class MockLockDevice: LockDeviceProvider {
  weak var model: AppModel?
  init(model: AppModel) { self.model=model }
  private var fixture: String? {
    let args=ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"),let i=args.firstIndex(of:"--persistence-test"),args.indices.contains(i+1),
      UUID(uuidString:args[i+1]) != nil,let j=args.firstIndex(of:"--mock-lock-state"),args.indices.contains(j+1) else { return nil }
    return args[j+1]
  }
  func read() async throws -> LockReading {
    try readNow()
  }
  private func readNow() throws -> LockReading {
    guard let model else { throw LockDeviceError.unavailable }
    return reading(try model.readMockControlSnapshot())
  }
  private func reading(_ home:MockHome) -> LockReading {
    guard home.online else { return LockReading(state:.unknown) }
    switch fixture {
    case "unknown": return LockReading(state:.unknown)
    case "jammed": return LockReading(state:.jammed,batteryPercent:15)
    case "battery-fault": return LockReading(state:home.locked ? .locked:.unlocked,batteryFault:true)
    case "low-battery": return LockReading(state:home.locked ? .locked:.unlocked,batteryPercent:15)
    default: return LockReading(state:home.locked ? .locked:.unlocked)
    }
  }
  func setLocked(_ target: Bool,expected: LockReading) async throws {
    guard let model,model.route == .lock,model.canControlMockSecurity else { throw LockDeviceError.denied }
    // Read and modify the same current snapshot, not the AppModel cache. A
    // persisted target change must invalidate the consumed approval before any
    // write; unrelated current device values/audit must survive an allowed one.
    var candidate=try model.readMockControlSnapshot()
    let current=reading(candidate)
    guard current.canCommand,current==expected,current.state.lockedValue != target else { throw LockDeviceError.stateChanged }
    try candidate.transact(.lock,authorized:true)
    guard candidate.locked==target else { throw LockDeviceError.stateChanged }
    guard model.commitMockLock(candidate) else { throw LockDeviceError.notWritable }
  }
}
#endif
