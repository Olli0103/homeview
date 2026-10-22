import SwiftUI

/// Own public layer effect on system text. No saved/extracted font contours.
struct WeatherGlassTemperature: View {
  let value: String
  let size: CGFloat
  let phase: Double
  let cover: Float
  let night: Float
  var highContrastNight = false
  private var number: Text {
    if value.hasSuffix("°") {
      return Text("\(Text(String(value.dropLast())).font(.system(size:size,weight:.regular)))\(Text("°").font(.system(size:size*0.86,weight:.regular)).baselineOffset(size*0.12))")
    }
    return Text(value).font(.system(size:size,weight:.regular))
  }
  @ViewBuilder var body: some View {
    if highContrastNight {
      number.tracking(-4).lineLimit(1).minimumScaleFactor(0.6).foregroundStyle(.white)
        .accessibilityIdentifier("weather.temperature")
    } else {
    number.tracking(-4)
      .lineLimit(1).minimumScaleFactor(0.6).foregroundStyle(.white).blur(radius:1.4)
      .visualEffect { content,geometry in
        let bounds=geometry.frame(in:.named("weather-face"))
        return content.layerEffect(ShaderLibrary.weatherGlassNumber(
          .float2(Float(bounds.minX),Float(bounds.minY)),.float2(600,600),
          .float(Float(phase)),.float(cover),.float(night)),
          maxSampleOffset:CGSize(width:16,height:16))
      }
      .shadow(color:.black.opacity(0.06),radius:1,x:0,y:1)
      .accessibilityIdentifier("weather.temperature")
    }
  }
}
