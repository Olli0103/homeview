import AVFoundation
import Foundation
import SwiftUI

#if !os(watchOS)
struct PodcastCaptionChoice:Identifiable,Equatable {
  let id:String
  let name:String
  let playable:Bool
}

/// This delegate is installed only on DispatchQueue.main. Copy the public cue
/// strings before entering the actor; no sample buffers or foreign attributes cross.
@MainActor final class PodcastCaptionDelegate:NSObject,AVPlayerItemLegibleOutputPushDelegate {
  private let receive:@MainActor ([String])->Void
  private let flushed:@MainActor ()->Void
  init(receive:@escaping @MainActor ([String])->Void,flushed:@escaping @MainActor ()->Void) {
    self.receive=receive;self.flushed=flushed
  }
  nonisolated func legibleOutput(_ output:AVPlayerItemLegibleOutput,
    didOutputAttributedStrings strings:[NSAttributedString],nativeSampleBuffers:[Any],forItemTime:CMTime) {
    let plain=strings.map(\.string)
    MainActor.assumeIsolated {receive(plain)}
  }
  nonisolated func outputSequenceWasFlushed(_ output:AVPlayerItemOutput) {
    MainActor.assumeIsolated {flushed()}
  }
}

struct PodcastCaptionControls:View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var scale
  let loaded:Bool
  private var side:CGFloat {ceil(44/max(0.01,scale))}
  var body:some View {
    VStack(spacing:10) {
      HStack(alignment:.center,spacing:12) {
        Menu {
          Button("Automatic") {model.podcastPlayer.selectCaption("automatic")}
            .accessibilityIdentifier("podcast.captions.automatic")
          Button("Off") {model.podcastPlayer.selectCaption("off")}
            .accessibilityIdentifier("podcast.captions.off")
          ForEach(model.podcastPlayer.captionChoices) { choice in
            Button(choice.name) {model.podcastPlayer.selectCaption(choice.id)}
              .disabled(!choice.playable).accessibilityIdentifier("podcast.captions.option."+choice.id)
          }
        } label: {
          Label("Captions",systemImage:"captions.bubble")
            .font(.system(size:max(17,ceil(17/max(0.01,scale)))))
            .frame(minWidth:side,minHeight:side).contentShape(Rectangle())
        }.disabled(!loaded || model.podcastPlayer.captionChoices.isEmpty)
          .accessibilityLabel("Podcast captions")
          .accessibilityValue(loaded ? model.podcastPlayer.captionSelection:"Unavailable")
          .accessibilityIdentifier("podcast.captions")
        Text(loaded ? model.podcastPlayer.captionStatus:"Captions are checked when this episode is played.")
          .font(.system(size:16)).foregroundStyle(.secondary)
          .accessibilityIdentifier("podcast.captions.status")
      }
      if loaded,!model.podcastPlayer.captionText.isEmpty {
        Text(model.podcastPlayer.captionText).font(.system(size:max(24,ceil(17/max(0.01,scale))),weight:.medium))
          .multilineTextAlignment(.center).lineLimit(4).frame(maxWidth:.infinity)
          .padding(14).background(Color(white:0.94),in:RoundedRectangle(cornerRadius:12))
          .accessibilityIdentifier("podcast.captions.current")
      }
    }.padding(.bottom,side)
  }
}
#endif
