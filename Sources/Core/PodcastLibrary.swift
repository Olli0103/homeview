import Foundation

struct PodcastEpisode: Codable, Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let mediaURL: URL
  let duration: Double?
}
struct PodcastFeed: Codable, Equatable, Identifiable, Sendable {
  let url: URL
  let title: String
  let episodes: [PodcastEpisode]
  var id: String { url.absoluteString }
}
struct PodcastLibrary: Codable, Sendable {
  var feeds: [PodcastFeed] = []
  var selectedID: String?
  var positions: [String:Double] = [:]
  var selectedEpisode: PodcastEpisode? {
    feeds.lazy.flatMap(\.episodes).first { $0.id == selectedID }
  }
  var selectedFeed: PodcastFeed? { feeds.first { $0.episodes.contains { $0.id == selectedID } } }
  var normalized: Self {
    var result = Self(); var feedIDs = Set<String>();var episodeIDs = Set<String>()
    for feed in feeds.prefix(8) where PodcastURLPolicy.allows(feed.url) && feedIDs.insert(feed.id).inserted {
      let episodes=feed.episodes.prefix(100).compactMap { episode -> PodcastEpisode? in
        guard PodcastURLPolicy.allows(episode.mediaURL), episode.id == Self.episodeID(feed:feed.url,media:episode.mediaURL),
          episodeIDs.insert(episode.id).inserted else { return nil }
        return PodcastEpisode(id:episode.id,title:Self.label(episode.title),mediaURL:episode.mediaURL,
          duration:episode.duration.flatMap { $0.isFinite && $0>0 && $0<=604800 ? $0:nil })
      }
      result.feeds.append(PodcastFeed(url:feed.url,title:Self.label(feed.title),episodes:episodes))
    }
    if episodeIDs.contains(selectedID ?? "") { result.selectedID = selectedID }
    for episode in result.feeds.flatMap(\.episodes) {
      if let position=positions[episode.id],position.isFinite {
        result.positions[episode.id]=min(max(0,position),episode.duration ?? 604800)
      }
    }
    return result
  }
  mutating func upsert(_ feed: PodcastFeed) {
    if let index=feeds.firstIndex(where: { $0.id == feed.id }) { feeds[index]=feed }
    else if feeds.count<8 { feeds.append(feed) }
    self=normalized
  }
  mutating func remove(_ id: String) { feeds.removeAll { $0.id==id };self=normalized }
  static func episodeID(feed: URL,media: URL) -> String { feed.absoluteString+"\n"+media.absoluteString }
  static func label(_ value: String) -> String {
    String(value.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
      .map(String.init).joined().trimmingCharacters(in:.whitespacesAndNewlines).prefix(240))
  }
}
enum PodcastURLPolicy {
  static func allows(_ url: URL) -> Bool {
    url.absoluteString.count<=4096 && url.scheme?.lowercased()=="https"
      && url.host?.isEmpty==false && url.user==nil && url.password==nil && url.fragment==nil
      && (url.port == nil || url.port==443)
  }
  static func address(_ text: String) -> URL? {
    let value=text.trimmingCharacters(in:.whitespacesAndNewlines)
    guard let url=URL(string:value),allows(url) else { return nil };return url
  }
}
