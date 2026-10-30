/// A local demo video never overrides the user's motion, autoplay or power policy.
enum ArtworkMotionPolicy {
  static let maximumBundledBytes = 1_000_000
  static func allows(playing: Bool, foreground: Bool, reduceMotion: Bool,
                     autoplay: Bool, lowPower: Bool, thermalRestricted: Bool) -> Bool {
    playing && foreground && !reduceMotion && autoplay && !lowPower && !thermalRestricted
  }
}
