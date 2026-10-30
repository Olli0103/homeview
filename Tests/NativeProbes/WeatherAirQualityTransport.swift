import Foundation

/// Isolated native verification of the real WeatherService with owned public-
/// response fixtures. URLProtocol intercepts every request; no live requests.
private final class TransportState: @unchecked Sendable {
  let lock = NSLock()
  var scenario = ""
  var hosts: [String] = []
  func reset(_ scenario: String) { lock.lock(); defer {lock.unlock()}; self.scenario=scenario;hosts=[] }
  func visit(_ host: String) -> String { lock.lock(); defer {lock.unlock()};hosts.append(host);return scenario }
  func visited() -> [String] { lock.lock(); defer {lock.unlock()};return hosts }
}
private final class FixtureTransport: URLProtocol, @unchecked Sendable {
  static let state=TransportState()
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    let host=request.url!.host!,scenario=Self.state.visit(host)
    var status=200,body=""
    switch host {
    case "geocoding-api.open-meteo.com":
      body=#"{"results":[{"name":"Synthetic","latitude":52.52,"longitude":13.41}]}"#
    case "api.open-meteo.com":
      body=#"{"utc_offset_seconds":0,"current":{"time":1700000000,"temperature_2m":55}}"#
      if scenario=="forecast-failure" {status=503}
    case "air-quality-api.open-meteo.com":
      let query=URLComponents(url:request.url!,resolvingAgainstBaseURL:false)!.queryItems!
      precondition(query.contains { $0.name=="current" && $0.value=="european_aqi" })
      precondition(query.contains { $0.name=="timeformat" && $0.value=="unixtime" })
      precondition(request.timeoutInterval==8)
      body=#"{"current":{"time":1699999200,"european_aqi":42}}"#
      switch scenario {
      case "optional-failure":status=503
      case "malformed":body="not JSON"
      case "missing":body=#"{"current":{"time":1699999200,"european_aqi":null}}"#
      case "cancelled":client!.urlProtocol(self,didFailWithError:URLError(.cancelled));return
      default:break
      }
    default:preconditionFailure("Unowned request must not escape the fixture")
    }
    client!.urlProtocol(self,didReceive:HTTPURLResponse(url:request.url!,statusCode:status,
      httpVersion:"HTTP/1.1",headerFields:["Content-Type":"application/json"])!,cacheStoragePolicy:.notAllowed)
    client!.urlProtocol(self,didLoad:Data(body.utf8));client!.urlProtocolDidFinishLoading(self)
  }
  override func stopLoading() {}
}
@main struct WeatherAirQualityTransportProbe {
  static func main() async throws {
    var passed=0
    for scenario in ["success","optional-failure","malformed","missing","cancelled","forecast-failure"] {
      FixtureTransport.state.reset(scenario)
      let config=URLSessionConfiguration.ephemeral;config.protocolClasses=[FixtureTransport.self]
      let session=URLSession(configuration:config)
      defer {session.invalidateAndCancel()}
      do {
        let reading=try await WeatherService(session:session).fetch(city:"Synthetic")
        precondition(!["cancelled","forecast-failure"].contains(scenario))
        precondition(reading.city=="Synthetic" && reading.temperature==55)
        precondition(reading.observedAt.timeIntervalSince1970==1700000000)
        if scenario=="success" {
          precondition(reading.airQuality?.europeanIndex==42)
          precondition(reading.airQuality?.validAt.timeIntervalSince1970==1699999200)
        } else {precondition(reading.airQuality==nil)}
      } catch {
        switch scenario {
        case "cancelled":precondition(error is CancellationError || (error as? URLError)?.code == .cancelled)
        case "forecast-failure":precondition((error as? URLError)?.code == .badServerResponse)
        default:throw error
        }
      }
      precondition(FixtureTransport.state.visited()==["geocoding-api.open-meteo.com","api.open-meteo.com"] +
        (scenario=="forecast-failure" ? []:["air-quality-api.open-meteo.com"]))
      passed+=1
    }
    print("WEATHER_AQI_TRANSPORT_PASS scenarios=\(passed) live_requests=0")
  }
}
