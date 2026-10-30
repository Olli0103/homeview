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
    guard model.data.home.online else { return LockReading(state:.unknown) }
    switch fixture {
    case "unknown": return LockReading(state:.unknown)
    case "jammed": return LockReading(state:.jammed,batteryPercent:15)
    case "battery-fault": return LockReading(state:model.data.home.locked ? .locked:.unlocked,batteryFault:true)
    case "low-battery": return LockReading(state:model.data.home.locked ? .locked:.unlocked,batteryPercent:15)
    default: return LockReading(state:model.data.home.locked ? .locked:.unlocked)
    }
  }
  func setLocked(_ target: Bool,expected: LockReading) async throws {
    guard let model,model.route == .lock,model.canControlMockSecurity else { throw LockDeviceError.denied }
    let current=try readNow()
    guard current.canCommand,current==expected,current.state.lockedValue != target else { throw LockDeviceError.stateChanged }
    var candidate=model.data.home
    try candidate.transact(.lock,authorized:true)
    guard candidate.locked==target else { throw LockDeviceError.stateChanged }
    guard model.commitMockLock(candidate) else { throw LockDeviceError.notWritable }
  }
}
#endif
