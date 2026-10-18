import Foundation

/// Top-left-origin normalized source or destination coordinates.
struct PhotoRect: Codable, Equatable, Sendable {
  var x: Double
  var y: Double
  var width: Double
  var height: Double
  static let full = PhotoRect(x: 0, y: 0, width: 1, height: 1)
  var area: Double { max(0, width) * max(0, height) }
  var valid: Bool {
    [x, y, width, height].allSatisfy(\.isFinite) && width > 0 && height > 0
  }
  func intersection(_ other: Self) -> Self {
    guard valid, other.valid else { return .init(x: 0, y: 0, width: 0, height: 0) }
    let left = max(x, other.x), top = max(y, other.y)
    return .init(x: left, y: top, width: max(0, min(x + width, other.x + other.width) - left),
                 height: max(0, min(y + height, other.y + other.height) - top))
  }
}

/// Standard summed-area table. Values are mask strength, not binary subject identity.
struct PhotoSubjectMask: Sendable {
  let width: Int
  let height: Int
  private let sums: [UInt64]
  let total: UInt64
  init?(width: Int, height: Int, values: [UInt8]) {
    guard (1...512).contains(width), (1...512).contains(height),
          values.count == width * height else { return nil }
    self.width = width
    self.height = height
    let stride = width + 1
    var table = [UInt64](repeating: 0, count: stride * (height + 1))
    for y in 0..<height {
      var row: UInt64 = 0
      for x in 0..<width {
        row += UInt64(values[y * width + x])
        table[(y + 1) * stride + x + 1] = table[y * stride + x + 1] + row
      }
    }
    sums = table
    total = table.last!
  }
  private func sample(_ rect: PhotoRect) -> (sum: UInt64, pixels: Int) {
    let r = rect.intersection(.full)
    guard r.valid else { return (0, 0) }
    let x0 = max(0, min(width, Int(floor(r.x * Double(width)))))
    let y0 = max(0, min(height, Int(floor(r.y * Double(height)))))
    let x1 = max(x0, min(width, Int(ceil((r.x + r.width) * Double(width)))))
    let y1 = max(y0, min(height, Int(ceil((r.y + r.height) * Double(height)))))
    let stride = width + 1
    // Pair subtractions to avoid unsigned intermediate underflow.
    let right = sums[y1 * stride + x1] - sums[y0 * stride + x1]
    let left = sums[y1 * stride + x0] - sums[y0 * stride + x0]
    return (right - left, (x1 - x0) * (y1 - y0))
  }
  func coverage(_ rect: PhotoRect) -> Double {
    let s = sample(rect)
    return s.pixels > 0 ? Double(s.sum) / (Double(s.pixels) * 255) : 0
  }
  func retention(_ crop: PhotoRect) -> Double {
    total > 0 ? min(1, Double(sample(crop).sum) / Double(total)) : 1
  }
}

enum PhotoClockPosition: String, Codable, CaseIterable, Identifiable, Sendable {
  case automatic, top, middle, bottom
  var id: String { rawValue }
  var centerY: Double {
    switch self { case .automatic, .top: 0.23; case .middle: 0.5; case .bottom: 0.76 }
  }
  var rect: PhotoRect { .init(x: 0.05, y: centerY - 0.16, width: 0.9, height: 0.32) }
}

struct PhotoAdjustment: Codable, Equatable, Sendable {
  var clock: PhotoClockPosition = .automatic
  var automaticCrop = true
  var horizontal = 0.5
  var vertical = 0.5
}

extension PhotoAdjustment {
  private enum CodingKeys: String, CodingKey { case clock, automaticCrop, horizontal, vertical }
  init(from decoder: any Decoder) throws {
    self.init()
    guard let values = try? decoder.container(keyedBy: CodingKeys.self) else { return }
    clock = (try? values.decode(PhotoClockPosition.self, forKey: .clock)) ?? .automatic
    automaticCrop = (try? values.decode(Bool.self, forKey: .automaticCrop)) ?? true
    func offset(_ key: CodingKeys) -> Double {
      guard let value = try? values.decode(Double.self, forKey: key), value.isFinite else { return 0.5 }
      return min(1, max(0, value))
    }
    horizontal = offset(.horizontal)
    vertical = offset(.vertical)
  }
}

