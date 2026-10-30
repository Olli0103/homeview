import CoreGraphics
import Foundation

/// Native configuration reconstructed from slot descriptors, not a private API adapter.
enum ComplicationKind: String, CaseIterable, Codable, Identifiable, Sendable {
  case none = "Off"
  case date = "Date"
  case clock = "Clock"
  case music = "Music"
  case weather = "Weather"
  case calendar = "Calendar"
  case timer = "Timer"
  var id: String { rawValue }
}
enum ComplicationFamily: String, Codable, Sendable {
  case small, large, panel, circular, rectangular, inline
  var title: String { rawValue.capitalized }
  var isCompact: Bool { [.small, .circular, .inline].contains(self) }
}
struct FaceSlot: Identifiable, Equatable, Sendable {
  let id: String
  let title: String
  let family: ComplicationFamily
  var choices: [ComplicationKind] {
    switch family {
    case .small, .circular: [.none, .date, .clock, .weather, .timer]
    case .large, .rectangular: [.none, .calendar, .music, .weather, .timer]
    case .inline: [.none, .date, .clock]
    case .panel: ComplicationKind.allCases
    }
  }
}
struct FaceConfiguration: Codable, Equatable, Sendable {
  var complications: [String: ComplicationKind] = [:]
  var theme = 0
  var flowTypeface = 0
  var flowBackground = true
  var flowPalette = 0
}
extension FaceConfiguration {
  private static let knownSlotIDs = Set(Face.allCases.flatMap(\.slots).map(\.id))
  private enum CodingKeys: String, CodingKey { case complications, theme, flowTypeface, flowBackground, flowPalette }
  private struct SlotKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
  }
  /// A later option or one unknown widget must not discard a saved face's
  /// healthy sibling settings. Non-object entries still fail at the table level.
  init(from decoder: any Decoder) throws {
    self.init()
    let values = try decoder.container(keyedBy:CodingKeys.self)
    if let raw = try? values.decode(Int.self,forKey:.theme), (0...1).contains(raw) { theme = raw }
    if let raw = try? values.decode(Int.self,forKey:.flowTypeface), (0...2).contains(raw) { flowTypeface = raw }
    flowBackground = (try? values.decode(Bool.self,forKey:.flowBackground)) ?? true
    if let raw = try? values.decode(Int.self,forKey:.flowPalette), (0...7).contains(raw) { flowPalette = raw }
    if let slots = try? values.nestedContainer(keyedBy:SlotKey.self,forKey:.complications) {
      let keys = slots.allKeys.filter { !$0.stringValue.isEmpty && $0.stringValue.count <= 128 }
        .sorted {
          let left = Self.knownSlotIDs.contains($0.stringValue)
          let right = Self.knownSlotIDs.contains($1.stringValue)
          return left == right ? $0.stringValue < $1.stringValue : left
        }
      for key in keys {
        if complications.count == 64 { break }
        guard let raw = try? slots.decode(String.self,forKey:key),
              let kind = ComplicationKind(rawValue:raw) else { continue }
        complications[key.stringValue] = kind
      }
    }
  }
}
/// Public SwiftUI layout data. Coordinates are our 600-point adaptation, not Watch metrics.
struct SlotPlacement: Sendable {
  let slot: FaceSlot
  let rect: CGRect
  let defaultKind: ComplicationKind
}
enum FaceOption: Equatable, Sendable { case color, flowTypeface, flowBackground }
struct FaceDefinition: Sendable {
  var placements: [SlotPlacement] = []
  var clockRect: CGRect? = nil
  var options: [FaceOption] = []
  var slots: [FaceSlot] { placements.map(\.slot) }
}
extension Face {
  var definition: FaceDefinition {
    func place(
      _ id: String, _ title: String, _ family: ComplicationFamily,
      _ kind: ComplicationKind, _ x: Double, _ y: Double,
      _ width: Double, _ height: Double
    ) -> SlotPlacement {
      SlotPlacement(
        slot: FaceSlot(id: id, title: title, family: family),
        rect: CGRect(x: x, y: y, width: width, height: height), defaultKind: kind)
    }
    switch self {
    case .modular:
      return FaceDefinition(
        placements: [
          place("panel0", "Top left", .panel, .date, 40, 40, 250, 250),
          place("panel1", "Top right", .panel, .clock, 310, 40, 250, 250),
          place("panel2", "Bottom left", .panel, .music, 40, 310, 250, 250),
          place("panel3", "Bottom right", .panel, .weather, 310, 310, 250, 250),
        ], options: [.color])
    case .watchModular:
      // Classic _orderedComplicationSlots: topLeft, center, bottomLeft/Center/Right.
      return FaceDefinition(
        placements: [
          place("topLeft", "Top left", .small, .date, 38, 38, 160, 125),
          place("center", "Middle", .large, .calendar, 38, 196, 524, 185),
          place("bottomLeft", "Bottom left", .small, .weather, 38, 399, 162, 145),
          place("bottomCenter", "Bottom center", .small, .timer, 218, 399, 162, 145),
          place("bottomRight", "Bottom right", .small, .clock, 398, 399, 164, 145),
        ], clockRect: CGRect(x: 228, y: 38, width: 334, height: 125), options: [.color])
    case .infographModular:
      // Six ordered slots read at 0x89a0. Date line is distinct from the fixed clock.
      return FaceDefinition(
        placements: [
          place("topLeft", "Top left", .circular, .weather, 38, 38, 130, 130),
          place("date", "Date line", .inline, .date, 208, 142, 354, 40),
          place("center", "Middle", .rectangular, .calendar, 38, 210, 524, 160),
          place("bottomLeft", "Bottom left", .circular, .timer, 38, 408, 150, 150),
          place("bottomCenter", "Bottom center", .circular, .clock, 225, 408, 150, 150),
          place("bottomRight", "Bottom right", .circular, .weather, 412, 408, 150, 150),
        ], clockRect: CGRect(x: 208, y: 38, width: 354, height: 100), options: [.color])
    case .modularDuo:
      // Signature Circular topLeft and Signature Rectangular center/bottom, 0x10d4.
      return FaceDefinition(
        placements: [
          place("topLeft", "Top left", .circular, .date, 38, 38, 130, 130),
          place("center", "Middle", .rectangular, .calendar, 38, 198, 524, 164),
          place("bottom", "Bottom", .rectangular, .music, 38, 392, 524, 164),
        ], clockRect: CGRect(x: 208, y: 38, width: 354, height: 130), options: [.color])
    case .modularCompact:
      // Three ordered slots at 0x5f4c. Family/geometry below are our own adaptation.
      return FaceDefinition(
        placements: [
          place("top", "Top", .circular, .weather, 38, 38, 160, 160),
          place("center", "Middle", .circular, .date, 38, 220, 160, 160),
          place("bottom", "Bottom", .rectangular, .calendar, 38, 412, 524, 144),
        ], clockRect: CGRect(x: 220, y: 38, width: 342, height: 342), options: [.color])
    case .flow: return FaceDefinition(options: [.flowTypeface, .flowBackground])
    case .home: return FaceDefinition(options: [.color])
    case .numerals: return FaceDefinition(options: [.color])
    default: return FaceDefinition()
    }
  }
  var slots: [FaceSlot] { definition.slots }
}
extension Snapshot {
  func configuration(for face: Face) -> FaceConfiguration {
    // Preserve the legacy Home/Modular theme without leaking it into new layouts.
    faceConfigurations[face.id]
      ?? FaceConfiguration(
        theme: [.home, .homeClock, .modular].contains(face) ? theme : 0)
  }
  func complication(for face: Face, slot: FaceSlot) -> ComplicationKind {
    guard let placement = face.definition.placements.first(where: { $0.slot == slot }) else {
      return .none
    }
    let configured = configuration(for: face).complications[slot.id]
    let index = face.slots.firstIndex(of: slot) ?? 0
    let legacy =
      face == .modular && widgets.indices.contains(index)
      ? ComplicationKind(rawValue: widgets[index]) : nil
    let fallback = placement.defaultKind
    let chosen = configured ?? legacy ?? fallback
    return slot.choices.contains(chosen) ? chosen : .none
  }
  mutating func setComplication(_ kind: ComplicationKind, for face: Face, slot: FaceSlot) {
    guard face.slots.contains(slot), slot.choices.contains(kind) else { return }
    var config = configuration(for: face)
    config.complications[slot.id] = kind
    faceConfigurations[face.id] = config
    if face == .modular, let i = face.slots.firstIndex(of: slot), widgets.indices.contains(i) {
      widgets[i] = kind.rawValue
    }
  }
  mutating func editConfiguration(for face: Face, _ edit: (inout FaceConfiguration) -> Void) {
    var config = configuration(for: face)
    edit(&config)
    faceConfigurations[face.id] = config
  }
}
