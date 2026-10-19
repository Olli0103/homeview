import XCTest
@testable import HomeViewCore

final class PodcastTests: XCTestCase {
  private let url=URL(string:"https://podcasts.example/feed.xml")!
  private func xml(_ items:String) -> Data {
    Data("<rss version=\"2.0\" xmlns:itunes=\"http://www.itunes.com/dtds/podcast-1.0.dtd\"><channel><title>Own Test Feed</title>\(items)</channel></rss>".utf8)
  }
  private func item(_ media:String="https://audio.example/one.mp3",duration:String="<itunes:duration>01:02</itunes:duration>") -> String {
    "<item><title>Own &amp; safe</title><enclosure url=\"\(media)\" type=\"audio/mpeg\"/>\(duration)</item>"
  }
  func testMaintainedRSSParserDecodesEscapesAndDurationWithoutInventingMissingMetadata() throws {
    let feed=try PodcastFeedParser.parse(xml(item()+item("https://audio.example/two.mp3",duration:"")),url:url)
    XCTAssertEqual(feed.title,"Own Test Feed");XCTAssertEqual(feed.episodes.count,2)
    XCTAssertEqual(feed.episodes[0].title,"Own & safe");XCTAssertEqual(feed.episodes[0].duration,62)
    XCTAssertNil(feed.episodes[1].duration)
  }
  func testEnclosuresRequireHTTPSAudioAndUniqueMediaIdentity() throws {
    let content=item()+item()+item("http://audio.example/no.mp3")+item("https://name:secret@audio.example/no.mp3")
      + "<item><title>Video</title><enclosure url=\"https://audio.example/video\" type=\"video/mp4\"/></item>"
    let feed=try PodcastFeedParser.parse(xml(content),url:url)
    XCTAssertEqual(feed.episodes.count,1)
    XCTAssertEqual(feed.episodes[0].id,PodcastLibrary.episodeID(feed:url,media:URL(string:"https://audio.example/one.mp3")!))
  }
  func testEntityDeclarationsMalformedAndOversizeFeedsFailClosed() {
    for data in [Data("<!DOCTYPE rss [<!ENTITY secret SYSTEM 'file:///etc/passwd'>]><rss/>".utf8),Data("<rss>".utf8),Data(repeating:65,count:2_000_001)] {
      XCTAssertThrowsError(try PodcastFeedParser.parse(data,url:url))
    }
    XCTAssertThrowsError(try PodcastFeedParser.parse(xml(""),url:url))
  }
  func testURLPolicyRejectsCredentialsNonHTTPSFragmentsAndUnexpectedPorts() {
    for raw in ["http://podcasts.example/rss","file:///tmp/feed","https://user:pass@podcasts.example/rss","https://podcasts.example/rss#login","https://podcasts.example:1234/rss","javascript:alert(1)"] {
      XCTAssertNil(PodcastURLPolicy.address(raw),raw)
    }
    XCTAssertEqual(PodcastURLPolicy.address("  https://podcasts.example/rss  "),URL(string:"https://podcasts.example/rss"))
  }
  func testLibraryRefreshKeepsStableProgressAndRemovalPurgesSelectedEpisode() throws {
    let feed=try PodcastFeedParser.parse(xml(item()),url:url)
    var library=PodcastLibrary();library.upsert(feed);let id=feed.episodes[0].id
    library.selectedID=id;library.positions[id]=31
    library.upsert(feed)
    XCTAssertEqual(library.selectedEpisode?.id,id);XCTAssertEqual(library.positions[id],31)
    library.remove(feed.id)
    XCTAssertNil(library.selectedID);XCTAssertTrue(library.positions.isEmpty)
  }
  func testLibraryNormalizesTamperedIdentityAndPositionsAndBoundsFeeds() throws {
    let feed=try PodcastFeedParser.parse(xml(item()),url:url)
    var library=PodcastLibrary();library.feeds=Array(repeating:feed,count:20)
    library.selectedID=feed.episodes[0].id;library.positions=[feed.episodes[0].id:999,"unknown":14]
    let saved=library.normalized
    XCTAssertEqual(saved.feeds.count,1);XCTAssertEqual(saved.positions.count,1)
    XCTAssertEqual(saved.positions[feed.episodes[0].id],62)
    library.feeds=[PodcastFeed(url:url,title:"Unsafe",episodes:[PodcastEpisode(id:"forged",title:"Fake",mediaURL:URL(string:"https://audio.example/test")!,duration:60)])]
    XCTAssertNil(library.normalized.selectedID)
  }
  func testSnapshotMigrationPreservesOlderStoresAndNormalizesPodcastState() throws {
    let old=try Snapshot.decodeMigrating(Data("{\"home\":{},\"worldClockZones\":[\"Asia/Kathmandu\"]}".utf8))
    XCTAssertTrue(old.podcasts.feeds.isEmpty);XCTAssertEqual(old.worldClockZones,["Asia/Kathmandu"])
    var state=Snapshot();let feed=try PodcastFeedParser.parse(xml(item()),url:url)
    state.podcasts.upsert(feed);state.podcasts.selectedID=feed.episodes[0].id;state.podcasts.positions[feed.episodes[0].id]=17
    let restored=try Snapshot.decodeMigrating(JSONEncoder().encode(state))
    XCTAssertEqual(restored.podcasts.selectedEpisode?.title,"Own & safe")
    XCTAssertEqual(restored.podcasts.positions[feed.episodes[0].id],17)
    let malformed=try Snapshot.decodeMigrating(Data("{\"podcasts\":42,\"night\":true}".utf8))
    XCTAssertTrue(malformed.podcasts.feeds.isEmpty);XCTAssertTrue(malformed.night)
  }
}

