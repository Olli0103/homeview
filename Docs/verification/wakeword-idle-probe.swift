import Foundation
import Speech
import AVFoundation

@main struct WakewordIdleGate {
  @MainActor static func main() async throws {
    var assertions=0
    func require(_ condition:Bool,_ label:String) { assertions+=1;precondition(condition,label) }
    let speechBefore=SFSpeechRecognizer.authorizationStatus()
    let microphoneBefore=AVCaptureDevice.authorizationStatus(for:.audio)
    let controller=VoiceInputController()
    require(!controller.gateIsSynthetic,"Must use the real idle branch")
    require(controller.phase == .idle,"Constructing a controller is idle")
    require(!controller.gateHasCapture,"Constructing a controller creates no SpeechCapture")
    require(!controller.busy && controller.transcript.isEmpty,"Idle is not listening")
    controller.finish()
    require(controller.phase == .idle && !controller.gateHasCapture,"Finishing idle starts nothing")
    controller.cancel()
    await Task.yield()
    require(controller.phase == .idle && !controller.gateHasCapture,"Cancellation stays idle")
    require(controller.transcript.isEmpty,"No synthetic transcript")
    require(SFSpeechRecognizer.authorizationStatus()==speechBefore,"No speech grant change")
    require(AVCaptureDevice.authorizationStatus(for:.audio)==microphoneBefore,"No microphone grant change")
    let result:[String:Any]=["assertions":assertions,"native_idle_branch":true,"capture_created":false,"start_called":false,"permissions_unchanged":true,"hardware_or_real_recording_tested":false]
    print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
  }
}
