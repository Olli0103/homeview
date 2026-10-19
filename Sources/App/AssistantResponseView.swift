import SwiftUI

struct AssistantResponseView:View {
  let document:AssistantResponseDocument
  let openRecipe:()->Void
  let selectExample:(AssistantResponseExample)->Void
  @State private var source:AssistantResponseDocument.Source?
  var body:some View {
    VStack(alignment:.leading,spacing:18) {
      Text("Bundled answer example · Not a live or personal result")
        .font(.caption).foregroundStyle(.secondary)
        .accessibilityIdentifier("assistant.card.scope")
      switch document.content {
      case .illustration:
        CyanotypeExampleIllustration().frame(height:220).clipShape(RoundedRectangle(cornerRadius:22))
          .accessibilityLabel("Illustration: pale fern-like branches on a deep-blue background")
          .accessibilityIdentifier("assistant.card.image")
        Text("HomeView illustration · Not a historical print").font(.caption).foregroundStyle(.secondary)
      case .agenda(let events):
        ForEach(Array(events.enumerated()),id:\.offset) { index,event in
          VStack(alignment:.leading,spacing:8) {
            Text(verbatim:event.day).font(.headline)
            HStack(alignment:.top,spacing:12) {
              Image(systemName:event.kind == .birthday ? "calendar":"calendar.badge.clock")
              VStack(alignment:.leading,spacing:4) {
                Text(verbatim:event.title).font(.body.bold())
                Text(verbatim:event.detail).font(.body)
              }
              Spacer(minLength:0)
            }.padding(16).frame(maxWidth:.infinity,alignment:.leading)
              .background(event.kind == .birthday ? Color.orange.opacity(0.13):Color.blue.opacity(0.12),in:RoundedRectangle(cornerRadius:22))
          }.accessibilityElement(children:.combine).accessibilityIdentifier("assistant.card.event.\(index)")
        }
      case .recipe:
        SoupExampleIllustration().frame(height:190)
          .clipShape(RoundedRectangle(cornerRadius:22))
          .accessibilityLabel("Illustration of a bowl of soup")
          .accessibilityIdentifier("assistant.card.image")
        Text("Butternut Squash Soup").font(.title2.bold())
        Text("Home Cookbook · 35 min · Serves 4").foregroundStyle(.secondary)
        Button("Open bundled recipe",action:openRecipe).frame(minHeight:44)
          .accessibilityIdentifier("assistant.card.openRecipe")
      case .loading:
        ProgressView("Loading preview").accessibilityIdentifier("assistant.card.loading")
        Text("Preview only. No request is running; choose another example below.")
      case .empty:
        Label("No matching sample",systemImage:"magnifyingglass")
          .accessibilityIdentifier("assistant.card.empty")
        Text("Try a different example. No personal sources were searched.")
      case .failure:
        Label("Result unavailable",systemImage:"exclamationmark.triangle")
          .accessibilityIdentifier("assistant.card.failure")
        Text("Nothing was changed. Choose another example; there is no automatic retry.")
      }
      ForEach(document.sources) { item in
        Button {source=item} label: {
          Label(item.title,systemImage:"info.circle").font(.subheadline)
            .frame(minHeight:44,alignment:.leading)
        }.accessibilityLabel("Source: "+item.title)
          .accessibilityIdentifier("assistant.card.source."+item.rawValue)
      }
      if !document.followUps.isEmpty {
        Text("Explore another example").font(.headline)
        ForEach(document.followUps) { example in
          Button(example.title) {selectExample(example)}.frame(minHeight:44)
            .accessibilityIdentifier("assistant.card.followup."+example.rawValue)
        }
      }
    }.frame(maxWidth:.infinity,alignment:.leading)
      .sheet(item:$source) { item in
        VStack(alignment:.leading,spacing:20) {
          HStack {Text(item.title).font(.title2.bold());Spacer();Button("Done") {source=nil}.frame(minHeight:44).accessibilityIdentifier("assistant.card.source.done")}
          ScrollView {
            VStack(alignment:.leading,spacing:20) {
              Text(verbatim:item.detail)
              if let url=item.url {Link("Open museum source",destination:url).frame(minHeight:44).accessibilityIdentifier("assistant.card.source.open")}
            }
          }
        }.padding(24).frame(minWidth:280,minHeight:300)
          .accessibilityIdentifier("assistant.card.source.detail")
      }
  }
}

private struct SoupExampleIllustration:View {
  var body:some View {
    Canvas { context,size in
      context.fill(Path(CGRect(origin:.zero,size:size)),with:.color(Color(red:0.96,green:0.87,blue:0.71)))
      let width=min(size.width*0.7,260),x=(size.width-width)/2,y=size.height*0.42
      var bowl=Path();bowl.move(to:CGPoint(x:x,y:y));bowl.addQuadCurve(to:CGPoint(x:x+width,y:y),control:CGPoint(x:size.width/2,y:size.height*1.3));bowl.closeSubpath()
      context.fill(bowl,with:.color(.white))
      context.fill(Path(ellipseIn:CGRect(x:x,y:y-12,width:width,height:40)),with:.color(Color.orange.opacity(0.8)))
      for index in 0..<3 {
        let cx=size.width/2+CGFloat(index-1)*28
        var steam=Path();steam.move(to:CGPoint(x:cx,y:y-22));steam.addCurve(to:CGPoint(x:cx,y:20),control1:CGPoint(x:cx-14,y:y-42),control2:CGPoint(x:cx+14,y:40))
        context.stroke(steam,with:.color(.white.opacity(0.9)),lineWidth:3)
      }
    }.accessibilityElement(children:.ignore)
  }
}

/// Own vector artwork: no copied original/reference/museum asset.
private struct CyanotypeExampleIllustration:View {
  var body:some View {
    Canvas { context,size in
      context.fill(Path(CGRect(origin:.zero,size:size)),with:.color(Color(red:0.04,green:0.19,blue:0.48)))
      for branch in 0..<5 {
        let base=CGPoint(x:size.width*CGFloat(branch+1)/6,y:size.height)
        let tip=CGPoint(x:base.x+CGFloat(branch-2)*12,y:20+CGFloat(branch%2)*30)
        var stem=Path();stem.move(to:base);stem.addLine(to:tip)
        context.stroke(stem,with:.color(.white.opacity(0.85)),lineWidth:2)
        for leaf in 1..<9 {
          let fraction=CGFloat(leaf)/10,point=CGPoint(x:base.x+(tip.x-base.x)*fraction,y:base.y+(tip.y-base.y)*fraction)
          for side in [-1.0,1.0] {
            var line=Path();line.move(to:point)
            line.addQuadCurve(to:CGPoint(x:point.x+CGFloat(side)*22*(1-fraction/2),y:point.y-18),control:CGPoint(x:point.x+CGFloat(side)*8,y:point.y-14))
            context.stroke(line,with:.color(.white.opacity(0.8)),lineWidth:2)
          }
        }
      }
    }.accessibilityElement(children:.ignore)
  }
}
