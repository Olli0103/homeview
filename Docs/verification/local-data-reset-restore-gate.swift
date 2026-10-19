import Foundation
@MainActor final class RestoreProvider:DeviceDataProvider {
 var log:[String]=[]
 var pending:CheckedContinuation<[DeviceEvent],Error>?
 var pauseCount=0
 var cacheDrops=0
 func authorized(_ kind:DataConnection)->Bool { log.append("permission-state:"+kind.rawValue);return true }
 func authorizePersonal(_ kind:DataConnection)async throws { log.append("permission-request") }
 func events(from:Date,to:Date)async throws->[DeviceEvent] {
  log.append("calendar-read")
  return try await withCheckedThrowingContinuation {pending=$0}
 }
 func reminders()async throws->[DeviceReminder] {log.append("reminder-read");return []}
 func addReminder(_ title:String)async throws->String {log.append("source-write");return "synthetic"}
 func completeReminder(_ id:String,completed:Bool)async throws {log.append("source-write")}
 func removeReminder(_ id:String)async throws {log.append("source-write")}
 func authorizeMusic()async throws {log.append("music-authorize")}
 func searchMusic(_ text:String)async throws->[DeviceTrack] {log.append("music-search");return []}
 func playMusic(_ index:Int)async throws {log.append("music-play")}
 func resumeMusic()async throws {log.append("music-resume")}
 func pauseMusic(){pauseCount+=1}
 func resetLocalCaches(){cacheDrops+=1;pauseMusic()}
 var musicPlaying:Bool {false};var musicTime:Double {0}
 func weather(_ city:String)async throws->WeatherReading {log.append("weather-fetch");throw CocoaError(.featureUnsupported)}
 func unlock()async->Bool {true}
}
@main struct RestoreGate {
 @MainActor static func wait(_ f:()->Bool) async {
  for _ in 0..<2000 {if f(){return};try? await Task.sleep(nanoseconds:1_000_000)}
  precondition(f(),"Synthetic restore gate stalled")
 }
 @MainActor static func main() async throws {
  var rows:[[String:Any]]=[]
  func check(_ id:String,_ pass:Bool){rows.append(["id":id,"passed":pass])}
  for globalCancel in [false,true] {
   let name="ResetIndependent-"+UUID().uuidString
   let defaults=UserDefaults(suiteName:name)!
   // Use only this generated suite, never standard/live provider defaults.
   defer {defaults.removePersistentDomain(forName:name)}
   let p=RestoreProvider()
   let c=DeviceConnections(provider:p,testing:false,defaults:defaults)
   _ = await c.unlock()
   let restore=Task {await c.restore(allowed:[.calendar,.reminders])}
   await wait {p.pending != nil}
   if globalCancel {c.cancelRestoration()}
   c.disconnect(.calendar);p.pending?.resume(returning:[]);await restore.value
   if globalCancel {
    check("global-revocation-stops-successor-service",!p.log.contains("reminder-read") && c.requested.isEmpty && c.enabled.isEmpty)
   } else {
    check("ordinary-single-service-disconnect-keeps-other-prior-consent",p.log.contains("reminder-read") && c.enabled==[.reminders])
   }
  }
  do {
   let name="ResetIndependent-"+UUID().uuidString
   let defaults=UserDefaults(suiteName:name)!
   defer {defaults.removePersistentDomain(forName:name)}
   for kind in DataConnection.allCases {defaults.set(true,forKey:"HomeView.connected."+kind.rawValue)}
   let p=RestoreProvider()
   let session=DeviceConnections(provider:p,testing:false,defaults:defaults)
   await session.restore(allowed:[])
   check("empty-Snapshot-consent-overrides-all-old-preferences",p.log.isEmpty && session.enabled.isEmpty && session.requested.isEmpty)
   let task=Task {await session.restore(allowed:[.weather])};task.cancel();await task.value
   check("pre-cancel-restore-never-starts-provider-or-state",p.log.isEmpty && session.requested.isEmpty)
   let direct=Task {await session.connect(.weather)};direct.cancel();await direct.value
   check("pre-cancel-direct-connect-zero-effect",p.log.isEmpty && session.requested.isEmpty)
   defaults.set("SYNTHETIC_SOURCE_LIST_ID",forKey:"HomeView.reminders.ownedCalendarID")
   session.city="Synthetic city";session.resetLocalPreferences()
   check("reset-clears-only-app-preferences-and-caches",p.cacheDrops==1 && session.city=="Berlin" && !session.personalUnlocked && !p.log.contains("source-write") && defaults.string(forKey:"HomeView.reminders.ownedCalendarID")=="SYNTHETIC_SOURCE_LIST_ID")
  }
  print(String(decoding:try JSONSerialization.data(withJSONObject:rows,options:[.sortedKeys]),as:UTF8.self))
  exit(rows.allSatisfy{$0["passed"] as? Bool==true} ? 0:1)
 }
}
