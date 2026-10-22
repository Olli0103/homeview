import Foundation

@MainActor private final class Spy: DeviceDataProvider {
  var permission=true, grant=true, pending=false
  var reads=0, prompts=0, writes=0, musicReads=0
  var continuation:CheckedContinuation<[DeviceEvent],any Error>?
  var ready:(()->Void)?
  let now=Date(timeIntervalSince1970:1792645200)
  var values:[DeviceEvent]=[]
  func authorized(_ kind:DataConnection)->Bool {permission}
  func authorizePersonal(_ kind:DataConnection) async throws {prompts+=1}
  func events(from:Date,to:Date) async throws->[DeviceEvent] {
    reads+=1
    if pending {return try await withCheckedThrowingContinuation {continuation=$0;ready?()}}
    return values
  }
  func reminders() async throws->[DeviceReminder] {writes+=1;return []}
  func addReminder(_ value:String) async throws->String {writes+=1;return ""}
  func completeReminder(_ id:String,completed:Bool) async throws {writes+=1}
  func removeReminder(_ id:String) async throws {writes+=1}
  func authorizeMusic() async throws {prompts+=1}
  func searchMusic(_ text:String) async throws->[DeviceTrack] {
    musicReads+=1;return [.init(id:"song-canary",title:"UNAPPROVED_MUSIC_CANARY",artist:"Private artist",artwork:nil)]
  }
  func playMusic(_ index:Int) async throws {}
  func resumeMusic() async throws {}
  func pauseMusic() {}
  func resetLocalCaches() {}
  var musicPlaying:Bool {true}
  var musicTime:Double {10}
  func weather(_ city:String) async throws->WeatherReading {throw URLError(.notConnectedToInternet)}
  func unlock() async->Bool {grant}
  func event(_ id:String,_ title:String,cancelled:Bool=false,duration:Double=60)->DeviceEvent {
    .init(id:id,title:title,start:now,end:now.addingTimeInterval(duration),
      location:"UNPUBLISHED_LOCATION_CANARY",calendar:"Source fixture",cancelled:cancelled)
  }
}

@main struct Gate {
  @MainActor static func main() async {
    var assertions=0
    func check(_ value:Bool,_ code:String) {assertions+=1;if !value {print("FAIL "+code);exit(1)}}
    let p=Spy(),c=DeviceConnections(provider:Spy())
    let s=DeviceConnections(provider:p)
    p.values=[p.event("a","Approved A"),p.event("b","Approved B"),p.event("hidden","UNAPPROVED_CALENDAR_CANARY"),p.event("cancel","Cancelled",cancelled:true),p.event("zero","Zero",duration:0),p.event("large",String(repeating:"x",count:501))]
    await s.connect(.calendar,date:p.now)
    check(p.reads==0 && s.events.isEmpty && s.sharedCalendarCards.isEmpty,"locked-permission-no-read")
    check(!s.shareCalendarEvent("a",label:"Alex"),"locked-publish-denied")
    _=await s.unlock()
    check(p.reads==0 && s.sharedCalendarCards.isEmpty,"authentication-not-publication")
    await s.refreshCalendar(p.now)
    check(p.reads==1 && s.sharedCalendarCards.isEmpty,"read-not-publication")
    check(s.shareCalendarEvent("a",label:"Alex"),"approve-a")
    let first=s.sharedCalendarCards[0]
    let before=p.reads
    for pair in [("b",""),("b","newline\nlabel"),("b","nul\0label"),("missing","Jamie"),("cancel","Jamie"),("zero","Jamie"),("large","Jamie"),("b",String(repeating:"z",count:41))] {
      check(!s.shareCalendarEvent(pair.0,label:pair.1),"invalid-publication-denied")
      check(s.sharedCalendarCards.count==1 && s.sharedCalendarCards[0].id==first.id,"invalid-zero-effect")
    }
    let exposed=String(reflecting:first)
    check(!exposed.contains("UNPUBLISHED_LOCATION_CANARY") && !exposed.contains("UNAPPROVED_CALENDAR_CANARY"),"field-minimization")
    check(Set(Mirror(reflecting:first).children.compactMap(\.label)) == ["id","label","title","start","end","calendar","allDay"],"no-source-identifier-or-private-fields")
    check(s.shareCalendarEvent("b",label:"Jamie"),"approve-b")
    s.lock()
    check(s.events.isEmpty && !s.personalUnlocked,"switch-private-cache-cleared")
    check(s.sharedCalendarCards.map(\.title)==["Approved A","Approved B"],"approved-publications-survive-private-lock")
    check(!s.shareCalendarEvent("hidden",label:"Jamie"),"locked-cannot-replace")
    check(p.reads==before,"publication-not-source-read")
    s.revokeSharedCalendar(first.id)
    check(s.sharedCalendarCards.map(\.title)==["Approved B"],"guest-revocation-is-narrow")
    s.endSharedPanelSession()
    check(s.sharedCalendarCards.isEmpty && c.sharedCalendarCards.isEmpty,"session-end-and-fresh-session-empty")
    _=await s.unlock();await s.refreshCalendar(p.now)
    check(s.shareCalendarEvent("a",label:"Alex"),"reapprove-explicitly")
    p.permission=false
    check(s.sharedCalendarCards.isEmpty,"permission-immediate-denial")
    s.tick();p.permission=true
    check(s.sharedCalendarCards.isEmpty,"observed-revocation-cannot-revive")
    await s.connect(.calendar,date:p.now)
    check(s.shareCalendarEvent("a",label:"Alex"),"reconnect-alone-never-shares")
    p.pending=true
    let task=Task {await s.refreshCalendar(p.now)}
    while p.continuation == nil {await Task.yield()}
    s.endSharedPanelSession();s.lock()
    p.continuation?.resume(returning:p.values);await task.value
    check(s.sharedCalendarCards.isEmpty && s.events.isEmpty,"late-read-cannot-restore-after-end")
    check(p.writes==0 && p.musicReads==0,"zero-unrelated-side-effects")
    _=await s.unlock();await s.connect(.music);await s.searchMusic("synthetic");await s.playMusic(0)
    check(s.musicAccessAllowed && s.sharedMusicTrack == nil,"private-music-is-not-public")
    check(s.setGuestMusicSharing(true) && s.sharedMusicTrack != nil,"separate-music-approval")
    s.lock();check(s.sharedMusicTrack != nil && !s.musicSearchAllowed,"queue-not-account-shared")
    s.endSharedPanelSession();check(s.sharedMusicTrack == nil && s.tracks.isEmpty,"both-grant-types-ended")
    print("PASS independent shared-panel gate assertions=\(assertions)")
  }
}
