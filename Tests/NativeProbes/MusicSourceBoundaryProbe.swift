import Foundation

/// Actual AppModel and its production-selected synthetic provider. No audio asset
/// is bundled, no system provider is selected and no native MusicKit call runs.
@main struct MusicSourceBoundaryProbe {
  @MainActor static func main() async throws {
    let args=ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"),let i=args.firstIndex(of:"--persistence-test"),
      args.indices.contains(i+1),UUID(uuidString:args[i+1]) != nil,
      Bundle.main.url(forResource:"demo-tone",withExtension:"wav") == nil,
      !args.contains("--system-alarms") else {fatalError("Owned synthetic fixture only")}
    let scenario=args.last!,model=AppModel()
    var checks:[String:Bool]=[:]
    func check(_ name:String,_ condition:Bool) {precondition(checks[name]==nil);checks[name]=condition}
    let granted=await model.connections.unlock();check("fixture_device_grant",granted)
    if scenario != "positive" {model.playing=true;model.startingMusic=true}
    await model.connectService(.music,expectedResetGeneration:model.localResetGeneration)
    if scenario=="positive" {
      await model.connections.loadMusicLibrary();await model.connections.playMusic(0)
      check("explicit_source_connected",model.connections.enabled.contains(.music))
      check("actual_fixture_title",model.currentMusicTitle=="Library fixture song")
      check("actual_fixture_artist",model.currentMusicArtist=="Synthetic Library")
      check("provider_playback_state",model.musicIsPlaying)
      model.connections.pauseMusic();check("provider_pause_state",!model.musicIsPlaying)
      model.connections.disconnect(.music)
      check("only_explicit_disconnect_returns_demo",model.currentMusicTitle==Fixtures.songs[model.song])
    } else {
      check("selected_source_is_not_connected",model.connections.requested.contains(.music) && !model.connections.enabled.contains(.music))
      check("source_choice_stops_old_demo_state",!model.playing && !model.startingMusic)
      model.playing=false;model.startingMusic=false
      if scenario=="locked" {model.connections.lock()}
      check("no_demo_title",model.currentMusicTitle != Fixtures.songs[model.song])
      check("no_demo_artist",model.currentMusicArtist != "Demo Artist")
      // A synthetic old-demo state must not override the selected source.
      model.playing=true;check("no_old_demo_playback_projection",!model.musicIsPlaying);model.playing=false
      let generation=model.audioGeneration
      model.togglePlayback()
      check("no_demo_start_request",!model.startingMusic)
      check("no_demo_audio_dispatch",model.audioGeneration==generation)
      check("correct_reconnect_or_unlock_route",scenario=="locked" ? model.route == .deviceUnlock:model.route == .app(.music))
      model.stopAudioForVoice()
    }
    let failed=checks.filter {!$0.value}.map(\.key).sorted()
    let result:[String:Any]=["scenario":scenario,"provider":"FixtureDeviceDataProvider",
      "checks":checks,"failed":failed,"verdict":failed.isEmpty ? "PASS":"FAIL",
      "real_MusicKit_or_audio":false]
    print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
  }
}
