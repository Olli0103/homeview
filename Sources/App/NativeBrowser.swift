import SwiftUI

#if canImport(WebKit) && !os(tvOS) && !os(watchOS)
  import WebKit

  @MainActor @Observable
  final class NativeBrowserController: NSObject, WKNavigationDelegate {
    let webView: WKWebView
    var address = "Demo Cookbook"
    var status = "Local demo page · No network request"
    var loading = false
    var isFixture = true
    var canBack = false
    var canForward = false
    private var loadingFixture = true
    private let testPages: Bool
    override init() {
      let localPages = ProcessInfo.processInfo.arguments.contains("--uitesting")
        && ProcessInfo.processInfo.arguments.contains("--browser-navigation-fixture")
      testPages = localPages
      let config = WKWebViewConfiguration()
      config.websiteDataStore = .nonPersistent()
      if localPages { config.setURLSchemeHandler(BrowserNavigationFixture(), forURLScheme: "homeview-fixture") }
      webView = WKWebView(frame: .zero, configuration: config)
      super.init()
      webView.navigationDelegate = self
      var html = Self.fixtureHTML
      if ProcessInfo.processInfo.arguments.contains("--uitesting"),
         ProcessInfo.processInfo.arguments.contains("--browser-policy-fixture") {
        html = html.replacingOccurrences(of: "</body>", with:
          "<p><a href='homeview-fixture://blocked'>Blocked scheme fixture</a></p></body>")
      }
      if testPages {
        webView.load(URLRequest(url: URL(string: "homeview-fixture://local/one")!))
      } else {
        webView.loadHTMLString(html, baseURL: URL(string: "https://example.invalid"))
      }
    }
    func openAddress() {
      let text = address.trimmingCharacters(in: .whitespacesAndNewlines)
      guard let url = BrowserPolicy.address(text) else {
        status = "Enter a valid HTTPS website address without credentials."
        return
      }
      isFixture = false
      loading = true
      webView.load(URLRequest(url: url))
    }
    func stop() {
      webView.stopLoading()
      loading = false
      status = "Loading stopped."
      updateHistory()
    }
    private func updateHistory() {
      canBack = webView.canGoBack
      canForward = webView.canGoForward
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
      loading = true
      status = isFixture ? "Loading local demo page…" : "Loading…"
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      loading = false
      updateHistory()
      loadingFixture = false
      status = testPages && webView.url?.scheme == "homeview-fixture"
        ? "Synthetic local page · No network request"
        : isFixture ? "Local demo page · No network request" : "Loaded"
      if !isFixture { address = webView.url?.absoluteString ?? address }
    }
    func webView(
      _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: Error
    ) {
      navigationFailed(error)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
      navigationFailed(error)
    }
    private func navigationFailed(_ error: Error) {
      let cancelled = (error as NSError).domain == NSURLErrorDomain
        && (error as NSError).code == NSURLErrorCancelled
      if !(cancelled && !loading) { status = "Could not load this page. Check the connection or reload." }
      loading = false
      updateHistory()
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
      loading = false
      status = "Page process stopped. Reload to continue."
      updateHistory()
    }
    func webView(
      _ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
      decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
      guard BrowserPolicy.allowsNavigation(action.request.url, fixture: isFixture, testPages: testPages) else {
        loading = false
        status = "Blocked unsupported or insecure navigation."
        decisionHandler(.cancel)
        return
      }
      if !loadingFixture, action.targetFrame?.isMainFrame != false {
        isFixture = false
      }
      if action.targetFrame == nil {
        decisionHandler(.cancel)
        webView.load(action.request)
      } else {
        decisionHandler(.allow)
      }
    }
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse,
      decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void) {
      guard BrowserPolicy.allowsNavigation(response.response.url, fixture: isFixture, testPages: testPages) else {
        loading = false
        status = "Blocked unsupported or insecure response."
        decisionHandler(.cancel)
        return
      }
      decisionHandler(.allow)
    }
    func recipe() async throws -> RecipeDocument {
      let js =
        "JSON.stringify(Array.from(document.querySelectorAll('script[type=\"application/ld+json\"]')).slice(0,20).map(n=>n.textContent.slice(0,100000)))"
      guard let text = try await webView.evaluateJavaScript(js) as? String,
        let scripts = try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String]
      else { throw RecipeParseError.noRecipe }
      for script in scripts {
        if let recipe = try? RecipeParser.parse(
          json: script, source: isFixture ? "Demo Cookbook" : webView.url?.host ?? "Web Recipe")
        {
          return recipe
        }
      }
      throw RecipeParseError.noRecipe
    }
    static let fixtureHTML = """
      <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{margin:0;padding:30px;background:#faf8f2;color:#252924;font:18px -apple-system}header{letter-spacing:3px;font-size:12px;color:#617258}h1{font-size:38px;line-height:1.1}article{padding:24px;border-radius:20px;background:#e6e9d9}li{margin:12px 0}.dish{font-size:72px}</style><script type="application/ld+json">{"@context":"https://schema.org","@type":"Recipe","name":"Garden Tomato Pasta","totalTime":"PT25M","recipeYield":"4","recipeIngredient":["300 g pasta","400 g tomatoes","2 tbsp olive oil","Fresh basil"],"recipeInstructions":[{"@type":"HowToStep","text":"Simmer the tomatoes in olive oil for 5 minutes."},{"@type":"HowToStep","text":"Cook the pasta, then toss with the sauce and fresh basil."}]}</script></head><body><header>DEMO COOKBOOK</header><h1>Garden Tomato Pasta</h1><p>25 minutes · Serves 4</p><article><div class="dish">🍅</div><h2>A simple dinner</h2><p>Open this page in the native cooking view with the Read Recipe button above.</p><ul><li>Pasta</li><li>Tomatoes</li><li>Olive oil</li><li>Fresh basil</li></ul></article><p>This page is bundled test data. No website or personal account is opened.</p></body></html>
      """
  }
  #if os(macOS)
    struct BrowserWebArea: NSViewRepresentable {
      let controller: NativeBrowserController
      func makeNSView(context: Context) -> WKWebView { controller.webView }
      func updateNSView(_ view: WKWebView, context: Context) {}
    }
  #else
    struct BrowserWebArea: UIViewRepresentable {
      let controller: NativeBrowserController
      func makeUIView(context: Context) -> WKWebView { controller.webView }
      func updateUIView(_ view: WKWebView, context: Context) {}
    }
  #endif
