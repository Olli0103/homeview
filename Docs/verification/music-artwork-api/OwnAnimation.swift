import Foundation
import MediaPlayer
@available(iOS 26.0,macOS 26.0,tvOS 26.0,watchOS 26.0,visionOS 26.0,*)
func ownAnimatedArtworkMetadata(_ supplied:MPMediaItemAnimatedArtwork)->([String:Any],[String]) {
  ([MPNowPlayingInfoProperty1x1AnimatedArtwork:supplied],MPNowPlayingInfoCenter.supportedAnimatedArtworkKeys)
}
