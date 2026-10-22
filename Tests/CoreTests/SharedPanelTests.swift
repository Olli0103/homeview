import XCTest
@testable import HomeViewCore

@MainActor final class SharedPanelTests: XCTestCase {
  private final class Provider: DeviceDataProvider {
    var permissions=true
    var reads=0
    var authorizationRequests=0
    var title="Alex private meeting"
    var delayed=false
    var reply:CheckedContinuation<[DeviceEvent],any Error>?
    var onRead:(()->Void)?
    func authorized(_ kind:DataConnection)->Bool { permissions }
    func authorizePersonal(_ kind:DataConnection) async throws {authorizationRequests+=1}
    func events(from:Date,to:Date) async throws->[DeviceEvent] {
      reads+=1
      if delayed { return try await withCheckedThrowingContinuation {reply=$0;onRead?()} }
      return [event(from)]
    }
    func event(_ date:Date)->DeviceEvent {
      DeviceEvent(id:title,title:title,start:date.addingTimeInterval(3600),
        end:date.addingTimeInterval(7200),location:"PRIVATE LOCATION NEVER PUBLISHED",
        calendar:"Synthetic source",cancelled:false)
    }
    func reminders() async throws->[DeviceReminder] {[]}
    func addReminder(_ title:String) async throws->String {""}
    func completeReminder(_ id:String,completed:Bool) async throws {}
    func removeReminder(_ id:String) async throws {}
    func authorizeMusic() async throws {}
    func searchMusic(_ text:String) async throws->[DeviceTrack] {
      [DeviceTrack(id:"song",title:"Private song",artist:"Private artist",artwork:nil)]
    }
    func playMusic(_ index:Int) async throws {}
    func resumeMusic() async throws {}
    func pauseMusic() {}
    var musicPlaying:Bool {false}
    var musicTime:Double {0}
    func weather(_ city:String) async throws->WeatherReading {throw URLError(.notConnectedToInternet)}
    func unlock() async->Bool {true}
  }
  func testPermissionAndUnlockAloneNeverPublishOrReadWhileLocked() async {
    let p=Provider()
    let s=DeviceConnections(provider:p)
    await s.connect(.calendar)
    XCTAssertEqual(p.reads,0)
    XCTAssertFalse(s.shareCalendarEvent(p.title,label:"Alex"))
    let unlocked=await s.unlock();XCTAssertTrue(unlocked)
    XCTAssertEqual(p.reads,0)
    await s.refreshCalendar(Date())
    XCTAssertEqual(p.reads,1);XCTAssertEqual(s.events.count,1)
    XCTAssertTrue(s.sharedCalendarCards.isEmpty)
  }
  func testTwoSyntheticLabelsPublishOnlySelectedSnapshotsAndLockKeepsNoPrivateCache() async {
    let p=Provider()
    let c=DeviceConnections(provider:p)
    _=await c.unlock();await c.connect(.calendar)
    XCTAssertTrue(c.shareCalendarEvent(p.title,label:"Alex"))
    let alex=c.sharedCalendarCards[0]
    c.lock();XCTAssertTrue(c.events.isEmpty)
    XCTAssertFalse(c.shareCalendarEvent(p.title,label:"Jamie"))
    p.title="Jamie private meeting"
    _=await c.unlock();await c.refreshCalendar(Date())
    XCTAssertEqual(c.sharedCalendarCards.map(\.title),[alex.title])
    XCTAssertTrue(c.shareCalendarEvent(p.title,label:"Jamie"))
    c.lock()
    XCTAssertTrue(c.events.isEmpty);XCTAssertEqual(p.reads,2)
    XCTAssertEqual(c.sharedCalendarCards.map(\.label),["Alex","Jamie"])
    XCTAssertEqual(c.sharedCalendarCards.map(\.title),["Alex private meeting","Jamie private meeting"])
    XCTAssertEqual(c.sharedCalendarCards.map(\.calendar),["Synthetic source","Synthetic source"])
    XCTAssertTrue(DeviceConnections(provider:p).sharedCalendarCards.isEmpty,"RAM grants never cross a new session")
    c.revokeSharedCalendar(alex.id)
    XCTAssertEqual(c.sharedCalendarCards.map(\.label),["Jamie"])
    XCTAssertEqual(p.reads,2,"Publishing, locking and revocation never read a store")
    c.endSharedPanelSession()
  }
  func testNewPrivateReadCannotSilentlyReplaceSharedSnapshot() async {
    let p=Provider()
    let s=DeviceConnections(provider:p)
    _=await s.unlock();await s.connect(.calendar)
    XCTAssertTrue(s.shareCalendarEvent(p.title,label:"Alex"))
    let id=s.sharedCalendarCards[0].id
    p.title="New unapproved event";await s.refreshCalendar(Date())
    XCTAssertEqual(s.events.first?.title,p.title)
    XCTAssertEqual(s.sharedCalendarCards.first?.title,"Alex private meeting")
    XCTAssertFalse(s.shareCalendarEvent("missing",label:"Alex"))
    XCTAssertEqual(s.sharedCalendarCards.first?.id,id)
    XCTAssertTrue(s.shareCalendarEvent(p.title,label:"Alex"))
    XCTAssertEqual(s.sharedCalendarCards.count,1)
    XCTAssertEqual(s.sharedCalendarCards.first?.title,p.title)
    s.revokeSharedCalendar(id) // obsolete grant ID cannot revoke a replacement
    XCTAssertEqual(s.sharedCalendarCards.count,1)
  }
  func testBoundedCardsAndInvalidLabelsCannotEvictHealthyPublications() async {
    let p=Provider()
    let c=DeviceConnections(provider:p)
    _=await c.unlock();await c.connect(.calendar)
    for label in ["Alex","Jamie","Casey","Morgan"] {XCTAssertTrue(c.shareCalendarEvent(p.title,label:label))}
    for label in ["Fifth","",String(repeating:"x",count:41),"Hidden\nLabel"] {
      XCTAssertFalse(c.shareCalendarEvent(p.title,label:label))
    }
    XCTAssertEqual(c.sharedCalendarCards.map(\.label),["Alex","Jamie","Casey","Morgan"])
    XCTAssertTrue(c.shareCalendarEvent(p.title,label:" Alex "))
    XCTAssertEqual(c.sharedCalendarCards.count,4)
  }
  func testReconnectDisconnectResetAndPermissionLossRevokePublications() async {
    for boundary in ["reconnect","disconnect","reset","permission"] {
      let p=Provider(),c=DeviceConnections(provider:p)
      _=await c.unlock();await c.connect(.calendar)
      XCTAssertTrue(c.shareCalendarEvent(p.title,label:"Alex"))
      switch boundary {
      case "reconnect":await c.connect(.calendar)
      case "disconnect":c.disconnect(.calendar)
      case "reset":c.resetLocalPreferences()
      default:
        p.permissions=false
        c.tick();p.permissions=true
      }
      XCTAssertTrue(c.sharedCalendarCards.isEmpty,boundary)
    }
  }
  func testRevocationDuringPendingReadCannotRepublishOrRestorePrivateDataAfterLock() async {
    let p=Provider(),c=DeviceConnections(provider:p)
    _=await c.unlock();await c.connect(.calendar)
    XCTAssertTrue(c.shareCalendarEvent(p.title,label:"Alex"))
    let id=c.sharedCalendarCards[0].id
    p.delayed=true
    let started=expectation(description:"actual read pending")
    p.onRead={started.fulfill()}
    let task=Task {await c.refreshCalendar(Date())}
    await fulfillment(of:[started],timeout:2)
    XCTAssertFalse(c.shareCalendarEvent(p.title,label:"Jamie"))
    c.revokeSharedCalendar(id);c.lock()
    p.reply?.resume(returning:[p.event(Date())]);await task.value
    XCTAssertTrue(c.sharedCalendarCards.isEmpty);XCTAssertTrue(c.events.isEmpty)
    XCTAssertFalse(c.personalUnlocked);XCTAssertEqual(p.reads,2)
  }
  func testSharedMusicMetadataRequiresSeparateQueueGrantEvenWhenAuthenticated() async {
    let p=Provider(),c=DeviceConnections(provider:p)
    _=await c.unlock();await c.connect(.music);await c.searchMusic("fixture");await c.playMusic(0)
    XCTAssertTrue(c.musicAccessAllowed);XCTAssertNil(c.sharedMusicTrack)
    XCTAssertTrue(c.setGuestMusicSharing(true));XCTAssertEqual(c.sharedMusicTrack?.title,"Private song")
    c.lock();XCTAssertEqual(c.sharedMusicTrack?.artist,"Private artist");XCTAssertFalse(c.musicSearchAllowed)
    c.endSharedPanelSession();XCTAssertNil(c.sharedMusicTrack);XCTAssertTrue(c.tracks.isEmpty)
  }
}
