import SwiftUI

/// The distinct city/conditions screen observed in UI20, not the weather face
/// repeated below a second clock/header. All forecast values come from a source.
struct WeatherScreen: View {
  @Environment(AppModel.self) private var model
  @State private var citySheet = false
  @State private var metric = WeatherMetric.temperature
  private var reading: WeatherReading? {
    model.connections.weatherDemo ? demo : model.connections.weather
  }
  private var demo: WeatherReading {
    let now=model.clock
    let hour=floor(now.timeIntervalSince1970/3600)*3600
    let hours=(1...6).map { i in
      WeatherHour(time:Date(timeIntervalSince1970:hour+Double(i)*3600),
        temperature:nil,rainChance:nil,wind:nil,code:i==1 ? 2:0,isDay:true)
    }
    return WeatherReading(city:"San Francisco",temperature:54,high:57,low:49,humidity:76,
      wind:7,code:2,sunset:nil,utcOffset:model.displayTimeZone.secondsFromGMT(for:now),
      observedAt:now,isDay:true,cloudCover:70,hourly:hours,timeZoneID:model.displayTimeZone.identifier)
  }
  var body: some View {
    ZStack {
      WeatherBackdrop(reading:reading,demo:model.connections.weatherDemo)
        .allowsHitTesting(false).accessibilityHidden(true)
      ScrollView {
        VStack(spacing:20) {
          header
          VStack(spacing:6) {
            Text(reading?.city ?? model.connections.city).font(.system(size:38,weight:.semibold))
              .lineLimit(1).minimumScaleFactor(0.7).accessibilityIdentifier("weather.app.city")
              .offset(y:12)
            Text(model.connections.weatherTemperature).font(.system(size:100,weight:.light))
              .accessibilityIdentifier("weather.temperature")
              .padding(.bottom,-10)
            Text(model.connections.weatherCondition.replacingOccurrences(of:" · Demo",with:""))
              .font(.system(size:23))
            Text(model.connections.weatherHighLow).font(.system(size:23)).padding(.top,-6)
          }.shadow(color:.black.opacity(0.18),radius:1,x:0,y:1)
            .frame(maxWidth:.infinity).padding(.top,6)
          source
          conditions
          if let reading {
            HStack {
              Label(reading.sunLabel(reading.sunrise),systemImage:"sunrise")
              Spacer()
              Label(reading.sunsetLabel,systemImage:"sunset")
            }.font(.system(size:22)).padding(22).background(.white.opacity(0.10),in:RoundedRectangle(cornerRadius:22))
          }
        }.padding(.horizontal,28).padding(.top,24).padding(.bottom,32)
      }.scrollIndicators(.hidden)
    }.foregroundStyle(.white)
      .sheet(isPresented:$citySheet) { WeatherCitySheet() }
  }
  private var header: some View {
    HStack {
      Button { citySheet=true } label: {
        Image(systemName:"list.bullet").font(.system(size:24,weight:.medium))
          .frame(width:52,height:52).background(.white.opacity(0.15),in:Circle())
          .contentShape(Circle())
      }.accessibilityLabel("Weather cities").accessibilityIdentifier("weather.cities")
      Spacer()
      Text(model.clock,style:.time).environment(\.timeZone,model.displayTimeZone)
        .font(.system(size:22,weight:.medium))
        .shadow(color:.black.opacity(0.24),radius:1,x:0,y:1)
    }.padding(.leading,6).padding(.trailing,20).buttonStyle(.plain)
  }
  private var source: some View {
    VStack(spacing:3) {
      Text(model.connections.weatherSource(at:model.now)).accessibilityIdentifier("weather.source")
      if !model.connections.weatherDemo {
        HStack(spacing:8) {
          Text("Sunrise \(reading?.sunLabel(reading?.sunrise) ?? "—") · AQI not supplied")
          Link("Open-Meteo",destination:URL(string:"https://open-meteo.com/")!)
        }
      }
    }.font(.system(size:11)).foregroundStyle(.white.opacity(0.85)).padding(.bottom,6)
  }
  private var conditions: some View {
    VStack(alignment:.leading,spacing:14) {
      HStack {
        VStack(alignment:.leading,spacing:3) {
          Text("Conditions").font(.system(size:28,weight:.semibold))
          Text(metric.legend(units:model.connections.weatherUnits)).font(.system(size:19))
            .foregroundStyle(Color(red:0.56,green:0.84,blue:0.94)).accessibilityIdentifier("weather.metric")
        }
        Spacer(minLength:8)
        HStack(spacing:1) {
          ForEach(WeatherMetric.allCases) { item in
            Button { metric=item } label: {
              Image(systemName:item.symbol).font(.system(size:23))
                .frame(width:52,height:38)
                .background(metric==item ? .white.opacity(0.17):.clear,in:Capsule())
                .contentShape(Capsule())
            }.accessibilityLabel(item.rawValue).accessibilityIdentifier("weather.mode."+item.rawValue)
              .accessibilityValue(metric==item ? "Selected":"")
          }
        }.padding(4).background(.blue.opacity(0.16),in:Capsule()).buttonStyle(.plain)
      }
      ScrollView(.horizontal) {
        HStack(spacing:20) {
          hour("Now",symbol:reading?.symbol ?? "questionmark.circle",
            value:metric.value(temperature:reading?.temperature,rain:nil,wind:reading?.wind,
              units:model.connections.weatherUnits),sunny:reading?.code==0)
          ForEach(reading?.upcomingHours ?? []) { item in
            hour(item.label(timeZone:reading?.timeZone ?? .gmt),symbol:item.symbol,
              value:metric.value(temperature:item.temperature,rain:item.rainChance,wind:item.wind,
                units:model.connections.weatherUnits),sunny:item.code==0)
          }
        }.padding(.bottom,6)
      }.scrollIndicators(.hidden).accessibilityIdentifier("weather.forecast")
      if reading?.upcomingHours.isEmpty != false {
        Text("Hourly forecast unavailable").font(.system(size:16)).foregroundStyle(.white.opacity(0.8))
          .accessibilityIdentifier("weather.forecast.unavailable")
      }
    }.padding(22).background(Color(red:0.05,green:0.27,blue:0.53).opacity(0.48),in:RoundedRectangle(cornerRadius:24))
  }
  private func hour(_ title:String,symbol:String,value:String,sunny:Bool) -> some View {
    VStack(spacing:18) {
      Text(title).font(.system(size:19,weight:.medium))
      Image(systemName:symbol).symbolRenderingMode(.palette)
        .foregroundStyle(sunny ? .yellow:.white,.yellow).font(.system(size:34)).frame(height:42)
      Text(value).font(.system(size:21,weight:.medium)).lineLimit(1).minimumScaleFactor(0.7)
    }.frame(width:58)
  }
}

