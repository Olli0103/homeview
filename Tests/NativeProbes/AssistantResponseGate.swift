import Foundation

@main struct AssistantResponseGate {
  @MainActor static func main() throws {
    guard ProcessInfo.processInfo.arguments.contains("--uitesting"),
      !ProcessInfo.processInfo.arguments.contains("--system-alarms"),
      Bundle.main.url(forResource:"demo-tone",withExtension:"wav")==nil else {fatalError("Local probe only")}
    let m=AppModel();var checks:[String:Bool]=[:]
    func state()throws->Data {try Snapshot.canonicalBytes(JSONEncoder().encode(m.data))}
    let initial=try state(),draft="plan: temperature 90; timer for 10 seconds"
    m.assistantInput=draft
    m.showAssistantExample(.recipe)
    checks["outside_assistant_rejected"]=m.assistantDocument==nil && m.route == .face
    m.route = .assistant;m.setAnswerSpeechForeground(true)
    for example in AssistantResponseExample.allCases {
      m.showAssistantExample(example)
      checks[example.rawValue+"_exact_document"]=m.assistantDocument==example.document
      checks[example.rawValue+"_readout_text_matches"]=m.answerReadoutText==example.document.text
      checks[example.rawValue+"_draft_not_sent"]=m.assistantInput==draft
      checks[example.rawValue+"_no_state_mutation"]=try state()==initial
      checks[example.rawValue+"_no_pending_actions"]=m.demoPlan==nil && m.route == .assistant
    }
    m.openAssistantExampleRecipe()
    checks["non_recipe_document_cannot_open"]=m.route == .assistant
    m.showAssistantExample(.recipe);m.setAnswerSpeechForeground(false)
    m.openAssistantExampleRecipe();m.showAssistantExample(.knowledge)
    checks["inactive_selection_and_action_rejected"]=m.route == .assistant && m.assistantDocument==AssistantResponseExample.recipe.document
    m.setAnswerSpeechForeground(true);m.assistantUsesAI=true
    m.showAssistantExample(.knowledge);m.openAssistantExampleRecipe()
    checks["AI_mode_cannot_select_or_execute_cards"]=m.route == .assistant && m.assistantDocument==AssistantResponseExample.recipe.document
    m.assistantUsesAI=false;m.openAssistantExampleRecipe()
    checks["explicit_recipe_opens_only_bundled_route"]=m.route == .recipe && m.assistantDocument==nil
    checks["recipe_action_no_state_mutation"]=try state()==initial
    checks["recipe_action_keeps_draft"]=m.assistantInput==draft
    m.route = .assistant;m.showAssistantExample(.knowledge);m.assistantReply="New plain answer [run](homeview://temperature/99)"
    checks["plain_answer_does_not_become_card"]=m.assistantDocument==nil
    checks["plain_answer_no_state_mutation"]=try state()==initial
    m.showAssistantExample(.agenda);m.route = .face
    checks["navigation_discards_document"]=m.assistantDocument==nil
    m.route = .assistant;m.showAssistantExample(.recipe);m.lockPersonalAccess()
    checks["lock_discards_document_and_draft"]=m.assistantDocument==nil && m.assistantInput.isEmpty
    m.showAssistantExample(.knowledge);m.assistantInput="SYNTHETIC unknown question";m.runAssistant()
    checks["new_sent_question_discards_document"]=m.assistantDocument==nil
    checks["all_state_unchanged"]=try state()==initial
    checks["no_system_IDs"]=m.data.nativeTimerIDs.isEmpty && m.data.nativeAlarmIDs.isEmpty
    let failures=checks.filter {!$0.value}.map(\.key).sorted()
    print(String(data:try JSONSerialization.data(withJSONObject:["checks":checks,"assertions":checks.count,"failed":failures,"verdict":failures.isEmpty ? "PASS":"FAIL"],options:[.sortedKeys]),encoding:.utf8)!)
  }
}
