// Compile-only API surface probe, 19 October 2026. Never run or call this function.
// Typechecking does not request permission, query a library or activate a player.
import Foundation
import MediaPlayer
import MusicKit
import AVFoundation
import CarPlay

@MainActor
func compileOnlyMediaSurface() {
  let _:MPMediaQuery = .audiobooks()
  let predicate=MPMediaPropertyPredicate(value:MPMediaType.movie.rawValue,
    forProperty:MPMediaItemPropertyMediaType)
  let _=MPMediaQuery(filterPredicates:[predicate])
  let _=MPMediaType.tvShow
  let _: (MPMediaItem)->URL? = { $0.assetURL }
  let _: (MPMediaItem)->Bool = { $0.hasProtectedAsset }
  let _: (MPMediaItem)->TimeInterval = { $0.bookmarkTime }
  let _=MPMediaLibrary.authorizationStatus()
  let _=MusicCatalogSearchRequest(term:"own synthetic probe",types:[Song.self])
  let _=ApplicationMusicPlayer.self
  let _=AVPlayer.self
  let _=CPTemplateApplicationScene.self
  let _=NSUserActivity(activityType:"org.example.homeview.research")
}
