import SwiftUI

struct WatchModularFace: View {
  @Environment(AppModel.self) private var model
  let face: Face
  var body: some View {
    ZStack(alignment: .topLeading) {
      Color.black
      if let rect = face.definition.clockRect {
        Group {
          if face == .modularCompact {
            AnalogClock(date: model.clock, timeZone: model.displayTimeZone, tint: .white)
          } else {
            Text(model.clock, style: .time).environment(\.timeZone, model.displayTimeZone)
              .font(.system(size: 96, weight: .medium, design: .rounded)).monospacedDigit()
              .minimumScaleFactor(0.6).lineLimit(1)
          }
        }.frame(width: rect.width, height: rect.height).position(x: rect.midX, y: rect.midY)
      }
      ForEach(face.definition.placements, id: \.slot.id) { placement in
        let slot = placement.slot
        let kind = model.data.complication(for: face, slot: slot)
        Button {
          activate(kind)
        } label: {
          ComplicationContent(kind: kind, family: slot.family, face: face)
            .padding(slot.family == .circular ? 12 : 0)
            .frame(
              width: placement.rect.width, height: placement.rect.height,
              alignment: slot.family == .circular ? .center : .leading
            )
            .background {
              if slot.family == .circular { Circle().fill(.white.opacity(0.06)) }
            }
            .contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(kind == .none)
          .accessibilityIdentifier("complication.slot.\(slot.id)")
          .accessibilityLabel("\(slot.title), \(kind.rawValue)")
          .position(x: placement.rect.midX, y: placement.rect.midY)
      }
    }.frame(width: 600, height: 600).foregroundStyle(.white)
  }
  private func activate(_ kind: ComplicationKind) {
    switch kind {
    case .date, .calendar: model.navigate(.calendar)
    case .music: model.navigate(.music)
    case .weather: model.navigate(.weather)
    case .timer: model.navigate(.timers)
    case .clock: model.navigate(.worldClock)
    case .none: break
    }
  }
}
struct ComplicationContent: View {
  @Environment(AppModel.self) private var model
  let kind: ComplicationKind
  let family: ComplicationFamily
  let face: Face
  private var accent: Color { model.data.configuration(for: face).theme == 1 ? .mint : .orange }
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      switch kind {
      case .none: Color.clear
      case .date:
        if family == .inline {
          Text(model.dateLabel("EEEE, MMM d")).foregroundStyle(accent)
        } else {
          Text(model.dateLabel("EEE").uppercased()).foregroundStyle(accent)
          Text(model.dateLabel("d")).font(
            .system(size: family == .circular ? 48 : 66, weight: .medium, design: .rounded))
        }
      case .clock:
        if family != .inline { Image(systemName: "globe").foregroundStyle(.cyan) }
        Text(model.dateLabel("HH:mm")).monospacedDigit()
      case .weather:
        Image(systemName: model.connections.weatherSymbol).foregroundStyle(
          .cyan)
        Text(model.connections.weatherTemperature)
        if !family.isCompact { Text(model.connections.weatherCondition) }
      case .timer:
        Image(systemName: "timer").foregroundStyle(accent)
        Text(model.data.timers.first?.display(at: model.now) ?? "No timers").monospacedDigit()
      case .calendar:
        Text("UP NEXT").foregroundStyle(accent).font(.system(size: 23, weight: .semibold))
        if model.connections.enabled.contains(.calendar) {
          Text(
            model.connections.personalUnlocked
              ? (model.connections.events.first?.title ?? "No events") : "Unlock calendar")
        } else {
          Text("Family dinner")
          Text("6:00 PM · Home").font(.system(size: 26)).foregroundStyle(.secondary)
        }
      case .music:
        Image(systemName: "music.note").foregroundStyle(.pink)
        Text(model.currentMusicTitle)
        Text(model.currentMusicArtist).font(.system(size: 24)).foregroundStyle(.secondary)
      }
    }.font(.system(size: family.isCompact ? 28 : 38, weight: .medium))
      .lineLimit(2).minimumScaleFactor(0.6)
  }
}
struct FaceEditor: View {
  @Environment(AppModel.self) private var model
  private struct Selection: Identifiable {
    let face: Face
    let slot: FaceSlot
    var id: String { face.id + "." + slot.id }
  }
  @State private var selection: Selection?
  @State private var highlightedSlot: String?
  private var face: Face { model.data.face }
  private func select(_ slot: FaceSlot) {
    highlightedSlot = slot.id
    selection = Selection(face: face, slot: slot)
  }
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Faces").font(.system(size: 30, weight: .bold))
        Spacer()
        Button("Done") {
          model.persist()
          model.route = .face
        }
        .accessibilityIdentifier("editor.done")
      }.padding(.horizontal, 28).padding(.vertical, 16)
      ScrollView {
        VStack(spacing: 18) {
          ScrollView(.horizontal) {
            HStack(spacing: 10) {
              ForEach(Face.allCases) { face in
                Button {
                  selection = nil
                  highlightedSlot = nil
                  model.data.face = face
                  model.persist()
                } label: {
                  Text(face.rawValue).font(.system(size: 17, weight: .medium))
                    .padding(.horizontal, 18).frame(height: 48)
                    .background(
                      model.data.face == face ? .lilac : .gray.opacity(0.12), in: Capsule())
                }.accessibilityIdentifier("select.\(face.rawValue)")
              }
            }.padding(.horizontal, 28)
          }
          editorPreview
          if face.definition.options.contains(.flowTypeface) {
            flowOptions
          } else if face.definition.options.contains(.color) {
            HStack {
              Text("Color")
              Spacer()
              ForEach(0..<2) { i in
                Button {
                  model.data.editConfiguration(for: model.data.face) { $0.theme = i }
                  // Home panels retain their legacy color binding.
                  if [.home, .homeClock].contains(model.data.face) { model.data.theme = i }
                  model.persist()
                } label: {
                  Circle().fill(
                    face == .modular
                      ? (i == 0 ? .mist : Color(red: 0.73, green: 0.76, blue: 0.63))
                      : face == .home || face == .homeClock
                        ? (i == 0 ? .purple : .teal)
                        : (i == 0 ? .orange : .mint)
                  ).frame(width: 34, height: 34)
                    .overlay(
                      Circle().stroke(
                        .black.opacity(
                          model.data.configuration(for: model.data.face).theme == i ? 0.8 : 0),
                        lineWidth: 3
                      ).padding(-3))
                }.accessibilityLabel(colorLabel(i))
                  .accessibilityValue(
                    model.data.configuration(for: model.data.face).theme == i
                      ? "Selected" : "Not selected")
              }
            }.padding(.horizontal, 32)
          }
          if !model.data.face.slots.isEmpty {
            Text("Complications").font(.system(size: 20, weight: .semibold))
              .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 32)
            ForEach(Array(model.data.face.slots.enumerated()), id: \.element.id) { i, slot in
              Button {
                select(slot)
              } label: {
                HStack {
                  VStack(alignment: .leading) {
                    Text(slot.title)
                    Text(slot.family.title)
                      .font(.system(size: 13)).foregroundStyle(.secondary)
                  }
                  Spacer()
                  Text(model.data.complication(for: model.data.face, slot: slot).rawValue)
                  Image(systemName: "chevron.right").font(.system(size: 14))
                }.padding(.horizontal, 18).padding(.vertical, 10)
                  .background(.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
              }.accessibilityIdentifier("widget.\(i)")
                .padding(.horizontal, 28)
            }
          }
        }.padding(.bottom, 28)
      }.accessibilityIdentifier("editor.content")
    }.foregroundStyle(.black).background(.white).buttonStyle(.plain)
      .sheet(item: $selection) { selected in
        let slot = selected.slot
        VStack(spacing: 16) {
          HStack {
            Text(slot.title).font(.title2.bold())
            Spacer()
            Button("Done") { selection = nil }.accessibilityIdentifier("complications.done")
          }
          ScrollView {
            ForEach(slot.choices) { kind in
              Button {
                model.data.setComplication(kind, for: selected.face, slot: slot)
                model.persist()
                selection = nil
              } label: {
                HStack {
                  Text(kind.rawValue)
                  Spacer()
                  if model.data.complication(for: selected.face, slot: slot) == kind {
                    Image(systemName: "checkmark")
                  }
                }.padding().frame(maxWidth: .infinity)
                  .background(.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
              }.accessibilityIdentifier("complication.choose.\(kind.rawValue)")
            }
          }
        }.padding(24).foregroundStyle(.primary).presentationDetents([.medium, .large])
      }
  }
  private func colorLabel(_ index: Int) -> String {
    if face == .modular { return index == 0 ? "Mist style" : "Sage style" }
    if face == .home || face == .homeClock { return index == 0 ? "Purple style" : "Teal style" }
    return index == 0 ? "Orange style" : "Mint style"
  }
  private var editorPreview: some View {
    VStack(spacing: 8) {
      ZStack(alignment: .topLeading) {
        FaceView(selection: face).allowsHitTesting(false).accessibilityHidden(true)
        ForEach(face.definition.placements, id: \.slot.id) { placement in
          let slot = placement.slot
          Button {
            select(slot)
          } label: {
            RoundedRectangle(cornerRadius: slot.family == .circular ? 80 : 18)
              .fill(.cyan.opacity(highlightedSlot == slot.id ? 0.22 : 0.05))
              .overlay {
                RoundedRectangle(cornerRadius: slot.family == .circular ? 80 : 18)
                  .strokeBorder(.cyan, lineWidth: highlightedSlot == slot.id ? 6 : 3)
              }
              .overlay {
                if model.data.complication(for: face, slot: slot) == .none {
                  Image(systemName: "plus").font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.cyan)
                }
              }
          }.frame(width: placement.rect.width, height: placement.rect.height)
            .position(x: placement.rect.midX, y: placement.rect.midY)
            .accessibilityIdentifier("preview.slot.\(slot.id)")
            .accessibilityLabel(
              "\(slot.title), \(slot.family.title), \(model.data.complication(for: face, slot: slot).rawValue)"
            )
            .accessibilityHint("Choose complication")
        }
      }.frame(width: 600, height: 600).scaleEffect(0.4).frame(width: 240, height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 24))
      if !face.slots.isEmpty {
        Text("Tap an outlined area to edit").font(.system(size: 15)).foregroundStyle(.secondary)
      }
    }
  }
  private var flowOptions: some View {
    VStack(spacing: 14) {
      HStack {
        Text("Typeface")
        Spacer()
        ForEach(0..<2) { i in
          Button {
            model.data.editConfiguration(for: .flow) { $0.flowTypeface = i }
            model.persist()
          } label: {
            Text(i == 0 ? "I" : "II").frame(width: 55, height: 38)
              .background(
                model.data.configuration(for: .flow).flowTypeface == i
                  ? .lilac : .gray.opacity(0.12), in: Capsule())
          }.accessibilityIdentifier("flow.typeface.\(i)")
        }
      }
      Toggle(
        "Background",
        isOn: Binding(
          get: { model.data.configuration(for: .flow).flowBackground },
          set: { value in
            model.data.editConfiguration(for: .flow) { $0.flowBackground = value }
            model.persist()
          })
      ).accessibilityIdentifier("flow.background")
    }.font(.system(size: 20)).padding(.horizontal, 32)
  }
}
