import Foundation

private final class PodcastRedirectGuard: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
  func urlSession(_ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
    completionHandler(request.url.map(PodcastURLPolicy.allows)==true ? request:nil)
  }
}
enum PodcastFeedTransport {
  static func load(_ url:URL,session injected:URLSession? = nil) async throws -> PodcastFeed {
    guard PodcastURLPolicy.allows(url) else { throw PodcastFeedError.invalidURL }
    let configuration=URLSessionConfiguration.ephemeral
    configuration.urlCache=nil;configuration.httpCookieStorage=nil;configuration.urlCredentialStorage=nil
    configuration.timeoutIntervalForRequest=20;configuration.timeoutIntervalForResource=30
    let session=injected ?? URLSession(configuration:configuration)
    defer { if injected==nil { session.invalidateAndCancel() } }
    var request=URLRequest(url:url);request.setValue("application/rss+xml, application/xml, text/xml",forHTTPHeaderField:"Accept")
    let (stream,response)=try await session.bytes(for:request,delegate:PodcastRedirectGuard())
    guard let http=response as? HTTPURLResponse,(200...299).contains(http.statusCode),
      let final=response.url,PodcastURLPolicy.allows(final) else { throw PodcastFeedError.unavailable }
    guard response.expectedContentLength<=PodcastFeedParser.maximumBytes else { throw PodcastFeedError.tooLarge }
    var bytes=Data()
    for try await byte in stream {
      guard bytes.count<PodcastFeedParser.maximumBytes else { throw PodcastFeedError.tooLarge }
      bytes.append(byte)
    }
    try Task.checkCancellation()
    let payload=bytes
    return try await Task.detached { try PodcastFeedParser.parse(payload,url:url) }.value
  }
}
