import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import CoreImage
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Original geometric fixtures. Only instantiated behind --uitesting.
enum PhotoLayoutFixture {
  @MainActor
  static func make(_ kind: String) -> (bytes: Data, analysis: PhotoAnalysis)? {
    if kind == "native-alpha-replay" { return nativeAlphaReplay() }
    guard ["top", "edges", "dense", "sparse-depth"].contains(kind) else { return nil }
    let width = kind == "edges" ? 800 : 600
    let height = kind == "edges" ? 400 : 600
    let subjects: [PhotoRect] = kind == "edges"
      ? [.init(x: 0.02, y: 0.35, width: 0.10, height: 0.3),
         .init(x: 0.88, y: 0.35, width: 0.10, height: 0.3)]
      : kind == "dense" ? [.full]
      : kind == "sparse-depth" ? [.init(x:0.12,y:0.16,width:0.13,height:0.28)]
      : [.init(x: 0.1, y: 0.02, width: 0.8, height: 0.4)]
    func image(background: Bool) -> Data? {
      guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                    bytesPerRow: width*4, space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
      context.clear(CGRect(x:0,y:0,width:width,height:height))
      if background {
        context.setFillColor(CGColor(red: 0.05, green: 0.13, blue: 0.2, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        if kind=="sparse-depth" {
          // Own asymmetric backdrop, so a misregistered glass texture cannot
          // pass just because both sampled areas are one uniform color.
          context.setFillColor(CGColor(red:0.04,green:0.36,blue:0.34,alpha:1))
          for y in stride(from:0,to:height,by:80) {
            for x in stride(from:0,to:width,by:80) where (x/80+y/80)%2==0 {
              context.fill(CGRect(x:x,y:y,width:80,height:80))
            }
          }
        }
      }
      context.setFillColor(CGColor(red: 0.85, green: 0.36, blue: 0.10, alpha: 1))
      for r in subjects {
        context.fill(CGRect(x: r.x*Double(width), y: (1-r.y-r.height)*Double(height),
                            width: r.width*Double(width), height: r.height*Double(height)))
      }
      let bytes = NSMutableData()
      guard let image = context.makeImage(),
            let destination = CGImageDestinationCreateWithData(bytes, UTType.png.identifier as CFString, 1, nil)
      else { return nil }
      CGImageDestinationAddImage(destination, image, nil)
      guard CGImageDestinationFinalize(destination) else { return nil }
      return bytes as Data
    }
    let side = 128
    let values: [UInt8] = (0..<side*side).map { i in
      let x = (Double(i % side)+0.5)/Double(side), y = (Double(i/side)+0.5)/Double(side)
      return subjects.contains { x >= $0.x && x <= $0.x+$0.width && y >= $0.y && y <= $0.y+$0.height } ? 255 : 0
    }
    guard let bytes = image(background: true) else { return nil }
    return (bytes, PhotoAnalysis(aspect: Double(width)/Double(height),
                                 mask: PhotoSubjectMask(width: side, height: side, values: values),
                                 foreground: image(background: false)))
  }
  /// Replay of a Mac-produced alpha from our own generated portrait. This is
  /// deterministic test input, never an iOS extraction or production fallback.
  @MainActor
  private static func nativeAlphaReplay() -> (bytes: Data, analysis: PhotoAnalysis)? {
    let portrait: CGImage?
    let matte: CGImage?
    #if os(macOS)
      portrait = NSImage(named:DemoPhotoAssets.portrait)?.cgImage(forProposedRect:nil,context:nil,hints:nil)
      matte = NSImage(named:"DemoPortraitNativeAlphaReplayV1")?.cgImage(forProposedRect:nil,context:nil,hints:nil)
    #elseif canImport(UIKit)
      portrait = UIImage(named:DemoPhotoAssets.portrait)?.cgImage
      matte = UIImage(named:"DemoPortraitNativeAlphaReplayV1")?.cgImage
    #else
      portrait = nil;matte = nil
    #endif
    guard let portrait, let matte,
          portrait.width == matte.width, portrait.height == matte.height else { return nil }
    let image = CIImage(cgImage:portrait)
    let alpha = CIImage(cgImage:matte,options:[.colorSpace:NSNull()])
    let context = CIContext(options:[.useSoftwareRenderer:true])
    let clear = CIImage(color:.clear).cropped(to:image.extent)
    let foreground = image.applyingFilter("CIBlendWithMask",
      parameters:[kCIInputBackgroundImageKey:clear,kCIInputMaskImageKey:alpha])
    guard let mask = PhotoMaskRasterizer.make(alpha,context:context),
          let bytes = context.pngRepresentation(of:image,format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB()),
          let cutout = context.pngRepresentation(of:foreground,format:.RGBA8,colorSpace:CGColorSpaceCreateDeviceRGB())
    else { return nil }
    return (bytes,.init(aspect:Double(portrait.width)/Double(portrait.height),
      mask:mask,foreground:cutout,diagnostic:"fixture_mac_native_alpha_replay"))
  }
}
