import XCTest
@testable import HomeViewCore

final class RecipeParserTests: XCTestCase {
  private func json(_ object: Any) throws -> String {
    String(data: try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]), encoding: .utf8)!
  }
  private func node(_ title: String) -> [String: Any] {
    ["@type":"Recipe","name":title,"recipeInstructions":["Mix the ingredients."]]
  }
  func testIncompleteFirstRecipeDoesNotHideTwoValidChoicesAndIDsAreStable() throws {
    let nodes: [Any] = [["@type":"Recipe","name":"Incomplete"], node("First"),node("Second"),node("First")]
    let payload = try json(["@graph":nodes])
    let recipes = try RecipeParser.parseAll(json: payload, source: "Synthetic cookbook")
    XCTAssertEqual(recipes.map(\.title),["First","Second"])
    XCTAssertNotEqual(recipes[0].id,recipes[1].id)
    XCTAssertEqual(try RecipeParser.parse(json: payload,source:"Synthetic cookbook").id,recipes[0].id)
    XCTAssertEqual(try RecipeParser.parseAll(json:payload,source:"Synthetic cookbook").map(\.id),recipes.map(\.id))
  }
  func testMissingMetadataStaysUnknownAndUnitsAreNotInvented() throws {
    let recipe = try RecipeParser.parse(json: json(node("No metadata")),source:"Test")
    XCTAssertEqual(recipe.durationMinutes,0)
    XCTAssertEqual(recipe.servings,"")
    XCTAssertEqual(recipe.durationLabel,"Duration not provided")
    XCTAssertEqual(recipe.servingsLabel,"Servings not provided")
    XCTAssertTrue(recipe.ingredients.isEmpty)
    var partial = node("Cook only");partial["cookTime"]="PT25M"
    partial["recipeYield"]=["4 bowls","800 ml"]
    let cooked = try RecipeParser.parse(json:json(partial),source:"Test")
    XCTAssertEqual(cooked.durationMinutes,0)
    XCTAssertEqual(cooked.durationLabel,"Cook 25 min.")
    XCTAssertEqual(cooked.servings,"4 bowls · 800 ml")
    partial["recipeYield"] = true
    XCTAssertEqual(try RecipeParser.parse(json:json(partial),source:"Test").servings, "")
  }
  func testSectionsRetainStepOrderAndNoInstructionIsSilentlyTruncated() throws {
    var value = node("Sections")
    value["recipeInstructions"] = [["@type":"HowToSection","name":"Prepare","itemListElement":[["@type":"HowToStep","text":"Prepare vegetables."],["@type":"HowToStep","name":"Wash hands."]]], ["@type":"HowToStep","text":"Cook for 1 hour and 30 minutes."]]
    let recipe = try RecipeParser.parse(json:json(value),source:"Test")
    XCTAssertEqual(recipe.steps.map(\.text),["Prepare vegetables.","Wash hands.","Cook for 1 hour and 30 minutes."])
    XCTAssertEqual(recipe.steps.last?.minutes,90)
    value["recipeInstructions"] = Array(repeating: "Mix.",count:101)
    XCTAssertThrowsError(try RecipeParser.parse(json:json(value),source:"Test"))
    value["recipeInstructions"] = [String(repeating:"x",count:3001)]
    XCTAssertThrowsError(try RecipeParser.parse(json:json(value),source:"Test"))
  }
  func testDurationRangesAndMultipleIndependentTimesDoNotCreateWrongTimer() {
    for text in ["Bake for 5–10 minutes.","Bake 5 to 10 minutes.","Cook 5 minutes then rest 10 minutes.","Cook -5 minutes.","Cook about 5 minutes.","Cook 90 seconds.","Cook 1.5 minutes."] {
      XCTAssertNil(RecipeParser.inlineMinutes(text),text)
    }
    XCTAssertEqual(RecipeParser.inlineMinutes("Cook 20 Minuten."),20)
    XCTAssertEqual(RecipeParser.inlineMinutes("Cook 1 Stunde und 15 Minuten."),75)
    XCTAssertEqual(RecipeParser.inlineMinutes("Cook 120 seconds."),2)
    XCTAssertEqual(RecipeParser.duration("P1DT2H"),1560)
    XCTAssertEqual(RecipeParser.duration("PT90S"),2)
    XCTAssertNil(RecipeParser.duration("P1DT"))
    XCTAssertNil(RecipeParser.duration("PT999999999999999999999999999999999H"))
  }
  func testRecipeImagesCannotLoadInsecureOrCredentialURLs() throws {
    for address in ["http://example.invalid/image.jpg","file:///tmp/image.jpg","https://user:pass@example.invalid/image.jpg"] {
      var value=node("Image");value["image"]=address
      XCTAssertNil(try RecipeParser.parse(json:json(value),source:"Test").imageURL)
    }
    var value=node("Image");value["image"]=["url":"https://example.invalid/image.jpg"]
    XCTAssertNotNil(try RecipeParser.parse(json:json(value),source:"Test").imageURL)
  }
}
