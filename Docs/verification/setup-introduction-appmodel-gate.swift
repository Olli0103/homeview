import Foundation
@main struct IntroductionGate {
 @MainActor static func main() throws {
  let args=ProcessInfo.processInfo.arguments
  let index=args.firstIndex(of:"--persistence-test")!
  let root=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0]
    .appendingPathComponent("HomeViewReplica/test-"+args[index+1])
  let file=root.appendingPathComponent("mock-state.json")
  let scenario=args[args.firstIndex(of:"--scenario")!+1]
  let model=AppModel();var rows:[[String:Any]]=[]
  func check(_ id:String,_ passed:Bool){ rows.append(["id":id,"passed":passed]) }
  func stored()->String? { guard let bytes=try? Data(contentsOf:file),let object=try? JSONSerialization.jsonObject(with:bytes) as? [String:Any] else {return nil};return object["introduction"] as? String }
  model.presentIntroductionOnLaunch()
  if scenario=="readonly" {
   let before=try Data(contentsOf:file)
   check("read-only-does-not-auto-trap-in-introduction",model.storeReadOnly && !model.showingIntroduction)
   model.showingIntroduction=true
   check("manual-read-only-introduction-can-close",model.endIntroduction(deferred:true) && !model.showingIntroduction)
   check("newer-store-bytes-preserved",try Data(contentsOf:file)==before)
  } else if scenario=="writefail" {
   try FileManager.default.createDirectory(at:file,withIntermediateDirectories:true)
   check("failed-completion-not-recorded",!model.endIntroduction(deferred:false) && model.data.introduction == .pending && model.showingIntroduction)
   check("failed-deferral-still-closes",model.endIntroduction(deferred:true) && model.data.introduction == .pending && !model.showingIntroduction)
   check("failure-does-not-pretend-durable-success",stored()==nil && model.error?.contains("without saving")==true)
  } else {
   check("new-owned-store-starts-pending",model.showingIntroduction && model.data.introduction == .pending)
   check("opening-introduction-no-connection-effect",model.connections.requested.isEmpty && model.connections.enabled.isEmpty && !model.connections.personalUnlocked)
   check("deferred-is-durable",model.endIntroduction(deferred:true) && stored()=="deferred")
   let deferredRestart=AppModel();deferredRestart.presentIntroductionOnLaunch()
   check("deferred-restart-stays-closed",!deferredRestart.showingIntroduction)
   model.showingIntroduction=true
   check("completed-is-durable",model.endIntroduction(deferred:false,openConnections:true) && stored()=="completed" && model.route == .app(.settings))
   model.showingIntroduction=true
   check("closing-reopened-intro-keeps-completed-choice",model.endIntroduction(deferred:true) && stored()=="completed")
   let completedRestart=AppModel();completedRestart.presentIntroductionOnLaunch()
   check("completed-restart-no-permission-or-connection",!completedRestart.showingIntroduction && completedRestart.connections.requested.isEmpty && !completedRestart.connections.personalUnlocked)
  }
  print(String(decoding:try JSONSerialization.data(withJSONObject:rows,options:[.sortedKeys]),as:UTF8.self))
  exit(rows.allSatisfy{$0["passed"] as? Bool==true} ? 0:1)
 }
}
