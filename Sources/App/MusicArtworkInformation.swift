import SwiftUI

/// Describes only this player's supplied content. It never requests media,
/// source permission, playback or another app's lyrics.
struct MusicArtworkInfoButton: View {
  enum Source: String { case demo, catalog }
  let source: Source
  @State private var presented = false
  var body: some View {
    Button { presented = true } label: {
      Image(systemName: "info.circle")
        .font(.system(size: 24, weight: .medium))
        .frame(width: 44, height: 44)
        .background(.ultraThinMaterial, in: Circle())
        .frame(width: 72, height: 72).contentShape(Rectangle())
    }.buttonStyle(.plain).foregroundStyle(.primary)
      .accessibilityLabel("Artwork and lyrics information")
      .accessibilityIdentifier("music.artwork.info." + source.rawValue)
      .sheet(isPresented: $presented) { MusicArtworkInformation(source: source) }
  }
}

private struct MusicArtworkInformation: View {
  let source: MusicArtworkInfoButton.Source
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          Label(source == .catalog ? "Apple Music connection" : "Bundled demo player",
                systemImage: "music.note")
            .font(.headline).accessibilityIdentifier("music.artwork.source")
          VStack(alignment: .leading, spacing: 8) {
            Text("Artwork").font(.title2.bold())
            Text(source == .catalog
              ? "This connection supplies static cover images, not animated cover videos."
              : "This player uses a synthetic static cover and bundled demo audio.")
              .accessibilityIdentifier("music.artwork.availability")
          }
          VStack(alignment: .leading, spacing: 8) {
            Text("Lyrics").font(.title2.bold())
            Text(source == .catalog
              ? "Lyric text is not supplied by this connection, even when Apple Music has lyrics for a song. HomeView does not fetch lyrics from other sites."
              : "No lyrics are included with the demo audio. No sample text is presented as song lyrics.")
              .accessibilityIdentifier("music.lyrics.availability")
          }
          Text("The cover stays static, including with Reduce Motion. No animated cover video is downloaded or cached.")
            .foregroundStyle(.secondary).accessibilityIdentifier("music.artwork.motion")
        }.font(.body).frame(maxWidth: .infinity, alignment: .leading).padding(24)
      }.navigationTitle("Artwork & lyrics")
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { dismiss() }.accessibilityIdentifier("music.artwork.done")
          }
        }
    }.foregroundStyle(Color.primary)
      .environment(\.colorScheme, .light)
      .preferredColorScheme(.light)
  }
}
