import Foundation

@main struct HandoffGate {
  @MainActor static func main() async throws {
    let args=ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"),let i=args.firstIndex(of:"--persistence-test"),i+1<args.count,
      let id=UUID(uuidString:args[i+1]),let s=args.firstIndex(of:"--gate-scenario"),s+1<args.count else { exit(90) }
    let scenario=args[s+1]
    let url=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0]
      .appendingPathComponent("HomeViewReplica/test-"+id.uuidString+"/mock-state.json")
    guard !FileManager.default.fileExists(atPath:url.path) else { exit(91) }
    let model=AppModel()
    var recipe=RecipeDocument.soup
    recipe.title="SYNTHETIC_PRIVATE_CANARY_7301";recipe.source="SYNTHETIC_SOURCE_CANARY_9843"
    model.data.recipe=recipe
    let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys]
    let before=try encoder.encode(model.data)
    let fileBefore=try? Data(contentsOf:url)
    let transfer=try RecipeContinuity.make(recipe:recipe,step:2)
    let good=try RecipeContinuity.encode(transfer)
    var type=RecipeContinuity.activityType;var payload=good
    switch scenario {
    case "invalid-type":type="invalid.untrusted"
    case "invalid-schema":payload=Data("{\"version\":99,\"document\":\"x\",\"step\":2}".utf8)
    case "extra-field":payload=Data(("{\"version\":1,\"document\":\""+transfer.document+"\",\"step\":2,\"source\":\"SYNTHETIC_SOURCE_CANARY_9843\"}").utf8)
    case "oversized":payload=Data(repeating:32,count:513)
    default:break
    }
    if scenario=="cancelled" || scenario=="cancelled-direct" { _=await model.connections.unlock() }
    model.receiveRecipeHandoff(type:type,data:payload)
    if scenario=="cancelled" {
      let task=Task { @MainActor in await model.acceptRecipeHandoff() };task.cancel();await task.value
    } else if scenario=="cancelled-direct" {
      let task=Task { @MainActor in _=model.applyRecipeTransfer(transfer) };task.cancel();await task.value
    } else if scenario=="revoked" {
      model.closeRecipeHandoff();await model.acceptRecipeHandoff()
    } else if scenario != "pending" { await model.acceptRecipeHandoff() }
    let fileAfter=try? Data(contentsOf:url)
    let unchanged=before == (try encoder.encode(model.data))
    let valid=scenario=="valid"
    let result:[String:Any]=[
      "scenario":scenario,"snapshotUnchanged":unchanged,"storeBytesUnchanged":fileBefore==fileAfter,
      "storeCreated":fileBefore==nil && fileAfter != nil,"cooking":model.cookingInProgress,
      "correctStep":model.cookingStep==2,"noTimers":model.data.timers.isEmpty,
      "unlocked":model.connections.personalUnlocked,"nativeActivityOffered":model.recipeHandoff.offering,
      "payloadNoPrivateCanaries":!String(decoding:good,as:UTF8.self).contains("CANARY"),
      "passed":valid ? model.cookingInProgress && model.cookingStep==2 && fileAfter != nil && model.data.timers.isEmpty : unchanged && fileBefore==fileAfter && !model.cookingInProgress]
    let bytes=try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys])
    print(String(decoding:bytes,as:UTF8.self))
    exit(result["passed"] as? Bool == true ? 0:1)
  }
}
