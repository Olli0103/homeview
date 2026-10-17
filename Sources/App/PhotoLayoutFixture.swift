import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Original geometric fixtures. Only instantiated behind --uitesting.
enum PhotoLayoutFixture {
  static func make(_ kind: String) -> (bytes: Data, analysis: PhotoAnalysis)? {
    guard ["top", "edges", "dense"].contains(kind) else { return nil }
    let width = kind == "edges" ? 800 : 600
    let height = kind == "edges" ? 400 : 600
    let subjects: [PhotoRect] = kind == "edges"
      ? [.init(x: 0.02, y: 0.35, width: 0.10, height: 0.3),
         .init(x: 0.88, y: 0.35, width: 0.10, height: 0.3)]
      : kind == "dense" ? [.full] : [.init(x: 0.1, y: 0.02, width: 0.8, height: 0.4)]
    func image(background: Bool) -> Data? {
      guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                    bytesPerRow: width*4, space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
      if background {
        context.setFillColor(CGColor(red: 0.05, green: 0.13, blue: 0.2, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
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
}
