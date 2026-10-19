import Foundation
import LocalAuthentication
func documentedDeviceAuthentication(_ context:LAContext) async throws -> Bool {
  try await context.evaluatePolicy(.deviceOwnerAuthentication,localizedReason:"Compile-only API-shape probe; never executed.")
}
