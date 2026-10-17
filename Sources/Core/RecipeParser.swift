import CoreFoundation
import CryptoKit
import Foundation

enum RecipeParser {
  static func parse(json: String, source: String) throws -> RecipeDocument {
    guard let first = try parseAll(json: json, source: source).first else { throw RecipeParseError.noRecipe }
    return first
  }
  static func parseAll(json: String, source: String) throws -> [RecipeDocument] {
    guard json.utf8.count <= 2_000_000 else { throw RecipeParseError.oversized }
    let root = try JSONSerialization.jsonObject(with: Data(json.utf8))
    let nodes = try candidates(root, depth: 0)
    guard nodes.count <= 20 else { throw RecipeParseError.oversized }
    var recipes: [RecipeDocument] = []
    var seen = Set<UUID>()
    for node in nodes {
      // An incomplete Recipe node must not hide a later valid Recipe.
      guard let recipe = try document(node, source: source) else { continue }
      if seen.insert(recipe.id).inserted { recipes.append(recipe) }
    }
    guard !recipes.isEmpty else { throw RecipeParseError.noRecipe }
    return recipes
  }
  private static func candidates(_ value: Any, depth: Int) throws -> [[String: Any]] {
    guard depth < 10 else { throw RecipeParseError.oversized }
    if let list = value as? [Any] {
      guard list.count <= 100 else { throw RecipeParseError.oversized }
      return try list.flatMap { try candidates($0, depth: depth + 1) }
    }
    guard let node = value as? [String: Any] else { return [] }
    let types = (node["@type"] as? [String]) ?? [node["@type"] as? String ?? ""]
    var result = types.contains(where: { $0 == "Recipe" || $0.hasSuffix("/Recipe") }) ? [node] : []
    if let graph = node["@graph"] { result += try candidates(graph, depth: depth + 1) }
    return result
  }
  private static func document(_ node: [String: Any], source: String) throws -> RecipeDocument? {
    guard let name = node["name"] as? String else { return nil }
    let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !title.isEmpty else { return nil }
    guard title.count <= 200 else { throw RecipeParseError.oversized }
    let instructions = try steps(node["recipeInstructions"], depth: 0)
    guard !instructions.isEmpty else { return nil }
    let ingredients: [String]
    if let raw = node["recipeIngredient"] {
      guard let lines = raw as? [String] else { return nil }
      guard lines.count <= 200, lines.allSatisfy({ $0.count <= 1000 }) else { throw RecipeParseError.oversized }
      ingredients = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    } else { ingredients = [] }
    let prep = duration(node["prepTime"] as? String), cook = duration(node["cookTime"] as? String)
    let total: Int?
    if let explicit = duration(node["totalTime"] as? String) { total = explicit }
    else if let prep, let cook { total = prep + cook }
    else { total = nil }
    let yield: String
    if let value = node["recipeYield"] as? String { yield = value }
    else if let values = node["recipeYield"] as? [String] { yield = values.joined(separator: " · ") }
    else if let value = node["recipeYield"] as? NSNumber,
      CFGetTypeID(value) != CFBooleanGetTypeID(), value.doubleValue.isFinite, value.doubleValue > 0 {
      yield = value.stringValue
    }
    else { yield = "" }
    guard yield.count <= 160 else { throw RecipeParseError.oversized }
    let image = (node["image"] as? String) ?? (node["image"] as? [String])?.first
      ?? (node["image"] as? [String: Any])?["url"] as? String
    let imageURL = image.flatMap(URL.init(string:)).flatMap { url in
      url.scheme?.lowercased() == "https" && url.host?.isEmpty == false
        && url.user == nil && url.password == nil ? url : nil
    }
    let identity: [String: Any] = ["source": source, "title": title,
      "ingredients": ingredients, "steps": instructions.map(\.text)]
    let canonical = try JSONSerialization.data(withJSONObject: identity, options: [.sortedKeys])
    var bytes = Array(SHA256.hash(data: canonical).prefix(16))
    bytes[6] = (bytes[6] & 0x0f) | 0x80
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    let id = UUID(uuid: (bytes[0],bytes[1],bytes[2],bytes[3],bytes[4],bytes[5],bytes[6],bytes[7],
                         bytes[8],bytes[9],bytes[10],bytes[11],bytes[12],bytes[13],bytes[14],bytes[15]))
    return RecipeDocument(id: id, title: title, source: source, durationMinutes: total ?? 0,
      servings: yield.trimmingCharacters(in: .whitespacesAndNewlines), ingredients: ingredients,
      steps: instructions, coverAsset: nil, imageURL: imageURL, prepMinutes: prep, cookMinutes: cook)
  }
  private static func steps(_ value: Any?, depth: Int) throws -> [RecipeStep] {
    guard depth < 10 else { throw RecipeParseError.oversized }
    if let text = value as? String {
      let lines = text.components(separatedBy: .newlines).map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
      }.filter { !$0.isEmpty }
      guard lines.count <= 100, lines.allSatisfy({ $0.count <= 3000 }) else { throw RecipeParseError.oversized }
      return lines.map { RecipeStep(text: $0, minutes: inlineMinutes($0)) }
    }
    if let list = value as? [Any] {
      guard list.count <= 100 else { throw RecipeParseError.oversized }
      let values = try list.flatMap { try steps($0, depth: depth + 1) }
      guard values.count <= 100 else { throw RecipeParseError.oversized }
      return values
    }
    if let node = value as? [String: Any] {
      if let children = node["itemListElement"] { return try steps(children, depth: depth + 1) }
      if let text = node["text"] as? String { return try steps(text, depth: depth + 1) }
      let type = node["@type"] as? String ?? ""
      if type == "HowToStep", let name = node["name"] as? String { return try steps(name, depth: depth + 1) }
    }
    return []
  }
  /// Explicit ISO duration only; missing/unsupported values remain unknown.
  static func duration(_ value: String?) -> Int? {
    guard let value, !value.uppercased().hasSuffix("T") else { return nil }
    let pattern = #"(?i)^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$"#
    guard let expression = try? NSRegularExpression(pattern: pattern),
      let match = expression.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) else { return nil }
    var seconds = 0.0, components = 0
    for (group, multiplier) in [(1,86400.0),(2,3600.0),(3,60.0),(4,1.0)] {
      if let range = Range(match.range(at: group), in: value), let number = Double(value[range]) {
        seconds += number * multiplier; components += 1
      }
    }
    guard components > 0, seconds.isFinite, seconds > 0, seconds <= 7 * 86400 else { return nil }
    return Int(ceil(seconds / 60))
  }
  static func inlineMinutes(_ text: String) -> Int? {
    if text.range(of: #"(?i)(?:[-−]\s*\d|\b(?:about|approximately|around|etwa|ungefähr|circa|ca\.)\s*\d)"#,
                  options: .regularExpression) != nil { return nil }
    if text.range(of: #"\d\s*(?:[-–—]|\bto\b|\bbis\b)\s*\d"#,
                  options: [.regularExpression, .caseInsensitive]) != nil { return nil }
    let pattern = #"(?i)\b(\d+(?:[.,]\d+)?)\s*(hours?|stunden?|std|minutes?|minuten|min|seconds?|sekunden?|sek)\b"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
    guard !matches.isEmpty, matches.count <= 3 else { return nil }
    var seconds = 0.0, last: String.Index?, used = Set<Int>()
    for match in matches {
      guard let whole = Range(match.range, in: text), let nr = Range(match.range(at: 1), in: text),
        let ur = Range(match.range(at: 2), in: text),
        let number = Double(text[nr].replacingOccurrences(of: ",", with: ".")), number > 0 else { return nil }
      if let last {
        let between = text[last..<whole.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard ["", "and", "und"].contains(between) else { return nil }
      }
      let unit = text[ur].lowercased()
      let multiplier = unit.hasPrefix("h") || unit.hasPrefix("st") ? 3600
        : unit.hasPrefix("m") ? 60 : 1
      guard used.insert(multiplier).inserted else { return nil }
      seconds += number * Double(multiplier)
      last = whole.upperBound
    }
    guard seconds.isFinite, seconds >= 60, seconds <= 86400, seconds.truncatingRemainder(dividingBy: 60) == 0 else { return nil }
    return Int(seconds / 60)
  }
}
