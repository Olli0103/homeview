import Combine
import SwiftUI
#if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
import EventKit
#endif

struct CalendarView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  private var minimumHitSide:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  @State private var selected: Int?
  private let labels = ["S", "M", "T", "W", "T", "F", "S"]
  private var calendar: Calendar {
    var value = Calendar(identifier: .gregorian)
    value.timeZone = model.displayTimeZone
    value.firstWeekday = 1
    return value
  }
  private var day: Int { selected ?? calendar.component(.weekday, from: model.clock) - 1 }
  private var start: Date { calendar.dateInterval(of: .weekOfYear, for: model.clock)!.start }
  private func date(_ index: Int) -> Date {
    calendar.date(byAdding: .day, value: index, to: start)!
  }
  var body: some View {
    if model.connections.requested.contains(.calendar), !model.connections.personalUnlocked {
      DeviceUnlockView()
    } else {
      calendarContent
    }
  }
  private var calendarContent: some View {
    VStack(alignment: .leading, spacing: 16) {
      AppHeader(title:model.dateLabel("MMMM"),closeSize:max(48,minimumHitSide))
      HStack(spacing: 6) {
        ForEach(0..<7) { i in
          Button {
            selected = i
          } label: {
            VStack(spacing: 13) {
              Text(labels[i]).font(.system(size: 20)).foregroundStyle(.gray)
              Text("\(calendar.component(.day, from: date(i)))").font(
                .system(size: 33, weight: .medium)
              ).frame(width: 54, height: 54)
                .background(day == i ? .red : .clear, in: Circle())
                .foregroundStyle(
                  day == i
                    ? .white
                    : calendar.component(.month, from: date(i))
                      == calendar.component(.month, from: model.clock) ? .black : .gray)
            }.frame(minWidth:minimumHitSide,minHeight:minimumHitSide).contentShape(Rectangle())
          }.accessibilityIdentifier("calendar.day.\(i)")
            .accessibilityValue(day == i ? "Selected":"")
        }
      }.frame(maxWidth: .infinity).padding(.top, 16).padding(.bottom, 2)
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          let events: [CalendarEntry] =
            model.connections.requested.contains(.calendar)
            ? model.connections.events.map { event in
              let f = DateFormatter()
              f.timeStyle = .short
              f.timeZone = model.displayTimeZone
              return CalendarEntry(
                id: event.id, time: event.allDay ? "All day" : f.string(from: event.start), title: event.title,
                subtitle: [event.calendar, event.location].filter { !$0.isEmpty }.joined(separator: " · "), color: 0,
                cancelled: event.cancelled)
            }
            : day == calendar.component(.weekday, from: model.clock) - 1
              ? CalendarEntry.fixtures : Array(CalendarEntry.fixtures.prefix(2))
          if model.connections.enabled.contains(.calendar) || model.connections.status[.calendar] != nil {
            HStack {
              Text(model.connections.busy.contains(.calendar) ? "Updating agenda…"
                : model.connections.status[.calendar] ?? "Connected calendar")
              Spacer()
              Button("Refresh") {
                Task { await model.connections.refreshCalendar(date(day), timeZone: model.displayTimeZone) }
              }.accessibilityIdentifier("calendar.refresh")
            }.font(.system(size: 13)).foregroundStyle(.gray)
              .accessibilityElement(children: .contain)
              .accessibilityIdentifier("calendar.sourceStatus")
          }
          if events.isEmpty {
            Text("No events").font(.system(size: 24)).foregroundStyle(.gray).padding(30)
          }
          ForEach(events.sorted { $0.cancelled && !$1.cancelled }) { entry in
            let color: Color = entry.cancelled ? .gray : [Color.green, .orange, .blue][entry.color]
            HStack(alignment: .top, spacing: 14) {
              RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 5)
              VStack(alignment: .leading, spacing: 6) {
                Text((entry.cancelled ? "CANCELED: " : "") + entry.title).font(
                  .system(size: 25, weight: .medium)
                ).strikethrough(entry.cancelled)
                Label(entry.time, systemImage: "checkmark.circle").font(.system(size: 19))
                  .strikethrough(entry.cancelled)
                if !entry.cancelled { Text(entry.subtitle).font(.system(size: 17)).opacity(0.7) }
              }.foregroundStyle(color)
              Spacer()
            }.padding(18).frame(minHeight: 92).background(
              color.opacity(0.12), in: RoundedRectangle(cornerRadius: 24))
          }
        }.padding(.horizontal, 32).padding(.bottom, 25)
      }
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
      .task(id: date(day)) {
        await model.connections.refreshCalendar(date(day), timeZone: model.displayTimeZone)
      }
      #if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
      .onReceive(NotificationCenter.default.publisher(for: .EKEventStoreChanged)) { _ in
        Task { await model.connections.refreshCalendar(date(day), timeZone: model.displayTimeZone) }
      }
      #endif
  }
}
struct TimerView: View {
  @Environment(AppModel.self) private var model
  @State private var minutes = 15
  @State private var controlsVisible = !ProcessInfo.processInfo.arguments.contains(
    "--reference-resting")
  private var testsKeepControlsVisible: Bool {
    let args=ProcessInfo.processInfo.arguments
    return args.contains("--uitesting") && !args.contains("--timer-idle-test")
  }
  private var selected: Countdown? {
    model.data.timers.first(where: { $0.id == model.selectedTimer }) ?? model.data.timers.last
  }
  private func showControls() {
    controlsVisible = true
    model.interact()
  }
  var body: some View {
    ZStack {
      Color.black
      if let t = selected {
        TimerTicks(fraction: max(0, min(1, t.remaining(at: model.now) / t.duration)))
        VStack(spacing: -10) {
          Text(t.display(at: model.now)).font(.system(size: 112, weight: .medium, design: .rounded))
            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            .accessibilityIdentifier("timer.countdown")
          Text(t.remaining(at: model.now) == 0 ? "DONE" : t.title.uppercased()).font(
            .system(size: 30, weight: .semibold)
          ).lineLimit(1).minimumScaleFactor(0.5).foregroundStyle(Color.timerAccent)
            .accessibilityIdentifier("timer.title")
        }.foregroundStyle(.white).frame(maxWidth:.infinity).padding(.horizontal,94).offset(y: -6)
        if controlsVisible {
          VStack {
            HStack {
              RoundButton(
                symbol: "xmark", color: .white.opacity(0.14), foreground: .white, label: "Close"
              ) { model.route = .personal }
              Spacer()
              RoundButton(
                symbol: "plus", color: .white.opacity(0.14), foreground: .white,
                label: "Add another timer"
              ) { model.addTimer(seconds: Double(minutes * 60), title: "\(minutes) min") }
            }.padding(32)
            Spacer()
            Text(
              model.data.nativeTimerIDs.contains(t.id) ? "System alert enabled" : "Foreground timer"
            ).font(.system(size: 14)).foregroundStyle(.gray).accessibilityIdentifier(
              "timer.systemStatus")
            HStack(spacing: 30) {
              RoundButton(
                symbol: t.deadline == nil ? "play.fill" : "pause.fill",
                color: .timerAccent.opacity(0.22), foreground: .timerAccent, size: 62,
                label: t.deadline == nil ? "Resume timer" : "Pause timer"
              ) { model.toggleTimer(t.id) }.disabled(t.remaining(at: model.now) == 0)
                .accessibilityIdentifier("timer.pause")
              RoundButton(
                symbol: "trash", color: .white.opacity(0.14), foreground: .white, size: 62,
                label: "Delete timer"
              ) { model.removeTimer(t.id) }.accessibilityIdentifier("timer.delete")
            // The 44pt choices row plus 10pt bottom inset uses 54pt of the
            // former 90pt gap. Keep status/actions clear of the central title.
            }.padding(.bottom, model.data.timers.count > 1 ? 36:90)
            if model.data.timers.count > 1 {
              ScrollView(.horizontal) {
                HStack {
                  ForEach(model.data.timers) { timer in
                    Button {
                      model.selectedTimer = timer.id
                    } label: {
                      Text(timer.display(at: model.now)).font(.system(size: 18)).foregroundStyle(.white).padding(10)
                        .background(.white.opacity(timer.id == t.id ? 0.25 : 0.1), in: Capsule())
                    }
                    .accessibilityIdentifier("timer.select."+timer.id.uuidString)
                    .accessibilityLabel(timer.title+" timer, "+timer.display(at:model.now))
                    .accessibilityValue(timer.id == t.id ? "Selected":"Not selected")
                  }
                }.padding(.horizontal, 40)
              }.frame(height:44).padding(.bottom,10)
                .accessibilityElement(children:.contain)
                .accessibilityIdentifier("timer.choices")
                .accessibilityLabel("Timer choices")
                .accessibilityValue("\(model.data.timers.count) timers")
            }
          }
        } else {
          Button(action:showControls) {
            Color.clear.contentShape(Rectangle())
          }.frame(maxWidth:.infinity,maxHeight:.infinity)
            .accessibilityLabel("Show timer controls")
            .accessibilityValue(t.display(at:model.now))
            .accessibilityHint("Shows pause, resume and delete controls.")
            .accessibilityIdentifier("timer.revealControls")
        }
      } else {
        timerSetup
      }
    }.buttonStyle(.plain)
      .onTapGesture(perform:showControls)
      .onChange(of: model.now) { _, now in
        if !testsKeepControlsVisible,
          now.timeIntervalSince(model.lastInteraction) > 4
        {
          controlsVisible = false
        }
      }
  }
  private var timerSetup: some View {
    VStack(spacing: 20) {
      AppHeader(title: "Timers", light: true)
      Spacer()
      Image(systemName: "timer").font(.system(size: 76)).foregroundStyle(Color.timerAccent)
      HStack(spacing: 30) {
        RoundButton(
          symbol: "minus", color: .white.opacity(0.12), foreground: .white,
          label: "Decrease minutes"
        ) { minutes = max(1, minutes - 1) }
        Text("\(minutes) min").font(.system(size: 58, weight: .medium, design: .rounded))
        RoundButton(
          symbol: "plus", color: .white.opacity(0.12), foreground: .white, label: "Increase minutes"
        ) { minutes = min(1440, minutes + 1) }
      }
      Pill(title: "Start Timer", symbol: "play.fill", tint: .timerAccent, textColor: .black) {
        model.addTimer(seconds: Double(minutes * 60), title: "\(minutes) min")
      }.padding(.horizontal, 65).accessibilityIdentifier("timer.start")
      HStack(spacing: 14) {
        ForEach([1, 5, 15, 30], id: \.self) { m in
          Button("\(m) min") { minutes = m }.padding(13).background(
            .white.opacity(0.1), in: Capsule())
        }
      }
      Spacer()
    }.foregroundStyle(.white)
  }
}
struct RecipeCover: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    ZStack(alignment: .bottom) {
      RecipeArtwork(recipe: model.recipe)
      LinearGradient(
        colors: [.clear, .black.opacity(0.15), .black.opacity(0.8)], startPoint: .center,
        endPoint: .bottom)
      VStack(alignment: .leading, spacing: 14) {
        AppHeader(light: true)
        Spacer()
        Text(model.recipe.title).font(.system(size: 34, weight: .semibold)).padding(
          .horizontal, 40)
        Text(
          "\(model.recipe.source) · \(model.recipe.durationLabel) · \(model.recipe.servingsLabel)"
        ).font(.system(size: 22)).opacity(0.75).padding(
          .horizontal, 40)
        HStack(spacing: 12) {
          Pill(
            title: "Ingredients", symbol: "checklist", tint: .white.opacity(0.22), textColor: .white
          ) { model.route = .ingredients }.accessibilityIdentifier("recipe.ingredients")
          Pill(
            title: "Start Cooking", symbol: "frying.pan", tint: .white.opacity(0.22),
            textColor: .white
          ) {
            model.startCooking()
          }.accessibilityIdentifier("recipe.start")
        }.padding(.horizontal, 32).padding(.bottom, 32)
      }.foregroundStyle(.white)
    }
  }
}
struct IngredientsView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  @State private var checked: Set<Int> = []
  private var minimumHitHeight:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      AppHeader(title: "Ingredients")
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          ForEach(model.recipe.ingredients.indices, id: \.self) { i in
            Button {
              if checked.contains(i) { checked.remove(i) } else { checked.insert(i) }
            } label: {
              HStack(spacing: 16) {
                Image(systemName: checked.contains(i) ? "checkmark.circle.fill" : "circle")
                  .foregroundStyle(checked.contains(i) ? .green : .gray)
                Text(model.recipe.ingredients[i]).strikethrough(checked.contains(i))
                Spacer()
              }.font(.system(size: 24))
                .frame(maxWidth:.infinity,minHeight:minimumHitHeight,alignment:.leading)
                .contentShape(Rectangle())
            }.accessibilityIdentifier("ingredient.\(i)")
              .accessibilityValue(checked.contains(i) ? "Checked":"Unchecked")
          }
        }.padding(32)
      }
      Pill(title: "Start Cooking", symbol: "frying.pan") {
        model.startCooking()
      }.padding(30)
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
  }
}
struct CookingView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  private var minimumHitHeight:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  var body: some View {
    let stepCount=model.recipe.steps.count,currentStep=model.cookingStep
    VStack(alignment: .leading, spacing: 20) {
      VStack(spacing: 7) {
        AppHeader(title: model.recipe.title)
        Canvas { context,_ in
          for index in 0..<stepCount {
            let dot=Path(ellipseIn:CGRect(x:index*14,y:0,width:7,height:7))
            context.fill(dot,with:.color(index == currentStep ? .black:.gray.opacity(0.4)))
          }
        }.frame(width:CGFloat(max(0,stepCount*14-7)),height:7).allowsHitTesting(false)
      }
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          Text("Step \(model.cookingStep+1)").font(.system(size: 18)).foregroundStyle(.gray)
            .accessibilityLabel("Step \(model.cookingStep+1) of \(model.recipe.steps.count)")
            .accessibilityIdentifier("cooking.step")
          Text(model.recipe.steps[model.cookingStep].text).font(.system(size: 30, weight: .regular))
            .lineSpacing(6).frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier(
              "cooking.text")
        }.padding(.horizontal, 35).padding(.top, 16)
      }.frame(maxHeight: .infinity)
      Button { model.presentRecipeHandoff() } label: {
        Text("Continue on another device").font(.system(size:18))
          .frame(maxWidth:.infinity,minHeight:minimumHitHeight,alignment:.leading)
          .contentShape(Rectangle())
      }.padding(.horizontal,35).accessibilityIdentifier("cooking.handoff")
      if let minutes = model.recipe.steps[model.cookingStep].minutes {
        Button {
          if model.addTimer(
            seconds: Double(minutes * 60),
            title: "\(model.recipe.title) · Step \(model.cookingStep+1)") {
            model.banner("\(minutes)-minute cooking timer started")
          }
        } label: {
          Label("Start \(minutes)-minute timer", systemImage: "timer").font(
            .system(size: 22, weight: .semibold)
          ).foregroundStyle(.orange)
            .frame(maxWidth:.infinity,minHeight:minimumHitHeight,alignment:.leading)
            .contentShape(Rectangle())
        }.padding(.horizontal, 35).accessibilityIdentifier("cooking.timer")
      }
      HStack(spacing: 16) {
        RoundButton(symbol: "chevron.left", label: "Previous step") {
          model.moveCookingStep(-1)
        }.disabled(model.cookingStep == 0)
        Pill(
          title: model.cookingStep == model.recipe.steps.count - 1 ? "Finish" : "Next Step",
          symbol: model.cookingStep == model.recipe.steps.count - 1 ? "checkmark" : "chevron.right"
        ) {
          model.moveCookingStep(1)
        }.accessibilityIdentifier("cooking.next")
        RoundButton(symbol: model.data.pinnedRecipe ? "pin.fill" : "pin", label: "Pin recipe") {
          model.pinRecipe()
        }.accessibilityIdentifier("recipe.pin")
          .accessibilityValue(model.data.pinnedRecipe ? "Pinned":"Not pinned")
      }.padding(30)
    }.background(.white).foregroundStyle(.black)
  }
}
struct RemindersView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  private var minimumHitSide:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  @State private var newItem = ""
  @FocusState private var inputFocused:Bool
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      AppHeader(title:"Reminders",closeSize:max(48,minimumHitSide))
      Text("Today").font(.system(size: 40, weight: .bold)).padding(.horizontal, 32)
      ScrollView {
        VStack(spacing: 0) {
          ForEach(model.reminders) { item in
            HStack {
              Button {
                if let i = model.reminders.firstIndex(where: { $0.id == item.id }) {
                  model.reminders[i].completed.toggle()
                }
              } label: {
                HStack(spacing: 16) {
                  Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.completed ? .orange : .gray)
                  Text(item.title).strikethrough(item.completed)
                  Spacer()
                }.frame(minHeight:minimumHitSide).contentShape(Rectangle())
              }.accessibilityIdentifier("reminder.\(item.title)")
                .accessibilityLabel(item.title)
                .accessibilityValue(item.completed ? "Completed":"Not completed")
              Button {
                model.reminders.removeAll { $0.id == item.id }
              } label: {
                Image(systemName: "minus.circle").foregroundStyle(.gray)
                  .frame(width:minimumHitSide,height:minimumHitSide).contentShape(Rectangle())
              }.accessibilityLabel("Delete \(item.title)")
            }.font(.system(size: 24)).padding(.vertical, 17)
            Divider()
          }
        }.padding(.horizontal, 32)
      }
      HStack {
        TextField("New reminder", text: $newItem).textFieldStyle(.plain).font(.system(size: 22))
          .focused($inputFocused)
          .frame(minHeight:minimumHitSide).contentShape(Rectangle())
          .simultaneousGesture(TapGesture().onEnded { inputFocused=true })
          .accessibilityIdentifier("reminder.input")
        RoundButton(symbol: "plus", color: .orange.opacity(0.2),size:max(48,minimumHitSide),label:"Add reminder") {
          let s = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
          if !s.isEmpty,model.addLocalReminder(s) { newItem = "" }
        }.accessibilityIdentifier("reminder.add")
      }.padding(30)
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
  }
}
struct MusicView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  private var minimumHitSide:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  @State private var browse = false
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(red: 0.31, green: 0.46, blue: 0.62), Color(red: 0.13, green: 0.22, blue: 0.35),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
      VStack(spacing: 17) {
        AppHeader(title:browse ? "Music":"",light:true,closeSize:max(48,minimumHitSide))
        if browse { library } else { player }
        Spacer(minLength: 0)
      }.foregroundStyle(.white)
    }.buttonStyle(.plain)
  }
  private var library: some View {
    VStack {
      ForEach(Fixtures.songs.indices, id: \.self) { i in
        Button {
          model.song = i
          model.progress = 0
          model.playing = false
          model.togglePlayback()
          browse = false
        } label: {
          HStack(spacing: 20) {
            DemoAlbumCover().frame(width: 78, height: 78).clipShape(
              RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 6) {
              Text(Fixtures.songs[i]).font(.system(size: 23, weight: .semibold))
              Text("Bundled demo audio").font(.system(size: 17)).opacity(0.65)
            }
            Spacer()
            Image(systemName: "play.fill")
          }.padding(.horizontal, 30)
        }
      }
    }
  }
  private var player: some View {
    VStack(spacing: 17) {
      DemoAlbumCover().frame(width: 270, height: 270).clipped()
        .clipShape(RoundedRectangle(cornerRadius: 18)).shadow(radius: 20)
        .overlay(alignment: .bottomTrailing) { MusicArtworkInfoButton(source: .demo) }
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Text(Fixtures.songs[model.song]).font(.system(size: 25, weight: .semibold))
          Text("Demo Artist").font(.system(size: 21)).opacity(0.6)
        }
        Spacer()
        Button {
          browse = true
        } label: {
          Image(systemName: "list.bullet").font(.system(size: 23))
            .frame(minWidth:minimumHitSide,minHeight:minimumHitSide).contentShape(Rectangle())
        }.accessibilityLabel("Music library")
      }.padding(.horizontal, 40)
      ProgressView(value: min(180, model.progress), total: 180).tint(.white).padding(
        .horizontal, 40)
        .accessibilityLabel("Demo progress")
        .accessibilityValue("\(Int(model.progress.isFinite ? max(0,min(180,model.progress)):0)) of 180 seconds")
        .accessibilityIdentifier("player.progress")
        .accessibilityRespondsToUserInteraction(false)
      HStack(spacing: 62) {
        Button {
          model.song = (model.song + Fixtures.songs.count - 1) % Fixtures.songs.count
          model.progress = 0
        } label: {
          Image(systemName: "backward.fill")
            .frame(minWidth:minimumHitSide,minHeight:minimumHitSide).contentShape(Rectangle())
        }.accessibilityLabel("Previous track")
        Button {
          model.togglePlayback()
        } label: {
          Image(systemName: model.playing ? "pause.fill" : "play.fill").font(.system(size: 43))
            .frame(minWidth:minimumHitSide,minHeight:minimumHitSide).contentShape(Rectangle())
        }.accessibilityLabel(model.playing ? "Pause" : "Play").accessibilityIdentifier(
          "player.play")
        Button {
          model.song = (model.song + 1) % Fixtures.songs.count
          model.progress = 0
        } label: {
          Image(systemName: "forward.fill")
            .frame(minWidth:minimumHitSide,minHeight:minimumHitSide).contentShape(Rectangle())
        }.accessibilityLabel("Next track").accessibilityIdentifier("player.next")
      }.font(.system(size: 29))
    }
  }
}
struct WorldClockView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  private var minimumHitSide:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  @State private var choosing = false
  @State private var search = ""
  private var selected: [WorldCity] {
    model.data.worldClockZones.compactMap { id in WorldCity.catalogue.first { $0.zone == id } }
  }
  var body: some View {
    VStack(spacing: 8) {
      AppHeader(title: choosing ? "Add City" : "World Clock",closeSize:max(48,minimumHitSide))
      HStack {
        Text(choosing ? "Choose a time zone" : "\(selected.count) of 12 cities")
        Spacer()
        Button { choosing.toggle(); search = "" } label: {
          Text(choosing ? "Done" : "Add City")
            .frame(minWidth:minimumHitSide,minHeight:minimumHitSide)
            .contentShape(Rectangle())
        }.disabled(!choosing && selected.count >= 12)
          .accessibilityIdentifier("world.add")
      }.font(.system(size: 18)).padding(.horizontal, 30)
      if choosing {
        TextField("Search cities", text: $search).textFieldStyle(.plain)
          .padding(12).background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
          .padding(.horizontal, 30).accessibilityIdentifier("world.search")
        ScrollView {
          VStack(spacing: 8) {
            ForEach(WorldCity.catalogue.filter {
              (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
               || $0.zone.localizedCaseInsensitiveContains(search))
              && !model.data.worldClockZones.contains($0.zone)
            }) { city in
              Button {
                guard model.addWorldCity(city.zone) else { return }
                choosing = false; search = ""
              } label: {
                HStack { Text(city.name); Spacer(); Image(systemName: "plus.circle") }
                  .font(.system(size: 24)).padding(18)
                  .frame(minHeight:minimumHitSide).contentShape(Rectangle())
              }.accessibilityIdentifier("world.choose.\(city.zone)")
            }
          }.padding(.horizontal, 18)
        }
      } else {
        ScrollView {
          VStack(spacing: 4) {
            ForEach(selected) { city in
              let reading = WorldClockReading(city: city, instant: model.clock,
                referenceZone: model.displayTimeZone)
              HStack(spacing: 12) {
                Image(systemName: reading.daylight ? "sun.max.fill" : "moon.fill")
                  .foregroundStyle(reading.daylight ? .orange : .indigo)
                  .accessibilityLabel(reading.daylight ? "Daylight estimate" : "Night estimate")
                VStack(alignment: .leading, spacing: 4) {
                  Text(city.name).font(.system(size: 25, weight: .medium))
                  Text(reading.date + " · " + reading.offset).font(.system(size: 13))
                  if let relation=reading.dayRelation {
                    Text(relation)
                      .font(.system(size: 13, weight: .semibold))
                  }
                }
                Spacer(minLength: 0)
                Text(reading.time).font(.system(size: 34, weight: .light)).monospacedDigit()
                  .accessibilityIdentifier("world.time.\(city.zone)")
                Button { model.removeWorldCity(city.zone) } label: {
                  Image(systemName: "minus.circle").font(.system(size: 22)).padding(8)
                    .frame(minWidth:minimumHitSide,minHeight:minimumHitSide)
                    .contentShape(Rectangle())
                }.accessibilityLabel("Remove \(city.name)")
                  .accessibilityIdentifier("world.remove.\(city.zone)")
              }.padding(.horizontal, 25).padding(.vertical, 13)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("world.row.\(city.zone)")
              Divider().padding(.horizontal, 30)
            }
            if selected.isEmpty { Text("Add a city to see its local time.").padding(30) }
          }
        }
        Text("Sun position is an offline estimate, not current weather.")
          .font(.system(size: 12)).foregroundStyle(.gray).padding(.bottom, 14)
      }
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
  }
}
struct AlarmsView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  private var minimumHitSide:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  @State private var hour = 7
  @State private var minute = 0
  var body: some View {
    VStack(spacing: 18) {
      AppHeader(title:"Alarms",closeSize:max(48,minimumHitSide))
      ScrollView {
        VStack(spacing: 18) {
          ForEach(model.data.alarms) { alarm in
            HStack {
              VStack(alignment: .leading, spacing: 6) {
                Text(String(format: "%02d:%02d", alarm.hour, alarm.minute)).font(
                  .system(size: 51, weight: .light))
                Text(
                  model.data.nativeAlarmIDs.contains(alarm.id)
                    ? "System alert enabled" : alarm.enabled ? "Foreground alarm" : "Off"
                ).font(.system(size: 15)).foregroundStyle(.gray)
              }
              Spacer()
              Button {
                model.toggleAlarm(alarm.id)
              } label: {
                Image(systemName: alarm.enabled ? "checkmark.circle.fill" : "circle").font(
                  .system(size: 38)
                ).foregroundStyle(alarm.enabled ? .green : .gray)
                  .frame(minWidth:minimumHitSide,minHeight:minimumHitSide)
                  .contentShape(Rectangle())
              }.accessibilityLabel("Toggle alarm at \(String(format:"%02d:%02d",alarm.hour,alarm.minute))")
                .accessibilityValue(alarm.enabled ? "On":"Off").accessibilityIdentifier(
                "alarm.toggle.\(alarm.id)")
              Button {
                model.removeAlarm(alarm.id)
              } label: {
                Image(systemName: "trash").foregroundStyle(.gray)
                  .frame(minWidth:minimumHitSide,minHeight:minimumHitSide)
                  .contentShape(Rectangle())
              }.accessibilityLabel("Delete alarm at \(String(format:"%02d:%02d",alarm.hour,alarm.minute))").accessibilityIdentifier(
                "alarm.delete.\(alarm.id)")
            }.padding(.horizontal, 32)
          }
        }
      }
      HStack(spacing: 24) {
        Picker("Hour", selection: $hour) {
          ForEach(0..<24) { h in Text(String(format: "%02d", h)).tag(h) }
        }
        Picker("Minute", selection: $minute) {
          ForEach(0..<60) { m in Text(String(format: "%02d", m)).tag(m) }
        }
      }.font(.system(size: 25)).padding(.horizontal, 32)
      Button {model.addAlarm(hour:hour,minute:minute)} label: {
        Label("Add Alarm",systemImage:"plus").font(.system(size:21,weight:.medium))
          .frame(maxWidth:.infinity).padding(.vertical,17)
          .frame(minHeight:minimumHitSide)
          .background(.black.opacity(0.08),in:Capsule()).foregroundStyle(.primary)
      }.padding(.horizontal,32).accessibilityIdentifier("alarm.add")
      Text(
        "System alerts use AlarmKit on iPhone and iPad after permission. Other targets use foreground alarms."
      ).font(.system(size: 16)).foregroundStyle(.gray).padding(.horizontal, 32).padding(.bottom, 24)
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
  }
}

struct TimerTicks: View {
  let fraction: Double
  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let radius = min(size.width, size.height) * 0.40
      for i in 0..<60 {
        let angle = Double(i) * Double.pi / 30 - Double.pi / 2
        let c = cos(angle)
        let s = sin(angle)
        let length = radius / pow(pow(abs(c), 5) + pow(abs(s), 5), 0.2)
        var p = Path()
        p.move(to: CGPoint(x: center.x + (length - 20) * c, y: center.y + (length - 20) * s))
        p.addLine(to: CGPoint(x: center.x + length * c, y: center.y + length * s))
        context.stroke(
          p, with: .color(Color.timerAccent.opacity(Double(i) / 60 < fraction ? 1 : 0.18)),
          style: StrokeStyle(lineWidth: 6, lineCap: .round))
      }
    }.allowsHitTesting(false)
  }
}
