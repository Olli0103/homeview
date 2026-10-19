import Foundation
@main struct PersistenceWriteGate {
 @MainActor static func main() throws {
  let args=ProcessInfo.processInfo.arguments
  guard args.contains("--uitesting"),let i=args.firstIndex(of:"--case"),args.indices.contains(i+1),let j=args.firstIndex(of:"--persistence-test"),args.indices.contains(j+1),let id=UUID(uuidString:args[j+1]),!args.contains("--reset-test-store") else {fatalError("Fresh owned UUID required")}
  let name=args[i+1],m=AppModel(),fm=FileManager.default
  let store=m.gateStoreURL,dir=store.deletingLastPathComponent()
  guard dir.lastPathComponent=="test-"+id.uuidString,store.lastPathComponent=="mock-state.json",!fm.fileExists(atPath:store.path) else {fatalError("Fresh test root only")}
  if name=="unpin" {m.pinRecipe()}
  if ["messages","reminders","typed_drafts"].contains(name) {m.signIn("Alex")}
  if name=="replace_recipe" {m.startCooking();m.moveCookingStep(1)}
  guard m.persist() else {fatalError("Positive save required")}
  let before=try Snapshot.canonicalBytes(JSONEncoder().encode(m.data)),original=try Data(contentsOf:store),step=m.cookingStep,cooking=m.cookingInProgress,route=m.route
  let preserved=dir.appendingPathComponent("before-fault.json"),canary=store.appendingPathComponent("owned-canary.txt"),marker=Data("OWNED_FAILED_WRITE_CANARY".utf8)
  try fm.moveItem(at:store,to:preserved);try fm.createDirectory(at:store,withIntermediateDirectories:false);try marker.write(to:canary)
  var replacement=m.recipe;replacement.id=UUID();replacement.title="Synthetic replacement recipe"
  func action() {
  switch name {
   case "pin","unpin":m.pinRecipe()
   case "next_face":m.nextFace(1)
   case "world_add":m.addWorldCity(WorldCity.catalogue.first(where:{!m.data.worldClockZones.contains($0.zone)})!.zone)
   case "world_remove":m.removeWorldCity(m.data.worldClockZones.first!)
   case "replace_recipe":m.recipe=replacement
   case "messages":m.messages=["Synthetic failed message"]
   case "reminders":m.reminders=[ReminderItem(title:"Synthetic failed reminder")]
   case "new_profile":m.signIn("Jamie")
   case "editor_controls":m.updateLocalControls { $0.editConfiguration(for:.flow) { $0.flowTypeface=1;$0.flowBackground=false } }
   case "typed_drafts":_ = m.addLocalReminder("Synthetic failed draft");_ = m.appendLocalMessage("Synthetic failed message draft")
   default:fatalError("Unknown owned case")
  }
  }
  action()
  var checks:[String:Bool]=["snapshot_unchanged":try Snapshot.canonicalBytes(JSONEncoder().encode(m.data))==before,"save_error_visible":m.error != nil,"preserved_bytes_unchanged":try Data(contentsOf:preserved)==original,"canary_unchanged":try Data(contentsOf:canary)==marker]
  if name=="replace_recipe" {checks["cooking_context_unchanged"]=m.cookingStep==step && m.cookingInProgress==cooking && m.route==route}
  if name=="new_profile" {checks["no_unsaved_new_profile"]=m.profile==nil}
  guard try Data(contentsOf:canary)==marker,try fm.contentsOfDirectory(atPath:store.path)==["owned-canary.txt"] else {fatalError("Fault directory identity mismatch")}
  try fm.removeItem(at:canary);try fm.removeItem(at:store);try fm.moveItem(at:preserved,to:store)
  let restored=AppModel()
  checks["restart_matches_original"]=try Snapshot.canonicalBytes(JSONEncoder().encode(restored.data))==before
  m.error=nil;action()
  let after=try Snapshot.canonicalBytes(JSONEncoder().encode(m.data))
  checks["retry_changes_expected_state"]=after != before
  checks["retry_saved_exact_snapshot"]=try Snapshot.canonicalBytes(Data(contentsOf:store))==after
  checks["retry_has_no_error"]=m.error==nil
  if name=="replace_recipe" {checks["successful_recipe_change_resets_cooking"]=m.recipe.id==replacement.id && m.cookingStep==0 && !m.cookingInProgress}
  if name=="new_profile" {checks["successful_new_profile_selected"]=m.profile=="Jamie"}
  let restarted=AppModel();checks["restart_matches_saved_retry"]=try Snapshot.canonicalBytes(JSONEncoder().encode(restarted.data))==after
  let failed=checks.filter{!$0.value}.map(\.key).sorted()
  let result:[String:Any] = ["case":name,"checks":checks,"failed":failed,"verdict":failed.isEmpty ? "PASS":"FAIL","assertions":checks.count,"owned_uuid":id.uuidString]
  print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
 }
}
