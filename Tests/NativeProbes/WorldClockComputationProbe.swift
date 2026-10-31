import CryptoKit
import Foundation

/// Fixed synthetic city/date workload; no UI, wall-clock changes or accounts.
@main struct WorldClockComputationProbe {
  static func main() async throws {
    let parser = ISO8601DateFormatter()
    let dates = ["2026-03-29T00:59:55Z", "2026-10-25T00:59:55Z",
      "2026-06-20T23:59:55Z", "2026-12-21T12:00:00Z",
      "2026-01-01T11:59:55Z", "2011-12-30T09:59:55Z"].map { parser.date(from: $0)! }
    let cities = WorldCity.catalogue + [
      WorldCity(name: "Synthetic date-line site", zone: "Pacific/Apia", latitude: -13.83, longitude: -171.75),
      WorldCity(name: "Synthetic UTC-12", zone: "Etc/GMT+12", latitude: 0, longitude: -180),
      WorldCity(name: "Synthetic Oslo site", zone: "Europe/Oslo", latitude: 59.91, longitude: 10.75),
      WorldCity.city(for: "Asia/Shanghai")!]
    let inputs = dates.flatMap { day in cities.flatMap { city in
      (0..<12).map { second in (city, day.addingTimeInterval(Double(second))) }
    } }
    var elapsed: [Double] = [], results: [DaylightWindow] = [], hashes: [String] = []
    for _ in 0..<3 {
      let clock = ContinuousClock(), start = clock.now
      let values = inputs.map { city, date in
        DaylightWindow.compute(latitude: city.latitude, longitude: city.longitude, dayOf: date, zone: city.timeZone)
      }
      let duration = start.duration(to: clock.now).components
      elapsed.append(Double(duration.seconds) + Double(duration.attoseconds) / 1e18)
      let rows: [[String: Any]] = values.map { w in
        ["kind": String(describing: w.kind),
         "sunrise": w.sunrise.map { $0.timeIntervalSince1970 } as Any? ?? NSNull(),
         "sunset": w.sunset.map { $0.timeIntervalSince1970 } as Any? ?? NSNull(),
         "sunriseFraction": w.sunriseFraction as Any? ?? NSNull(),
         "sunsetFraction": w.sunsetFraction as Any? ?? NSNull(),
         "intervals": w.daylightIntervals.map { [$0.lowerBound, $0.upperBound] }]
      }
      let data = try JSONSerialization.data(withJSONObject: rows, options: [.sortedKeys])
      hashes.append(SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined())
      results = values
    }
    var mismatches = 0
    await withTaskGroup(of: (Int, DaylightWindow).self) { group in
      for i in stride(from: 0, to: inputs.count, by: 7) {
        let (city, date) = inputs[i]
        group.addTask {
          (i, DaylightWindow.compute(latitude: city.latitude, longitude: city.longitude,
            dayOf: date, zone: city.timeZone))
        }
      }
      for await (i, value) in group { if value != results[i] { mismatches += 1 } }
    }
    print(String(decoding: try JSONSerialization.data(withJSONObject: [
      "calls_per_pass": inputs.count, "passes": 3, "elapsed_seconds": elapsed,
      "output_sha256": hashes, "concurrent_checks": (inputs.count + 6) / 7,
      "concurrent_mismatches": mismatches,
      "qualification": "Fixed native optimized solar-window workload, not whole-app CPU/GPU, energy or physical-device acceptance."
    ], options: [.sortedKeys]), as: UTF8.self))
  }
}
