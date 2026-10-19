import NearbyInteraction
func ownNearbyDistance(_ object:NINearbyObject)->Float? { object.distance }
func configurationForProvidedPeer(_ token:NIDiscoveryToken)->NINearbyPeerConfiguration {
  NINearbyPeerConfiguration(peerToken:token)
}
