
extension AppModel {
 var gatePlanStore:URL { store }
 var gatePlanEphemeral:Bool { ephemeral }
 func gateSetPlanScheduler(_ callback:@escaping @MainActor () async -> Void) { demoPlanBeforeStep=callback }
 func gateExpireDemoPlan() {
  guard let previous=demoPlan,case .proposal(let expired)=DemoActionPlan.parse(previous.request,context:personalSessionGeneration,uptime:ProcessInfo.processInfo.systemUptime-61) else { fatalError("Owned expiry setup failed") }
  demoPlan=expired
 }
}
