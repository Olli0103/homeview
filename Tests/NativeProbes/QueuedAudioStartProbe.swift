import Foundation

/// Symbolic audio dependency only. The runner excludes LocalAudioEngine.swift
/// and instruments Task entry without changing AppModel's control flow.
final class AudioProbeLog: @unchecked Sendable {
  static let shared=AudioProbeLog()
  private let lock=NSLock()
  private var entries:[String:Int]=[:],starts:[String:Int]=[:]
  func entered(_ kind:String) {lock.lock();defer {lock.unlock()};entries[kind,default:0]+=1}
  func started(_ kind:String) {lock.lock();defer {lock.unlock()};starts[kind,default:0]+=1}
  func counts(_ kind:String)->(entries:Int,starts:Int) {
    lock.lock();defer {lock.unlock()};return (entries[kind,default:0],starts[kind,default:0])
  }
}
final class LocalAudioEngine: @unchecked Sendable {
  func playMusic(volume:Float) async ->Bool {AudioProbeLog.shared.started("music");return true}
  func playPodcast(volume:Float) async ->Bool {AudioProbeLog.shared.started("podcast");return true}
  func playChime(volume:Float) async ->Bool {AudioProbeLog.shared.started("chime");return true}
  func prepareForSpeech() async ->Bool {true}
  func stopAll() {}
  func stopMusic() {}
  func stopPodcast() {}
  func setVolume(_ volume:Float) {}
}
enum NativeAudioError: Error {case missingAsset}
@main struct QueuedAudioStartProbe {
  @MainActor static func main() async throws {
    let args=ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"),let i=args.firstIndex(of:"--persistence-test"),
      args.indices.contains(i+1),UUID(uuidString:args[i+1]) != nil,
      !args.contains("--system-alarms"),
      Bundle.main.url(forResource:"demo-tone",withExtension:"wav") == nil else {fatalError("Owned symbolic audio probe only")}
    let scenario=args.last!,kind=scenario.hasPrefix("music") ? "music":"podcast"
    let positive=scenario.hasSuffix("positive"),model=AppModel()
    if scenario=="music_source" {_ = await model.connections.unlock()}
    if kind=="music" {model.togglePlayback()} else {model.togglePodcast()}
    if scenario.hasSuffix("stop") {model.stopAudioForVoice()}
    else if scenario.hasSuffix("double_toggle") {
      if kind=="music" {model.togglePlayback()} else {model.togglePodcast()}
    } else if scenario=="music_source" {
      await model.connectService(.music,expectedResetGeneration:model.localResetGeneration)
    }
    let deadline=ProcessInfo.processInfo.systemUptime+3
    while AudioProbeLog.shared.counts(kind).entries==0 && ProcessInfo.processInfo.systemUptime<deadline {await Task.yield()}
    for _ in 0..<20 {await Task.yield()}
    let counts=AudioProbeLog.shared.counts(kind)
    let checks:[String:Bool]=[
      "actual_appmodel_task_entered":counts.entries==1,
      "audio_api_admission":counts.starts==(positive ? 1:0),
      "music_model_state":kind != "music" || model.playing==positive,
      "podcast_model_state":kind != "podcast" || model.podcastPlaying==positive,
      "no_pending_music_flag":!model.startingMusic,
      "no_pending_podcast_flag":!model.startingPodcast,
      "no_timer_chime":AudioProbeLog.shared.counts("chime").starts==0]
    model.stopAudioForVoice()
    let failed=checks.filter {!$0.value}.map(\.key).sorted()
    let result:[String:Any]=["scenario":scenario,"checks":checks,"failed":failed,
      "verdict":failed.isEmpty ? "PASS":"FAIL","task_entries":counts.entries,
      "audio_api_calls":counts.starts,"real_audio":false,
      "scope":"Actual AppModel admission into a symbolic audio dependency, not AVAudioPlayer or acoustic evidence"]
    print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
  }
}
