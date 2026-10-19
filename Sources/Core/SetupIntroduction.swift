import Foundation

/// App introduction only: never an owner identity, account or permission grant.
enum SetupIntroduction:String,Codable,Sendable,CaseIterable {
  case pending,deferred,completed
}