#endif

struct NativeBrowserView: View {
  #if canImport(WebKit) && !os(tvOS) && !os(watchOS)
    @State private var browser: NativeBrowserController?
  #endif
  var body: some View {
    #if canImport(WebKit) && !os(tvOS) && !os(watchOS)
      if let browser {
        NativeBrowserContent(browser: browser)
      } else {
        ProgressView("Opening browser").frame(maxWidth: .infinity, maxHeight: .infinity).background(
          .white
        ).task { if self.browser == nil { self.browser = NativeBrowserController() } }
      }
    #else
      SafariLanding()
    #endif
  }
}
#if canImport(WebKit) && !os(tvOS) && !os(watchOS)
  private struct NativeBrowserContent: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var browser: NativeBrowserController
    var body: some View {
      VStack(spacing: 10) {
        AppHeader(title: "Safari")
        HStack(spacing: 12) {
          TextField("Website address", text: $browser.address).textFieldStyle(.plain).font(
            .system(size: 18)
          ).onSubmit { browser.openAddress() }.accessibilityIdentifier("browser.address")
            #if !os(macOS)
              .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
            #endif
          if browser.loading {
            RoundButton(symbol: "xmark", size: 38, label: "Stop loading") { browser.stop() }
              .accessibilityIdentifier("browser.stop")
          }
          RoundButton(symbol: "arrow.clockwise", size: 38, label: "Load website") {
            browser.openAddress()
          }.accessibilityIdentifier("browser.load")
        }.padding(12).background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 15))
          .padding(.horizontal, 28)
        HStack(spacing: 14) {
          Button {
            browser.webView.goBack()
          } label: {
            Image(systemName: "chevron.left")
          }.disabled(!browser.canBack).accessibilityLabel("Back").accessibilityIdentifier("browser.back")
          Button {
            browser.webView.goForward()
          } label: {
            Image(systemName: "chevron.right")
          }.disabled(!browser.canForward).accessibilityLabel("Forward").accessibilityIdentifier("browser.forward")
          Spacer()
          Button("Saved") { model.navigate(.recipes) }.accessibilityIdentifier("browser.saved")
          Button("Read Recipe") {
            Task {
              do {
                model.recipe = try await browser.recipe()
                model.route = .recipe
              } catch { model.error = error.localizedDescription }
            }
          }.fontWeight(.semibold).disabled(browser.loading).accessibilityIdentifier(
            "browser.recipe")
        }.font(.system(size: 19)).padding(.horizontal, 30)
        Text(browser.status).font(.system(size: 12)).foregroundStyle(.gray).accessibilityIdentifier(
          "browser.status")
        BrowserWebArea(controller: browser).accessibilityIdentifier("browser.page")
      }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
        .onDisappear { browser.stop() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { browser.stop() } }
    }
  }
#endif
struct RecipeArtwork: View {
  let recipe: RecipeDocument
  var body: some View {
    Group {
      if let name = recipe.coverAsset {
        Image(name).resizable().scaledToFill()
      } else if let url = recipe.imageURL {
        AsyncImage(url: url) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          placeholder
        }
      } else {
        placeholder
      }
    }.frame(width: 600, height: 600).clipped()
  }
  private var placeholder: some View {
    ZStack {
      LinearGradient(colors: [.orange, .brown], startPoint: .topLeading, endPoint: .bottomTrailing)
      Image(systemName: "fork.knife").font(.system(size: 160)).foregroundStyle(.white.opacity(0.3))
    }
  }
}
struct RecipeLibraryView: View {
  @Environment(AppModel.self) private var model
  private var recipes: [RecipeDocument] {
    [model.recipe] + model.data.pinnedRecipes.filter { $0.id != model.recipe.id }
  }
  var body: some View {
    VStack(spacing: 20) {
      AppHeader(title: "Recipes")
      ScrollView {
        VStack(alignment: .leading, spacing: 15) {
          Text("Recent & Pinned").font(.system(size: 30, weight: .bold))
          ForEach(recipes) { recipe in
            Button {
              model.recipe = recipe
              model.route = .recipe
            } label: {
              HStack {
                Image(systemName: "fork.knife").font(.system(size: 30)).foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 5) {
                  Text(recipe.title).font(.system(size: 24, weight: .semibold))
                  Text("\(recipe.durationMinutes) min. · \(recipe.source)").font(.system(size: 17))
                    .foregroundStyle(.gray)
                }
                Spacer()
                if model.data.pinnedRecipes.contains(where: { $0.id == recipe.id }) {
                  Image(systemName: "pin.fill")
                }
              }.padding(20).background(.gray.opacity(0.06), in: RoundedRectangle(cornerRadius: 20))
            }.accessibilityIdentifier("saved.\(recipe.title)")
          }
        }.padding(30)
      }
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
  }
}
