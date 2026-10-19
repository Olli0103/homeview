/// Local roles only. A demo profile never proves device or household ownership.
enum LocalAccessRole:CaseIterable,Sendable {
  case guest,demoUser,deviceAuthenticated
}
enum LocalCapability:CaseIterable,Sendable {
  case publicWeather,foregroundTimer,mockControls,mockSecurity,bundledMedia,publicPodcast
  case connectedMusicSearch,connectedMusicPlayback,personalSource,realCommunication,realHome
}
enum GuestAccessPolicy {
  static func allows(_ capability:LocalCapability,role:LocalAccessRole,sharedMusicQueue:Bool=false)->Bool {
    switch capability {
    case .publicWeather,.foregroundTimer,.mockControls,.bundledMedia,.publicPodcast:return true
    case .mockSecurity,.connectedMusicSearch,.personalSource:return role == .deviceAuthenticated
    case .connectedMusicPlayback:return role == .deviceAuthenticated || sharedMusicQueue
    case .realCommunication,.realHome:return false
    }
  }
}
