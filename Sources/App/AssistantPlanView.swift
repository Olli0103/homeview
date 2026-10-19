import SwiftUI

struct AssistantPlanView:View {
  @Environment(AppModel.self) private var model
  var body:some View {
    if let plan=model.demoPlan {
      VStack(alignment:.leading,spacing:12) {
        Text("Local demo plan").font(.headline)
        Text("Mock values and foreground-only demo timers. No real Home, system-alarm scheduling, accounts, messages, calls, scenes or security actions.")
          .font(.system(size:14)).foregroundStyle(.secondary)
        Text(plan.note).font(.system(size:16,weight:.medium))
          .accessibilityIdentifier("assistant.plan.status")
        ForEach(Array(plan.steps.enumerated()),id:\.element.id) { index,step in
          VStack(alignment:.leading,spacing:4) {
            Text("\(index+1). "+step.operation.summary).font(.system(size:18,weight:.semibold))
            if index>0 { Text("Depends on confirmed step \(index)").font(.system(size:12)).foregroundStyle(.secondary) }
            Text(step.disposition.text).font(.system(size:14))
              .accessibilityIdentifier("assistant.plan.step.\(index)")
          }
        }
        if plan.phase == .preview {
          Text("Confirmation expires after 60 seconds. This is not device authentication. Each step requires a confirmed predecessor; completed steps are not rolled back.")
            .font(.system(size:13)).foregroundStyle(.secondary)
          Button("Run demo plan") { model.confirmDemoPlan(id:plan.id) }
            .buttonStyle(.borderedProminent).frame(minHeight:44)
            .accessibilityIdentifier("assistant.plan.confirm")
        }
        if plan.phase == .preview || plan.phase == .running {
          Button("Cancel plan") { model.cancelDemoPlan() }.frame(minHeight:44)
            .accessibilityIdentifier("assistant.plan.cancel")
        }
        if plan.phase == .completed || plan.phase == .stopped || plan.phase == .cancelled {
          Text("This plan cannot run again. A new request needs a new preview and confirmation. Plans are not resumed after restarting the app.")
            .font(.system(size:13)).foregroundStyle(.secondary)
        }
      }.padding(18).background(.blue.opacity(0.06),in:RoundedRectangle(cornerRadius:20))
        .padding(.horizontal,30).accessibilityElement(children:.contain)
        .accessibilityIdentifier("assistant.plan")
    }
  }
}
