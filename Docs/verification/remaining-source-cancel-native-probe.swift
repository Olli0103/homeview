import Foundation
@MainActor final class GateProvider:DeviceDataProvider {
 var denied:Set<DataConnection>=[]
 var reads=0,writes=0,prompts=0
 var delayedMusicAuthorization=false
 var musicReply:CheckedContinuation<Void,any Error>?
 var delayedWeather=false
 var weatherReply:CheckedContinuation<WeatherReading,any Error>?
 var weatherValue:WeatherReading {WeatherReading(city:"Synthetic native weather",temperature:68,high:70,low:50,humidity:50,wind:10,code:0,sunset:nil,utcOffset:0,observedAt:Date())}
 var delayed=false
 var reply:CheckedContinuation<[DeviceReminder],any Error>?
 var list=[DeviceReminder(id:"own",title:"Synthetic source item",completed:false)]
 func authorized(_ kind:DataConnection)->Bool { !denied.contains(kind) }
 func authorizePersonal(_ kind:DataConnection) async throws { prompts+=1 }
 func events(from:Date,to:Date) async throws->[DeviceEvent] { reads+=1;return [DeviceEvent(id:"own",title:"Synthetic source event",start:from.addingTimeInterval(60),end:from.addingTimeInterval(120),location:"",calendar:"Synthetic",cancelled:false)] }
 func reminders() async throws->[DeviceReminder] { reads+=1;if delayed {return try await withCheckedThrowingContinuation {reply=$0}};return list }
 func addReminder(_ title:String) async throws->String {writes+=1;return "new"}
 func completeReminder(_ id:String,completed:Bool) async throws {writes+=1}
 func removeReminder(_ id:String) async throws {writes+=1}
 func authorizeMusic() async throws { if delayedMusicAuthorization {try await withCheckedThrowingContinuation {musicReply=$0}} }
 func searchMusic(_ text:String) async throws->[DeviceTrack] {[]}
 func playMusic(_ index:Int) async throws {}
 func resumeMusic() async throws {}
 func pauseMusic() {}
 var musicPlaying:Bool {false}
 var musicTime:Double {0}
 func weather(_ city:String) async throws->WeatherReading {if delayedWeather {return try await withCheckedThrowingContinuation {weatherReply=$0}};return weatherValue}
 func unlock() async->Bool {true}
}
@main struct PermissionGate {
 @MainActor static func main() async throws {
  var checks:[String:Bool]=[:]
  do {
   let p=GateProvider()
   let m=DeviceConnections(provider:p);_ = await m.unlock();await m.connect(.calendar);await m.connect(.reminders)
   checks["both_caches_loaded"]=m.events.count==1 && m.reminders.count==1
   let reads=p.reads,prompts=p.prompts;p.denied.insert(.calendar);m.tick()
   checks["calendar_cache_cleared"]=m.events.isEmpty && !m.enabled.contains(.calendar)
   checks["other_source_and_device_auth_preserved"]=m.reminders.count==1 && m.personalUnlocked
   checks["poll_neither_reads_nor_prompts"]=p.reads==reads && p.prompts==prompts
   p.denied.remove(.calendar);m.tick();checks["permission_return_is_not_reconnect"]=m.events.isEmpty && !m.enabled.contains(.calendar)
   await m.connect(.calendar);checks["explicit_reconnect_loads_again"]=m.events.count==1
   p.denied.insert(.reminders);let item=m.reminders[0];let added=await m.addReminder("Synthetic denied item");await m.completeReminder(item);await m.removeReminder(item)
   checks["all_new_writes_blocked"] = !added && p.writes==0
   checks["denied_reminder_cache_cleared"]=m.reminders.isEmpty && !m.enabled.contains(.reminders)
   checks["calendar_survives_reminder_revocation"]=m.events.count==1
  }
  do {
   let p=GateProvider();let m=DeviceConnections(provider:p);_ = await m.unlock();p.delayed=true
   let old=Task {await m.connect(.reminders)}
   for _ in 0..<1000 where p.reply==nil {await Task.yield()}
   guard let reply=p.reply else {fatalError("Controlled read did not enter")}
   p.denied.insert(.reminders);reply.resume(returning:p.list);await old.value
   checks["late_return_rechecks_live_permission"]=m.reminders.isEmpty && !m.enabled.contains(.reminders)
   checks["late_return_cleans_busy"] = !m.busy.contains(.reminders)
  }
  do {
   let p=GateProvider();let m=DeviceConnections(provider:p);_ = await m.unlock();p.delayed=true
   let old=Task {await m.connect(.reminders)}
   for _ in 0..<1000 where p.reply==nil {await Task.yield()}
   guard let oldReply=p.reply else {fatalError("Controlled old read did not enter")}
   p.denied.insert(.reminders);m.tick();p.denied.remove(.reminders);p.reply=nil
   let current=Task {await m.connect(.reminders)}
   for _ in 0..<1000 where p.reply==nil {await Task.yield()}
   guard let currentReply=p.reply else {fatalError("Controlled new read did not enter")}
   oldReply.resume(throwing:CocoaError(.featureUnsupported));await old.value
   checks["old_error_cannot_clear_new_busy"]=m.busy.contains(.reminders)
   checks["old_error_cannot_replace_new_status"]=m.status[.reminders]=="Connecting…"
   currentReply.resume(returning:p.list);await current.value
   checks["current_read_still_commits"]=m.reminders.count==1 && m.enabled.contains(.reminders)
   checks["current_read_cleans_own_busy"] = !m.busy.contains(.reminders)
  }
  do {
   let p=GateProvider();let m=DeviceConnections(provider:p);_ = await m.unlock();await m.connect(.reminders)
   let before=m.reminders.map(\.id),status=m.status[.reminders],reads=p.reads,item=m.reminders[0]
   let cancelled=Task { let added=await m.addReminder("Synthetic pre-cancelled item");await m.completeReminder(item);await m.removeReminder(item);return added }
   cancelled.cancel();let confirmed=await cancelled.value
   checks["cancelled_before_submit_calls_no_writes"] = !confirmed && p.writes==0
   checks["cancelled_before_submit_starts_no_readback"]=p.reads==reads
   checks["cancelled_before_submit_keeps_prior_status"]=m.status[.reminders]==status
   p.delayed=true;p.reply=nil
   let late=Task {await m.connect(.reminders)}
   for _ in 0..<1000 where p.reply==nil {await Task.yield()}
   guard let reply=p.reply else {fatalError("Cancelled read did not enter")}
   late.cancel();reply.resume(returning:[DeviceReminder(id:"late",title:"Synthetic cancelled result",completed:false)]);await late.value
   checks["cancelled_read_cannot_install"]=m.reminders.map(\.id)==before
   checks["cancelled_read_restores_status"]=m.status[.reminders]==status && !m.busy.contains(.reminders)
   p.reply=nil
   let error=Task {await m.connect(.reminders)}
   for _ in 0..<1000 where p.reply==nil {await Task.yield()}
   guard let errorReply=p.reply else {fatalError("Cancelled error read did not enter")}
   error.cancel();errorReply.resume(throwing:CocoaError(.featureUnsupported));await error.value
   checks["cancelled_error_keeps_cache_and_enabled"]=m.reminders.map(\.id)==before && m.enabled.contains(.reminders)
   checks["cancelled_error_restores_status"]=m.status[.reminders]==status && !m.busy.contains(.reminders)
  }
  do {
   let suite="org.example.homeview.native.cancelled-source."+UUID().uuidString
   guard let defaults=UserDefaults(suiteName:suite) else {fatalError("Own defaults fixture unavailable")}
   defer {defaults.removePersistentDomain(forName:suite)}
   let p=GateProvider();let m=DeviceConnections(provider:p,testing:false,defaults:defaults);_ = await m.unlock();p.delayedMusicAuthorization=true
   let connect=Task {await m.connect(.music)}
   for _ in 0..<1000 where p.musicReply==nil {await Task.yield()}
   guard let reply=p.musicReply else {fatalError("Controlled music permission did not enter")}
   connect.cancel();reply.resume();await connect.value
   checks["cancelled_music_cannot_enable_connection"] = !m.enabled.contains(.music)
   checks["cancelled_music_cannot_set_restore_preference"] = !defaults.bool(forKey:"HomeView.connected.Apple Music")
   checks["cancelled_music_restores_status_and_busy"]=m.status[.music]=="Not connected" && !m.busy.contains(.music)
  }
  do {
   let p=GateProvider();let m=DeviceConnections(provider:p);await m.connect(.weather);let status=m.status[.weather];p.delayedWeather=true
   let refresh=Task {await m.connect(.weather)}
   for _ in 0..<1000 where p.weatherReply==nil {await Task.yield()}
   guard let reply=p.weatherReply else {fatalError("Controlled weather error did not enter")}
   refresh.cancel();reply.resume(throwing:CocoaError(.featureUnsupported));await refresh.value
   checks["cancelled_weather_error_retains_good_status"]=m.status[.weather]==status && !m.weatherFetchFailed
   checks["cancelled_weather_error_retains_reading"]=m.enabled.contains(.weather) && m.weather?.temperature==68
  }
  do {
   let p=GateProvider();let m=DeviceConnections(provider:p);p.delayedWeather=true
   let read=Task {await m.connect(.weather)}
   for _ in 0..<1000 where p.weatherReply==nil {await Task.yield()}
   guard let reply=p.weatherReply else {fatalError("Controlled weather success did not enter")}
   read.cancel();reply.resume(returning:p.weatherValue);await read.value
   checks["cancelled_weather_success_drops_data_and_restores_status"]=m.weather==nil && !m.enabled.contains(.weather) && m.status[.weather]=="Not connected" && !m.busy.contains(.weather)
  }
  let failed=checks.filter{!$0.value}.map(\.key).sorted()
  print(String(data:try JSONSerialization.data(withJSONObject:["checks":checks,"assertions":checks.count,"failed":failed,"verdict":failed.isEmpty ? "PASS":"FAIL"],options:[.sortedKeys]),encoding:.utf8)!)
 }
}
