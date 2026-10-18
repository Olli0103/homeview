import SwiftUI

/// Project-owned geometry, not traced or extracted system font contours.
/// The taller photo references use long straight sides and rounded counters.
struct PhotoTallDigitShape: Shape {
  let digit: Int
  var strokeWidth: CGFloat?
  func path(in rect: CGRect) -> Path {
    let ink=rect.insetBy(dx:3,dy:6)
    guard ink.width>0,ink.height>0 else { return Path() }
    let stroke=min(ink.width*0.45,strokeWidth ?? ink.width*0.31)
    func ring(_ box:CGRect) -> Path {
      let outside=Path(roundedRect:box,cornerRadius:box.width*0.49)
      let inside=box.insetBy(dx:stroke,dy:stroke)
      guard inside.width>0,inside.height>0 else { return outside }
      return outside.subtracting(Path(roundedRect:inside,cornerRadius:inside.width*0.49))
    }
    func nine() -> Path {
      var result=ring(CGRect(x:ink.minX,y:ink.minY,width:ink.width,height:ink.height*0.62))
      var tail=Path()
      tail.move(to:CGPoint(x:ink.maxX-stroke/2,y:ink.minY+ink.height*0.31))
      tail.addLine(to:CGPoint(x:ink.maxX-stroke/2,y:ink.maxY-ink.width/2))
      tail.addQuadCurve(to:CGPoint(x:ink.midX,y:ink.maxY-stroke/2),
        control:CGPoint(x:ink.maxX-stroke/2,y:ink.maxY-stroke/2))
      tail.addQuadCurve(to:CGPoint(x:ink.minX+stroke/2,y:ink.maxY-ink.width/2),
        control:CGPoint(x:ink.minX+stroke/2,y:ink.maxY-stroke/2))
      tail.addLine(to:CGPoint(x:ink.minX+stroke/2,y:ink.minY+ink.height*0.73))
      return result.union(tail.strokedPath(.init(lineWidth:stroke,lineCap:.round,lineJoin:.round)))
    }
    if digit==0 { return ring(ink) }
    if digit==9 { return nine() }
    if digit==6 {
      return nine().applying(CGAffineTransform(a:-1,b:0,c:0,d:-1,
        tx:ink.minX+ink.maxX,ty:ink.minY+ink.maxY))
    }
    if digit==8 {
      var result=Path(roundedRect:ink,cornerRadius:ink.width*0.49)
      for y in [ink.minY+stroke,ink.midY+stroke/2] {
        let counter=CGRect(x:ink.minX+stroke,y:y,width:ink.width-2*stroke,
          height:ink.height/2-stroke*1.5)
        result=result.subtracting(Path(roundedRect:counter,cornerRadius:counter.width*0.49))
      }
      return result
    }
    func point(_ p:SIMD2<Double>) -> CGPoint {
      CGPoint(x:ink.minX+stroke/2+CGFloat(p.x)*(ink.width-stroke),
        y:ink.minY+stroke/2+CGFloat(p.y)*(ink.height-stroke))
    }
    var line=Path()
    if digit==1 {
      line.move(to:point(.init(0.15,0.14)))
      line.addLine(to:point(.init(0.8,0)))
      line.addLine(to:point(.init(0.8,1)))
    } else {
      // Reuse our own cubic skeletons for the remaining, uncalibrated digits.
      for segment in FlowTypography.skeleton(digit) {
        switch segment {
        case .move(let p):line.move(to:point(p))
        case .line(let p):line.addLine(to:point(p))
        case .curve(let a,let b,let c):
          line.addCurve(to:point(c),control1:point(a),control2:point(b))
        }
      }
    }
    return line.strokedPath(.init(lineWidth:stroke,lineCap:.round,lineJoin:.round))
  }
}

struct PhotoTallGlyphs: View {
  let digits:[Int]
  let height:CGFloat
  private var unit: CGFloat {
    CGFloat(PhotoClockGlyphLayout.unit(for:digits) ?? 0)
  }
  var body: some View {
    HStack(spacing:120) {
      ForEach(0..<2) { pair in
        HStack(spacing:10) {
          ForEach(0..<2) { index in
            let digit=digits[pair*2+index]
            PhotoTallDigitShape(digit:digit,strokeWidth:(unit-6)*0.31).fill(.white)
              .frame(width:unit*(digit==1 ? 0.75:1),height:height)
          }
        }
      }
    }.frame(width:540,height:height)
  }
}

/// All ten own shapes on a deterministic surface, only shown under UITesting.
struct PhotoTallGlyphAtlas: View {
  var body: some View {
    VStack(spacing:30) {
      ForEach(0..<2) { row in
        HStack(spacing:14) {
          ForEach(0..<5) { column in
            let digit=row*5+column
            PhotoTallDigitShape(digit:digit).fill(.white)
              .frame(width:94,height:245).background(.black)
              .accessibilityElement(children:.ignore)
              .accessibilityLabel("Own photo glyph \(digit)")
              .accessibilityIdentifier("photo.glyph.\(digit)")
          }
        }
      }
    }.frame(width:600,height:600).background(.black)
  }
}
