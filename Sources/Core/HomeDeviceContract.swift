import Foundation

struct HomeCharacteristicID: Hashable, Codable, Sendable {
  let accessory: UUID
  let characteristic: UUID
}
enum HomeControlSlot: String, CaseIterable, Sendable {
  case temperature, thermostatMode, entryLight, bedroomLight, brightness, fan, fanSpeed, blinds
}
enum HomeCharacteristicKind: String, Sendable {
  case targetTemperature, targetMode, power, brightness, rotationSpeed, targetPosition
}
enum HomeCharacteristicUnit: String, Sendable {
  case none, celsius, fahrenheit, percent
}
enum HomeControlSource: String, Sendable { case mock, homeKit }
enum HomeControlValue: Equatable, Sendable {
  case number(Double), flag(Bool), mode(Int)
  var number: Double? { if case .number(let value)=self { value } else { nil } }
  var flag: Bool? { if case .flag(let value)=self { value } else { nil } }
  var mode: Int? { if case .mode(let value)=self { value } else { nil } }
}
struct HomeNumericDomain: Equatable, Sendable {
  let minimum: Double
  let maximum: Double
  /// nil means no advertised quantization, not an invented hardware step.
  let step: Double?
  var valid: Bool {
    guard minimum.isFinite,maximum.isFinite,minimum<=maximum,(maximum-minimum).isFinite else { return false }
    guard let step else { return true }
    return step.isFinite && step>0 && ((maximum-minimum)/step).isFinite
  }
  func accepts(_ value: Double) -> Bool {
    guard valid,value.isFinite,value>=minimum,value<=maximum else { return false }
    guard let step else { return true }
    let quotient=(value-minimum)/step
    return quotient.isFinite && abs(quotient-quotient.rounded())<=max(1e-9,quotient.ulp*4)
  }
  func next(from value: Double, direction: Int, continuousIncrement: Double) -> Double? {
    guard valid,value.isFinite,[-1,1].contains(direction),continuousIncrement.isFinite,continuousIncrement>0 else { return nil }
    let candidate: Double
    if let step {
      let quotient=(value-minimum)/step
      let index=direction>0 ? floor(quotient+1e-9)+1:ceil(quotient-1e-9)-1
      candidate=minimum+index*step
    } else { candidate=value+Double(direction)*continuousIncrement }
    return accepts(candidate) ? candidate:nil
  }
}
struct HomeCharacteristicDescriptor: Equatable, Sendable {
  let id: HomeCharacteristicID
  let kind: HomeCharacteristicKind
  let unit: HomeCharacteristicUnit
  let source: HomeControlSource
  let readable: Bool
  let writable: Bool
  let numeric: HomeNumericDomain?
  let modes: Set<Int>

  var valid: Bool {
    switch kind {
    case .power: unit == .none && numeric == nil && modes.isEmpty
    case .targetMode: unit == .none && numeric == nil && !modes.isEmpty && modes.isSubset(of:[0,1,2,3])
    case .targetTemperature: [.celsius,.fahrenheit].contains(unit) && numeric?.valid == true && modes.isEmpty
    case .brightness,.rotationSpeed,.targetPosition:
      unit == .percent && numeric?.valid == true && modes.isEmpty
      && numeric!.minimum>=0 && numeric!.maximum<=100
    }
  }
  func accepts(_ value: HomeControlValue, forWrite: Bool) -> Bool {
    guard valid,readable,(!forWrite || writable) else { return false }
    switch (kind,value) {
    case (.power,.flag): return true
    case (.targetMode,.mode(let value)): return modes.contains(value)
    case (.targetTemperature,.number(let value)),(.brightness,.number(let value)),
      (.rotationSpeed,.number(let value)),(.targetPosition,.number(let value)):
      if forWrite { return numeric?.accepts(value) == true }
      return value.isFinite && value>=numeric!.minimum && value<=numeric!.maximum
    default: return false
    }
  }
  func displayTemperature(_ value: Double, in displayUnit: HomeCharacteristicUnit) -> Double? {
    guard kind == .targetTemperature,value.isFinite,[.celsius,.fahrenheit].contains(unit),[.celsius,.fahrenheit].contains(displayUnit) else { return nil }
    if unit == displayUnit { return value }
    let input=Measurement(value:value,unit:unit == .celsius ? UnitTemperature.celsius:.fahrenheit)
    let result=input.converted(to:displayUnit == .celsius ? .celsius:.fahrenheit).value
    return result.isFinite ? result:nil
  }
}
struct HomeCharacteristicReading: Equatable, Sendable {
  let descriptor: HomeCharacteristicDescriptor
  let value: HomeControlValue
  var valid: Bool { descriptor.accepts(value,forWrite:false) }
}
enum HomeControlFailure: Error, Equatable, Sendable, LocalizedError {
  case offline, readOnly, unsupported, invalidValue, changed, timeout, unavailable, realHomeDisabled, unverified
  var errorDescription: String? {
    switch self {
    case .offline: "The mock home is offline. No changes were made."
    case .readOnly: "This characteristic is read-only. No command was sent."
    case .unsupported: "This characteristic has no supported control contract. No command was sent."
    case .invalidValue: "That value does not match the device's type, range or step. No command was sent."
    case .changed: "The device or its controls changed. Review its observed state before trying again."
    case .timeout: "The device check timed out. No command was sent."
    case .unavailable: "The device state is unavailable."
    case .realHomeDisabled: "Apple Home remains disconnected. Only mock controls are enabled."
    case .unverified: "The command outcome is not confirmed. No automatic retry."
    }
  }
}
@MainActor protocol HomeControlObservation: AnyObject { func cancel() }
@MainActor final class HomeControlObservationToken: HomeControlObservation {
  private var cancellation: (@MainActor () -> Void)?
  init(_ cancellation: @escaping @MainActor () -> Void) { self.cancellation=cancellation }
  func cancel() { let callback=cancellation;cancellation=nil;callback?() }
}
/// Callback contract deliberately supports synchronous local mocks and asynchronous device transports.
/// A successful write callback alone is never a confirmed device state.
@MainActor protocol HomeDeviceProvider: AnyObject {
  var descriptors: [HomeCharacteristicID:HomeCharacteristicDescriptor] { get }
  func read(_ id: HomeCharacteristicID,
    completion: @escaping @MainActor @Sendable (Result<HomeCharacteristicReading,HomeControlFailure>) -> Void)
  func write(_ id: HomeCharacteristicID, value: HomeControlValue, expected: HomeCharacteristicReading,
    completion: @escaping @MainActor @Sendable (Result<Void,HomeControlFailure>) -> Void)
  func observe(_ receive: @escaping @MainActor @Sendable (HomeCharacteristicID,Result<HomeCharacteristicReading,HomeControlFailure>) -> Void) -> any HomeControlObservation
}

