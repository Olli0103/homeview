import Foundation

/// Local MockHome only. The real HomeKit service remains unconstructible.
@MainActor final class MockHomeDevice: HomeDeviceProvider {
  weak var model:AppModel?
  private var observers:[UUID:@MainActor @Sendable (HomeCharacteristicID,Result<HomeCharacteristicReading,HomeControlFailure>)->Void]=[:]
  private var last:[HomeCharacteristicID:HomeCharacteristicReading]=[:]
  private var fixtureUsed=false
  init(model:AppModel) {self.model=model}
  private var fixture:(String,HomeControlSlot)? {
    let args=ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"),let i=args.firstIndex(of:"--persistence-test"),args.indices.contains(i+1),
      UUID(uuidString:args[i+1]) != nil,let j=args.firstIndex(of:"--mock-control-case"),args.indices.contains(j+2),
      ["delayed","timeout","denied","foreign","read-only","stepped"].contains(args[j+1]),
      let slot=HomeControlSlot(rawValue:args[j+2]) else {return nil}
    return(args[j+1],slot)
  }
  var descriptors:[HomeCharacteristicID:HomeCharacteristicDescriptor] {
    var result=HomeMockControls.descriptors
    if let (scenario,slot)=fixture,scenario == "read-only" || scenario == "stepped" {
      let key=HomeMockControls.id(slot),d=result[key]!
      result[key]=HomeCharacteristicDescriptor(id:key,kind:d.kind,unit:d.unit,source:d.source,
        readable:d.readable,writable:scenario != "read-only",numeric:scenario == "stepped"
          ? HomeNumericDomain(minimum:slot == .temperature ? 50:10,maximum:90,step:5):d.numeric,modes:d.modes)
    }
    return result
  }
  func reading(_ key:HomeCharacteristicID)->Result<HomeCharacteristicReading,HomeControlFailure> {
    guard let model else {return .failure(.unavailable)}
    do {
      return reading(key,home:try model.readMockControlSnapshot())
    } catch {return .failure(.unavailable)}
  }
  private func reading(_ key:HomeCharacteristicID,home:MockHome)->Result<HomeCharacteristicReading,HomeControlFailure> {
    guard let descriptor=descriptors[key] else {return .failure(.unsupported)}
    guard home.online else {return .failure(.offline)}
    guard let value=HomeMockControls.values(home)[key] else {return .failure(.unsupported)}
    let reading=HomeCharacteristicReading(descriptor:descriptor,value:value)
    return reading.valid ? .success(reading):.failure(.unsupported)
  }
  func read(_ key:HomeCharacteristicID,completion:@escaping @MainActor @Sendable (Result<HomeCharacteristicReading,HomeControlFailure>)->Void) {
    // Only the explicit owned-store fixture holds a preflight; normal reads are synchronous.
    if let (scenario,slot)=fixture,HomeMockControls.id(slot)==key,!fixtureUsed,
      model?.homeControlState(slot) == .checking {
      if scenario == "timeout" {fixtureUsed=true;return}
      if scenario == "foreign" {
        fixtureUsed=true;let previous=reading(key)
        Task { @MainActor [weak self] in
          try? await Task.sleep(for:.seconds(2))
          guard let self,let model=self.model,model.homeControlsActive else {return}
          var changed=model.data.home
          let value:HomeControlValue = switch slot {
          case .temperature:.number(74)
          case .thermostatMode:.mode(1)
          case .entryLight,.bedroomLight,.fan:.flag(false)
          case .brightness:.number(40)
          case .fanSpeed:.number(65)
          case .blinds:.number(35)
          }
          do {try HomeMockControls.apply(slot,value:value,to:&changed)} catch {completion(.failure(.unavailable));return}
          guard model.updateLocalControls({$0.home=changed}) else {completion(.failure(.unavailable));return}
          self.publishChanges();completion(previous)
        }
        return
      }
    }
    completion(reading(key))
  }
  func write(_ key:HomeCharacteristicID,value:HomeControlValue,expected:HomeCharacteristicReading,
    completion:@escaping @MainActor @Sendable (Result<Void,HomeControlFailure>)->Void) {
    guard let slot=HomeControlSlot.allCases.first(where:{HomeMockControls.id($0)==key}) else {completion(.failure(.unsupported));return}
    if let (scenario,target)=fixture,target==slot,!fixtureUsed {
      if scenario == "denied" {fixtureUsed=true;completion(.failure(.readOnly));return}
      if scenario == "delayed" {
        fixtureUsed=true
        Task { @MainActor [weak self] in
          try? await Task.sleep(for:.seconds(6))
          guard let self else {completion(.failure(.unavailable));return}
          self.commit(slot,value:value,expected:expected,completion:completion)
        }
        return
      }
    }
    commit(slot,value:value,expected:expected,completion:completion)
  }
  private func commit(_ slot:HomeControlSlot,value:HomeControlValue,expected:HomeCharacteristicReading,
    completion:@escaping @MainActor @Sendable (Result<Void,HomeControlFailure>)->Void) {
    let key=HomeMockControls.id(slot)
    guard let model,model.homeControlsActive,model.homeControlState(slot) == .writing else {completion(.failure(.unavailable));return}
    // Validate and change the same freshly read mock-home snapshot. Starting
    // from model.data.home would silently restore stale neighbours and a lock
    // even though this characteristic's optimistic precondition still matches.
    var candidate:MockHome
    do {candidate=try model.readMockControlSnapshot()} catch {completion(.failure(.unavailable));return}
    switch reading(key,home:candidate) {
    case .failure(let error):completion(.failure(error))
    case .success(let actual):
      guard actual==expected,actual.descriptor.accepts(value,forWrite:true) else {completion(.failure(.changed));return}
      do {try HomeMockControls.apply(slot,value:value,to:&candidate)} catch {completion(.failure(.invalidValue));return}
      guard model.commitMockHomeControl(candidate) else {completion(.failure(.unverified));return}
      completion(.success(()))
    }
  }
  func observe(_ receive:@escaping @MainActor @Sendable (HomeCharacteristicID,Result<HomeCharacteristicReading,HomeControlFailure>)->Void)->any HomeControlObservation {
    for key in descriptors.keys {
      if case .success(let reading)=reading(key) {last[key]=reading}
    }
    let id=UUID();observers[id]=receive
    return HomeControlObservationToken { [weak self] in self?.observers.removeValue(forKey:id) }
  }
  func publishChanges() {
    guard !observers.isEmpty else {return}
    for key in descriptors.keys {
      let result=reading(key)
      if case .success(let reading)=result {
        guard last[key] != reading else {continue};last[key]=reading
      }
      for callback in Array(observers.values) {callback(key,result)}
    }
  }
}
