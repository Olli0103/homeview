import XCTest
@testable import HomeViewCore

final class RecipeTransferTests:XCTestCase {
  func testRoundTripResolvesSameRecipeAndExactCookingStep() throws {
    let transfer=try RecipeContinuity.make(recipe:.soup,step:2)
    let decoded=try RecipeContinuity.decode(RecipeContinuity.encode(transfer),activityType:RecipeContinuity.activityType)
    XCTAssertEqual(decoded,transfer)
    XCTAssertEqual(try RecipeContinuity.resolve(decoded,recipes:[.soup]).title,RecipeDocument.soup.title)
    XCTAssertEqual(decoded.step,2)
  }
  func testPayloadContainsOnlyFingerprintVersionAndStepNotPrivateRecipeData() throws {
    var privateRecipe=RecipeDocument.soup
    privateRecipe.title="Synthetic private recipe name"
    privateRecipe.source="https://private.example/recipe?token=synthetic-only"
    privateRecipe.ingredients=["Synthetic private ingredient"]
    let data=try RecipeContinuity.encode(RecipeContinuity.make(recipe:privateRecipe,step:0))
    let object=try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
    XCTAssertEqual(Set(object.keys),["version","document","step"])
    let text=String(decoding:data,as:UTF8.self)
    XCTAssertFalse(text.contains(privateRecipe.title));XCTAssertFalse(text.contains(privateRecipe.source))
    XCTAssertFalse(text.contains("private ingredient"));XCTAssertLessThan(data.count,512)
  }
  func testIndependentLocalIDsAndCoverImagesDoNotPreventMatchingSameRecipe() throws {
    var other=RecipeDocument.soup;other.id=UUID();other.coverAsset=nil
    other.imageURL=URL(string:"https://images.example/cover.jpg")
    let transfer=try RecipeContinuity.make(recipe:.soup,step:1)
    XCTAssertEqual(try RecipeContinuity.resolve(transfer,recipes:[other]).id,other.id)
  }
  func testChangedContentOrProvenanceDoesNotResumeAnOldRecipeVersion() throws {
    let transfer=try RecipeContinuity.make(recipe:.soup,step:1)
    var changed=RecipeDocument.soup;changed.source="Different synthetic source"
    XCTAssertThrowsError(try RecipeContinuity.resolve(transfer,recipes:[changed])) {
      XCTAssertEqual($0 as? RecipeTransferError,.recipeUnavailable)
    }
    changed=RecipeDocument.soup;changed.steps[0]=RecipeStep(text:"Different synthetic step",minutes:nil)
    XCTAssertThrowsError(try RecipeContinuity.resolve(transfer,recipes:[changed]))
  }
  func testUnknownSchemaAndActivityTypeFailWithoutARecipe() throws {
    let valid=try RecipeContinuity.make(recipe:.soup,step:0)
    let future=RecipeTransfer(version:99,document:valid.document,step:0)
    XCTAssertThrowsError(try RecipeContinuity.decode(JSONEncoder().encode(future),activityType:RecipeContinuity.activityType)) {
      XCTAssertEqual($0 as? RecipeTransferError,.unsupportedVersion)
    }
    XCTAssertThrowsError(try RecipeContinuity.decode(RecipeContinuity.encode(valid),activityType:"untrusted.other.activity"))
  }
  func testMalformedOversizedAndUnexpectedContentAreRejected() throws {
    let valid=try RecipeContinuity.make(recipe:.soup,step:0)
    for bytes in [Data(),Data(repeating:65,count:513),Data("{\"version\":true}".utf8),
      Data("{\"version\":1,\"document\":\"bad\",\"step\":-1}".utf8)] {
      XCTAssertThrowsError(try RecipeContinuity.decode(bytes,activityType:RecipeContinuity.activityType))
    }
    var object=try XCTUnwrap(JSONSerialization.jsonObject(with:RecipeContinuity.encode(valid)) as? [String:Any])
    object["recipeText"]="Unexpected content"
    XCTAssertThrowsError(try RecipeContinuity.decode(JSONSerialization.data(withJSONObject:object),activityType:RecipeContinuity.activityType))
  }
  func testMissingRecipeAndInvalidStepNeverSelectAFallbackRecipe() throws {
    let valid=try RecipeContinuity.make(recipe:.soup,step:0)
    XCTAssertThrowsError(try RecipeContinuity.resolve(valid,recipes:[]))
    XCTAssertThrowsError(try RecipeContinuity.make(recipe:.soup,step:-1))
    let bad=RecipeTransfer(version:1,document:valid.document,step:99)
    XCTAssertThrowsError(try RecipeContinuity.resolve(bad,recipes:[.soup])) {
      XCTAssertEqual($0 as? RecipeTransferError,.stepUnavailable)
    }
  }
}


extension RecipeTransferTests {
  func testEveryValidSavedRecipeSlotCanBeResolvedNotOnlyTheFirstTwenty() throws {
    let pinned=(0..<50).map { index -> RecipeDocument in
      var recipe=RecipeDocument.soup;recipe.id=UUID();recipe.title="Saved synthetic recipe \(index)";return recipe
    }
    let last=try XCTUnwrap(pinned.last)
    let transfer=try RecipeContinuity.make(recipe:last,step:1)
    XCTAssertEqual(try RecipeContinuity.resolve(transfer,recipes:[.soup]+pinned).id,last.id)
  }
  func testLargestAllowedSnapshotRecipeCanStillUseSmallMetadataHandoff() throws {
    var large=RecipeDocument.soup
    large.ingredients=Array(repeating:String(repeating:"i",count:1000),count:200)
    large.steps=Array(repeating:RecipeStep(text:String(repeating:"s",count:3000),minutes:1),count:100)
    var snapshot=Snapshot();snapshot.recipe=large
    let restored=try Snapshot.decodeMigrating(JSONEncoder().encode(snapshot))
    XCTAssertEqual(restored.recipe.ingredients.count,200);XCTAssertEqual(restored.recipe.steps.count,100)
    let transfer=try RecipeContinuity.make(recipe:restored.recipe,step:99)
    XCTAssertLessThan(try RecipeContinuity.encode(transfer).count,512)
    XCTAssertEqual(try RecipeContinuity.resolve(transfer,recipes:[restored.recipe]).steps.count,100)
  }
}
