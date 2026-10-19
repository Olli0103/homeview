import Foundation
@main struct PersistenceWriteGate {
 @MainActor static func main() throws {
  let args=ProcessInfo.processInfo.arguments
  guard args.contains("--uitesting"),let i=args.firstIndex(of:"--case"),args.indices.contains(i+1),let j=args.firstIndex(of:"--persistence-test"),args.indices.contains(j+1),let id=UUID(uuidString:args[j+1]),!args.contains("--reset-test-store"),!args.contains("--system-alarms") else {fatalError("Fresh owned Mock-only test required")}
  let name=args[i+1],m=AppModel(),fm=FileManager.default,store=m.gateStoreURL,assistant=name.hasPrefix("assistant_")
  let rejected=["invalid_value","security_rejected","offline_rejected"].contains(name),dir=store.deletingLastPathComponent()
  guard dir.lastPathComponent=="test-"+id.uuidString,!fm.fileExists(atPath:store.path) else {fatalError("Fresh owned root only")}
  if name=="offline_rejected" {m.data.home.online=false}
  if assistant {m.route = .assistant;m.setAnswerSpeechForeground(true)}
  guard m.persist() else {fatalError("Positive baseline save")}
  let before=try Snapshot.canonicalBytes(JSONEncoder().encode(m.data)),original=try Data(contentsOf:store),priorHome=m.data.home
  let preserved=dir.appendingPathComponent("before-fault.json"),canary=store.appendingPathComponent("owned-canary.txt"),marker=Data("OWNED_MOCK_WRITE_CANARY".utf8)
  try fm.moveItem(at:store,to:preserved);try fm.createDirectory(at:store,withIntermediateDirectories:false);try marker.write(to:canary)
  func act() {
   switch name {
    case "temperature":m.command(.temperature(72))
    case "brightness":m.command(.brightness(30))
    case "entry_light":m.command(.entryLight)
    case "compound_scene":m.command(.scene("Movie Time"))
    case "invalid_value":m.command(.temperature(100))
    case "security_rejected":m.command(.scene("Good Night"))
    case "offline_rejected":m.command(.scene("Good Morning"))
    case "assistant_temperature":m.assistantInput="temperature 72";m.runAssistant()
    case "assistant_lights":m.assistantInput="lights";m.runAssistant()
    case "assistant_scene":m.assistantInput="good morning";m.runAssistant()
    default:fatalError("Unknown case")
   }
  }
  act()
  var checks:[String:Bool]=["snapshot_unchanged":try Snapshot.canonicalBytes(JSONEncoder().encode(m.data))==before,"failure_reported":m.error != nil,"original_bytes_unchanged":try Data(contentsOf:preserved)==original,"canary_unchanged":try Data(contentsOf:canary)==marker,"no_system_alarms":m.data.nativeTimerIDs.isEmpty && m.data.nativeAlarmIDs.isEmpty]
  if assistant {checks["assistant_reports_error_not_success"]=m.assistantReply==m.error && !m.assistantReply.isEmpty}
  guard try Data(contentsOf:canary)==marker,try fm.contentsOfDirectory(atPath:store.path)==["owned-canary.txt"] else {fatalError("Owned fault identity mismatch")}
  try fm.removeItem(at:canary);try fm.removeItem(at:store);try fm.moveItem(at:preserved,to:store)
  let restored=AppModel();checks["restart_matches_original"]=try Snapshot.canonicalBytes(JSONEncoder().encode(restored.data))==before
  if args.contains("--retry-after-fault") {
   m.error=nil;act();let after=try Snapshot.canonicalBytes(JSONEncoder().encode(m.data))
   checks["retry_expected_change"]=rejected ? after==before:after != before
   checks["retry_expected_error"]=rejected ? m.error != nil:m.error==nil
   checks["retry_saved_exactly"]=try Snapshot.canonicalBytes(Data(contentsOf:store))==after
   checks["audit_exactly_once"]=m.data.home.audit.count==priorHome.audit.count+(rejected ? 0:1)
   if assistant {checks["assistant_retry_reports_success"]=m.error==nil && !m.assistantReply.contains("Could not save") && m.assistantInput.isEmpty}
   var nonHome=m.data;nonHome.home=priorHome
   checks["unrelated_snapshot_fields_unchanged"]=try Snapshot.canonicalBytes(JSONEncoder().encode(nonHome))==before
   let restarted=AppModel();checks["restart_matches_retry"]=try Snapshot.canonicalBytes(JSONEncoder().encode(restarted.data))==after
  }
  let failed=checks.filter{!$0.value}.map(\.key).sorted();let r:[String:Any]=["case":name,"checks":checks,"failed":failed,"verdict":failed.isEmpty ? "PASS":"FAIL","assertions":checks.count,"owned_uuid":id.uuidString]
  print(String(data:try JSONSerialization.data(withJSONObject:r,options:[.sortedKeys]),encoding:.utf8)!)
 }
}