private final class PodcastProtocol: URLProtocol, @unchecked Sendable {
  override class func canInit(with request: URLRequest) -> Bool { request.url?.host=="podcast-transport.example" }
  override class func canonicalRequest(for request:URLRequest) -> URLRequest { request }
  override func startLoading() {
    let url=request.url!
    let xml="<rss version=\"2.0\"><channel><title>Own transport fixture</title><item><title>Own audio</title><enclosure url=\"https://audio.example/own.wav\" type=\"audio/wav\"/></item></channel></rss>"
    let data=Data(xml.utf8)
    let response=HTTPURLResponse(url:url,statusCode:url.path=="/failure" ? 503:200,httpVersion:"HTTP/1.1",headerFields:["Content-Type":"application/rss+xml","Content-Length":url.path=="/large" ? "2000001":String(data.count)])!
    client?.urlProtocol(self,didReceive:response,cacheStoragePolicy:.notAllowed)
    client?.urlProtocol(self,didLoad:data)
    client?.urlProtocolDidFinishLoading(self)
  }
  override func stopLoading() {}
}
extension PodcastTests {
  private func transportSession() -> URLSession {
    let config=URLSessionConfiguration.ephemeral;config.protocolClasses=[PodcastProtocol.self]
    config.urlCache=nil;config.urlCredentialStorage=nil;config.httpCookieStorage=nil
    return URLSession(configuration:config)
  }
  func testActualHTTPSClientParsesOwnResponseWithoutAnExternalRequest() async throws {
    let session=transportSession();defer { session.invalidateAndCancel() }
    let feed=try await PodcastFeedTransport.load(URL(string:"https://podcast-transport.example/rss")!,session:session)
    XCTAssertEqual(feed.title,"Own transport fixture");XCTAssertEqual(feed.episodes.count,1)
  }
  func testActualHTTPSClientRejectsFailedStatusWithoutReturningFixtureData() async {
    let session=transportSession();defer { session.invalidateAndCancel() }
    do { _=try await PodcastFeedTransport.load(URL(string:"https://podcast-transport.example/failure")!,session:session);XCTFail("503 must fail") }
    catch { XCTAssertTrue(error is PodcastFeedError) }
  }
  func testActualHTTPSClientRejectsDeclaredOversizeBeforeParsing() async {
    let session=transportSession();defer { session.invalidateAndCancel() }
    do { _=try await PodcastFeedTransport.load(URL(string:"https://podcast-transport.example/large")!,session:session);XCTFail("Oversized response must fail") }
    catch { XCTAssertTrue(error is PodcastFeedError) }
  }
}
