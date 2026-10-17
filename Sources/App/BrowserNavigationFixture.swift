#if canImport(WebKit) && !os(tvOS) && !os(watchOS)
import Foundation
@preconcurrency import WebKit

/// In-memory pages only. Installed exclusively by --uitesting + the navigation
/// fixture flag. Not a native command bridge, file handler or network proxy.
@MainActor
final class BrowserNavigationFixture: NSObject, @preconcurrency WKURLSchemeHandler {
  func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
    guard let url = urlSchemeTask.request.url, url.host == "local" else {
      urlSchemeTask.didFailWithError(URLError(.unsupportedURL)); return
    }
    if url.path == "/offline" {
      urlSchemeTask.didFailWithError(URLError(.notConnectedToInternet)); return
    }
    if url.path == "/slow" { return } // deterministic pending request for Stop
    guard ["/one", "/two"].contains(url.path) else {
      urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist)); return
    }
    let title = url.path == "/one" ? "First local page" : "Second local page"
    let html = """
      <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head>
      <body style="font:24px -apple-system;padding:24px"><h1>\(title)</h1>
      <p><a href="homeview-fixture://local/two">Next page</a></p>
      <p><a href="homeview-fixture://local/offline">Offline page</a></p>
      <p><a href="homeview-fixture://local/slow">Slow page</a></p>
      <p>Synthetic content. No network or account access.</p></body></html>
      """
    let bytes = Data(html.utf8)
    urlSchemeTask.didReceive(URLResponse(url: url, mimeType: "text/html",
      expectedContentLength: bytes.count, textEncodingName: "utf-8"))
    urlSchemeTask.didReceive(bytes)
    urlSchemeTask.didFinish()
  }
  func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}
}
#endif
