import Foundation
import CryptoKit

struct RecipeTransfer: Codable, Equatable, Sendable {
  let version: Int
  let document: String
  let step: Int
}
enum RecipeTransferError: Error, LocalizedError, Equatable {
  case malformed, unsupportedVersion, recipeUnavailable, stepUnavailable
  var errorDescription:String? {
    switch self {
    case .malformed: "This recipe handoff is invalid. Nothing was changed."
    case .unsupportedVersion: "This recipe handoff version is not supported. Update both apps."
    case .recipeUnavailable: "This recipe is not available on this device. Save the same recipe here first."
    case .stepUnavailable: "This recipe version does not contain that cooking step. Nothing was changed."
    }
  }
}
enum RecipeContinuity {
  static let activityType="org.example.homeview.recipe.v1"
  static let maximumBytes=512
  private struct Identity: Encodable {
    let title:String
    let source:String
    let ingredients:[String]
    let steps:[RecipeStep]
  }
  static func fingerprint(_ recipe:RecipeDocument) throws -> String {
    guard recipe.title.count<=200,recipe.source.count<=4096,recipe.ingredients.count<=200,recipe.ingredients.allSatisfy({$0.count<=1000}),
      recipe.steps.count<=100,recipe.steps.allSatisfy({ !$0.text.isEmpty && $0.text.count<=3000
        && ($0.minutes.map { (1...1440).contains($0) } ?? true) }) else { throw RecipeTransferError.recipeUnavailable }
    let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys]
    let bytes=try encoder.encode(Identity(title:recipe.title,source:recipe.source,
      ingredients:recipe.ingredients,steps:recipe.steps))
    guard bytes.count<=3_100_000 else { throw RecipeTransferError.recipeUnavailable }
    return SHA256.hash(data:bytes).map { String(format:"%02x",$0) }.joined()
  }
  static func make(recipe:RecipeDocument,step:Int) throws -> RecipeTransfer {
    guard recipe.steps.indices.contains(step) else { throw RecipeTransferError.stepUnavailable }
    return RecipeTransfer(version:1,document:try fingerprint(recipe),step:step)
  }
  static func encode(_ transfer:RecipeTransfer) throws -> Data {
    let bytes=try JSONEncoder().encode(transfer)
    _=try decode(bytes,activityType:activityType)
    return bytes
  }
  static func decode(_ data:Data,activityType:String) throws -> RecipeTransfer {
    guard activityType==Self.activityType,data.count<=maximumBytes,
      let keys=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any],
      Set(keys.keys)==["version","document","step"],
      let transfer=try? JSONDecoder().decode(RecipeTransfer.self,from:data) else { throw RecipeTransferError.malformed }
    guard transfer.version==1 else { throw RecipeTransferError.unsupportedVersion }
    guard transfer.document.count==64,transfer.document.allSatisfy({ "0123456789abcdef".contains($0) }),
      (0..<100).contains(transfer.step) else { throw RecipeTransferError.malformed }
    return transfer
  }
  static func resolve(_ transfer:RecipeTransfer,recipes:[RecipeDocument]) throws -> RecipeDocument {
    guard transfer.version==1 else { throw RecipeTransferError.unsupportedVersion }
    for recipe in recipes.prefix(51) where (try? fingerprint(recipe))==transfer.document {
      guard recipe.steps.indices.contains(transfer.step) else { throw RecipeTransferError.stepUnavailable }
      return recipe
    }
    throw RecipeTransferError.recipeUnavailable
  }
}
