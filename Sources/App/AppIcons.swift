import SwiftUI

/// Runtime vector reconstructions of the visible app marks in UI16/UI41/UI42.
/// SF Symbols resolve from the installed OS; no extracted app-icon bitmaps ship.
struct AppIcon: View {
  @Environment(AppModel.self) private var model
  let page: AppPage
  var edge: CGFloat = 92
  var body: some View {
    ZStack {
      LinearGradient(colors: colors,startPoint:.top,endPoint:.bottom)
      artwork
    }.frame(width:edge,height:edge)
      .clipShape(RoundedRectangle(cornerRadius:edge*0.24,style:.continuous))
      .overlay(RoundedRectangle(cornerRadius:edge*0.24,style:.continuous)
        .strokeBorder(.white.opacity(0.20),lineWidth:0.7))
      .accessibilityHidden(true)
  }
  private var colors: [Color] {
    switch page {
    case .home,.calendar,.reminders,.safari,.findMy: [.white,Color(white:0.94)]
    case .messages,.faceTime: [Color(red:0.30,green:0.96,blue:0.34),Color(red:0.02,green:0.75,blue:0.16)]
    case .music: [Color(red:1,green:0.25,blue:0.40),Color(red:0.99,green:0.02,blue:0.21)]
    case .weather: [Color(red:0.07,green:0.53,blue:0.95),Color(red:0.26,green:0.76,blue:1)]
    case .timers,.alarms,.worldClock,.intercom: [Color(red:1,green:0.70,blue:0.08),Color(red:0.96,green:0.47,blue:0.02)]
    case .podcasts: [Color(red:0.75,green:0.32,blue:1),Color(red:0.42,green:0.12,blue:0.91)]
    case .settings: [Color(white:0.88),Color(white:0.69)]
    default: [page.color.opacity(0.8),page.color]
    }
  }
  @ViewBuilder private var artwork: some View {
    switch page {
    case .calendar:
      VStack(spacing:0) {
        Text(model.dateLabel("EEE")).font(.system(size:edge*0.18,weight:.medium)).foregroundStyle(.red)
        Text(model.dateLabel("d")).font(.system(size:edge*0.55,weight:.light)).foregroundStyle(.black)
      }.padding(.top,edge*0.03)
    case .home:
      ZStack {
        mark("house.fill",0.65,.orange)
        mark("house.fill",0.48,Color(red:1,green:0.75,blue:0.20)).offset(y:edge*0.04)
        mark("house.fill",0.28,Color(red:1,green:0.88,blue:0.48)).offset(y:edge*0.07)
        RoundedRectangle(cornerRadius:edge*0.025).fill(.white)
          .frame(width:edge*0.13,height:edge*0.19).offset(y:edge*0.12)
      }
    case .weather:
      Image(systemName:"cloud.sun.fill").symbolRenderingMode(.palette)
        .foregroundStyle(.white,.yellow).font(.system(size:edge*0.66))
        .shadow(color:.blue.opacity(0.16),radius:2,y:1)
    case .music:
      MusicMark().fill(.white).frame(width:edge*0.70,height:edge*0.70)
    case .messages:
      MessageMark().fill(.white).frame(width:edge,height:edge)
    case .reminders:
      VStack(spacing:edge*0.105) {
        ForEach(0..<3) { i in
          HStack(spacing:edge*0.08) {
            Circle().strokeBorder([Color.blue,.red,.orange][i],lineWidth:edge*0.026)
              .frame(width:edge*0.13,height:edge*0.13)
            Rectangle().fill(Color(white:0.70)).frame(width:edge*0.47,height:edge*0.012)
          }
        }
      }
    case .safari:
      ZStack {
        Circle().fill(LinearGradient(colors:[.cyan,.blue],startPoint:.top,endPoint:.bottom))
          .padding(edge*0.07)
        ForEach(0..<24) { i in
          Rectangle().fill(.white.opacity(0.8)).frame(width:edge*0.012,height:edge*(i%2==0 ? 0.065:0.035))
            .offset(y:-edge*0.34).rotationEffect(.degrees(Double(i)*15))
        }
        CompassNeedle().fill(.white).frame(width:edge*0.18,height:edge*0.64)
          .rotationEffect(.degrees(45))
        CompassNeedle(topOnly:true).fill(.red).frame(width:edge*0.18,height:edge*0.64)
          .rotationEffect(.degrees(45))
      }
    case .findMy:
      ZStack {
        Circle().fill(.green.gradient).padding(edge*0.08)
        ForEach([0.32,0.54,0.76],id:\.self) { diameter in
          Circle().stroke(.white.opacity(0.55),lineWidth:edge*0.012)
            .frame(width:edge*diameter,height:edge*diameter)
        }
        Circle().fill(.blue).frame(width:edge*0.19,height:edge*0.19)
          .overlay(Circle().stroke(.white,lineWidth:edge*0.03))
      }
    case .settings:
      mark("gearshape.fill",0.84,Color(white:0.40))
        .overlay(Circle().stroke(.white.opacity(0.8),lineWidth:edge*0.04)
          .frame(width:edge*0.46,height:edge*0.46))
    case .podcasts:
      ZStack {
        ForEach([0.50,0.76],id:\.self) { diameter in
          Circle().stroke(.white,lineWidth:edge*0.035).frame(width:edge*diameter,height:edge*diameter)
        }
        Circle().fill(.white).frame(width:edge*0.16,height:edge*0.16).offset(y:-edge*0.04)
        Capsule().fill(.white).frame(width:edge*0.16,height:edge*0.34).offset(y:edge*0.22)
      }
    default:
      mark(page.symbol,page == .music ? 0.65 : 0.61,.white)
    }
  }
  private func mark(_ symbol: String,_ fraction: CGFloat,_ tint: Color) -> some View {
    Image(systemName:symbol).font(.system(size:edge*fraction,weight:.regular)).foregroundStyle(tint)
  }
}
private struct MusicMark: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let points: [CGPoint] = [CGPoint(x:0.26,y:0.18),CGPoint(x:0.90,y:0.04),
      CGPoint(x:0.90,y:0.69),CGPoint(x:0.77,y:0.72),CGPoint(x:0.77,y:0.28),
      CGPoint(x:0.39,y:0.36),CGPoint(x:0.39,y:0.83),CGPoint(x:0.26,y:0.86)]
    p.addLines(points);p.closeSubpath()
    p.addEllipse(in:CGRect(x:0.04,y:0.73,width:0.35,height:0.22))
    p.addEllipse(in:CGRect(x:0.55,y:0.59,width:0.35,height:0.22))
    return p.applying(CGAffineTransform(a:rect.width,b:0,c:0,d:rect.height,
      tx:rect.minX,ty:rect.minY))
  }
}
private struct MessageMark: Shape {
  func path(in rect: CGRect) -> Path {
    let bubble = Path(ellipseIn:CGRect(x:rect.minX+rect.width*0.14,y:rect.minY+rect.height*0.20,
      width:rect.width*0.72,height:rect.height*0.60))
    func point(_ x:CGFloat,_ y:CGFloat) -> CGPoint {
      CGPoint(x:rect.minX+rect.width*x,y:rect.minY+rect.height*y)
    }
    var tail = Path()
    tail.move(to:point(0.28,0.63))
    tail.addCurve(to:point(0.20,0.84),control1:point(0.28,0.74),control2:point(0.24,0.80))
    tail.addCurve(to:point(0.45,0.70),control1:point(0.35,0.82),control2:point(0.42,0.76))
    tail.closeSubpath()
    return bubble.union(tail)
  }
}
private struct CompassNeedle: Shape {
  var topOnly = false
  func path(in rect: CGRect) -> Path {
    Path { p in
      p.move(to:CGPoint(x:rect.midX,y:rect.minY))
      p.addLine(to:CGPoint(x:rect.maxX,y:rect.midY))
      if !topOnly { p.addLine(to:CGPoint(x:rect.midX,y:rect.maxY)) }
      p.addLine(to:CGPoint(x:rect.minX,y:rect.midY));p.closeSubpath()
    }
  }
}
