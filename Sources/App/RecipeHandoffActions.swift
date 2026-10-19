import Foundation

#if !os(watchOS)
extension AppModel {
  func presentRecipeHandoff() { route = .handoff }
  func closeRecipeHandoff() {
    recipeHandoff.cancelPending()
    route=cookingInProgress ? .cooking:.recipe
  }
  func offerRecipeHandoff() async {
    guard cookingInProgress else { recipeHandoff.status="Start cooking before offering a recipe.";return }
    guard RecipeHandoffController.canPublish else {
      do { try recipeHandoff.offer(RecipeContinuity.make(recipe:recipe,step:cookingStep)) }
      catch { recipeHandoff.status="This recipe cannot be offered." }
      return
    }
    let generation=personalSessionGeneration;let ticket=recipeHandoff.generation
    guard let document=try? RecipeContinuity.fingerprint(recipe) else {
      recipeHandoff.status="This recipe cannot be offered.";return
    }
    recipeHandoff.busy=true
    defer { if recipeHandoff.generation==ticket { recipeHandoff.busy=false } }
    if document != (try? RecipeContinuity.fingerprint(.soup)),!connections.personalUnlocked {
      let unlocked=await connections.unlock()
      guard personalSessionGeneration==generation,recipeHandoff.generation==ticket else { return }
      guard unlocked else { recipeHandoff.status="Device unlock was not granted. Nothing was sent.";return }
    }
    guard personalSessionGeneration==generation,recipeHandoff.generation==ticket,
      route == .handoff,cookingInProgress,document == (try? RecipeContinuity.fingerprint(recipe)) else { return }
    do { try recipeHandoff.offer(RecipeContinuity.make(recipe:recipe,step:cookingStep)) }
    catch { recipeHandoff.status="This recipe cannot be offered." }
  }
  func acceptRecipeHandoff() async {
    guard let transfer=recipeHandoff.incoming else { return }
    let ticket=recipeHandoff.generation;let session=personalSessionGeneration
    recipeHandoff.busy=true
    defer { if recipeHandoff.generation==ticket { recipeHandoff.busy=false } }
    if !connections.personalUnlocked {
      let unlocked=await connections.unlock()
      guard recipeHandoff.generation==ticket,personalSessionGeneration==session else { return }
      guard unlocked else { recipeHandoff.status="Device unlock was not granted. Nothing was changed.";return }
    }
    guard recipeHandoff.generation==ticket,personalSessionGeneration==session,
      connections.personalUnlocked,recipeHandoff.incoming==transfer,route == .handoff else { return }
    if applyRecipeTransfer(transfer) { recipeHandoff.cancelPending() }
  }
  func receiveRecipeHandoff(type:String,data:Data) {
    recipeHandoff.receive(type:type,data:data)
    route = .handoff
  }
  func installRecipeHandoffFixture() {
    guard !recipeHandoffFixtureInstalled else { return }
    recipeHandoffFixtureInstalled=true
    let args=ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"),let index=args.firstIndex(of:"--recipe-handoff-fixture"),index+1<args.count else { return }
    do {
      let mode=args[index+1]
      let valid=try RecipeContinuity.make(recipe:RecipeDocument.soup,step:2)
      let payload:RecipeTransfer
      switch mode {
      case "valid":payload=valid
      case "missing":payload=RecipeTransfer(version:1,document:String(repeating:"a",count:64),step:2)
      case "version":payload=RecipeTransfer(version:99,document:valid.document,step:2)
      default:return
      }
      receiveRecipeHandoff(type:RecipeContinuity.activityType,data:try JSONEncoder().encode(payload))
    } catch { recipeHandoff.status="Synthetic recipe handoff could not be prepared." }
  }
}
#endif
