import Foundation
@main struct NativeGuestGate {
 @MainActor static func main() async throws {
  let args=ProcessInfo.processInfo.arguments
  guard let i=args.firstIndex(of:"--case"),args.indices.contains(i+1) else { fatalError("Owned case required") }
  let scenario=args[i+1],model=AppModel()
  var assertions=0
  func require(_ value:Bool,_ message:String) {assertions+=1;precondition(value,message)}
  func disk()->Snapshot {try! Snapshot.decodeMigrating(Data(contentsOf:model.gateStoreURL))}
  func activeAssistant() {model.route = .assistant;model.setAnswerSpeechForeground(true)}
  func wait(_ predicate:()->Bool) async throws {
   let end=ContinuousClock.now.advanced(by:.seconds(3))
   while !predicate() && ContinuousClock.now<end {try await Task.sleep(for:.milliseconds(1))}
   require(predicate(),"Bounded owned fixture completion")
  }
  func prepareMusic() async {
   let granted=await model.connections.unlock();require(granted,"Positive synthetic device authentication")
   await model.connectService(.music,expectedResetGeneration:model.localResetGeneration)
   require(model.connections.enabled.contains(.music),"Explicit owner connection")
   await model.connections.searchMusic("synthetic approved queue");await model.connections.playMusic(0)
   require(model.currentMusicTitle=="Connected fixture song" && model.connections.musicPlaying,"Actual synthetic source selected and playing")
   require(disk().connectionConsent?.contains(.music)==true,"Source choice actually saved")
  }
  require(model.persist(),"Create owned baseline store explicitly")
  switch scenario {
  case "role_matrix_security":
   model.data.home.locked=false;require(model.persist(),"Owned unlocked mock fixture saved")
   let guestBytes=try Data(contentsOf:model.gateStoreURL),before=model.data.home
   model.command(.lock);require(model.data.home==before,"Guest direct security rejected atomically")
   model.error=nil;model.command(.scene("Good Night"));require(model.data.home==before,"Guest scene cannot bypass security")
   require(try Data(contentsOf:model.gateStoreURL)==guestBytes,"Denied commands cannot save success")
   activeAssistant();model.error=nil;model.assistantInput="good night";model.runAssistant()
   require(model.data.home==before,"Assistant scene goes through same authorization")
   require(model.assistantReply.contains("Device authentication"),"No fabricated assistant success")
   model.signIn("Alex");require(!model.canControlMockSecurity,"Demo user has no device authority")
   model.error=nil;model.command(.lock);require(model.data.home==before,"Demo-profile security rejected")
   model.error=nil;model.command(.temperature(72));model.command(.brightness(30))
   require(model.data.home.temperature==72 && model.data.home.brightness==30,"Shared nonsecurity controls remain available")
   require(model.addTimer(seconds:90,title:"Synthetic guest timer"),"Guest timer permitted")
   require(model.data.nativeTimerIDs.isEmpty,"No system timer integration enabled by the test")
   let granted=await model.connections.unlock();require(granted && model.canControlMockSecurity,"Synthetic authenticated device holder positive role")
   model.error=nil;model.command(.lock);require(model.data.home.locked,"Explicit authenticated security operation works")
   model.command(.scene("Good Night"));require(disk().home.temperature==66 && disk().home.locked,"Authenticated scene saved; no real Home")
  case "private_music":
   await prepareMusic();model.lockPersonalAccess()
   require(model.connections.tracks.isEmpty && model.connections.currentTrack==nil,"Unshared account queue cleared on lock")
   require(!model.connections.musicPlaying && !model.musicIsPlaying,"Unshared music stopped")
   require(!model.currentMusicTitle.contains("fixture song") && !model.currentMusicArtist.contains("Synthetic Artist"),"Activity/widget metadata gated")
   await model.connections.searchMusic("guest query");await model.connections.playMusic(0);await model.connections.toggleMusic()
   require(model.connections.tracks.isEmpty && !model.connections.musicPlaying,"Direct source calls cannot restore unshared account data")
   model.route = .face;model.togglePlayback()
   require(model.route == .deviceUnlock && model.pendingPage == .music,"Shared widget toggle requests authentication, never resumes")
   activeAssistant();model.assistantInput="music";model.runAssistant()
   require(model.route == .deviceUnlock && !model.connections.musicPlaying,"Assistant cannot resume private account source")
  case "shared_queue":
   await prepareMusic();require(model.connections.setGuestMusicSharing(true),"Explicit authenticated current queue approval")
   model.beginGuestMusicUse()
   require(model.profile==nil && !model.connections.personalUnlocked,"Guest handover clears profile and private authentication")
   require(model.connections.guestMusicShared && model.connections.musicAccessAllowed,"Only explicit queue remains available")
   let ids=model.connections.tracks.map(\.id)
   await model.connections.searchMusic("unapproved new query")
   require(model.connections.tracks.map(\.id)==ids && !model.connections.musicSearchAllowed,"Sharing never grants search")
   require(!model.connections.setGuestMusicSharing(true),"Guest cannot create/extend sharing authority")
   model.togglePlayback();try await wait { !model.connections.musicPlaying }
   model.togglePlayback();try await wait { model.connections.musicPlaying }
   require(model.currentMusicTitle=="Connected fixture song","Approved queue metadata remains explicit")
   let owner=await model.connections.unlock();require(owner,"Synthetic owner returns")
   require(model.connections.setGuestMusicSharing(false),"Explicit revocation")
   require(!model.connections.musicPlaying && !model.connections.guestMusicShared,"Revocation stops shared playback")
   model.lockPersonalAccess();require(model.connections.tracks.isEmpty,"Revoked queue cannot survive lock")
  case "background_lifetime":
   await prepareMusic();require(model.connections.setGuestMusicSharing(true),"Explicit queue approval")
   model.beginGuestMusicUse()
   // The Root background handler calls these same operations; actual scene entry is tested in UI.
   model.connections.endGuestMusicSession();model.lockPersonalAccess()
   require(!model.connections.guestMusicShared && !model.connections.musicAccessAllowed,"Background sequence revokes grant")
   require(model.connections.tracks.isEmpty && model.connections.currentTrack==nil,"No queue metadata remains")
   require(!model.connections.musicPlaying,"Playback stopped")
   require(disk().connectionConsent?.contains(.music)==true,"Source choice may remain; it is not a sharing grant")
   model.connections.resetLocalPreferences()
   require(!model.connections.guestMusicShared && model.connections.enabled.isEmpty,"Reset cannot retain guest media authority")
  case "denied_owner":
   model.signIn("Alex");activeAssistant()
   let granted=await model.connections.unlock();require(!granted,"Synthetic denied device authentication")
   await model.connectService(.music,expectedResetGeneration:model.localResetGeneration)
   require(model.connections.enabled.isEmpty && model.connections.requested.isEmpty,"Demo profile cannot connect an account-backed source")
   require(model.data.connectionConsent?.contains(.music) != true,"Rejected account choice cannot be persisted")
   require(!model.connections.setGuestMusicSharing(true),"Denied authentication cannot create sharing grant")
   let before=model.data.home;model.command(.lock);require(model.data.home==before,"Denied owner cannot operate mock security")
  case "fresh_session":
   require(!model.connections.guestMusicShared && model.connections.tracks.isEmpty,"New app session defaults to no sharing and no account queue")
   require(!model.canControlMockSecurity && !model.connections.personalUnlocked,"No automatic owner role")
   require(!GuestAccessPolicy.allows(.realHome,role:.deviceAuthenticated) && !GuestAccessPolicy.allows(.realCommunication,role:.deviceAuthenticated),"Even authenticated device role cannot enable real Home or communications")
  default:fatalError("Unknown owned case")
  }
  let result:[String:Any]=["case":scenario,"assertions":assertions,"verdict":"PASS"]
  print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
 }
}