struct PhotoComposition: Equatable, Sendable {
  var crop: PhotoRect = .full
  var destination: PhotoRect = .full
  var clock: PhotoClockPosition = .top
  var coverage = 0.0
  var retention = 1.0
  var depthEnabled = false
  var protectedCoverage = 0.0
  /// An optional larger band is only selected with a usable foreground matte.
  var clockFrame: PhotoRect?
  var clockRect: PhotoRect { clockFrame ?? clock.rect }
}

enum PhotoPlacement {
  /// Ranking, candidate positions and thresholds are our own choices, not Apple's rules.
  static func choose(aspect: Double, mask: PhotoSubjectMask?,
                     protectedRegions: [PhotoRect] = [], foregroundAvailable: Bool = true,
                     adjustment: PhotoAdjustment = .init()) -> PhotoComposition {
    guard aspect.isFinite, (0.0001...10_000).contains(aspect) else { return .init() }
    // Rectangles are explicit protection hints, not a fabricated segmentation mask.
    // Too many hints conservatively protect the complete image instead of dropping faces.
    let protected: [PhotoRect] = protectedRegions.count > 64 ? [.full] : protectedRegions.compactMap {
      guard $0.valid else { return nil }
      let rect = $0.intersection(.full)
      return rect.valid ? rect : nil
    }
    let w = min(1, 1 / aspect), h = min(1, aspect)
    func unit(_ value: Double) -> Double { value.isFinite ? min(1, max(0, value)) : 0.5 }
    let center = PhotoRect(x: (1-w)/2, y: (1-h)/2, width: w, height: h)
    let crops: [PhotoRect]
    if adjustment.automaticCrop, (mask?.total ?? 0) > 0 || !protected.isEmpty {
      crops = [0.5, 0.25, 0.75, 0.0, 1.0].map {
        PhotoRect(x: (1-w) * $0, y: (1-h) * $0, width: w, height: h)
      }
    } else if adjustment.automaticCrop {
      crops = [center]
    } else {
      crops = [.init(x: (1-w) * unit(adjustment.horizontal),
                     y: (1-h) * unit(adjustment.vertical), width: w, height: h)]
    }
    var candidates = crops.map { crop in
      let regionRetention = protected.map { $0.intersection(crop).area / $0.area }.min() ?? 1
      return PhotoComposition(crop: crop, retention: min(mask?.retention(crop) ?? 1, regionRetention))
    }
    // If no square crop keeps the detected subjects, preserve the complete image.
    if adjustment.automaticCrop {
      let safeCrops = candidates.filter { $0.retention >= 0.985 }
      if safeCrops.isEmpty {
        let destination = PhotoRect(x: (1-min(1,aspect))/2, y: (1-min(1,1/aspect))/2,
                                    width: min(1,aspect), height: min(1,1/aspect))
        candidates = [.init(destination: destination)]
      } else {
        // Clock readability must not buy a crop that discards a detected subject.
        candidates = safeCrops
      }
    }
    let positions: [PhotoClockPosition] = adjustment.clock == .automatic
      ? [.top, .bottom, .middle] : [adjustment.clock]
    var best: PhotoComposition?
    var bestScore = Double.infinity
    for candidate in candidates {
      for position in positions {
        var layout = candidate
        layout.clock = position
        let visible = position.rect.intersection(layout.destination)
        if let mask, visible.valid {
          let source = PhotoRect(
            x: layout.crop.x + (visible.x-layout.destination.x)/layout.destination.width*layout.crop.width,
            y: layout.crop.y + (visible.y-layout.destination.y)/layout.destination.height*layout.crop.height,
            width: visible.width/layout.destination.width*layout.crop.width,
            height: visible.height/layout.destination.height*layout.crop.height)
          layout.coverage = mask.coverage(source) * visible.area / position.rect.area
          layout.depthEnabled = foregroundAvailable && mask.total > 0 && layout.coverage <= 0.18
        }
        layout.protectedCoverage = protected.reduce(0) { sum, region in
          let r = region.intersection(layout.crop)
          guard r.valid else { return sum }
          let destination = PhotoRect(
            x: layout.destination.x + (r.x-layout.crop.x)/layout.crop.width*layout.destination.width,
            y: layout.destination.y + (r.y-layout.crop.y)/layout.crop.height*layout.destination.height,
            width: r.width/layout.crop.width*layout.destination.width,
            height: r.height/layout.crop.height*layout.destination.height)
          return sum + destination.intersection(position.rect).area / position.rect.area
        }
        layout.protectedCoverage = min(1, layout.protectedCoverage)
        let displacement = abs(layout.crop.x-center.x) + abs(layout.crop.y-center.y)
        let positionCost = position == .top ? 0.0 : position == .bottom ? 0.015 : 0.03
        // A real foreground layer may occlude clock ink. Without one, opaque
        // clock ink must not trade away detected faces for a slightly nicer crop.
        let protectionCost = layout.depthEnabled ? 0 : layout.protectedCoverage * 1_000
        let score = protectionCost + (1-layout.retention)*8 + layout.coverage + displacement*0.01 + positionCost
        // Stable iteration and epsilon retain the preferred layout on near-ties.
        if score < bestScore - 0.000_001 { best = layout; bestScore = score }
      }
    }
    if let best, !best.depthEnabled, best.protectedCoverage > 0.000_001,
       adjustment.clock == .automatic, adjustment.automaticCrop, !protected.isEmpty {
      // No full-size overlay avoids the detected heads. Preserve the whole photo
      // below a separate clock band; never invent a cutout or discard a face.
      let availableHeight = 0.58
      let width = min(1, availableHeight * aspect)
      let height = width / aspect
      return PhotoComposition(
        destination: .init(x: (1-width)/2, y: 0.42+(availableHeight-height)/2,
                           width: width, height: height),
        clock: .top, retention: 1, depthEnabled: false, protectedCoverage: 0)
    }
    if var expanded = best, expanded.depthEnabled, adjustment.clock == .automatic,
       adjustment.automaticCrop,
       expanded.destination == .full, let mask {
      // Own bounded candidates informed by the tall reference states, not a
      // claim about Apple's placement algorithm. Keep the same occlusion limit.
      for height in [0.90, 0.56] {
        let mediumY: Double = switch expanded.clock {
          case .automatic, .top: 0.05
          case .middle: 0.22
          case .bottom: 0.39
        }
        let rect = PhotoRect(x:0.05,y:height == 0.90 ? 0.05:mediumY,
                             width:0.90,height:height)
        let source = PhotoRect(x:expanded.crop.x+rect.x*expanded.crop.width,
          y:expanded.crop.y+rect.y*expanded.crop.height,
          width:rect.width*expanded.crop.width,height:rect.height*expanded.crop.height)
        let coverage = mask.coverage(source)
        guard coverage <= 0.18 else { continue }
        expanded.clockFrame = rect
        expanded.coverage = coverage
        expanded.protectedCoverage = min(1,protected.reduce(0) { sum, region in
          let r=region.intersection(expanded.crop)
          guard r.valid else { return sum }
          let destination=PhotoRect(x:(r.x-expanded.crop.x)/expanded.crop.width,
            y:(r.y-expanded.crop.y)/expanded.crop.height,
            width:r.width/expanded.crop.width,height:r.height/expanded.crop.height)
          return sum+destination.intersection(rect).area/rect.area
        })
        return expanded
      }
    }
    return best ?? .init()
  }
}

struct PhotoAnalysis: Sendable {
  let aspect: Double
  let mask: PhotoSubjectMask?
  let foreground: Data?
  var protectedRegions: [PhotoRect] = []
  var diagnostic = "unspecified"
}
