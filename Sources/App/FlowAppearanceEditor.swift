import SwiftUI

/// Own choices approximating the visible swatches in UI37. Names and channel
/// multipliers are not asserted original palette metadata or a fluid algorithm.
enum FlowReplicaPalette:Int,CaseIterable,Identifiable {
  case automatic,ice,lavender,rose,pearl,spectrum,ocean,turquoise
  var id:Int {rawValue}
  var title:String {
    switch self {
    case .automatic:"Automatic"
    case .ice:"Ice"
    case .lavender:"Lavender"
    case .rose:"Rose"
    case .pearl:"Pearl"
    case .spectrum:"Spectrum"
    case .ocean:"Ocean"
    case .turquoise:"Turquoise"
    }
  }
  var tint:Color {
    switch self {
    case .automatic:.white
    case .ice:Color(red:0.65,green:0.88,blue:1)
    case .lavender:Color(red:0.88,green:0.70,blue:1)
    case .rose:Color(red:1,green:0.65,blue:0.90)
    case .pearl:Color(red:0.89,green:0.95,blue:1)
    case .spectrum:Color(red:1,green:0.85,blue:1)
    case .ocean:Color(red:0.50,green:0.76,blue:1)
    case .turquoise:Color(red:0.55,green:1,blue:0.88)
    }
  }
  var swatch:[Color] {
    switch self {
    case .automatic:[.blue,.purple,.pink]
    case .spectrum:[.pink,.purple,.cyan,.green]
    default:[tint,.blue]
    }
  }
}

struct FlowPaletteTreatment:ViewModifier {
  let index:Int
  var disabled=false
  @ViewBuilder func body(content:Content)->some View {
    if !disabled,let palette=FlowReplicaPalette(rawValue:index),palette != .automatic {
      content.colorMultiply(palette.tint)
    } else {content}
  }
}

/// A staged appearance screen: preview cannot operate the home or persist a
/// draft. Only the explicit check button writes via the normal guarded writer.
struct FlowAppearanceEditor:View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  @ScaledMetric(relativeTo:.headline) private var tabSize:CGFloat=20
  @ScaledMetric(relativeTo:.body) private var automaticSize:CGFloat=19
  @State private var draft:FaceConfiguration
  @State private var fontPage=false
  @State private var saveError:String?
  let close:()->Void
  init(configuration:FaceConfiguration,close:@escaping ()->Void) {
    _draft=State(initialValue:configuration);self.close=close
  }
  private var hit:CGFloat {max(44,ceil(44/max(0.01,canvasScale)))}
  private var selectedPalette:FlowReplicaPalette {FlowReplicaPalette(rawValue:draft.flowPalette) ?? .automatic}
  var body:some View {
    ScrollView {
    VStack(spacing:12) {
      HStack(spacing:24) {
        page("Color",font:false);page("Font",font:true)
      }.padding(.top,20)
      HStack(spacing:16) {
        FlowArtwork(date:model.clock,timeZone:model.displayTimeZone,far:false,
          typeface:draft.flowTypeface,showBackground:draft.flowBackground,
          highContrastNight:model.data.night,palette:draft.flowPalette)
          .allowsHitTesting(false).accessibilityHidden(true)
          .disabled(true).frame(width:600,height:600).scaleEffect(0.63)
          .frame(width:378,height:378).clipShape(RoundedRectangle(cornerRadius:30))
          .overlay {RoundedRectangle(cornerRadius:30).stroke(.cyan.opacity(0.8),lineWidth:3)}
        ScrollView {
          VStack(spacing:2) {
            if fontPage {
              ForEach(0..<3) { i in
                Button {draft.flowTypeface=i} label: {
                  Text(["I","II","III"][i]).font(.system(size:27,weight:.medium))
                    .frame(width:hit,height:hit)
                    .background(draft.flowTypeface==i ? .blue:.white.opacity(0.12),in:Capsule())
                    .contentShape(Rectangle())
                }.accessibilityLabel(["Stencil font","Solid font","Inline font"][i])
                  .accessibilityIdentifier("flow.appearance.font.\(i)")
                  .accessibilityValue(draft.flowTypeface==i ? "Selected":"Not selected")
              }
            } else {
              ForEach(FlowReplicaPalette.allCases) { palette in
                Button {draft.flowPalette=palette.rawValue} label: {
                  Circle().fill(LinearGradient(colors:palette.swatch,startPoint:.top,endPoint:.bottom))
                    .frame(width:25,height:25)
                    .overlay {Circle().stroke(.white,lineWidth:draft.flowPalette==palette.rawValue ? 3:0).padding(-4)}
                    .frame(width:hit,height:hit).contentShape(Rectangle())
                }.accessibilityLabel(palette.title+" color")
                  .accessibilityIdentifier("flow.appearance.palette.\(palette.rawValue)")
                  .accessibilityValue(draft.flowPalette==palette.rawValue ? "Selected":"Not selected")
              }
            }
          }.padding(5)
        }.frame(width:hit+10,height:388).accessibilityIdentifier("flow.appearance.choices")
      }.frame(maxWidth:.infinity)
      HStack {
        circleButton("xmark",label:"Cancel appearance",id:"flow.appearance.cancel",action:close)
        Spacer(minLength:10)
        Button {draft.flowPalette=0;fontPage=false} label: {
          Label("Automatic",systemImage:"circle.lefthalf.filled")
            .font(.system(size:automaticSize,weight:.semibold)).padding(.horizontal,15)
            .frame(minHeight:hit).contentShape(Capsule())
            .overlay {Capsule().stroke(.cyan.opacity(0.8),lineWidth:2)}
        }.accessibilityIdentifier("flow.appearance.automatic")
          .accessibilityValue(selectedPalette == .automatic ? "Selected":"Not selected")
        Spacer(minLength:10)
        circleButton("checkmark",label:"Save appearance",id:"flow.appearance.done") {
          let palette=draft.flowPalette,font=draft.flowTypeface
          if model.updateLocalControls({state in
            state.editConfiguration(for:.flow) {$0.flowPalette=palette;$0.flowTypeface=font}
          }) {close()} else {
            saveError=model.error ?? "Could not save appearance."
            model.error=nil
          }
        }
      }.padding(.horizontal,32).padding(.bottom,20)
    }.frame(minHeight:600)
    }.frame(width:600,height:600).foregroundStyle(.white)
      .background(LinearGradient(colors:[Color(red:0.015,green:0.025,blue:0.14),.black],
        startPoint:.top,endPoint:.bottom))
      .buttonStyle(.plain).snapshotErrorAlert($saveError)
  }
  private func page(_ title:String,font:Bool)->some View {
    Button {fontPage=font} label: {
      Text(title.uppercased()).font(.system(size:tabSize,weight:.semibold))
        .foregroundStyle(fontPage==font ? .cyan:.white.opacity(0.65))
        .frame(minWidth:hit+20,minHeight:hit).contentShape(Rectangle())
    }.accessibilityLabel(title)
      .accessibilityIdentifier("flow.appearance.page."+(font ? "font":"color"))
      .accessibilityValue(fontPage==font ? "Selected":"Not selected")
  }
  private func circleButton(_ symbol:String,label:String,id:String,action:@escaping ()->Void)->some View {
    Button(action:action) {
      Image(systemName:symbol).font(.system(size:30,weight:.medium))
        .frame(width:max(64,hit),height:max(64,hit)).background(.blue.opacity(0.85),in:Circle())
        .contentShape(Circle())
    }.accessibilityLabel(label).accessibilityIdentifier(id)
  }
}