enum HomeMockControls {
  static func values(_ home:MockHome)->[HomeCharacteristicID:HomeControlValue] {
    Dictionary(uniqueKeysWithValues:HomeControlSlot.allCases.map {slot in
      let value:HomeControlValue = switch slot {
      case .temperature:.number(Double(home.temperature))
      case .thermostatMode:.mode(home.thermostatMode ?? 2)
      case .entryLight:.flag(home.entryLight)
      case .bedroomLight:.flag(home.bedroomLight)
      case .brightness:.number(home.brightness)
      case .fan:.flag(home.fan)
      case .fanSpeed:.number(home.fanSpeed)
      case .blinds:.number(home.blinds)
      }
      return(id(slot),value)
    })
  }
  static func apply(_ slot:HomeControlSlot,value:HomeControlValue,to home:inout MockHome) throws {
    guard descriptors[id(slot)]!.accepts(value,forWrite:true) else {throw HomeControlFailure.invalidValue}
    switch slot {
    case .temperature:try home.transact(.temperature(Int(value.number!)))
    case .thermostatMode:try home.transact(.thermostatMode(value.mode!))
    case .entryLight:if home.entryLight != value.flag! {try home.transact(.entryLight)}
    case .bedroomLight:if home.bedroomLight != value.flag! {try home.transact(.bedroomLight)}
    case .brightness:try home.transact(.brightness(value.number!))
    case .fan:if home.fan != value.flag! {try home.transact(.fan)}
    case .fanSpeed:try home.transact(.fanSpeed(value.number!))
    case .blinds:try home.transact(.blinds(value.number!))
    }
  }
  static func id(_ slot: HomeControlSlot) -> HomeCharacteristicID {
    let index=HomeControlSlot.allCases.firstIndex(of:slot)!+1
    let device: Int
    switch slot { case .temperature,.thermostatMode: device=1;case .entryLight,.brightness:device=2;case .bedroomLight:device=3;case .fan,.fanSpeed:device=4;case .blinds:device=5 }
    return HomeCharacteristicID(accessory:UUID(uuidString:String(format:"00000000-0000-4000-8000-%012d",device))!,
      characteristic:UUID(uuidString:String(format:"00000000-0000-4000-9000-%012d",index))!)
  }
  static var descriptors: [HomeCharacteristicID:HomeCharacteristicDescriptor] {
    Dictionary(uniqueKeysWithValues:HomeControlSlot.allCases.map {slot in
      let kind: HomeCharacteristicKind,unit:HomeCharacteristicUnit,numeric:HomeNumericDomain?,modes:Set<Int>
      switch slot {
      case .temperature:kind = .targetTemperature;unit = .fahrenheit;numeric=HomeNumericDomain(minimum:50,maximum:90,step:1);modes=[]
      case .thermostatMode:kind = .targetMode;unit = .none;numeric=nil;modes=[0,1,2,3]
      case .entryLight,.bedroomLight,.fan:kind = .power;unit = .none;numeric=nil;modes=[]
      case .brightness:kind = .brightness;unit = .percent;numeric=HomeNumericDomain(minimum:0,maximum:100,step:nil);modes=[]
      case .fanSpeed:kind = .rotationSpeed;unit = .percent;numeric=HomeNumericDomain(minimum:0,maximum:100,step:nil);modes=[]
      case .blinds:kind = .targetPosition;unit = .percent;numeric=HomeNumericDomain(minimum:0,maximum:100,step:nil);modes=[]
      }
      let key=id(slot)
      return(key,HomeCharacteristicDescriptor(id:key,kind:kind,unit:unit,source:.mock,readable:true,writable:true,numeric:numeric,modes:modes))
    })
  }
}
