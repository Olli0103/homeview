import SwiftUI

/// Clearly synthetic inbox. No HomeKit setup, real notification stream or alarm acknowledgement.
struct HouseNoticesView:View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var phase
  @State private var authentication:Task<Void,Never>?
  @State private var actionStatus=""
  private var groups:[HouseNoticeGroup] {
    model.houseNotices.groups(at:model.clock,allowed:model.noticeHouseholds,
      personalAccess:model.connections.personalUnlocked && phase == .active)
  }
  var body:some View {
    VStack(alignment:.leading,spacing:14) {
      HStack {
        Text("Mock house notices").font(.title2.bold())
        Spacer()
        Button("Done") {dismiss()}.frame(minWidth:60,minHeight:44).accessibilityIdentifier("notices.done")
      }
      Text("Synthetic events only · Demo house · Apple Home disconnected")
        .font(.subheadline).foregroundStyle(.secondary)
      HStack {
        Button("Load demo sequence") {model.loadHouseNoticeDemo()}
          .frame(minHeight:44).accessibilityIdentifier("notices.load")
        Spacer()
        Button("Clear") {model.clearHouseNotices()}
          .frame(minWidth:44,minHeight:44).accessibilityIdentifier("notices.clear")
      }
      Text(model.houseNoticeStatus).font(.caption).accessibilityIdentifier("notices.status")
      Text("\(groups.count) groups · \(groups.flatMap(\.rows).count) visible events")
        .font(.caption).accessibilityIdentifier("notices.count")
      HStack {
        if model.connections.personalUnlocked {
          Button("Hide private details") {model.lockPersonalAccess()}
            .frame(minHeight:44).accessibilityIdentifier("notices.lock")
        } else {
          Button("Unlock private demo details") {
            authentication?.cancel()
            authentication=Task {_ = await model.connections.unlock()}
          }.frame(minHeight:44).accessibilityIdentifier("notices.authenticate")
        }
      }
      Text("A demo profile is not authentication. Old events are retained but cannot open an action.")
        .font(.caption).foregroundStyle(.secondary)
      ScrollView {
        VStack(alignment:.leading,spacing:16) {
          if groups.isEmpty {Text("No visible demo notices").accessibilityIdentifier("notices.empty")}
          ForEach(groups) {group in
            VStack(alignment:.leading,spacing:8) {
              Text("Demo house · "+(group.source == .demoSequence ? "Mock sequence":"Mock sensor")+" · \(group.rows.count) events")
                .font(.subheadline.bold())
              ForEach(group.rows) {row in
                VStack(alignment:.leading,spacing:3) {
                  Text(row.title).font(.headline).accessibilityIdentifier("notice.title."+row.id.id)
                  Text(row.occurredAt.formatted(date:.abbreviated,time:.shortened))
                    .font(.caption).foregroundStyle(.secondary)
                  if row.stale {Text("Old event · Actions unavailable").font(.caption).accessibilityIdentifier("notice.stale."+row.id.id)}
                  Button("Open mock view") {
                    if model.openHouseNotice(row.id) {dismiss()}
                    else {actionStatus="Event unavailable or old. No device was changed."}
                  }.frame(minHeight:44)
                    .disabled(model.houseNotices.destination(for:row.id,at:model.clock,
                      allowed:model.noticeHouseholds,online:model.data.home.online)==nil)
                    .accessibilityIdentifier("notice.open."+row.id.id)
                }
                Divider()
              }
            }.padding(14).frame(maxWidth:.infinity,alignment:.leading)
              .background(.secondary.opacity(0.08),in:RoundedRectangle(cornerRadius:18))
              .accessibilityElement(children:.contain).accessibilityIdentifier("notice.group."+group.id.id)
          }
        }
      }.accessibilityIdentifier("notices.list")
      if !actionStatus.isEmpty {Text(actionStatus).font(.caption).accessibilityIdentifier("notices.action.status")}
    }.padding(20).buttonStyle(.plain)
      .onDisappear {authentication?.cancel();authentication=nil}
      .onChange(of:phase) {_,value in
        if value == .background {authentication?.cancel();model.lockPersonalAccess();dismiss()}
      }
  }
}
