
extension AssistantVoiceSession {func gateSetBoundary(_ operation:@escaping @MainActor () async->Void) {beforeStart=operation};var gateStartTask:Task<Void,Never>? {startTask} }
