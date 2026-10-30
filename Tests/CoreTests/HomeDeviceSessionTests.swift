import XCTest
@testable import HomeViewCore

@MainActor final class HomeDeviceSessionTests: XCTestCase {
  final class Clock { var now:Double=100;var allowed=true }
  final class Provider: HomeDeviceProvider {
    var descriptors=HomeMockControls.descriptors
    var values:[HomeCharacteristicID:HomeControlValue]=[:]
    var reads=0,writes=0,applied=0,cancellations=0
    var holdReads=false,holdWrites=false,denyWrite=false,applyWrite=true
    var readFailure:HomeControlFailure?
    var readReplies:[@MainActor @Sendable (Result<HomeCharacteristicReading,HomeControlFailure>)->Void]=[]
    var writeReplies:[@MainActor @Sendable (Result<Void,HomeControlFailure>)->Void]=[]
    var receiver:(@MainActor @Sendable (HomeCharacteristicID,Result<HomeCharacteristicReading,HomeControlFailure>)->Void)?
    init() {
      for slot in HomeControlSlot.allCases {
        values[HomeMockControls.id(slot)] = switch slot {
        case .temperature:.number(68)
        case .thermostatMode:.mode(2)
        case .entryLight,.bedroomLight,.fan:.flag(true)
        case .brightness:.number(75)
        case .fanSpeed:.number(45)
        case .blinds:.number(80)
        }
      }
    }
    func reading(_ key:HomeCharacteristicID)->HomeCharacteristicReading {
      HomeCharacteristicReading(descriptor:descriptors[key]!,value:values[key]!)
    }
    func read(_ key:HomeCharacteristicID,completion:@escaping @MainActor @Sendable (Result<HomeCharacteristicReading,HomeControlFailure>)->Void) {
      reads+=1
      if holdReads {readReplies.append(completion)}
      else if let readFailure {completion(.failure(readFailure))}
      else {completion(.success(reading(key)))}
    }
    func write(_ key:HomeCharacteristicID,value:HomeControlValue,expected:HomeCharacteristicReading,
      completion:@escaping @MainActor @Sendable (Result<Void,HomeControlFailure>)->Void) {
      writes+=1
      guard !denyWrite else {completion(.failure(.readOnly));return}
      guard reading(key)==expected else {completion(.failure(.changed));return}
      if applyWrite {values[key]=value;applied+=1}
      if holdWrites {writeReplies.append(completion)} else {completion(.success(()))}
    }
    func observe(_ receive:@escaping @MainActor @Sendable (HomeCharacteristicID,Result<HomeCharacteristicReading,HomeControlFailure>)->Void)->any HomeControlObservation {
      receiver=receive
      return HomeControlObservationToken { [weak self] in self?.cancellations+=1;self?.receiver=nil }
    }
    func emit(_ key:HomeCharacteristicID,_ value:HomeControlValue) {
      values[key]=value;receiver?(key,.success(reading(key)))
    }
  }
  func setup()->(HomeDeviceSession,Provider,Clock) {
    let p=Provider(),c=Clock()
    let s=HomeDeviceSession(provider:p,contextAllowed:{c.allowed},uptime:{c.now})
    s.start();return(s,p,c)
  }
  func desired(_ slot:HomeControlSlot)->HomeControlValue {
    switch slot {
    case .temperature:.number(72)
    case .thermostatMode:.mode(1)
    case .entryLight,.bedroomLight,.fan:.flag(false)
    case .brightness:.number(30)
    case .fanSpeed:.number(60)
    case .blinds:.number(20)
    }
  }
  func testEveryControlConfirmsOnlyAfterItsOwnMatchingReadback() async {
    for slot in HomeControlSlot.allCases {
      let(s,p,_)=setup(),key=HomeMockControls.id(slot),before=p.reads
      XCTAssertEqual(s.request(key,value:desired(slot)),.confirmed)
      XCTAssertEqual(s.readings[key]?.value,desired(slot));XCTAssertEqual(p.writes,1)
      XCTAssertEqual(p.applied,1);XCTAssertEqual(p.reads,before+2)
    }
  }
  func testWriteAcknowledgementIsNotReadbackAndOldValueRemainsWhilePending() async throws {
    for slot in HomeControlSlot.allCases {
      let(s,p,_)=setup(),key=HomeMockControls.id(slot),old=p.values[key]
      p.holdWrites=true
      XCTAssertEqual(s.request(key,value:desired(slot)),.writing)
      XCTAssertEqual(s.readings[key]?.value,old)
      p.holdReads=true;try XCTUnwrap(p.writeReplies.first)(.success(()))
      XCTAssertEqual(s.state(key),.verifying);XCTAssertEqual(s.readings[key]?.value,old)
      try XCTUnwrap(p.readReplies.first)(.success(p.reading(key)))
      XCTAssertEqual(s.state(key),.confirmed)
    }
  }
  func testWriteCallbackWithoutMatchingEffectNeverConfirmsForAnyDevice() async {
    for slot in HomeControlSlot.allCases {
      let(s,p,_)=setup(),key=HomeMockControls.id(slot),old=p.values[key]
      p.applyWrite=false
      XCTAssertEqual(s.request(key,value:desired(slot)),.unverified)
      XCTAssertEqual(s.readings[key]?.value,old);XCTAssertEqual(p.writes,1);XCTAssertEqual(p.applied,0)
    }
  }
  func testTimeoutBeforeDispatchAndLateReplySendZeroWritesForAllControls() async throws {
    for slot in HomeControlSlot.allCases {
      let(s,p,c)=setup(),key=HomeMockControls.id(slot);p.holdReads=true
      XCTAssertEqual(s.request(key,value:desired(slot)),.checking)
      c.now=110;s.tick();XCTAssertEqual(s.state(key),.failed(.timeout))
      try XCTUnwrap(p.readReplies.first)(.success(p.reading(key)))
      XCTAssertEqual(p.writes,0);XCTAssertEqual(p.applied,0)
    }
  }
  func testDeniedWriteHasNoOptimisticSuccessAndNoRetryForEveryControl() async {
    for slot in HomeControlSlot.allCases {
      let(s,p,_)=setup(),key=HomeMockControls.id(slot),old=p.values[key];p.denyWrite=true
      XCTAssertEqual(s.request(key,value:desired(slot)),.unverified)
      XCTAssertEqual(p.writes,1);XCTAssertEqual(p.applied,0);XCTAssertEqual(s.readings[key]?.value,old)
      s.tick();XCTAssertEqual(p.writes,1)
    }
  }
  func testForeignChangeDuringPreflightIsDisplayedAndFencesOldReadForEveryControl() async throws {
    for slot in HomeControlSlot.allCases {
      let(s,p,_)=setup(),key=HomeMockControls.id(slot),old=p.reading(HomeMockControls.id(slot))
      p.holdReads=true;s.request(key,value:desired(slot));p.emit(key,desired(slot))
      XCTAssertEqual(s.readings[key]?.value,desired(slot))
      try XCTUnwrap(p.readReplies.first)(.success(old))
      XCTAssertEqual(s.state(key),.failed(.changed));XCTAssertEqual(p.writes,0)
      XCTAssertEqual(s.readings[key]?.value,desired(slot))
    }
  }
  func testForeignPostWriteUpdateCannotBeOverwrittenByStaleReadback() async throws {
    let(s,p,_)=setup(),key=HomeMockControls.id(.temperature);p.holdWrites=true
    s.request(key,value:.number(72));p.holdReads=true
    try XCTUnwrap(p.writeReplies.first)(.success(()));let stale=p.reading(key)
    p.emit(key,.number(74));try XCTUnwrap(p.readReplies.first)(.success(stale))
    XCTAssertEqual(s.state(key),.unverified);XCTAssertEqual(s.readings[key]?.value,.number(74))
    XCTAssertEqual(p.writes,1)
  }
  func testReadOnlyAndUnreadableMetadataSendNoWrite() async {
    for readable in [false,true] {
      let p=Provider(),key=HomeMockControls.id(.brightness),d=p.descriptors[key]!
      p.descriptors[key]=HomeCharacteristicDescriptor(id:key,kind:d.kind,unit:d.unit,source:.mock,
        readable:readable,writable:false,numeric:d.numeric,modes:[])
      let s=HomeDeviceSession(provider:p,contextAllowed:{true});s.start()
      XCTAssertFalse(s.canWrite(key));XCTAssertFalse(s.request(key,value:.number(10)).pending)
      XCTAssertEqual(p.writes,0)
      if !readable {XCTAssertEqual(p.reads,7)}
    }
  }
  func testUnsupportedTypeUnitsIDsAndLiveSourceNeverWrite() async {
    for source in [HomeControlSource.mock,.homeKit] {
      let p=Provider(),key=HomeMockControls.id(.temperature),d=p.descriptors[key]!
      p.descriptors[key]=HomeCharacteristicDescriptor(id:key,kind:d.kind,unit:.percent,source:source,
        readable:true,writable:true,numeric:d.numeric,modes:[])
      let s=HomeDeviceSession(provider:p,contextAllowed:{true});s.start()
      XCTAssertFalse(s.canWrite(key));s.request(key,value:.number(70));XCTAssertEqual(p.writes,0)
    }
    let(s,p,_)=setup();s.request(HomeCharacteristicID(accessory:UUID(),characteristic:UUID()),value:.number(70))
    XCTAssertEqual(p.writes,0)
  }
  func testWrongValueTypesNonfiniteBoundsAndUnknownModesSendNoWrites() async {
    let(s,p,_)=setup()
    for value in [HomeControlValue.number(.nan),.number(.infinity),.number(49),.number(91),.number(68.5),.flag(true),.mode(1)] {
      XCTAssertEqual(s.request(HomeMockControls.id(.temperature),value:value),.failed(.invalidValue))
    }
    for slot in [HomeControlSlot.brightness,.fanSpeed,.blinds] {
      for value in [-1.0,101,.nan,.infinity] {s.request(HomeMockControls.id(slot),value:.number(value))}
    }
    for mode in [-1,4,Int.max] {s.request(HomeMockControls.id(.thermostatMode),value:.mode(mode))}
    XCTAssertEqual(p.writes,0)
  }
  func testActualMetadataStepAndUnitConversionAreNotHardcodedUIRanges() async {
    let domain=HomeNumericDomain(minimum:3,maximum:99,step:7)
    XCTAssertTrue(domain.accepts(10));XCTAssertFalse(domain.accepts(11));XCTAssertFalse(domain.accepts(99))
    XCTAssertEqual(domain.next(from:10,direction:1,continuousIncrement:10),17)
    XCTAssertEqual(domain.next(from:11,direction:-1,continuousIncrement:10),10)
    XCTAssertNil(domain.next(from:94,direction:1,continuousIncrement:10))
    let key=HomeMockControls.id(.temperature)
    let d=HomeCharacteristicDescriptor(id:key,kind:.targetTemperature,unit:.celsius,source:.mock,
      readable:true,writable:true,numeric:HomeNumericDomain(minimum:10,maximum:30,step:0.5),modes:[])
    XCTAssertEqual(d.displayTemperature(20,in:.fahrenheit)!,68,accuracy:1e-8)
    XCTAssertTrue(d.accepts(.number(20.5),forWrite:true));XCTAssertFalse(d.accepts(.number(20.2),forWrite:true))
    for domain in [HomeNumericDomain(minimum:.nan,maximum:100,step:1),.init(minimum:0,maximum:100,step:0),.init(minimum:0,maximum:100,step:-1),.init(minimum:100,maximum:0,step:1)] {XCTAssertFalse(domain.valid)}
  }
  func testCapabilityChangeBetweenReadAndDispatchRequiresReviewWithZeroWrites() async throws {
    let(s,p,_)=setup(),key=HomeMockControls.id(.temperature),d=p.descriptors[key]!
    p.holdReads=true;s.request(key,value:.number(72))
    p.descriptors[key]=HomeCharacteristicDescriptor(id:key,kind:d.kind,unit:d.unit,source:d.source,
      readable:true,writable:false,numeric:d.numeric,modes:[])
    try XCTUnwrap(p.readReplies.first)(.success(p.reading(key)))
    XCTAssertEqual(s.state(key),.failed(.changed));XCTAssertFalse(s.canWrite(key));XCTAssertEqual(p.writes,0)
  }
  func testOfflineReadsAndBackwardInvalidClockNeverDispatch() async {
    for now in [99.0,110,.nan,.infinity,-1] {
      let(s,p,c)=setup(),key=HomeMockControls.id(.temperature);p.holdReads=true
      s.request(key,value:.number(72));c.now=now;s.tick()
      XCTAssertEqual(s.state(key),.failed(.timeout));XCTAssertEqual(p.writes,0)
    }
    let(s,p,_)=setup();p.readFailure = .offline
    XCTAssertEqual(s.request(HomeMockControls.id(.temperature),value:.number(72)),.failed(.offline));XCTAssertEqual(p.writes,0)
  }
  func testStopAndRestartFencesPreflightAndDuplicateCallbacks() async throws {
    let(s,p,_)=setup(),key=HomeMockControls.id(.temperature);p.holdReads=true
    s.request(key,value:.number(72));let old=try XCTUnwrap(p.readReplies.first)
    s.stop();XCTAssertEqual(p.cancellations,1);p.holdReads=false;s.start()
    old(.success(p.reading(key)));old(.success(p.reading(key)));XCTAssertEqual(p.writes,0)
    p.holdWrites=true;s.request(key,value:.number(72));let write=try XCTUnwrap(p.writeReplies.first)
    write(.success(()));write(.success(()))
    XCTAssertEqual(p.writes,1);XCTAssertEqual(s.state(key),.confirmed)
  }
  func testUnsettledTimedOutWriteBlocksResendUntilActualCallbackAndDoesNotReplay() async throws {
    let(s,p,c)=setup(),key=HomeMockControls.id(.temperature);p.holdWrites=true
    s.request(key,value:.number(72));c.now=110;s.tick();XCTAssertEqual(s.state(key),.unverified)
    s.request(key,value:.number(73));XCTAssertEqual(p.writes,1)
    try XCTUnwrap(p.writeReplies.first)(.success(()));XCTAssertEqual(s.state(key),.unverified)
    s.refresh(key);XCTAssertEqual(s.readings[key]?.value,.number(72));XCTAssertEqual(p.writes,1)
  }
  func testIndependentDevicesDoNotBlockEachOtherAndLifecycleRevocationStopsAdmission() async {
    let(s,p,c)=setup();p.holdWrites=true
    s.request(HomeMockControls.id(.temperature),value:.number(72))
    s.request(HomeMockControls.id(.brightness),value:.number(30));XCTAssertEqual(p.writes,2)
    c.allowed=false;s.tick();XCTAssertFalse(s.active)
    s.request(HomeMockControls.id(.fan),value:.flag(false));XCTAssertEqual(p.writes,2)
  }
  func testRefreshReadCannotRollBackNewerObservation() async throws {
    let(s,p,_)=setup(),key=HomeMockControls.id(.temperature),old=p.reading(HomeMockControls.id(.temperature))
    p.holdReads=true;s.refresh(key);p.emit(key,.number(75))
    try XCTUnwrap(p.readReplies.first)(.success(old));XCTAssertEqual(s.readings[key]?.value,.number(75))
  }
  func testModePersistenceIsBackwardCompatibleAndRejectsUnsupportedMode() async throws {
    let old=Data("{\"temperature\":68,\"entryLight\":true,\"bedroomLight\":true,\"brightness\":75,\"fan\":true,\"fanSpeed\":45,\"locked\":true,\"blinds\":80,\"online\":true,\"lastScene\":\"\",\"audit\":[]}".utf8)
    var home=try JSONDecoder().decode(MockHome.self,from:old);XCTAssertNil(home.thermostatMode)
    try home.transact(.thermostatMode(1));XCTAssertEqual(try JSONDecoder().decode(MockHome.self,from:JSONEncoder().encode(home)).thermostatMode,1)
    XCTAssertThrowsError(try home.transact(.thermostatMode(4)));XCTAssertEqual(home.thermostatMode,1)
  }
}
