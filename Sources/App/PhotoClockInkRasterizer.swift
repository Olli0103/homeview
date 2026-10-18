import SwiftUI
import CoreGraphics

/// Only typography is cached. Subject coverage is recomputed from the current
/// photo mask and selected crop in PhotoPlacement on every composition update.
@MainActor
enum PhotoClockInkRasterizer {
  static func candidates(digits: [Int]) -> [PhotoClockInkCandidate] {
    var frames: [PhotoRect] = []
    for position in [PhotoClockPosition.top,.middle,.bottom] {
      for frame in PhotoPlacement.expansionFrames(for:position) where !frames.contains(frame) {
        frames.append(frame)
      }
    }
    return frames.compactMap { frame in
      guard let slots = PhotoClockGlyphLayout.frames(digits:digits,in:frame) else { return nil }
      let glyphs = slots.compactMap { slot -> PhotoClockInkRaster? in
        let side = 128
        guard let context = CGContext(data:nil,width:side,height:side,bitsPerComponent:8,
          bytesPerRow:side,space:CGColorSpaceCreateDeviceGray(),bitmapInfo:CGImageAlphaInfo.none.rawValue)
        else { return nil }
        context.setFillColor(gray:0,alpha:1)
        context.fill(CGRect(x:0,y:0,width:side,height:side))
        // Bitmap drawing has a lower-left coordinate origin. Our own Shape and
        // mask model use top-left coordinates; convert once at rasterization.
        context.translateBy(x:0,y:CGFloat(side))
        context.scaleBy(x:CGFloat(side)/600,y:-CGFloat(side)/600)
        context.translateBy(x:slot.rect.x*600,y:slot.rect.y*600)
        let path = PhotoTallDigitShape(digit:slot.digit,strokeWidth:slot.stroke)
          .path(in:CGRect(x:0,y:0,width:slot.rect.width*600,height:slot.rect.height*600))
        context.addPath(path.cgPath)
        context.setFillColor(gray:1,alpha:1);context.fillPath()
        guard let data = context.data else { return nil }
        let values = Array(UnsafeBufferPointer(start:data.assumingMemoryBound(to:UInt8.self),count:side*side))
        return PhotoClockInkRaster(width:side,height:side,values:values)
      }
      guard glyphs.count == 4 else { return nil }
      return .init(frame:frame,glyphs:glyphs)
    }
  }
  /// Raw top-down matrix, without a compensating display flip. UITesting only.
  static func controlImage(_ candidate: PhotoClockInkCandidate?) -> CGImage? {
    guard let glyphs = candidate?.glyphs, let first = glyphs.first else { return nil }
    var values = [UInt8](repeating:0,count:first.values.count)
    for glyph in glyphs {
      for i in values.indices { values[i] = max(values[i],glyph.values[i]) }
    }
    guard let provider = CGDataProvider(data:Data(values) as CFData) else { return nil }
    return CGImage(width:first.width,height:first.height,bitsPerComponent:8,bitsPerPixel:8,
      bytesPerRow:first.width,space:CGColorSpaceCreateDeviceGray(),bitmapInfo:[],
      provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent)
  }
}
