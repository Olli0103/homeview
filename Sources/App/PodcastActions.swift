import Foundation

#if !os(watchOS)
extension AppModel {
  var currentPodcastTitle: String { data.podcasts.selectedEpisode?.title ?? "A Quiet Morning" }
  var currentPodcastSource: String { data.podcasts.selectedFeed?.title ?? "Demo episode · Local audio" }
  var podcastRequested: Bool { data.podcasts.selectedEpisode == nil ? podcastPlaying:podcastPlayer.requested }
  func importPodcastFeed(_ raw: String) async {
    guard let url=PodcastURLPolicy.address(raw) else { podcastStatus=PodcastFeedError.invalidURL.localizedDescription;return }
    guard data.podcasts.feeds.count<8 || data.podcasts.feeds.contains(where: { $0.url==url }) else {
      podcastStatus="Remove a feed before adding another (maximum eight).";return
    }
    podcastFeedGeneration+=1;let ticket=podcastFeedGeneration;podcastLoading=true;podcastStatus="Loading RSS…"
    defer { if podcastFeedGeneration==ticket { podcastLoading=false } }
    do {
      let feed=try await PodcastFeedClient.load(url)
      guard podcastFeedGeneration==ticket,!Task.isCancelled else { return }
      let old=data.podcasts;data.podcasts.upsert(feed)
      guard persist() else { data.podcasts=old;podcastStatus="Feed not saved.";return }
      if old.selectedID != data.podcasts.selectedID { podcastPlayer.stop();podcastPlaying=false }
      podcastStatus="RSS loaded · \(feed.episodes.count) episodes"
    } catch {
      guard podcastFeedGeneration==ticket,!Task.isCancelled else { return }
      podcastStatus=(error as? PodcastFeedError)?.localizedDescription ?? PodcastFeedError.unavailable.localizedDescription
    }
  }
  func removePodcastFeed(_ id: String) {
    podcastFeedGeneration+=1;podcastLoading=false
    let old=data.podcasts;let selected=data.podcasts.selectedID;data.podcasts.remove(id)
    guard persist() else { data.podcasts=old;return }
    if selected != data.podcasts.selectedID { podcastPlayer.stop();podcastPlaying=false }
    podcastStatus="Feed removed. Local metadata and progress were removed."
  }
  func selectPodcastEpisode(_ id: String) {
    savePodcastPosition()
    let old=data.podcasts;data.podcasts.selectedID=id
    guard data.podcasts.selectedEpisode != nil,persist() else { data.podcasts=old;return }
    audioGeneration+=1;startingPodcast=false;audio.stopPodcast()
    podcastPlayer.stop();podcastPlaying=false
    // Selection never autoplays. The explicit Play action starts network audio.
  }
  func usePodcastDemo() {
    savePodcastPosition();let old=data.podcasts;data.podcasts.selectedID=nil
    guard persist() else { data.podcasts=old;return }
    podcastPlayer.stop();podcastPlaying=false
  }
  func toggleFeedPodcast() {
    guard let episode=data.podcasts.selectedEpisode else { return }
    connections.pauseMusic();audioGeneration+=1;startingMusic=false;startingPodcast=false
    playing=false;audio.stopMusic();audio.stopPodcast()
    if podcastPlayer.requested { podcastPlayer.pause();savePodcastPosition() }
    else if podcastPlayer.episodeID==episode.id { podcastPlayer.resume() }
    else { podcastPlayer.load(episode,position:data.podcasts.positions[episode.id] ?? 0) }
    podcastPlayer.poll();podcastPlaying=podcastPlayer.playing
  }
  func seekPodcast(by delta: Double) {
    guard data.podcasts.selectedEpisode != nil else { return }
    podcastPlayer.seek(to:podcastPlayer.position+delta);savePodcastPosition()
  }
  func savePodcastPosition() {
    guard let id=podcastPlayer.episodeID,data.podcasts.selectedID==id else { return }
    let old=data.podcasts;data.podcasts.positions[id]=podcastPlayer.position
    if !persist() { data.podcasts=old }
  }
  func pauseFeedPodcast() {
    guard podcastPlayer.episodeID != nil else { return }
    podcastPlayer.pause();podcastPlaying=false;savePodcastPosition()
  }
}
#endif
