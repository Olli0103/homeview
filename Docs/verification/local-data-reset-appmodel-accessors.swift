
extension AppModel {
  func gateExpireResetProof() { localResetAuthorizationDeadline=ContinuousClock.now.advanced(by:.seconds(-1)) }
  var gateAudioEngine:LocalAudioEngine { audio }
}
