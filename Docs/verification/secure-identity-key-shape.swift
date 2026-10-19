import CryptoKit
func documentedCryptographicKey(_ key:SecureEnclave.P256.Signing.PrivateKey) -> P256.Signing.PublicKey {
  key.publicKey
}
