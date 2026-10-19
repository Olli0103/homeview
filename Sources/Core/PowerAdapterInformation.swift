import Foundation
import CoreFoundation

/// An optional OS-reported adapter field, never a measurement or adequacy verdict.
struct PowerAdapterInformation:Equatable,Sendable {
  let reportedWatts:Int?
  init(reportedNumber:NSNumber?) {
    guard let value=reportedNumber,CFGetTypeID(value) != CFBooleanGetTypeID() else {
      reportedWatts=nil;return
    }
    let number=value.doubleValue
    // IOPS documents a CFNumber integer in watts. Never round, clamp or infer.
    guard number.isFinite,number>=1,number<=Double(Int32.max),number.rounded()==number else {
      reportedWatts=nil;return
    }
    reportedWatts=Int(number)
  }
}