private enum WeatherMetric: String, CaseIterable, Identifiable {
  case temperature="Temperature",rain="Precipitation",wind="Wind"
  var id:String { rawValue }
  var symbol:String { switch self { case .temperature:"cloud.sun.fill";case .rain:"drop.fill";case .wind:"wind" } }
  func legend(units:WeatherUnits) -> String {
    switch self {
    case .temperature:"Temperature (\(units == .celsius ? "°C":"°F"))"
    case .rain:"Precipitation (%)"
    case .wind:"Wind (\(units == .celsius ? "km/h":"mph"))"
    }
  }
  func value(temperature:Double?,rain:Double?,wind:Double?,units:WeatherUnits) -> String {
    switch self {
    case .temperature:return units.temperature(temperature)
    case .wind:return units.wind(wind)
    case .rain:
      guard let value=WeatherReading.valid(rain,in:0...100) else { return "—" }
      return "\(Int(value.rounded()))%"
    }
  }
}

private struct WeatherCitySheet: View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  @State private var draft=""
  @State private var sessionID=UUID()
  var body: some View {
    VStack(alignment:.leading,spacing:22) {
      HStack {
        Text("Weather city").font(.title2.bold())
        Spacer();Button("Done") { dismiss() }.accessibilityIdentifier("weather.city.done")
      }
      TextField("City",text:$draft).accessibilityIdentifier("weather.app.city.input")
        #if !os(tvOS)
        .textFieldStyle(.roundedBorder)
        #endif
      Picker("Units",selection:Binding(get:{model.connections.weatherUnits},set:{model.connections.weatherUnits=$0})) {
        ForEach(WeatherUnits.allCases,id:\.self) { Text($0.rawValue).tag($0) }
      }.pickerStyle(.segmented).accessibilityIdentifier("weather.app.units")
      Text(model.connections.status[.weather] ?? "Connect to public Open-Meteo weather for this city.")
        .font(.callout).foregroundStyle(.secondary).accessibilityIdentifier("weather.app.city.status")
      Button("Update weather") {
        let requestedCity=draft
        let ticket=sessionID
        model.connections.city=requestedCity
        Task {
          await model.connections.connect(.weather)
          guard ticket==sessionID,model.connections.city==requestedCity,!Task.isCancelled else { return }
          if model.connections.weather != nil && !model.connections.weatherFetchFailed { dismiss() }
        }
      }.disabled(model.connections.busy.contains(.weather) || draft.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
        .accessibilityIdentifier("weather.app.city.update")
      Spacer(minLength:0)
    }.padding(28).frame(minWidth:300,minHeight:320).background(.background)
      .onAppear { sessionID=UUID();draft=model.connections.city }
      .onDisappear { sessionID=UUID() }
  }
}
