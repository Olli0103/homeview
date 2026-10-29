import SwiftUI

#if os(iOS) && canImport(MessageUI)
  import MessageUI
  private struct MessageComposer: UIViewControllerRepresentable {
    let body: String
    let done: () -> Void
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
      var done: () -> Void
      init(_ done: @escaping () -> Void) { self.done = done }
      func messageComposeViewController(
        _ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult
      ) { done() }
    }
    func makeCoordinator() -> Coordinator { Coordinator(done) }
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
      let c = MFMessageComposeViewController()
      c.body = body
      c.messageComposeDelegate = context.coordinator
      return c
    }
    func updateUIViewController(_ controller: MFMessageComposeViewController, context: Context) {}
  }
#endif
struct SystemMessageButton: View {
  var draft: String
  @State private var showing = false
  @State private var status = ""
  var body: some View {
    VStack(spacing: 5) {
      Button("Compose in Messages") {
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
          status = "System composer not opened in tests"
          return
        }
        #if os(iOS) && canImport(MessageUI)
          if MFMessageComposeViewController.canSendText() {
            showing = true
          } else {
            status = "Messages is unavailable on this device."
          }
        #else
          status = "Open Messages on your personal device."
        #endif
      }.font(.system(size: 20)).accessibilityIdentifier("messages.compose")
      if !status.isEmpty { Text(status).font(.system(size: 15)).foregroundStyle(.gray) }
    }
    #if os(iOS) && canImport(MessageUI)
      .sheet(isPresented: $showing) { MessageComposer(body: draft) { showing = false } }
    #endif
  }
}
struct SystemFaceTimeAction: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.scenePhase) private var phase
  @FocusState private var inputFocused:Bool
  @State private var recipient = ""
  @State private var status = ""
  var body: some View {
    VStack(spacing: 10) {
      #if os(tvOS)
        TextField("Phone number or Apple Account email", text: $recipient)
          .textFieldStyle(.plain)
          .font(.system(size: 18)).accessibilityIdentifier("facetime.recipient").focused($inputFocused)
          .onChange(of:phase) { _,phase in if phase != .active { inputFocused=false } }
      #else
        TextField("Phone number or Apple Account email", text: $recipient).textFieldStyle(
          .roundedBorder
        )
        .font(.system(size: 18)).accessibilityIdentifier("facetime.recipient").focused($inputFocused)
          .onChange(of:phase) { _,phase in if phase != .active { inputFocused=false } }
      #endif
      Button("Call in FaceTime") {
        guard !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
          status = "FaceTime not opened in tests"
          return
        }
        let value = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let escaped = value.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
          let url = URL(string: "facetime:" + escaped)
        else { return }
        openURL(url) { accepted in
          if !accepted { status = "FaceTime could not be opened on this device." }
        }
      }.font(.system(size: 21, weight: .medium)).disabled(
        recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      )
      .accessibilityIdentifier("facetime.system")
      if !status.isEmpty { Text(status).font(.system(size: 15)).foregroundStyle(.gray) }
    }
  }
}
