import Foundation
@main struct HostPowerMetadata {
 static func main() throws {
  let field=readPowerAdapterInformation()
  let result:[String:Any]=["reportedAdapterWatts":field.reportedWatts.map { $0 as Any } ?? NSNull(),
   "adequacy":"not available","actualDeliveryMeasured":false,"adapterDictionarySerialized":false,
   "batteryMonitoringChanged":false,"chargingControlInvoked":false]
  print(String(decoding:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),as:UTF8.self))
 }
}
