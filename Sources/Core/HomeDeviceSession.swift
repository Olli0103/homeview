import Foundation
import Observation

enum HomeControlOperationState: Equatable, Sendable {
  case idle, checking, writing, verifying, confirmed, failed(HomeControlFailure), unverified
  var pending: Bool {
    switch self { case .checking,.writing,.verifying:true;default:false }
  }
  var text: String {
    switch self {
    case .idle: "Observed mock state"
    case .checking: "Checking device · No command sent"
    case .writing: "Command pending · Not confirmed"
    case .verifying: "Waiting for device state confirmation"
    case .confirmed: "Confirmed by device state read-back"
    case .failed(let reason): reason.errorDescription ?? "Device control unavailable"
    case .unverified: "Outcome unverified · No automatic retry"
    }
  }
}

/// One bounded, explicit write per characteristic. Different devices stay independent.
/// All admitted sources are mock-only in this revision; source labels are not live-home permission.
@MainActor @Observable final class HomeDeviceSession {
  private struct Pending {
    let id: UUID
    let epoch: UUID
    let created: TimeInterval
    let expected: HomeCharacteristicReading
    let desired: HomeControlValue
    var writeIssued=false
  }
  private(set) var readings: [HomeCharacteristicID:HomeCharacteristicReading]
  private(set) var states: [HomeCharacteristicID:HomeControlOperationState]=[:]
  private(set) var active=false
  @ObservationIgnored private let provider: any HomeDeviceProvider
  @ObservationIgnored private let contextAllowed: @MainActor () -> Bool
  @ObservationIgnored private let uptime: @MainActor () -> TimeInterval
  @ObservationIgnored private let failure: @MainActor (HomeControlFailure) -> Void
  @ObservationIgnored private var epoch=UUID()
  @ObservationIgnored private var versions: [HomeCharacteristicID:UUID]=[:]
  @ObservationIgnored private var pending: [HomeCharacteristicID:Pending]=[:]
  @ObservationIgnored private var unsettledWrites: [HomeCharacteristicID:UUID]=[:]
  @ObservationIgnored private var refreshTickets: [HomeCharacteristicID:UUID]=[:]
  @ObservationIgnored private var observation: (any HomeControlObservation)?
  static let timeout: TimeInterval=10

