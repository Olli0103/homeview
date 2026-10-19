import Foundation
import AVFoundation
import Observation

#if !os(watchOS)
enum PodcastFeedClient {
  static func load(_ url:URL) async throws -> PodcastFeed {
    guard PodcastURLPolicy.allows(url) else { throw PodcastFeedError.invalidURL }
    let args=ProcessInfo.processInfo.arguments
    if args.contains("--uitesting") {
      guard args.contains("--podcast-fixture"),url==PodcastFixture.feedURL else { throw PodcastFeedError.unavailable }
      return try PodcastFeedParser.parse(Data(PodcastFixture.xml.utf8),url:url)
    }
    return try await PodcastFeedTransport.load(url)
  }
}
enum PodcastFixture {
  static let feedURL=URL(string:"https://fixtures.invalid/homeview-podcast.xml")!
  static let xml="""
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"><channel><title>HomeView Test Feed</title>
  <item><title>Own Audio Episode One</title><enclosure url="https://fixtures.invalid/first.wav" type="audio/wav" length="1920044"/><itunes:duration>60</itunes:duration></item>
  <item><title>Own Audio Episode Two</title><enclosure url="https://fixtures.invalid/second.wav" type="audio/wav" length="1920044"/><itunes:duration>60</itunes:duration></item>
  </channel></rss>
  """
  static func playbackURL(_ url: URL) -> URL? {
    guard ProcessInfo.processInfo.arguments.contains("--uitesting"),
      ProcessInfo.processInfo.arguments.contains("--podcast-fixture"),url.host=="fixtures.invalid",
      ["/first.wav","/second.wav"].contains(url.path) else { return nil }
    return Bundle.main.url(forResource:"podcast-test-audio",withExtension:"wav")
  }
}
@MainActor @Observable
final class PodcastPlaybackController {
  private var player: AVPlayer?
  private(set) var episodeID: String?
  private(set) var requested = false
  private(set) var playing = false
  private(set) var position = 0.0
  private(set) var duration: Double?
  private(set) var status = "Paused"
  private var generation = 0
  private var initialSeek: Double?
  func load(_ episode: PodcastEpisode,position: Double) {
    stop();episodeID=episode.id;self.position=max(0,position);duration=episode.duration
    let args=ProcessInfo.processInfo.arguments
    let url: URL
    if args.contains("--uitesting") {
      guard let local=PodcastFixture.playbackURL(episode.mediaURL) else { status="Playback unavailable in tests";return }
      url=local
    } else { url=episode.mediaURL }
    let item=AVPlayerItem(url:url);player=AVPlayer(playerItem:item)
    player?.volume=1;initialSeek=max(0,position);requested=true;status="Loading audio…"
  }
  func poll() {
    guard let player,let item=player.currentItem else { return }
    if item.status == .failed { requested=false;playing=false;status="Audio unavailable. You can retry or choose another episode.";return }
    guard item.status == .readyToPlay else { return }
    let actual=item.duration.seconds
    if actual.isFinite,actual>0 { duration=actual }
    if let initial=initialSeek {
      initialSeek=nil;seek(to:initial);return
    }
    let time=player.currentTime().seconds
    if time.isFinite { position=max(0,time) }
    if let duration,position>=duration-0.15 { requested=false;player.pause();status="Finished" }
    if requested,player.rate==0 { player.play() }
    playing=player.timeControlStatus == .playing
    if status != "Finished" { status=playing ? "Playing":requested ? "Buffering…":"Paused" }
  }
  func pause() { requested=false;player?.pause();playing=false;poll();status="Paused" }
  func resume() {
    guard let player else { return }
    if let item=player.currentItem,item.status == .failed {
      generation+=1;initialSeek=position
      player.replaceCurrentItem(with:AVPlayerItem(asset:item.asset))
    } else if status == "Finished" { status="Paused";seek(to:0) }
    requested=true;player.play();poll()
  }
  func seek(to value: Double) {
    guard value.isFinite,let player else { return }
    let target=min(max(0,value),max(0,(duration ?? 604800)-0.05));let ticket=generation
    position=target
    player.seek(to:CMTime(seconds:target,preferredTimescale:600),toleranceBefore:.zero,toleranceAfter:.zero) { [weak self] finished in
      Task { @MainActor in
        guard let self,self.generation==ticket,finished else { return }
        if self.requested { self.player?.play() }
      }
    }
  }
  func stop() {
    generation+=1;requested=false;playing=false;player?.pause();player?.replaceCurrentItem(with:nil)
    player=nil;episodeID=nil;initialSeek=nil;status="Paused"
  }
}
#endif
