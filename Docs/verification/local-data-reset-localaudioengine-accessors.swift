
final class GateAudioOwners:@unchecked Sendable {
 weak var music:AVAudioPlayer?;weak var podcast:AVAudioPlayer?;weak var chime:AVAudioPlayer?
 init(_ a:AVAudioPlayer?,_ b:AVAudioPlayer?,_ c:AVAudioPlayer?){music=a;podcast=b;chime=c}
}
extension LocalAudioEngine {
 func gateCaptureOwners() async -> GateAudioOwners {
  await withCheckedContinuation { continuation in queue.async { [self] in continuation.resume(returning:GateAudioOwners(music,podcast,chime)) } }
 }
 func gateOldState(_ owners:GateAudioOwners) async -> [String:Bool] {
  await withCheckedContinuation { continuation in queue.async { continuation.resume(returning:["musicAlive":owners.music != nil,"chimeAlive":owners.chime != nil,"podcastAlive":owners.podcast != nil,"musicPlaying":owners.music?.isPlaying==true,"chimePlaying":owners.chime?.isPlaying==true]) } }
 }
 func gateCurrentState() async -> [String:Bool] {
  await withCheckedContinuation { continuation in queue.async { [self] in continuation.resume(returning:["music":music != nil,"podcast":podcast != nil,"chime":chime != nil]) } }
 }
}
