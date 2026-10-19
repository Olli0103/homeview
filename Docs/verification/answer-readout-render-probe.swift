import Foundation
import AVFoundation

final class PCMMeasurement:@unchecked Sendable {
 private let lock=NSLock()
 private var frames:UInt64=0
 private var sum=0.0
 private var peak=0.0
 private var maxBuffer=0,skipped=0,rangeEnd=0
 private var sampleRate=0.0
 func add(_ pcm:AVAudioPCMBuffer) {
  lock.lock();defer { lock.unlock() }
  let n=Int(pcm.frameLength);maxBuffer=max(maxBuffer,n);sampleRate=pcm.format.sampleRate
  guard n>0,n<=20_000_000 else { if n>20_000_000 { skipped+=1 };return }
  var measured=false
  if let channel=pcm.floatChannelData?[0] {
   for i in 0..<n { let x=Double(channel[i]);sum+=x*x;peak=max(peak,abs(x)) };measured=true
  } else if let channel=pcm.int16ChannelData?[0] {
   for i in 0..<n { let x=Double(channel[i])/32768;sum+=x*x;peak=max(peak,abs(x)) };measured=true
  }
  if measured { frames+=UInt64(n) }
 }
 func mark(_ markers:[AVSpeechSynthesisMarker]) {
  lock.lock();defer { lock.unlock() }
  for marker in markers where marker.textRange.location != NSNotFound { rangeEnd=max(rangeEnd,NSMaxRange(marker.textRange)) }
 }
 func result() -> (UInt64,Double,Double,Int,Int,Double,Int) {
  lock.lock();defer { lock.unlock() };return (frames,frames==0 ? 0:sqrt(sum/Double(frames)),peak,maxBuffer,skipped,sampleRate,rangeEnd)
 }
}
final class RenderDelegate:NSObject,AVSpeechSynthesizerDelegate,@unchecked Sendable {
 let done:@Sendable (Bool) -> Void
 init(done:@escaping @Sendable (Bool) -> Void) { self.done=done }
 func speechSynthesizer(_ synthesizer:AVSpeechSynthesizer,didFinish utterance:AVSpeechUtterance) { done(true) }
 func speechSynthesizer(_ synthesizer:AVSpeechSynthesizer,didCancel utterance:AVSpeechUtterance) { done(false) }
}
@main struct RenderSpeech {
 @MainActor static func main() async throws {
  let catalogue=SystemAnswerSpeech().voices()
  guard let voice=catalogue.first(where: { $0.language=="en-US" }),
    let nativeVoice=AVSpeechSynthesisVoice(identifier:voice.id),!nativeVoice.voiceTraits.contains(.isPersonalVoice) else {
    print("SYSTEM_VOICE_UNAVAILABLE");exit(2)
  }
  var results:[[String:Any]]=[]
  for rate:Float in [0.5] {
   let synth=AVSpeechSynthesizer(),meter=PCMMeasurement()
   let stream=AsyncStream<Bool>.makeStream(bufferingPolicy:.bufferingNewest(1))
   let delegate=RenderDelegate { result in stream.continuation.yield(result);stream.continuation.finish() }
   synth.delegate=delegate
   let deadline=Task { @MainActor in
    try? await Task.sleep(nanoseconds:45_000_000_000)
    if !Task.isCancelled { synth.stopSpeaking(at:.immediate);stream.continuation.yield(false);stream.continuation.finish() }
   }
   let utterance=AVSpeechUtterance(string:String(String(repeating:"This is a synthetic HomeView answer. ",count:120).prefix(4000)))
   utterance.voice=nativeVoice;utterance.rate=rate;utterance.volume=1
   synth.write(utterance,toBufferCallback: { buffer in
    guard let pcm=buffer as? AVAudioPCMBuffer else { return }
    if pcm.frameLength==0 { /* A buffer boundary is not accepted as whole-utterance completion. */ }
    else { meter.add(pcm) }
   },toMarkerCallback: { meter.mark($0) })
   var complete=false
   for await success in stream.stream { complete=success }
   deadline.cancel();synth.stopSpeaking(at:.immediate);withExtendedLifetime(delegate) {}
   try await Task.sleep(nanoseconds:20_000_000)
   let measurement=meter.result()
   results.append(["inputCharacters":utterance.speechString.utf16.count,"lastMarkerEnd":measurement.6,"maxBufferFrames":measurement.3,"skippedBuffers":measurement.4,"sampleRate":measurement.5,"rate":rate,"frames":measurement.0,"rms":measurement.1,"peak":measurement.2,
    "complete":complete,"speakerPlayback":false,"personalVoice":false,"voiceLanguage":voice.language])
  }
  print(String(decoding:try JSONSerialization.data(withJSONObject:results,options:[.sortedKeys]),as:UTF8.self))
  guard results.allSatisfy({$0["complete"] as? Bool==true && ($0["frames"] as? UInt64 ?? 0)>0 && ($0["rms"] as? Double ?? 0)>0}),
    results.count==1 && (results[0]["lastMarkerEnd"] as? Int ?? 0)>=4000 && (results[0]["skippedBuffers"] as? Int ?? -1)==0 else { exit(1) }
 }
}
