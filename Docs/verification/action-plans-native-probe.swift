import Foundation

@MainActor final class StepGate {
  private var pending:[CheckedContinuation<Void,Never>]=[]
  var count:Int { pending.count }
  func hold() async { await withCheckedContinuation { pending.append($0) } }
  func release() { precondition(!pending.isEmpty);pending.removeFirst().resume() }
}
@main struct NativePlanGate {
  @MainActor static func main() async throws {
    let args=ProcessInfo.processInfo.arguments
    guard let arg=args.firstIndex(of:"--case"),args.indices.contains(arg+1),
      let storeArg=args.firstIndex(of:"--persistence-test"),args.indices.contains(storeArg+1),
      let uid=UUID(uuidString:args[storeArg+1]) else { fatalError("Owned case and test UUID required") }
    let scenario=args[arg+1],model=AppModel()
    precondition(model.gatePlanStore.deletingLastPathComponent().lastPathComponent=="test-"+uid.uuidString)
    precondition(!model.gatePlanEphemeral)
    model.route = .assistant;model.setAnswerSpeechForeground(true)
    var assertions=0
    func require(_ value:Bool,_ description:String) { assertions+=1;precondition(value,description) }
    func preview(_ text:String="plan: temperature 72; brightness 30") {
      model.assistantInput=text;model.runAssistant()
      require(model.demoPlan?.phase == .preview,"Must preview, not execute")
    }
    func stored()->Snapshot { try! Snapshot.decodeMigrating(Data(contentsOf:model.gatePlanStore)) }
    func wait(_ predicate:()->Bool) async throws {
      let until=ContinuousClock.now.advanced(by:.seconds(4))
      while !predicate() && ContinuousClock.now<until { try await Task.sleep(for:.milliseconds(1)) }
      require(predicate(),"Controlled async boundary timed out")
    }
    require(model.persist(),"Create the owned baseline fixture explicitly; initialization does not save it")
    switch scenario {
    case "preview":
      let before=try Data(contentsOf:model.gatePlanStore)
      preview("plan: temperature 72; brightness 30; timer for 1 hour")
      require(model.data.home.temperature==68 && model.data.timers.isEmpty,"Preview cannot mutate")
      require(try Data(contentsOf:model.gatePlanStore)==before,"Preview cannot save plan effects")
      require(!model.confirmDemoPlan(id:UUID()),"Wrong plan ID cannot confirm")
      model.cancelDemoPlan();require(model.demoPlan?.phase == .cancelled,"Cancel preview")
      require(model.data.home.temperature==68 && model.data.timers.isEmpty,"Cancelled preview has no effects")
    case "success_replay":
      preview("plan: temperature 72; brightness 30; timer for 1 hour named Native synthetic")
      let id=model.demoPlan!.id,timerID=model.demoPlan!.steps[2].id
      require(model.confirmDemoPlan(id:id),"Explicit confirm")
      require(!model.confirmDemoPlan(id:id),"Repeated confirmation rejected before await")
      try await wait { !model.demoPlanBusy }
      require(model.demoPlan?.phase == .completed && model.demoPlan?.confirmedCount==3,"All actual receipts")
      let disk=stored()
      require(disk.home.temperature==72 && disk.home.brightness==30,"Actual saved mock values")
      require(disk.timers.count==1 && disk.timers[0].id==timerID && disk.timers[0].duration==3600,"Actual saved stable timer")
      require(disk.nativeTimerIDs.isEmpty && model.nativeSchedulesInFlight==0,"No OS alarm schedule")
      require(!model.confirmDemoPlan(id:id),"Finished plan cannot replay")
      require(stored().timers.count==1,"No duplicate timer")
    case "middle_failure":
      model.data.home.online=false;require(model.persist(),"Owned offline setup")
      preview("plan: timer for 1 hour named Native first; temperature 72; brightness 30")
      require(model.confirmDemoPlan(id:model.demoPlan!.id),"Explicit partial plan")
      try await wait { !model.demoPlanBusy }
      require(model.demoPlan?.phase == .stopped && model.demoPlan?.confirmedCount==1,"Actual middle failure, not overall success")
      require(model.demoPlan?.steps[2].disposition == .dependencyNotMet,"Dependent step never ran")
      let disk=stored();require(disk.timers.count==1 && disk.timers[0].title=="Native first","First effect retained")
      require(disk.home.temperature==68 && disk.home.brightness==75,"Later values not fabricated")
      require(disk.home.audit.isEmpty,"Neither failed nor dependent mock action was applied")
    case "expiry_context":
      preview();model.gateExpireDemoPlan()
      require(!model.confirmDemoPlan(id:model.demoPlan!.id),"Actual AppModel rejects expired plan")
      require(model.data.home.temperature==68,"Expiry has no effect")
      preview();let id=model.demoPlan!.id;model.lockPersonalAccess()
      require(!model.confirmDemoPlan(id:id) && model.demoPlan==nil,"Lock revokes plan")
      require(stored().home.temperature==68,"Lock does not mutate")
    case "cancel_prestart":
      preview("plan: timer for 1 hour; temperature 72")
      let id=model.demoPlan!.id
      let caller=Task { @MainActor in model.confirmDemoPlan(id:id) };caller.cancel()
      require(!(await caller.value),"Pre-cancelled caller cannot start")
      require(model.demoPlan?.phase == .preview,"Unconsumed preview")
      require(model.confirmDemoPlan(id:id),"Ordinary explicit approval")
      model.cancelDemoPlan();await Task.yield()
      require(model.demoPlan?.phase == .cancelled,"Immediate cancellation")
      require(stored().timers.isEmpty && stored().home.temperature==68,"No effect before first step")
    case "cancel_midstep":
      let gate=StepGate();model.gateSetPlanScheduler { await gate.hold() }
      preview("plan: timer for 1 hour; temperature 72; brightness 30")
      require(model.confirmDemoPlan(id:model.demoPlan!.id),"Explicit approval")
      try await wait { gate.count==1 };gate.release()
      try await wait { gate.count==1 && model.demoPlan?.confirmedCount==1 }
      model.cancelDemoPlan();gate.release();await Task.yield()
      require(model.demoPlan?.phase == .cancelled && model.demoPlan?.confirmedCount==1,"Cancel preserves first receipt")
      let disk=stored();require(disk.timers.count==1 && disk.home.temperature==68 && disk.home.brightness==75,"No later local mutations")
    case "late_completion_new_plan":
      let gate=StepGate();model.gateSetPlanScheduler { await gate.hold() }
      preview("plan: timer for 1 hour; temperature 72")
      require(model.confirmDemoPlan(id:model.demoPlan!.id),"First approval")
      try await wait { gate.count==1 };model.cancelDemoPlan()
      preview("plan: temperature 74; brightness 40")
      let next=model.demoPlan!.id;require(model.confirmDemoPlan(id:next),"New approval")
      try await wait { gate.count==2 };gate.release();await Task.yield()
      require(model.demoPlan?.id==next && model.demoPlanBusy,"Old completion cannot clear new plan")
      gate.release();try await wait { gate.count==1 && model.demoPlan?.confirmedCount==1 }
      gate.release();try await wait { !model.demoPlanBusy }
      require(stored().home.temperature==74 && stored().home.brightness==40 && stored().timers.isEmpty,"Only new plan effects")
    case "save_failure":
      preview();let folder=model.gatePlanStore.deletingLastPathComponent()
      let attributes=try FileManager.default.attributesOfItem(atPath:folder.path),mode=attributes[.posixPermissions] as! NSNumber
      try FileManager.default.setAttributes([.posixPermissions:0o500],ofItemAtPath:folder.path)
      defer { try? FileManager.default.setAttributes([.posixPermissions:mode],ofItemAtPath:folder.path) }
      require(!FileManager.default.isWritableFile(atPath:folder.path),"Fault fixture actually denies directory writes")
      require(model.confirmDemoPlan(id:model.demoPlan!.id),"Explicit failing save")
      try await wait { !model.demoPlanBusy }
      guard case .failed = model.demoPlan!.steps[0].disposition else { fatalError("Verified unchanged write failure was not classified") }
      require(model.data.home.temperature==68 && stored().home.temperature==68,"Saved read-back confirms no step effect")
      require(model.demoPlan?.steps[1].disposition == .dependencyNotMet,"Failure stops dependency")
      require(!model.storeReadOnly,"Verified unchanged state is not mislabeled uncertain")
    case "unverified_store":
      preview();let folder=model.gatePlanStore.deletingLastPathComponent(),retired=folder.appendingPathExtension("plan-retired")
      let before=try Data(contentsOf:model.gatePlanStore)
      require(!FileManager.default.fileExists(atPath:retired.path),"One-use owned retire path")
      try FileManager.default.moveItem(at:folder,to:retired)
      let canary=Data("SYNTHETIC_PLAN_DIRECTORY_CANARY".utf8);try canary.write(to:folder)
      require(model.confirmDemoPlan(id:model.demoPlan!.id),"Explicit unverified save")
      try await wait { !model.demoPlanBusy }
      guard case .unverified = model.demoPlan!.steps[0].disposition else { fatalError("Unverifiable storage must not become success or no-effect certainty") }
      require(model.storeReadOnly,"Uncertain state fences future persistence")
      require(try Data(contentsOf:folder)==canary,"Unowned replacement canary unchanged")
      require(try Data(contentsOf:retired.appendingPathComponent("mock-state.json"))==before,"Captured old snapshot preserved")
      require(model.demoPlan?.steps[1].disposition == .dependencyNotMet,"No continuation after uncertainty")
    case "ai_answer_only":
      model.selectAssistantAnswers(true)
      model.assistantInput="plan: temperature 72; timer for 1 hour";model.runAssistant()
      try await wait { !model.assistantAI.busy }
      require(model.demoPlan==nil,"Answer-only mode cannot create an action plan")
      require(stored().home.temperature==68 && stored().timers.isEmpty,"Answer does not mutate")
    default:fatalError("Unknown owned case")
    }
    print(String(data:try JSONSerialization.data(withJSONObject:["case":scenario,"assertions":assertions,"storeID":uid.uuidString,"Home_constructed":false,"real_system_timer_scheduled":false],options:[.sortedKeys]),encoding:.utf8)!)
  }
}
