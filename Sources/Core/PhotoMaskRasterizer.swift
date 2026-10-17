#if canImport(CoreImage)
import CoreImage

enum PhotoMaskRasterizer {
  /// render(_:toBitmap:) produces top-to-bottom bitmap rows. Do not flip them again.
  static func make(_ image: CIImage, context: CIContext) -> PhotoSubjectMask? {
    let extent = image.extent
    guard !extent.isEmpty, !extent.isInfinite,
          extent.width.isFinite, extent.height.isFinite else { return nil }
    let side = 128
    let normalized = image.transformed(by: CGAffineTransform(translationX: -extent.minX, y: -extent.minY))
      .transformed(by: CGAffineTransform(scaleX: CGFloat(side)/extent.width, y: CGFloat(side)/extent.height))
    var topDown = [UInt8](repeating: 0, count: side * side)
    context.render(normalized, toBitmap: &topDown, rowBytes: side,
                   bounds: CGRect(x: 0, y: 0, width: side, height: side), format: .R8, colorSpace: nil)
    return PhotoSubjectMask(width: side, height: side, values: topDown)
  }
}
#endif
