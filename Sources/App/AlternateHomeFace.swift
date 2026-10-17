import SwiftUI

/// UI45: large clock, thermostat and Home above a scene/camera row.
struct AlternateHomeFace: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(red: 0.78, green: 0.77, blue: 0.69), Color(red: 0.48, green: 0.5, blue: 0.46),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
      PrismBackground(theme: 2).opacity(0.12)
      VStack(spacing: 10) {
        HStack(spacing: 10) {
          AnalogClock(date: model.clock, timeZone: model.displayTimeZone, tint: .white).padding(8)
            .background(.white.opacity(0.12), in: Circle()).frame(width: 383, height: 383)
          VStack(spacing: 10) {
            Button {
              model.route = .thermostat
            } label: {
              Tile(glass: true) {
                VStack(spacing: 12) {
                  Text("\(model.data.home.temperature)–\(model.data.home.temperature)").font(
                    .system(size: 36, weight: .medium))
                  Text("Thermostat").font(.system(size: 17, weight: .semibold))
                  Text("Living Room").font(.system(size: 16)).opacity(0.6)
                }
              }
            }.accessibilityIdentifier("alternate.thermostat")
            Button {
              model.navigate(.home)
            } label: {
              Tile(glass: true) {
                Image(systemName: "homekit").font(.system(size: 61, weight: .light))
              }
            }
          }
        }.frame(height: 383)
        HStack(spacing: 10) {
          scene("sofa.fill", "Chill Out")
          scene("fork.knife", "Dinner Time")
          Button {
            model.route = .camera(2)
          } label: {
            MockCameraScene(index: 2).clipShape(RoundedRectangle(cornerRadius: 34))
          }.accessibilityLabel("Living room camera")
        }
      }.padding(10)
    }.foregroundStyle(.white).buttonStyle(.plain)
  }
  private func scene(_ symbol: String, _ title: String) -> some View {
    Button {
      model.command(.scene(title))
      model.banner("\(title) · Mock scene applied")
    } label: {
      Tile(glass: true) {
        VStack(spacing: 12) {
          Image(systemName: symbol).font(.system(size: 39))
          Text(title).font(.system(size: 20, weight: .semibold))
          Text("Scene").font(.system(size: 18)).opacity(0.65)
        }
      }
    }.accessibilityIdentifier("scene.\(title)")
  }
}
