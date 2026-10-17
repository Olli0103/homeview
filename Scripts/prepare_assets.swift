import AppKit
let root = URL(fileURLWithPath: CommandLine.arguments[1])
let names = ["IconHome","IconCalendar","IconMusic","IconWeather","IconTimers",
 "IconReminders","IconIntercom","IconMessages","IconFaceTime","IconFindMy",
 "IconAlarms","IconWorldClock","IconSafari","IconPodcasts","IconSettings","Soup","AlbumArt"]
for (i, name) in names.enumerated() {
  let rep = NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:512,pixelsHigh:512,
    bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,
    colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep:rep)
  NSColor(calibratedHue:CGFloat(i)/CGFloat(names.count),saturation:0.5,brightness:0.65,alpha:1).setFill()
  NSBezierPath(roundedRect:NSRect(x:0,y:0,width:512,height:512),xRadius:85,yRadius:85).fill()
  NSColor.white.withAlphaComponent(0.8).setStroke()
  let ring = NSBezierPath(ovalIn:NSRect(x:96,y:96,width:320,height:320))
  ring.lineWidth = 18
  ring.stroke()
  let mark = NSBezierPath()
  mark.move(to:NSPoint(x:170,y:256)); mark.line(to:NSPoint(x:342,y:256))
  mark.move(to:NSPoint(x:256,y:170)); mark.line(to:NSPoint(x:256,y:342))
  mark.lineWidth=CGFloat(8+i%5*5); mark.stroke()
  NSGraphicsContext.restoreGraphicsState()
  let output=root.appendingPathComponent("Resources/Assets.xcassets/\(name).imageset/image.png")
  try rep.representation(using:.png,properties:[:])!.write(to:output)
}
