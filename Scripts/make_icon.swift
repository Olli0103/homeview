import AppKit
let root=URL(fileURLWithPath:CommandLine.arguments[1])
let rep=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:1024,pixelsHigh:1024,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:rep)
NSGradient(starting:NSColor(red:0.38,green:0.32,blue:0.85,alpha:1),ending:NSColor(red:0.11,green:0.1,blue:0.37,alpha:1))!.draw(in:NSRect(x:0,y:0,width:1024,height:1024),angle:45)
for (x,y,w,h) in [(70.0,380.0,570.0,570.0),(665,665,285,285),(665,380,285,260),(70,70,285,285),(380,70,260,285),(665,70,285,285)] {
 NSColor.white.withAlphaComponent(0.19).setFill();NSBezierPath(roundedRect:NSRect(x:x,y:y,width:w,height:h),xRadius:60,yRadius:60).fill()
}
let house=NSImage(systemSymbolName:"house.fill",accessibilityDescription:nil)!.withSymbolConfiguration(.init(pointSize:300,weight:.regular))!
house.draw(in:NSRect(x:190,y:515,width:330,height:300))
NSColor.white.setStroke();let clock=NSBezierPath(ovalIn:NSRect(x:715,y:715,width:185,height:185));clock.lineWidth=12;clock.stroke()
let hands=NSBezierPath();hands.move(to:NSPoint(x:807,y:807));hands.line(to:NSPoint(x:807,y:865));hands.move(to:NSPoint(x:807,y:807));hands.line(to:NSPoint(x:855,y:775));hands.lineWidth=13;hands.lineCapStyle = .round;hands.stroke()
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"))
