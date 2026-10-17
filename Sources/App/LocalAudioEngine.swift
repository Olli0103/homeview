import AVFoundation
import Foundation

/// AVAudioPlayer/session activation can block. All player access is serialized off-main.
/// The unchecked conformance is limited to this queue-owned state, not a shared player.
final class LocalAudioEngine: @unchecked Sendable {
  private let queue = DispatchQueue(label: "org.example.homeview.audio", qos: .userInitiated)
  private var music: AVAudioPlayer?
  private var podcast: AVAudioPlayer?
  private var chime: AVAudioPlayer?
  private func player(volume: Float, loop: Bool) throws -> AVAudioPlayer {
    guard let url = Bundle.main.url(forResource: "demo-tone", withExtension: "wav") else {
      throw NativeAudioError.missingAsset
    }
    let player = try AVAudioPlayer(contentsOf: url)
    player.volume = volume
    player.numberOfLoops = loop ? -1 : 0
    return player
  }
  func playMusic(volume: Float) async -> Bool {
    await withCheckedContinuation { continuation in
      queue.async { [self] in
        do {
          podcast?.stop()
          music = try player(volume: volume, loop: true)
          continuation.resume(returning: music?.play() == true)
        } catch { continuation.resume(returning: false) }
      }
    }
  }
  func playPodcast(volume: Float) async -> Bool {
    await withCheckedContinuation { continuation in
      queue.async { [self] in
        do {
          music?.stop()
          podcast = try player(volume: volume, loop: true)
          continuation.resume(returning: podcast?.play() == true)
        } catch { continuation.resume(returning: false) }
      }
    }
  }
  func playChime(volume: Float) async -> Bool {
    await withCheckedContinuation { continuation in
      queue.async { [self] in
        do {
          chime = try player(volume: volume, loop: false)
          continuation.resume(returning: chime?.play() == true)
        } catch { continuation.resume(returning: false) }
      }
    }
  }
  func stopMusic() { queue.async { [self] in music?.stop() } }
  func stopPodcast() { queue.async { [self] in podcast?.stop() } }
  func setVolume(_ volume: Float) {
    queue.async { [self] in
      music?.volume = volume
      podcast?.volume = volume
      chime?.volume = volume
    }
  }
}
enum NativeAudioError: Error { case missingAsset }
