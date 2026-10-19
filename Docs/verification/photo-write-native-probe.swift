import Foundation
import CryptoKit
@main struct PersistenceWriteGate {
 @MainActor static func main() throws {
  let args=ProcessInfo.processInfo.arguments
  guard args.contains("--uitesting"),let i=args.firstIndex(of:"--case"),args.indices.contains(i+1),let j=args.firstIndex(of:"--persistence-test"),args.indices.contains(j+1),let id=UUID(uuidString:args[j+1]),!args.contains("--reset-test-store") else {fatalError("Fresh owned synthetic photo root required")}
  let name=args[i+1],m=AppModel(),fm=FileManager.default,store=m.gateStoreURL,dir=m.gateStoreURL.deletingLastPathComponent()
  guard dir.lastPathComponent=="test-"+id.uuidString,!fm.fileExists(atPath:store.path),let fixture=PhotoLayoutFixture.make("top") else {fatalError("Fresh owned root and geometric fixture required")}
  m.setPhoto(fixture.bytes)
  guard m.photoData==fixture.bytes,m.data.photoIDs.count==1 else {fatalError("Actual synthetic photo save required")}
  if name=="existing_adjustment" {m.adjustPhoto(PhotoAdjustment(clock:.top,automaticCrop:false,horizontal:0.4,vertical:0.4))}
  if name=="capacity_adjustment" {m.data.photoAdjustments=Dictionary(uniqueKeysWithValues:(0..<100).map { (String(format:"%064x",$0),PhotoAdjustment()) })}
  if name=="open_face" {m.data.face = .home;m.route = .app(.settings)}
  guard m.persist() else {fatalError("Valid photo baseline save required")}
  let before=try Snapshot.canonicalBytes(JSONEncoder().encode(m.data)),original=try Data(contentsOf:store),oldAdjustment=m.photoAdjustment,oldComposition=m.photoComposition,oldRoute=m.route,oldEntries=m.data.photoAdjustments
  let photo=dir.appendingPathComponent("photos/"+m.data.photoIDs[0]+".jpg"),photoBytes=try Data(contentsOf:photo)
  let preserved=dir.appendingPathComponent("before-fault.json"),canary=store.appendingPathComponent("owned-canary.txt"),marker=Data("OWNED_PHOTO_WRITE_CANARY".utf8)
  try fm.moveItem(at:store,to:preserved);try fm.createDirectory(at:store,withIntermediateDirectories:false);try marker.write(to:canary)
  func act() {
   switch name {
    case "existing_adjustment","capacity_adjustment":m.adjustPhoto(PhotoAdjustment(clock:.bottom,automaticCrop:false,horizontal:0.2,vertical:0.7))
    case "open_face":m.openPhotoFace()
    default:fatalError("Unknown case")
   }
  }
  act()
  var checks:[String:Bool]=["snapshot_unchanged":try Snapshot.canonicalBytes(JSONEncoder().encode(m.data))==before,"failure_visible":m.error != nil,"original_bytes_unchanged":try Data(contentsOf:preserved)==original,"canary_unchanged":try Data(contentsOf:canary)==marker,"photo_bytes_unchanged":try Data(contentsOf:photo)==photoBytes,"display_photo_unchanged":m.photoData==fixture.bytes,"route_unchanged":m.route==oldRoute]
  if name != "open_face" {checks["adjustment_unchanged"]=m.photoAdjustment==oldAdjustment;checks["composition_unchanged"]=m.photoComposition==oldComposition;checks["previous_entries_preserved"]=m.data.photoAdjustments==oldEntries}
  guard try Data(contentsOf:canary)==marker,try fm.contentsOfDirectory(atPath:store.path)==["owned-canary.txt"] else {fatalError("Owned fault identity mismatch")}
  try fm.removeItem(at:canary);try fm.removeItem(at:store);try fm.moveItem(at:preserved,to:store)
  let restored=AppModel();checks["restart_matches_original"]=try Snapshot.canonicalBytes(JSONEncoder().encode(restored.data))==before;checks["restart_original_photo"]=restored.photoData==fixture.bytes
  if args.contains("--retry-after-fault") {
   m.error=nil;act();let after=try Snapshot.canonicalBytes(JSONEncoder().encode(m.data))
   checks["retry_changes_expected_state"]=after != before;checks["retry_saved_exactly"]=try Snapshot.canonicalBytes(Data(contentsOf:store))==after;checks["retry_has_no_error"]=m.error==nil
   if name=="open_face" {checks["retry_photo_face_open"]=m.data.face == .photos && m.route == .face}
   else {checks["retry_exact_adjustment"]=m.photoAdjustment==PhotoAdjustment(clock:.bottom,automaticCrop:false,horizontal:0.2,vertical:0.7);checks["cache_still_bounded"]=m.data.photoAdjustments.count<=100;checks["retry_composition_changes_only_after_save"]=m.photoComposition != oldComposition}
   let restarted=AppModel();checks["restart_matches_retry"]=try Snapshot.canonicalBytes(JSONEncoder().encode(restarted.data))==after;checks["retry_photo_bytes_unchanged"]=try Data(contentsOf:photo)==photoBytes
  }
  let failed=checks.filter{!$0.value}.map(\.key).sorted();let r:[String:Any]=["case":name,"checks":checks,"failed":failed,"verdict":failed.isEmpty ? "PASS":"FAIL","assertions":checks.count,"owned_uuid":id.uuidString]
  print(String(data:try JSONSerialization.data(withJSONObject:r,options:[.sortedKeys]),encoding:.utf8)!)
 }
}
