import Foundation

/// Navigation only; no website gets an app-command or native-message bridge.
enum BrowserPolicy {
  static func address(_ input: String) -> URL? {
    let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty, text.count <= 4096,
      !text.contains(where: { $0.isWhitespace || $0.isNewline || $0.asciiValue.map { $0 < 32 } == true })
    else { return nil }
    let candidate = text.contains("://") ? text : "https://" + text
    guard let url = URL(string: candidate), allows(url) else { return nil }
    return url
  }
  static func allows(_ url: URL) -> Bool {
    guard url.scheme?.lowercased() == "https", let host = url.host, !host.isEmpty,
      url.user == nil, url.password == nil,
      !host.contains(where: { $0.isWhitespace || $0.isNewline }),
      url.port.map({ (1...65535).contains($0) }) ?? true else { return false }
    return true
  }
  static func allowsNavigation(_ url: URL?, fixture: Bool, testPages: Bool = false) -> Bool {
    guard let url else { return false }
    if testPages, url.scheme == "homeview-fixture", url.host == "local",
       ["/one", "/two", "/offline", "/slow"].contains(url.path),
       url.user == nil, url.password == nil, url.port == nil, url.query == nil {
      return true
    }
    return allows(url) || (fixture && url.absoluteString == "about:blank")
  }
}
