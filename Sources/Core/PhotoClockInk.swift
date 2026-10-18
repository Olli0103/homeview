import Foundation

/// Destination-space ink, not a subject segmentation or extracted font outline.
struct PhotoClockInkRaster: Sendable {
  let width: Int
  let height: Int
  let values: [UInt8]
  init?(width: Int, height: Int, values: [UInt8]) {
    guard (1...512).contains(width), (1...512).contains(height),
          values.count == width * height else { return nil }
    self.width = width; self.height = height; self.values = values
  }
}

struct PhotoClockInkCoverage: Equatable, Sendable {
  let overall: Double
  let perDigit: [Double]
  /// Our expanded-band policy: protect both the entire time and each digit.
  /// This is an ink denominator, deliberately distinct from rectangle coverage.
  var allowed: Bool {
    perDigit.count == 4 && ([overall] + perDigit).allSatisfy {
      $0.isFinite && (0...1).contains($0)
    } && overall <= 0.18 && perDigit.allSatisfy { $0 <= 0.30 }
  }
}

struct PhotoClockInkCandidate: Sendable {
  let frame: PhotoRect
  let glyphs: [PhotoClockInkRaster]
}

struct PhotoClockDigitFrame: Equatable, Sendable {
  let digit: Int
  let rect: PhotoRect
  let stroke: Double
}

/// Shared logical geometry for the visible own paths and their ink rasters.
enum PhotoClockGlyphLayout {
  static func digits(in text: String) -> [Int]? {
    let digits = text.filter { !$0.isWhitespace }.compactMap(\.wholeNumberValue)
    guard digits.count == 4,
          text.filter({ !$0.isWhitespace }).count == 4,
          digits.allSatisfy({ (0...9).contains($0) }) else { return nil }
    return digits
  }
  static func unit(for digits: [Int]) -> Double? {
    guard digits.count == 4, digits.allSatisfy({ (0...9).contains($0) }) else { return nil }
    return 400 / digits.reduce(0.0) { $0 + ($1 == 1 ? 0.75 : 1) }
  }
  static func frames(digits: [Int], in band: PhotoRect) -> [PhotoClockDigitFrame]? {
    guard let unit = unit(for: digits), band.valid,
          band == band.intersection(.full) else { return nil }
    var x = band.x
    return digits.enumerated().map { index, digit in
      let width = unit * (digit == 1 ? 0.75 : 1) / 540 * band.width
      let result = PhotoClockDigitFrame(digit: digit,
        rect: .init(x: x, y: band.y, width: width, height: band.height),
        stroke: (unit - 6) * 0.31)
      x += width + (index == 1 ? 120 : 10) / 540 * band.width
      return result
    }
  }
}
