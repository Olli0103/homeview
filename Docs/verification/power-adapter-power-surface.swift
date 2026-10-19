import Foundation
#if os(macOS) || targetEnvironment(macCatalyst)
import IOKit.ps
func declaredAdapterMetadata() -> Unmanaged<CFDictionary>? { IOPSCopyExternalPowerAdapterDetails() }
#elseif os(watchOS)
import WatchKit
@MainActor func declaredWatchBattery() -> (Bool,Float,WKInterfaceDeviceBatteryState) {
 let device=WKInterfaceDevice.current()
 return (device.isBatteryMonitoringEnabled,device.batteryLevel,device.batteryState)
}
#elseif os(iOS) || os(visionOS)
import UIKit
@MainActor func declaredDeviceBattery() -> (Bool,Float,UIDevice.BatteryState) {
 let device=UIDevice.current
 return (device.isBatteryMonitoringEnabled,device.batteryLevel,device.batteryState)
}
#endif
func declaredEnergyPolicy() -> (Bool,ProcessInfo.ThermalState) {
 (ProcessInfo.processInfo.isLowPowerModeEnabled,ProcessInfo.processInfo.thermalState)
}
// Type-check only: no battery-monitor setting is changed, no function invoked.
