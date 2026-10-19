import Foundation
import MusicKit
func suppliedCatalogMetadata(_ song:Song)->(URL?,Bool) {
  (song.artwork?.url(width:512,height:512),song.hasLyrics)
}