  init(provider: any HomeDeviceProvider, initial: [HomeCharacteristicID:HomeCharacteristicReading]=[:],
       contextAllowed: @escaping @MainActor () -> Bool,
       uptime: @escaping @MainActor () -> TimeInterval = {ProcessInfo.processInfo.systemUptime},
       failure: @escaping @MainActor (HomeControlFailure) -> Void = {_ in}) {
    self.provider=provider;self.contextAllowed=contextAllowed;self.uptime=uptime;self.failure=failure
    readings=initial.filter {key,value in value.descriptor.id==key && value.descriptor.source == .mock && value.valid}
  }
  func state(_ key: HomeCharacteristicID) -> HomeControlOperationState { states[key] ?? .idle }
  func descriptor(_ key: HomeCharacteristicID) -> HomeCharacteristicDescriptor? {
    readings[key]?.descriptor ?? provider.descriptors[key]
  }
  func canWrite(_ key: HomeCharacteristicID) -> Bool {
    guard active,contextAllowed(),pending[key]==nil,unsettledWrites[key]==nil,let descriptor=descriptor(key) else { return false }
    return descriptor.source == .mock && descriptor.valid && descriptor.readable && descriptor.writable && readings[key]?.valid == true
  }
  private func version(_ key: HomeCharacteristicID) -> UUID {
    if let current=versions[key] { return current }
    let value=UUID();versions[key]=value;return value
  }
  private func ageValid(_ created: TimeInterval) -> Bool {
    let now=uptime()
    return created.isFinite && created>=0 && now.isFinite && now>=created && now-created<Self.timeout
  }
  private func current(_ request: Pending, key: HomeCharacteristicID, phase: HomeControlOperationState) -> Bool {
    active && contextAllowed() && request.epoch==epoch && pending[key]?.id==request.id && state(key)==phase
  }
  private func accepts(_ reading: HomeCharacteristicReading, key: HomeCharacteristicID) -> Bool {
    reading.descriptor.id==key && reading.descriptor.source == .mock && reading.valid
  }
  private func publish(_ reading: HomeCharacteristicReading, key: HomeCharacteristicID) {
    readings[key]=reading;versions[key]=UUID()
  }
  func start() {
    guard !active,contextAllowed() else { return }
    active=true;epoch=UUID();let owner=epoch
    observation=provider.observe { [weak self] key,result in
      guard let self,self.active,self.contextAllowed(),self.epoch==owner else { return }
      self.versions[key]=UUID()
      switch result {
      case .success(let reading):
        guard self.accepts(reading,key:key) else {
          self.readings.removeValue(forKey:key)
          if self.pending[key]==nil { self.states[key] = .failed(.unsupported) }
          return
        }
        // A genuine observed foreign update is displayable, but is not a write acknowledgement.
        // Its stamp fences outstanding reads, including a stale post-write response.
        self.readings[key]=reading
        if self.pending[key]==nil { self.states[key] = .idle }
      case .failure(let reason):
        if self.pending[key]==nil { self.states[key] = .failed(reason) }
      }
    }
    refreshAll()
  }
  func stop() {
    active=false;epoch=UUID();observation?.cancel();observation=nil;refreshTickets.removeAll()
    for (key,request) in pending {
      states[key]=request.writeIssued ? .unverified:.failed(.unavailable)
    }
    pending.removeAll()
  }
  func refreshAll() {
    for key in provider.descriptors.keys { refresh(key) }
  }
  func refresh(_ key: HomeCharacteristicID) {
    guard active,contextAllowed(),pending[key]==nil,let descriptor=descriptor(key),descriptor.source == .mock,
      descriptor.valid,descriptor.readable else { return }
    let ticket=UUID(),owner=epoch,stamp=version(key)
    refreshTickets[key]=ticket
    provider.read(key) { [weak self] result in
      guard let self,self.active,self.contextAllowed(),self.epoch==owner,self.refreshTickets[key]==ticket,self.pending[key]==nil else { return }
      self.refreshTickets.removeValue(forKey:key)
      guard self.version(key)==stamp else { return }
      switch result {
      case .success(let reading):
        guard self.accepts(reading,key:key) else { self.states[key] = .failed(.unsupported);return }
        self.publish(reading,key:key);self.states[key] = .idle
      case .failure(let reason):self.states[key] = .failed(reason)
      }
    }
  }
  @discardableResult func request(_ key: HomeCharacteristicID, value: HomeControlValue) -> HomeControlOperationState {
    guard active,contextAllowed() else { return .failed(.unavailable) }
    guard pending[key]==nil,unsettledWrites[key]==nil else { return state(key) }
    guard let expected=readings[key],let descriptor=descriptor(key),descriptor.source == .mock else {
      states[key] = .failed(provider.descriptors[key]?.source == .homeKit ? .realHomeDisabled:.unsupported)
      return state(key)
    }
    guard descriptor.valid,descriptor.readable else { states[key] = .failed(.unsupported);return state(key) }
    guard descriptor.writable else { states[key] = .failed(.readOnly);return state(key) }
    guard descriptor.accepts(value,forWrite:true),expected.valid,descriptor==expected.descriptor else {
      states[key] = .failed(.invalidValue);return state(key)
    }
    let created=uptime()
    guard ageValid(created) else { states[key] = .failed(.timeout);return state(key) }
    let request=Pending(id:UUID(),epoch:epoch,created:created,expected:expected,desired:value)
    let stamp=version(key);pending[key]=request;refreshTickets.removeValue(forKey:key);states[key] = .checking
    provider.read(key) { [weak self] result in self?.preflight(result,key:key,request:request,stamp:stamp) }
    return state(key)
  }
  private func reject(_ key: HomeCharacteristicID, request: Pending, reason: HomeControlFailure) {
    guard pending[key]?.id==request.id else { return }
    pending.removeValue(forKey:key)
    states[key]=request.writeIssued ? .unverified:.failed(reason)
    failure(request.writeIssued ? .unverified:reason)
  }
  private func preflight(_ result: Result<HomeCharacteristicReading,HomeControlFailure>,key: HomeCharacteristicID,request: Pending,stamp: UUID) {
    guard current(request,key:key,phase:.checking) else { return }
    guard ageValid(request.created) else { reject(key,request:request,reason:.timeout);return }
    guard version(key)==stamp else { reject(key,request:request,reason:.changed);return }
    switch result {
    case .failure(let reason):reject(key,request:request,reason:reason)
    case .success(let reading):
      guard accepts(reading,key:key),reading==request.expected,reading.descriptor.accepts(request.desired,forWrite:true) else {
        if accepts(reading,key:key) { publish(reading,key:key) }
        reject(key,request:request,reason:.changed);return
      }
      var writing=request;writing.writeIssued=true;pending[key]=writing
      let sending=writing
      unsettledWrites[key]=request.id;states[key] = .writing
      provider.write(key,value:request.desired,expected:reading) { [weak self] result in
        self?.written(result,key:key,request:sending)
      }
    }
  }
  private func written(_ result: Result<Void,HomeControlFailure>,key: HomeCharacteristicID,request: Pending) {
    if unsettledWrites[key]==request.id { unsettledWrites.removeValue(forKey:key) }
    guard current(request,key:key,phase:.writing) else { return }
    guard ageValid(request.created) else { reject(key,request:request,reason:.timeout);return }
    switch result {
    case .failure(let reason):reject(key,request:request,reason:reason)
    case .success:
      states[key] = .verifying;let stamp=version(key)
      provider.read(key) { [weak self] result in self?.readBack(result,key:key,request:request,stamp:stamp) }
    }
  }
  private func readBack(_ result: Result<HomeCharacteristicReading,HomeControlFailure>,key: HomeCharacteristicID,request: Pending,stamp: UUID) {
    guard current(request,key:key,phase:.verifying) else { return }
    guard ageValid(request.created) else { reject(key,request:request,reason:.timeout);return }
    guard version(key)==stamp else { reject(key,request:request,reason:.changed);return }
    switch result {
    case .failure(let reason):reject(key,request:request,reason:reason)
    case .success(let reading):
      guard accepts(reading,key:key) else { reject(key,request:request,reason:.unsupported);return }
      publish(reading,key:key)
      guard reading.value==request.desired,reading.descriptor==request.expected.descriptor else {
        reject(key,request:request,reason:.changed);return
      }
      pending.removeValue(forKey:key);states[key] = .confirmed
    }
  }
  func tick() {
    guard active else { return }
    if !contextAllowed() { stop();return }
    for (key,request) in pending where !ageValid(request.created) {
      reject(key,request:request,reason:.timeout)
    }
  }
}
