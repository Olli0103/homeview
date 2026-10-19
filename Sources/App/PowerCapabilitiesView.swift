import SwiftUI
#if os(macOS)
import IOKit.ps
#endif

func readPowerAdapterInformation() -> PowerAdapterInformation {
  #if os(macOS)
    guard let details=IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() else {
      return PowerAdapterInformation(reportedNumber:nil)
    }
    // Select only this numeric field; never serialize the adapter dictionary.
    let value=(details as NSDictionary).object(forKey:kIOPSPowerAdapterWattsKey) as? NSNumber
    return PowerAdapterInformation(reportedNumber:value)
  #else
    return PowerAdapterInformation(reportedNumber:nil)
  #endif
}

struct PowerCapabilitiesView:View {
  @Environment(\.dismiss) private var dismiss
  var body:some View {
    VStack(spacing:0) {
      HStack {
        Text("Power adapter").font(.title2.bold());Spacer()
        Button("Done") { dismiss() }.accessibilityIdentifier("power.capabilities.done")
      }.padding(24)
      ScrollView {
        VStack(alignment:.leading,spacing:20) {
          Text("Adapter adequacy: Not available").font(.headline)
            .accessibilityIdentifier("power.assessment")
          Text("HomeView does not determine whether this device’s adapter is sufficient. No adapter warning or replacement advice is inferred from battery percentage, charging state, Low Power Mode or temperature.")
            .accessibilityIdentifier("power.noheuristics")
          #if os(macOS)
            MacAdapterReport()
          #elseif targetEnvironment(macCatalyst)
            Text("Newer Mac Catalyst SDKs can expose adapter metadata, but this app does not integrate or assess that path. No adequate-power result is claimed.")
              .accessibilityIdentifier("power.platform")
          #elseif os(iOS) || os(visionOS)
            Text("Public device APIs expose battery state and charge level, not a generic wattage or adequacy result. HomeView does not turn on battery monitoring for this information page.")
              .accessibilityIdentifier("power.platform")
          #else
            Text("This app has no adapter measurement or adequacy assessment on this platform. No value is guessed.")
              .accessibilityIdentifier("power.platform")
          #endif
          Text("An OS-reported adapter wattage, where available, is not an independent measurement of power delivered to the device. A valid comparison would also need a documented requirement and appropriate hardware tests. Neither is claimed here.")
            .accessibilityIdentifier("power.limits")
          Text("No charger control, battery settings, Home connection or personal-data permission is changed.")
            .font(.callout).foregroundStyle(.gray)
        }.padding(24)
      }
    }.frame(minWidth:300,minHeight:400).background(.white).foregroundStyle(.black)
  }
}

#if os(macOS)
private struct MacAdapterReport:View {
  @State private var information=PowerAdapterInformation(reportedNumber:nil)
  var body:some View {
    VStack(alignment:.leading,spacing:12) {
      if let watts=information.reportedWatts {
        Text("OS-reported adapter field: \(watts) W · Not a delivered-power or adequacy measurement.")
          .accessibilityIdentifier("power.reported")
      } else {
        Text("No reported adapter wattage is available. The API does not distinguish a missing adapter field from an unavailable/error result here. This is not an underpowered-adapter finding.")
          .accessibilityIdentifier("power.reported")
      }
      Button("Refresh reported field") { information=readPowerAdapterInformation() }
        .accessibilityIdentifier("power.refresh")
    }.onAppear { information=readPowerAdapterInformation() }
  }
}
#endif
