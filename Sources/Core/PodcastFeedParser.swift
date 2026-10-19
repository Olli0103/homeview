import Foundation
import FeedKit

enum PodcastFeedError: Error, LocalizedError {
  case invalidURL, invalidFeed, noAudio, tooLarge, unavailable
  var errorDescription: String? {
    switch self {
    case .invalidURL: "Use a public HTTPS RSS URL without a login or fragment."
    case .invalidFeed: "This is not a supported UTF-8 RSS podcast feed."
    case .noAudio: "The RSS feed contains no supported HTTPS audio episodes."
    case .tooLarge: "The feed exceeds the 2 MB limit."
    case .unavailable: "The feed could not be loaded. Saved episodes have not been replaced."
    }
  }
}
enum PodcastFeedParser {
  static let maximumBytes=2_000_000
  static func parse(_ data: Data,url: URL) throws -> PodcastFeed {
    guard PodcastURLPolicy.allows(url) else { throw PodcastFeedError.invalidURL }
    guard data.count<=maximumBytes else { throw PodcastFeedError.tooLarge }
    guard let xml=String(data:data,encoding:.utf8),!xml.uppercased().contains("<!DOCTYPE"),
      !xml.uppercased().contains("<!ENTITY") else { throw PodcastFeedError.invalidFeed }
    guard case .rss(let feed)=try Feed(data:data),let channel=feed.channel else { throw PodcastFeedError.invalidFeed }
    var seen=Set<String>();var episodes:[PodcastEpisode]=[]
    for item in (channel.items ?? []).prefix(1000) {
      guard episodes.count<100,let enclosure=item.enclosure,
        let kind=enclosure.attributes?.type?.lowercased(),kind.hasPrefix("audio/"),
        let raw=enclosure.attributes?.url,let media=URL(string:raw),PodcastURLPolicy.allows(media) else { continue }
      let id=PodcastLibrary.episodeID(feed:url,media:media)
      guard seen.insert(id).inserted else { continue }
      let duration=item.iTunes?.duration.flatMap { $0.isFinite && $0>0 && $0<=604800 ? $0:nil }
      let title=PodcastLibrary.label(item.title ?? "Untitled episode")
      episodes.append(PodcastEpisode(id:id,title:title.isEmpty ? "Untitled episode":title,mediaURL:media,duration:duration))
    }
    guard !episodes.isEmpty else { throw PodcastFeedError.noAudio }
    return PodcastFeed(url:url,title:PodcastLibrary.label(channel.title ?? url.host ?? "RSS feed"),episodes:episodes)
  }
}
