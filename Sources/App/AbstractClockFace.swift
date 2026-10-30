import SwiftUI

/// Project-owned ellipse/capsule construction for UI09's visible 0/1/9.
/// Other digits deliberately use our existing own contours, not an invented
/// claim about an unseen original typeface. No reference image is loaded.
struct AbstractDigitShape: Shape {
  let digit:Int
  func path(in rect:CGRect)->Path {
    func box(_ x:CGFloat,_ y:CGFloat,_ w:CGFloat,_ h:CGFloat)->CGRect {
      CGRect(x:rect.minX+x*rect.width,y:rect.minY+y*rect.height,
        width:w*rect.width,height:h*rect.height)
    }
    switch digit {
    case 0:return Path(ellipseIn:rect)
    case 1:
      let stem=box(0.55,0,0.45,1),d=rect.width*0.47
      var p=Path(roundedRect:stem,cornerRadius:stem.width/2)
      p.addEllipse(in:CGRect(x:rect.minX,y:rect.minY+rect.height*0.19,width:d,height:d))
      return p
    case 9:
      let stem=box(0.57,0,0.43,1)
      var p=Path(roundedRect:stem,cornerRadius:stem.width/2)
      func point(_ x:CGFloat,_ y:CGFloat)->CGPoint {
        CGPoint(x:rect.minX+x*rect.width,y:rect.minY+y*rect.height)
      }
      var bowl=Path()
      bowl.move(to:point(0.48,0.01))
      bowl.addCurve(to:point(0,0.30),control1:point(0.12,0.01),control2:point(0,0.11))
      bowl.addCurve(to:point(0.48,0.59),control1:point(0,0.49),control2:point(0.12,0.59))
      bowl.closeSubpath();p.addPath(bowl)
      let d=rect.width*0.37
      p.addEllipse(in:CGRect(x:rect.minX+rect.width*0.12,y:rect.maxY-d,width:d,height:d))
      return p
    default:
      return FlowDigitShape(digit:digit,stencil:false,
        typography:FlowTypography(width:1.06,weight:0)).path(in:rect).normalized(eoFill:false)
    }
  }
}

/// Own working-name renderer of the previously unclassified UI09 state.
/// It shares public drawing/timeline facilities, not a claimed Flow identity.
struct AbstractClockFace:View {
  @Environment(AppModel.self) private var model
  private let cells:[CGRect]=[
    CGRect(x:122,y:58,width:168,height:226),
    CGRect(x:308,y:60,width:210,height:226),
    CGRect(x:95,y:308,width:214,height:234),
    CGRect(x:309,y:310,width:185,height:230)
  ]
  private var digits:[Int] {
    var calendar=Calendar(identifier:.gregorian);calendar.timeZone=model.displayTimeZone
    let twelve = !model.referenceClock &&
      (DateFormatter.dateFormat(fromTemplate:"j",options:0,locale:.current)?.contains("a") ?? false)
    return FlowTypography.digits(hour:calendar.component(.hour,from:model.clock),
      minute:calendar.component(.minute,from:model.clock),twelveHour:twelve)
  }
  var body:some View {
    let values=digits
    ZStack {
      if model.data.night {Color.black} else {AbstractClockBackdrop().accessibilityHidden(true)}
      ForEach(0..<4) { i in
        digit(values[i]).frame(width:cells[i].width,height:cells[i].height)
          .position(x:cells[i].midX,y:cells[i].midY).accessibilityHidden(true)
      }
    }.frame(width:600,height:600).clipped()
      .accessibilityElement(children:.ignore)
      .accessibilityLabel("Abstract clock")
      .accessibilityValue("\(values[0])\(values[1]):\(values[2])\(values[3])")
      .accessibilityIdentifier("abstract.clock.time")
  }
  @ViewBuilder private func digit(_ value:Int)->some View {
    let shape=AbstractDigitShape(digit:value)
    if model.data.night {shape.fill(.white)} else {
      #if os(visionOS)
      fallback(shape)
      #else
      if #available(macOS 26.0,*) {
        Color.clear.glassEffect(.clear,in:shape)
          .overlay {shape.stroke(.white.opacity(0.45),lineWidth:1)}
      } else {fallback(shape)}
      #endif
    }
  }
  private func fallback(_ shape:AbstractDigitShape)->some View {
    shape.fill(.ultraThinMaterial)
      .overlay {shape.stroke(.white.opacity(0.6),lineWidth:1)}
      .shadow(color:.purple.opacity(0.2),radius:3,x:1,y:2)
  }
}

/// Analytic pink/blue field, not an extracted texture or an inferred original
/// fluid algorithm. The existing timeline pauses for background/Reduce Motion.
private struct AbstractClockBackdrop:View {
  var body:some View {
    MotionTimeline { t in
      Canvas { context,size in
        let bounds=CGRect(origin:.zero,size:size),path=Path(bounds),side=min(size.width,size.height)
        context.fill(path,with:.color(Color(red:0.79,green:0.71,blue:0.86)))
        func blob(_ color:Color,_ x:Double,_ y:Double,_ radius:Double) {
          context.fill(path,with:.radialGradient(Gradient(colors:[color,color.opacity(0.85),.clear]),
            center:CGPoint(x:size.width*x,y:size.height*y),startRadius:0,endRadius:side*radius))
        }
        let shift=sin(t/12)*0.06
        blob(Color(red:1,green:0.39,blue:0.77),0.30+shift,0.24,0.55)
        blob(Color(red:0.31,green:0.39,blue:1),0.58,0.52+shift,0.54)
        blob(Color(red:0.31,green:0.85,blue:1).opacity(0.85),0.31-shift,0.46,0.26)
        blob(Color(red:1,green:0.53,blue:0.88),0.35,0.81-shift,0.39)
      }.blur(radius:14)
    }
  }
}
