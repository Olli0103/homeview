
// Test-only access to own class state; no Apple private APIs.
extension VoiceInputController {
  var gateHasCapture:Bool { capture != nil }
  var gateIsSynthetic:Bool { synthetic }
}
