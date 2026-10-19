# Adapter capability disclosure · #72

19 October 2026. This fulfils the issue’s **explicitly unavailable** acceptance branch, not an insufficient-adapter detector. Original F102 remains blocked and parity is false.

Settings → **Power adapter information** always states **Adapter adequacy: Not available**. No warning/replacement advice is derived from battery percentage, charging state, Low Power Mode or temperature. No charger control, battery-monitoring enablement, Home connection or personal permission change occurs.

## Public platform boundary

| Platform | Verified surface and implemented scope |
| --- | --- |
| iOS/iPadOS, visionOS | UIDevice battery state/level are not generic adapter wattage or adequacy. The page does not enable monitoring. No detector. |
| macOS | Public IOPSCopyExternalPowerAdapterDetails, optional kIOPSPowerAdapterWattsKey only. The app selects this scalar, never serializes the dictionary. NULL can mean no adapter **or error**; a missing/malformed value means unavailable, not underpowered. |
| Mac Catalyst | Current IOKit metadata surface is public from Mac Catalyst 18.4 and typechecks. This app’s reader is deliberately macOS-only; Catalyst integration is not claimed. |
| watchOS | WKInterfaceDevice exposes battery state/level, not an implemented adapter assessment. Reduced Watch app does not include this information sheet. |
| tvOS | UIDevice battery surface explicitly unavailable; tested negative compilation. App information sheet offers no measurement. |

The actual macOS production reader returned **140 W**, OS-reported metadata only. It is not measured power delivered under load, nor proof of the device’s requirement, cable/adapter compatibility or sufficiency. No physical adapter replacement, wattmeter or iPad power test occurred. Numeric input rejects Boolean, fractional, non-finite, non-positive and out-of-range values without rounding/clamping.

## Evidence

[Receipt](verification/power-adapter-capability.json), [frozen 176-source manifest](verification/power-adapter-source.json). 229 Core tests passed (3 new scalar cases). One UI case on each iPad/iPhone simulator passed, zero skips/failures/runtime warnings: explicit unavailable text, no battery guessing, return to Mock home only. All 23 compiled inputs unchanged before/after; installed apps read back. Six PNGs decoded; both contact sheets visually reviewed; four selected images published. Five native SDK builds passed: iOS, macOS, tvOS, visionOS, watchOS. Generator regenerated externally byte-identically; Python AST checked. SDK success is not hardware acceptance.

Seven public-surface typechecks passed: six positive platform surfaces including Catalyst plus expected tvOS battery rejection. They do not execute or enable battery monitoring. [Probe](verification/power-adapter-power-surface.swift), [negative probe](verification/power-adapter-tvos-battery-negative.swift). [Host probe](verification/power-adapter-host-read.swift) uses the production reader; compile with Sources/Core/PowerAdapterInformation.swift and Sources/App/PowerCapabilitiesView.swift plus SwiftUI/IOKit on macOS. No whole adapter dictionary is logged.

The external 199-entry source/compiled-input ZIP was read back entry by entry; its digest is in the receipt. No original private imagery or real personal fixture is published. A future detector requires a supported assessment path, documented device requirement and appropriate hardware tests; a charged battery or successful build is not a substitute.

## Sources inspected

Current local Xcode 27 SDK headers UIDevice.h, WKInterfaceDevice.h, IOPowerSources.h and IOPSKeys.h plus these Apple documents, fetched 19 October 2026:

- [UIDevice battery state](https://developer.apple.com/documentation/uikit/uidevice/batterystate-swift.property)
- [Low Power Mode policy](https://developer.apple.com/documentation/foundation/processinfo/islowpowermodeenabled)
- [Watch battery state](https://developer.apple.com/documentation/watchkit/wkinterfacedevice/batterystate)
- [External power adapter details](https://developer.apple.com/documentation/iokit/1523866-iopscopyexternalpoweradapterdeta)

Earlier guessed IOKit/Watch URL spellings returned 404; those failures were not treated as API absence. Correct canonical documentation and SDK declarations were checked.
