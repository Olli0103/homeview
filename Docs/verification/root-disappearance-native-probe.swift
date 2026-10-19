import AppKit
import SwiftUI
import Foundation
@MainActor @Observable final class ProbeState { var visible=true;var phase=ScenePhase.active;var appeared=false;var disappeared=false }
struct ProbeHost:View {
 let model:AppModel;let state:ProbeState
 var body:some View {
  Group {
   if state.visible { RootView().environment(model).environment(\.scenePhase,state.phase)
    .onAppear { state.appeared=true }.onDisappear { state.disappeared=true } }
   else { Color.black }
  }
 }
}
@main struct RootDisappearanceGate {
 @MainActor static func main() {
  NSApplication.shared.setActivationPolicy(.accessory)
  Task { @MainActor in
   do {try await run();exit(0)} catch {print("PREPARATION_ERROR",String(describing:error));exit(2)}
  }
  NSApplication.shared.run()
 }
 enum ProbeError:Error {case invalidFixture,timeout(String)}
 @MainActor static func wait(_ name:String,_ ready:()->Bool) async throws {
  let deadline=ContinuousClock.now.advanced(by:.seconds(5))
  while !ready() {guard ContinuousClock.now<deadline else {throw ProbeError.timeout(name)};try await Task.sleep(for:.milliseconds(20))}
 }
 @MainActor static func run() async throws {
  let a=ProcessInfo.processInfo.arguments
  guard a.contains("--uitesting"),let i=a.firstIndex(of:"--persistence-test"),a.indices.contains(i+1),let id=UUID(uuidString:a[i+1]),!a.contains("--reset-test-store"),!a.contains("--system-alarms"),Bundle.main.url(forResource:"demo-tone",withExtension:"wav")==nil else {throw ProbeError.invalidFixture}
  let m=AppModel(),fm=FileManager.default
  guard m.gateStoreURL.deletingLastPathComponent().lastPathComponent=="test-"+id.uuidString,!fm.fileExists(atPath:m.gateStoreURL.path) else {throw ProbeError.invalidFixture}
  m.data.keepDisplayOn=false;m.data.volume=0;m.idleSeconds=3600;m.lastInteraction=Date()
  m.signIn("Alex");_ = await m.connections.unlock();await m.connections.connect(.calendar)
  m.route = .app(.calendar);m.pendingPage=nil;m.messageText="SYNTHETIC_PRIVATE_DRAFT";m.assistantInput="SYNTHETIC_ASSISTANT_DRAFT"
  guard m.profile=="Alex",m.connections.personalUnlocked,!m.connections.events.isEmpty,m.persist() else {throw ProbeError.invalidFixture}
  let before=try Data(contentsOf:m.gateStoreURL),generation=m.personalSessionGeneration
  let s=ProbeState(),v=NSHostingView(rootView:ProbeHost(model:m,state:s)),window=NSWindow(contentRect:NSRect(x:-4000,y:-4000,width:820,height:900),styleMask:[.borderless],backing:.buffered,defer:false)
  window.contentView=v;window.orderBack(nil)
  try await wait("actual root appeared"){s.appeared && m.localResetForeground && m.answerSpeechForeground}
  var checks:[String:Bool]=["active_root_keeps_unlocked_fixture":m.connections.personalUnlocked && !m.connections.events.isEmpty && m.profile=="Alex","display_wake_disabled":!m.display.active]
  s.phase = .inactive
  try await wait("actual inactive callback"){!m.localResetForeground && !m.answerSpeechForeground}
  checks["inactive_does_not_revoke_authentication"]=m.connections.personalUnlocked && m.personalSessionGeneration==generation
  checks["inactive_keeps_cache_and_drafts"] = !m.connections.events.isEmpty && m.profile=="Alex" && !m.messageText.isEmpty && !m.assistantInput.isEmpty
  s.phase = .active
  try await wait("actual active callback"){m.localResetForeground && m.answerSpeechForeground}
  s.visible=false
  try await wait("actual root disappearance"){s.disappeared && !m.localResetForeground && !m.answerSpeechForeground}
  checks["actual_root_disappeared_while_phase_active"]=s.phase == .active && s.disappeared
  checks["disappearance_revokes_authentication"] = !m.connections.personalUnlocked
  checks["disappearance_clears_calendar_cache"] = m.connections.events.isEmpty
  checks["disappearance_clears_profile"] = m.profile==nil
  checks["disappearance_clears_message_draft"] = m.messageText.isEmpty
  checks["disappearance_clears_assistant_draft"] = m.assistantInput.isEmpty
  checks["disappearance_invalidates_generation"] = m.personalSessionGeneration>generation
  checks["disappearance_gates_personal_route"] = m.route == .privacy && m.pendingPage == .calendar
  checks["locking_does_not_delete_saved_fixture"] = try Data(contentsOf:m.gateStoreURL)==before
  checks["no_system_alarm_ids"] = m.data.nativeTimerIDs.isEmpty && m.data.nativeAlarmIDs.isEmpty
  window.orderOut(nil)
  let failed=checks.filter{!$0.value}.map(\.key).sorted()
  let result:[String:Any]=["checks":checks,"failed":failed,"assertions":checks.count,"verdict":failed.isEmpty ? "PASS":"FAIL","owned_uuid":id.uuidString,"actual_RootView":true,"synthetic_scene_phase":true,"physical_window_scene_test":false,"audio_asset_present":false]
  print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
 }
}
