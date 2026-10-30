import Combine
import SwiftUI
#if canImport(EventKit) && (os(iOS) || os(macOS) || os(visionOS))
import EventKit
#endif

struct CalendarView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.locale) private var inheritedLocale
  @Environment(\.nativeCanvasScale) private var canvasScale
  private var minimumHitSide:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  @State private var selected: Int?
  private var labels:[String] {model.calendarPresentation.weekdaySymbols}
  private var calendar: Calendar {model.calendarPresentation.calendar}
  private var day: Int { selected ?? model.calendarPresentation.weekdayIndex(at:model.clock) }
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
      AppHeader(title:model.calendarPresentation.monthName,closeSize:max(48,minimumHitSide))
        .environment(\.locale,inheritedLocale)
      HStack(spacing: 6) {
        ForEach(0..<7) { i in
          Button {
            selected = i
          } label: {
            VStack(spacing: 13) {
              Text(labels[i]).font(.system(size: 20)).foregroundStyle(.gray)
              Text(model.calendarPresentation.dayText(calendar.component(.day,from:date(i)))).font(
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
            : day == model.calendarPresentation.weekdayIndex(at:model.clock)
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
                if !entry.cancelled, model.connections.enabled.contains(.calendar),
                  model.connections.personalUnlocked {
                  Text("Share title, time and calendar source on shared faces as "+(model.profile ?? "Device holder")+". No location is shared.")
                    .font(.system(size:14)).foregroundStyle(.secondary)
                  Button("Share this event") {
                    if !model.connections.shareCalendarEvent(entry.id,label:model.profile ?? "Device holder") {
                      model.error="Event not shared. Refresh access or remove an existing card (maximum four)."
                    }
                  }.frame(minHeight:minimumHitSide)
                    .accessibilityIdentifier("calendar.share."+entry.id)
                }
              }.foregroundStyle(color)
              Spacer()
            }.padding(18).frame(minHeight: 92).background(
              color.opacity(0.12), in: RoundedRectangle(cornerRadius: 24))
          }
        }.padding(.horizontal, 32).padding(.bottom, 25)
      }
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
      .environment(\.locale,model.calendarLocale)
      .environment(\.layoutDirection,model.calendarPresentation.rightToLeft ? .rightToLeft:.leftToRight)
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
  @Environment(\.dynamicTypeSize) private var textSize
  @Environment(\.nativeCanvasScale) private var canvasScale
  @ScaledMetric(relativeTo:.headline) private var titleSize:CGFloat=30
  @ScaledMetric(relativeTo:.caption) private var statusSize:CGFloat=14
  @ScaledMetric(relativeTo:.body) private var choiceSize:CGFloat=18
  @ScaledMetric(relativeTo:.headline) private var setupHeaderSize:CGFloat=23
  @ScaledMetric(relativeTo:.title2) private var setupClockSize:CGFloat=22
  @ScaledMetric(relativeTo:.largeTitle) private var setupDurationSize:CGFloat=58
  @ScaledMetric(relativeTo:.headline) private var setupStartSize:CGFloat=21
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
        if textSize.isAccessibilitySize {
          accessibleTimer(t)
        } else {
        VStack(spacing: -10) {
          Text(t.display(at: model.now)).font(.system(size: 112, weight: .medium, design: .rounded))
            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            .accessibilityIdentifier("timer.countdown")
          Text(t.remaining(at: model.now) == 0 ? "DONE" : t.title.uppercased()).font(
            .system(size: titleSize, weight: .semibold)
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
            ).font(.system(size: statusSize)).foregroundStyle(.gray).accessibilityIdentifier(
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
            #if os(tvOS)
              // Extend the focus region across the empty horizontal space so
              // Down from either corner control can reach the timer actions.
              .frame(maxWidth:.infinity).focusSection()
            #endif
            if model.data.timers.count > 1 {
              ScrollView(.horizontal) {
                HStack {
                  ForEach(model.data.timers) { timer in
                    Button {
                      model.selectedTimer = timer.id
                    } label: {
                      Text(timer.display(at: model.now)).font(.system(size: choiceSize)).foregroundStyle(.white).padding(10)
                        .background(.white.opacity(timer.id == t.id ? 0.25 : 0.1), in: Capsule())
                    }
                    .accessibilityIdentifier("timer.select."+timer.id.uuidString)
                    .accessibilityLabel(timer.title+" timer, "+timer.display(at:model.now))
                    .accessibilityValue(timer.id == t.id ? "Selected":"Not selected")
                  }
                }.padding(.horizontal, 40)
              }.frame(height:choiceHeight).padding(.bottom,10)
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
  private var choiceHeight:CGFloat { max(44,ceil(choiceSize*1.3+20)) }
  private var accessibleControlSize:CGFloat { max(62,ceil(44/max(canvasScale,0.01))) }
  private func accessibleTimer(_ t:Countdown) -> some View {
    // Large text gets its own scrollable reading order, not a compressed dial.
    // Keep explicit actions available even when the normal dial is resting.
    ScrollView {
      VStack(spacing:24) {
        HStack {
          RoundButton(symbol:"xmark",color:.white.opacity(0.14),foreground:.white,
            size:accessibleControlSize,label:"Close") { model.route = .personal }
          Spacer()
          RoundButton(symbol:"plus",color:.white.opacity(0.14),foreground:.white,
            size:accessibleControlSize,label:"Add another timer") {
              model.addTimer(seconds:Double(minutes*60),title:"\(minutes) min")
            }
        }.padding(.horizontal,32).padding(.top,32)
        VStack(spacing:8) {
          Text(t.display(at:model.now)).font(.system(size:112,weight:.medium,design:.rounded))
            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
            .accessibilityIdentifier("timer.countdown")
          Text(t.remaining(at:model.now)==0 ? "DONE":t.title.uppercased())
            .font(.system(size:titleSize,weight:.semibold)).foregroundStyle(Color.timerAccent)
            .multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
            .accessibilityIdentifier("timer.title")
        }.padding(.horizontal,32)
        Text(model.data.nativeTimerIDs.contains(t.id) ? "System alert enabled":"Foreground timer")
          .font(.system(size:statusSize)).foregroundStyle(.gray)
          .multilineTextAlignment(.center).padding(.horizontal,32)
          .accessibilityIdentifier("timer.systemStatus")
        HStack(spacing:30) {
          RoundButton(symbol:t.deadline==nil ? "play.fill":"pause.fill",
            color:.timerAccent.opacity(0.22),foreground:.timerAccent,size:accessibleControlSize,
            label:t.deadline==nil ? "Resume timer":"Pause timer") { model.toggleTimer(t.id) }
            .disabled(t.remaining(at:model.now)==0).accessibilityIdentifier("timer.pause")
          RoundButton(symbol:"trash",color:.white.opacity(0.14),foreground:.white,
            size:accessibleControlSize,label:"Delete timer") { model.removeTimer(t.id) }
            .accessibilityIdentifier("timer.delete")
        }
        if model.data.timers.count>1 {
          ScrollView(.horizontal) {
            HStack {
              ForEach(model.data.timers) { timer in
                Button { model.selectedTimer=timer.id } label: {
                  Text(timer.display(at:model.now)).font(.system(size:choiceSize)).padding(10)
                    .background(.white.opacity(timer.id==t.id ? 0.25:0.1),in:Capsule())
                }.accessibilityIdentifier("timer.select."+timer.id.uuidString)
                  .accessibilityLabel(timer.title+" timer, "+timer.display(at:model.now))
                  .accessibilityValue(timer.id==t.id ? "Selected":"Not selected")
              }
            }.padding(.horizontal,40)
          }.frame(height:choiceHeight).accessibilityElement(children:.contain)
            .accessibilityIdentifier("timer.choices").accessibilityLabel("Timer choices")
            .accessibilityValue("\(model.data.timers.count) timers")
        }
      }.frame(maxWidth:.infinity).padding(.bottom,64)
    }.background(.black).foregroundStyle(.white)
      .accessibilityIdentifier("timer.accessible.content")
  }
  @ViewBuilder private var timerSetup: some View {
    if textSize.isAccessibilitySize {
      accessibleTimerSetup
    } else {
    VStack(spacing: 20) {
      AppHeader(title:"Timers",light:true,titleFontSize:setupHeaderSize,clockFontSize:setupClockSize)
      Spacer()
      Image(systemName: "timer").font(.system(size: 76)).foregroundStyle(Color.timerAccent)
      HStack(spacing: 30) {
        RoundButton(
          symbol: "minus", color: .white.opacity(0.12), foreground: .white,
          label: "Decrease minutes"
        ) { minutes = max(1, minutes - 1) }
        Text("\(minutes) min").font(.system(size: setupDurationSize, weight: .medium, design: .rounded))
        RoundButton(
          symbol: "plus", color: .white.opacity(0.12), foreground: .white, label: "Increase minutes"
        ) { minutes = min(1440, minutes + 1) }
      }
      Pill(title: "Start Timer", symbol: "play.fill", tint: .timerAccent, textColor: .black,fontSize:setupStartSize) {
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
  private var accessibleTimerSetup:some View {
    ScrollView {
      VStack(spacing:24) {
        HStack(spacing:12) {
          RoundButton(symbol:"xmark",color:.white.opacity(0.18),foreground:.white,
            size:accessibleControlSize,label:"Close") {model.route = .personal}
            .accessibilityIdentifier("close")
          Spacer(minLength:0)
          Text("Timers").font(.system(size:setupHeaderSize,weight:.semibold))
          Spacer(minLength:0)
          Color.clear.frame(width:accessibleControlSize,height:1).accessibilityHidden(true)
        }.padding(.horizontal,32).padding(.top,32)
        Text(model.clock,style:.time).font(.system(size:setupClockSize,weight:.medium))
          .environment(\.timeZone,model.displayTimeZone)
        Text("\(minutes) min").font(.system(size:setupDurationSize,weight:.medium,design:.rounded))
          .multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true).padding(.horizontal,32)
        HStack(spacing:40) {
          RoundButton(symbol:"minus",color:.white.opacity(0.12),foreground:.white,
            size:accessibleControlSize,label:"Decrease minutes") {minutes=max(1,minutes-1)}
          RoundButton(symbol:"plus",color:.white.opacity(0.12),foreground:.white,
            size:accessibleControlSize,label:"Increase minutes") {minutes=min(1440,minutes+1)}
        }
        Pill(title:"Start Timer",symbol:"play.fill",tint:.timerAccent,textColor:.black,fontSize:setupStartSize) {
          model.addTimer(seconds:Double(minutes*60),title:"\(minutes) min")
        }.padding(.horizontal,65).accessibilityIdentifier("timer.start")
        LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:16) {
          ForEach([1,5,15,30],id:\.self) { m in
            Button {minutes=m} label: {
              Text("\(m) min").padding(13).frame(maxWidth:.infinity)
                .background(.white.opacity(0.1),in:Capsule())
            }
          }
        }.padding(.horizontal,40)
      }.frame(maxWidth:.infinity).padding(.bottom,64)
    }.background(.black).foregroundStyle(.white)
      .accessibilityIdentifier("timer.setup.accessible.content")
  }
}
struct RecipeCover: View {
  @Environment(AppModel.self) private var model
  @Environment(\.dynamicTypeSize) private var textSize
  @Environment(\.nativeCanvasScale) private var canvasScale
  @ScaledMetric(relativeTo:.largeTitle) private var titleSize:CGFloat=34
  @ScaledMetric(relativeTo:.body) private var metadataSize:CGFloat=22
  @ScaledMetric(relativeTo:.headline) private var actionSize:CGFloat=21
  @ScaledMetric(relativeTo:.title2) private var clockSize:CGFloat=22
  private var minimumHitHeight:CGFloat {ceil(44/max(0.01,canvasScale))}
  var body: some View {
    ZStack(alignment: .bottom) {
      RecipeArtwork(recipe: model.recipe)
      LinearGradient(
        colors: [.clear, .black.opacity(0.15), .black.opacity(0.8)], startPoint: .center,
        endPoint: .bottom)
      if textSize.isAccessibilitySize {
        VStack(spacing:0) {
          AppHeader(light:true,closeSize:max(48,minimumHitHeight),clockFontSize:clockSize,
            accessibilityLayout:true)
          ScrollView {
            VStack(alignment:.leading,spacing:20) {
              Text(model.recipe.title).font(.system(size:titleSize,weight:.semibold))
              Text("\(model.recipe.source) · \(model.recipe.durationLabel) · \(model.recipe.servingsLabel)")
                .font(.system(size:metadataSize)).opacity(0.75)
              Pill(title:"Ingredients",symbol:"checklist",tint:.white.opacity(0.22),textColor:.white,
                fontSize:actionSize,minimumHeight:minimumHitHeight) {
                  model.route = .ingredients
                }.accessibilityIdentifier("recipe.ingredients")
              Pill(title:"Start Cooking",symbol:"frying.pan",tint:.white.opacity(0.22),textColor:.white,
                fontSize:actionSize,minimumHeight:minimumHitHeight) {
                  model.startCooking()
                }.accessibilityIdentifier("recipe.start")
            }.padding(32)
          }.accessibilityIdentifier("recipe.cover.accessible.content")
        }.background(.black.opacity(0.72)).foregroundStyle(.white)
      } else {
        VStack(alignment: .leading, spacing: 14) {
          AppHeader(light: true,clockFontSize:clockSize)
          Spacer()
          Text(model.recipe.title).font(.system(size: titleSize, weight: .semibold)).padding(
            .horizontal, 40)
          Text(
            "\(model.recipe.source) · \(model.recipe.durationLabel) · \(model.recipe.servingsLabel)"
          ).font(.system(size: metadataSize)).opacity(0.75).padding(
            .horizontal, 40)
          HStack(spacing: 12) {
            Pill(title:"Ingredients",symbol:"checklist",tint:.white.opacity(0.22),textColor:.white,
              fontSize:actionSize) {model.route = .ingredients}.accessibilityIdentifier("recipe.ingredients")
            Pill(title:"Start Cooking",symbol:"frying.pan",tint:.white.opacity(0.22),textColor:.white,
              fontSize:actionSize) {model.startCooking()}.accessibilityIdentifier("recipe.start")
          }.padding(.horizontal, 32).padding(.bottom, 32)
        }.foregroundStyle(.white)
      }
    }
  }
}
struct IngredientsView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  @Environment(\.dynamicTypeSize) private var textSize
  @ScaledMetric(relativeTo:.headline) private var headerSize:CGFloat=23
  @ScaledMetric(relativeTo:.title2) private var clockSize:CGFloat=22
  @ScaledMetric(relativeTo:.body) private var ingredientSize:CGFloat=24
  @ScaledMetric(relativeTo:.headline) private var actionSize:CGFloat=21
  @State private var checked: Set<Int> = []
  private var minimumHitHeight:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      AppHeader(title:"Ingredients",closeSize:textSize.isAccessibilitySize ? max(48,minimumHitHeight):48,
        titleFontSize:headerSize,clockFontSize:clockSize,accessibilityLayout:textSize.isAccessibilitySize)
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
              }.font(.system(size: ingredientSize))
                .frame(maxWidth:.infinity,minHeight:minimumHitHeight,alignment:.leading)
                .contentShape(Rectangle())
            }.accessibilityIdentifier("ingredient.\(i)")
              .accessibilityValue(checked.contains(i) ? "Checked":"Unchecked")
          }
        }.padding(32)
      }
      Pill(title:"Start Cooking",symbol:"frying.pan",fontSize:actionSize,
        minimumHeight:textSize.isAccessibilitySize ? minimumHitHeight:0) {
          model.startCooking()
        }.padding(30)
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
  }
}
struct CookingView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  @Environment(\.dynamicTypeSize) private var textSize
  @ScaledMetric(relativeTo:.headline) private var headerSize:CGFloat=23
  @ScaledMetric(relativeTo:.title2) private var clockSize:CGFloat=22
  @ScaledMetric(relativeTo:.body) private var stepSize:CGFloat=18
  @ScaledMetric(relativeTo:.body) private var instructionSize:CGFloat=30
  @ScaledMetric(relativeTo:.body) private var handoffSize:CGFloat=18
  @ScaledMetric(relativeTo:.body) private var timerSize:CGFloat=22
  @ScaledMetric(relativeTo:.headline) private var nextSize:CGFloat=21
  private var minimumHitHeight:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  private var navigationSize:CGFloat {textSize.isAccessibilitySize ? max(48,minimumHitHeight):48}
  var body: some View {
    Group {
      if textSize.isAccessibilitySize {
        VStack(alignment:.leading,spacing:20) {
          header
          ScrollView {
            VStack(alignment:.leading,spacing:20) {
              // Long recipe names belong to the scroll, not a fixed header.
              Text(model.recipe.title).font(.system(size:headerSize,weight:.semibold))
                .frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,35)
              instruction
              handoff
              timer
              footer
            }
          }.accessibilityIdentifier("recipe.cooking.accessible.content")
        }
      } else {
        VStack(alignment:.leading,spacing:20) {
          header
          ScrollView {instruction}.frame(maxHeight:.infinity)
          handoff
          timer
          footer
        }
      }
    }.background(.white).foregroundStyle(.black)
  }
  private var header:some View {
    VStack(spacing:7) {
      AppHeader(title:textSize.isAccessibilitySize ? "":model.recipe.title,
        closeSize:navigationSize,titleFontSize:headerSize,clockFontSize:clockSize,
        accessibilityLayout:textSize.isAccessibilitySize)
      Canvas {context,_ in
        for index in 0..<model.recipe.steps.count {
          let dot=Path(ellipseIn:CGRect(x:index*14,y:0,width:7,height:7))
          context.fill(dot,with:.color(index == model.cookingStep ? .black:.gray.opacity(0.4)))
        }
      }.frame(width:CGFloat(max(0,model.recipe.steps.count*14-7)),height:7).allowsHitTesting(false)
    }
  }
  private var instruction:some View {
    VStack(alignment:.leading,spacing:14) {
      Text("Step \(model.cookingStep+1)").font(.system(size:stepSize)).foregroundStyle(.black.opacity(0.65))
        .accessibilityLabel("Step \(model.cookingStep+1) of \(model.recipe.steps.count)")
        .accessibilityIdentifier("cooking.step")
      Text(model.recipe.steps[model.cookingStep].text).font(.system(size:instructionSize,weight:.regular))
        .lineSpacing(6).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("cooking.text")
    }.padding(.horizontal,35).padding(.top,16)
  }
  private var handoff:some View {
    Button {model.presentRecipeHandoff()} label: {
      Text("Continue on another device").font(.system(size:handoffSize))
        .frame(maxWidth:.infinity,minHeight:minimumHitHeight,alignment:.leading)
        .contentShape(Rectangle())
    }.padding(.horizontal,35).accessibilityIdentifier("cooking.handoff")
  }
  @ViewBuilder private var timer:some View {
    if let minutes=model.recipe.steps[model.cookingStep].minutes {
      Button {
        if model.addTimer(seconds:Double(minutes*60),title:"\(model.recipe.title) · Step \(model.cookingStep+1)") {
          model.banner("\(minutes)-minute cooking timer started")
        }
      } label: {
        Label("Start \(minutes)-minute timer",systemImage:"timer")
          .font(.system(size:timerSize,weight:.semibold))
          .foregroundStyle(Color(red:0.65,green:0.23,blue:0))
          .frame(maxWidth:.infinity,minHeight:minimumHitHeight,alignment:.leading)
          .contentShape(Rectangle())
      }.padding(.horizontal,35).accessibilityIdentifier("cooking.timer")
    }
  }
  private var footer:some View {
    HStack(spacing:16) {
      RoundButton(symbol:"chevron.left",size:navigationSize,label:"Previous step") {
        model.moveCookingStep(-1)
      }.disabled(model.cookingStep == 0)
      Pill(title:model.cookingStep == model.recipe.steps.count-1 ? "Finish":"Next Step",
        symbol:model.cookingStep == model.recipe.steps.count-1 ? "checkmark":"chevron.right",
        fontSize:nextSize,minimumHeight:textSize.isAccessibilitySize ? minimumHitHeight:0) {
          model.moveCookingStep(1)
        }.accessibilityIdentifier("cooking.next")
      RoundButton(symbol:model.data.pinnedRecipe ? "pin.fill":"pin",size:navigationSize,label:"Pin recipe") {
        model.pinRecipe()
      }.accessibilityIdentifier("recipe.pin")
        .accessibilityValue(model.data.pinnedRecipe ? "Pinned":"Not pinned")
    }.padding(30)
  }
}
struct RemindersView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.scenePhase) private var phase
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
          .onChange(of:phase) { _,phase in if phase != .active { inputFocused=false } }
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
  @Environment(\.dynamicTypeSize) private var textSize
  @ScaledMetric(relativeTo:.headline) private var headerSize:CGFloat=23
  @ScaledMetric(relativeTo:.title2) private var clockSize:CGFloat=22
  @ScaledMetric(relativeTo:.headline) private var libraryTitleSize:CGFloat=23
  @ScaledMetric(relativeTo:.body) private var libraryDetailSize:CGFloat=17
  @ScaledMetric(relativeTo:.headline) private var trackTitleSize:CGFloat=25
  @ScaledMetric(relativeTo:.body) private var artistSize:CGFloat=21
  private var minimumHitSide:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  @State private var browse = false
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          Color(red: 0.31, green: 0.46, blue: 0.62), Color(red: 0.13, green: 0.22, blue: 0.35),
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
      VStack(spacing: 17) {
        AppHeader(title:browse ? "Music":"",light:true,closeSize:max(48,minimumHitSide),
          titleFontSize:headerSize,clockFontSize:clockSize,accessibilityLayout:textSize.isAccessibilitySize)
        if textSize.isAccessibilitySize {
          ScrollView {
            if browse {library} else {player}
          }.accessibilityIdentifier("music.demo.accessible.content")
        } else {
          if browse {library} else {player}
        }
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
              Text(Fixtures.songs[i]).font(.system(size: libraryTitleSize, weight: .semibold))
              Text("Bundled demo audio").font(.system(size: libraryDetailSize)).opacity(0.65)
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
      DemoAnimatedArtwork(playing:model.playing).frame(width: 270, height: 270).clipped()
        .clipShape(RoundedRectangle(cornerRadius: 18)).shadow(radius: 20)
        .overlay(alignment: .bottomTrailing) { MusicArtworkInfoButton(source: .demo) }
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Text(Fixtures.songs[model.song]).font(.system(size: trackTitleSize, weight: .semibold))
          Text("Demo Artist").font(.system(size: artistSize)).opacity(0.6)
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
  @Environment(\.scenePhase) private var phase
  @Environment(\.dynamicTypeSize) private var textSize
  @ScaledMetric(relativeTo:.headline) private var headerSize:CGFloat=23
  @ScaledMetric(relativeTo:.title2) private var clockSize:CGFloat=22
  @ScaledMetric(relativeTo:.body) private var actionSize:CGFloat=18
  @ScaledMetric(relativeTo:.title3) private var choiceSize:CGFloat=22
  @ScaledMetric(relativeTo:.caption) private var zoneSize:CGFloat=12
  @ScaledMetric(relativeTo:.title2) private var citySize:CGFloat=25
  @ScaledMetric(relativeTo:.caption) private var infoSize:CGFloat=13
  @ScaledMetric(relativeTo:.largeTitle) private var timeSize:CGFloat=34
  @ScaledMetric(relativeTo:.caption) private var policySize:CGFloat=12
  @FocusState private var inputFocused:Bool
  @Environment(\.nativeCanvasScale) private var canvasScale
  private var minimumHitSide:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  @State private var choosing = false
  @State private var search = ""
  @State private var detail: WorldCity?
  private var selected: [WorldCity] {
    model.data.worldClockZones.compactMap { WorldCity.city(for: $0) }
  }
  private var matches: [WorldCity] {
    let candidates = search.isEmpty ? WorldCity.catalogue : WorldCity.allZones
    let taken = Set(model.data.worldClockZones)
    return candidates.filter { city in
      !taken.contains(city.zone) && (search.isEmpty
        || city.name.localizedCaseInsensitiveContains(search)
        || city.zone.localizedCaseInsensitiveContains(search))
    }.prefix(40).map { $0 }
  }
  var body: some View {
    VStack(spacing: 8) {
      AppHeader(title: choosing ? "Add City" : "World Clock",closeSize:max(48,minimumHitSide),
        titleFontSize:headerSize,clockFontSize:clockSize,accessibilityLayout:textSize.isAccessibilitySize)
      HStack {
        Text(choosing ? "Choose a time zone" : "\(selected.count) of 12 cities")
        Spacer()
        Button { choosing.toggle(); search = "" } label: {
          Text(choosing ? "Done" : "Add City")
            .frame(minWidth:minimumHitSide,minHeight:minimumHitSide)
            .contentShape(Rectangle())
        }.disabled(!choosing && selected.count >= 12)
          .accessibilityIdentifier("world.add")
      }.font(.system(size:actionSize)).padding(.horizontal, 30)
      if choosing {
        TextField("Search all time zones", text: $search).textFieldStyle(.plain)
          .padding(12).background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
          .padding(.horizontal, 30).accessibilityIdentifier("world.search").focused($inputFocused)
          .onChange(of:phase) { _,phase in if phase != .active { inputFocused=false } }
        ScrollView {
          LazyVStack(spacing: 8) {
            ForEach(matches) { city in
              Button {
                guard model.addWorldCity(city.zone) else { return }
                choosing = false; search = ""
              } label: {
                HStack(spacing: 8) {
                  VStack(alignment: .leading, spacing: 2) {
                    Text(city.name)
                    Text(city.zone).font(.system(size:zoneSize)).foregroundStyle(.black.opacity(0.65))
                  }
                  Spacer()
                  Image(systemName: "plus.circle")
                }
                  .font(.system(size:choiceSize)).padding(14)
                  .frame(minHeight:minimumHitSide).contentShape(Rectangle())
              }.accessibilityIdentifier("world.choose.\(city.zone)")
            }
            if matches.isEmpty { Text("No matching time zone.").padding(20) }
          }.padding(.horizontal, 18)
        }
      } else {
        ScrollView {
          VStack(spacing: 4) {
            ForEach(selected) { city in
              let reading = WorldClockReading(city: city, instant: model.clock,
                referenceZone: model.displayTimeZone)
              HStack(spacing: 8) {
                Button { detail = city } label: {
                  if textSize.isAccessibilitySize {
                    VStack(alignment:.leading,spacing:8) {
                      HStack(alignment:.top,spacing:12) {
                        Image(systemName:reading.daylight == nil ? "clock"
                          :(reading.daylight! ? "sun.max.fill":"moon.fill"))
                          .foregroundStyle(reading.daylight == nil ? .gray
                            :(reading.daylight! ? .orange:.indigo))
                          .accessibilityLabel(reading.daylight == nil ? "No sun position"
                            :(reading.daylight! ? "Daylight estimate":"Night estimate"))
                        VStack(alignment:.leading,spacing:4) {
                          Text(city.name).font(.system(size:citySize,weight:.medium))
                          Text(reading.date+" · "+reading.offset).font(.system(size:infoSize))
                          if let relation=reading.dayRelation {
                            Text(relation).font(.system(size:infoSize,weight:.semibold))
                          }
                        }
                      }
                      Text(reading.time).font(.system(size:timeSize,weight:.light)).monospacedDigit()
                        .accessibilityIdentifier("world.time.\(city.zone)")
                    }.frame(maxWidth:.infinity,alignment:.leading).contentShape(Rectangle())
                  } else {
                  HStack(spacing: 12) {
                    Image(systemName: reading.daylight == nil ? "clock"
                      : (reading.daylight! ? "sun.max.fill" : "moon.fill"))
                      .foregroundStyle(reading.daylight == nil ? .gray
                        : (reading.daylight! ? .orange : .indigo))
                      .accessibilityLabel(reading.daylight == nil ? "No sun position"
                        : (reading.daylight! ? "Daylight estimate" : "Night estimate"))
                    VStack(alignment: .leading, spacing: 4) {
                      Text(city.name).font(.system(size:citySize,weight:.medium))
                      Text(reading.date + " · " + reading.offset).font(.system(size:infoSize))
                      if let relation=reading.dayRelation {
                        Text(relation)
                          .font(.system(size:infoSize,weight:.semibold))
                      }
                    }
                    Spacer(minLength: 0)
                    Text(reading.time).font(.system(size:timeSize,weight:.light)).monospacedDigit()
                      .accessibilityIdentifier("world.time.\(city.zone)")
                  }.contentShape(Rectangle())
                  }
                }.buttonStyle(.plain)
                  .accessibilityIdentifier("world.detail.open.\(city.zone)")
                Button { model.removeWorldCity(city.zone) } label: {
                  Image(systemName: "minus.circle").font(.system(size:choiceSize)).padding(8)
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
            if textSize.isAccessibilitySize {worldPolicy}
          }
        }
        if !textSize.isAccessibilitySize {worldPolicy}
      }
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
    .sheet(item: $detail) { city in WorldClockDetail(city: city).snapshotPrivacyProtected() }
  }
  private var worldPolicy:some View {
    Text("Tap a city for day and night. Sun position is an offline estimate.")
      .font(.system(size:policySize)).foregroundStyle(.black.opacity(0.65))
      .multilineTextAlignment(.center).padding(.horizontal,30).padding(.bottom,14)
  }
}
struct WorldClockDetail: View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var textSize
  @ScaledMetric(relativeTo:.title) private var citySize:CGFloat=28
  @ScaledMetric(relativeTo:.caption) private var zoneSize:CGFloat=13
  @ScaledMetric(relativeTo:.headline) private var doneSize:CGFloat=18
  @ScaledMetric(relativeTo:.largeTitle) private var timeSize:CGFloat=72
  @ScaledMetric(relativeTo:.body) private var dateSize:CGFloat=16
  @ScaledMetric(relativeTo:.subheadline) private var relationSize:CGFloat=15
  let city: WorldCity
  private var reading: WorldClockReading {
    WorldClockReading(city: city, instant: model.clock, referenceZone: model.displayTimeZone)
  }
  private func localTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeZone = city.timeZone
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
  var body: some View {
    let reading=reading
    VStack(spacing:18) {
      if textSize.isAccessibilitySize {
        VStack(alignment:.leading,spacing:8) {
          HStack {Spacer();done}
          Text(city.name).font(.system(size:citySize,weight:.medium))
          Text(city.zone).font(.system(size:zoneSize)).foregroundStyle(.black.opacity(0.65))
        }.frame(maxWidth:.infinity,alignment:.leading)
        ScrollView {
          VStack(spacing:18) {detailReading(reading)}.frame(maxWidth:.infinity)
        }
      } else {
        HStack {
          VStack(alignment:.leading,spacing:2) {
            Text(city.name).font(.system(size:citySize,weight:.medium))
            Text(city.zone).font(.system(size:zoneSize)).foregroundStyle(.black.opacity(0.65))
          }
          Spacer()
          done
        }
        detailReading(reading)
        Spacer(minLength:0)
      }
    }.padding(28).background(.white).foregroundStyle(.black)
  }
  private var done:some View {
    Button {dismiss()} label: {
      Text("Done").font(.system(size:doneSize,weight:.semibold))
        .padding(.horizontal,6).frame(minHeight:44).contentShape(Rectangle())
    }.accessibilityIdentifier("world.detail.done")
  }
  @ViewBuilder private func detailReading(_ reading:WorldClockReading)->some View {
    // Large digital numerals remain one line inside a narrow native sheet.
    Text(reading.time).font(.system(size:min(timeSize,112),weight:.thin)).monospacedDigit()
      .accessibilityIdentifier("world.detail.time")
    Text(reading.date+" · "+reading.offset).font(.system(size:dateSize))
    if let relation=reading.dayRelation {
      Text(relation).font(.system(size:relationSize,weight:.semibold))
    }
    DaylightBar(sun:reading.sun,daylight:reading.daylight,localTime:localTime)
  }
}
struct DaylightBar: View {
  @ScaledMetric(relativeTo:.caption) private var statusSize:CGFloat=13
  @ScaledMetric(relativeTo:.caption2) private var estimateSize:CGFloat=11
  let sun: DaylightWindow
  let daylight: Bool?
  let localTime: (Date) -> String
  private var status: String {
    switch sun.kind {
    case .normal:
      let rise = sun.sunrise.map(localTime) ?? "—", set = sun.sunset.map(localTime) ?? "—"
      return "Sunrise \(rise) · Sunset \(set)"
    case .polarDay: return "Polar day: the sun stays above the horizon."
    case .polarNight: return "Polar night: the sun stays below the horizon."
    case .unavailable: return "No sun position for this time zone."
    }
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      GeometryReader { geometry in
        let width = geometry.size.width
        ZStack(alignment: .leading) {
          Capsule().fill(Color.indigo.opacity(0.85))
          switch sun.kind {
          case .normal:
            ForEach(sun.daylightIntervals.indices,id:\.self) { index in
              let interval=sun.daylightIntervals[index]
              Rectangle().fill(Color.orange.opacity(0.85))
                .frame(width:width * CGFloat(interval.upperBound-interval.lowerBound))
                .offset(x:width * CGFloat(interval.lowerBound))
            }
          case .polarDay:
            Capsule().fill(Color.orange.opacity(0.85))
          case .polarNight:
            Capsule().fill(Color.indigo.opacity(0.85))
          case .unavailable:
            Capsule().fill(Color(white:0.88))
          }
        }.clipShape(Capsule())
      }.frame(height: 14)
        .accessibilityLabel("Day and night course")
        .accessibilityValue(status)
        .accessibilityIdentifier("world.daylight.bar")
      Text(status).font(.system(size:statusSize)).foregroundStyle(.black.opacity(0.65))
      Text(daylight == nil ? "Current light unknown" : (daylight! ? "Currently daylight" : "Currently night"))
        .font(.system(size:statusSize,weight:.semibold))
      Text("Offline estimate from a low-order solar model, not an ephemeris.")
        .font(.system(size:estimateSize)).foregroundStyle(.black.opacity(0.65))
    }
  }
}
struct AlarmsView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  private var minimumHitSide:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  @State private var hour = 7
  @State private var minute = 0
  @State private var recurrence: AlarmRecurrence = .once
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
                Text(alarm.recurrence.title).font(.system(size: 16))
                  .accessibilityIdentifier("alarm.repeat.\(alarm.id)")
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
        Picker("Repeat", selection: $recurrence) {
          ForEach(AlarmRecurrence.allCases, id: \.self) { choice in
            Text(choice.title).tag(choice)
          }
        }.pickerStyle(.menu).frame(minHeight:minimumHitSide)
          .accessibilityIdentifier("alarm.recurrence")
      }.font(.system(size: 25)).padding(.horizontal, 32)
      Button {model.addAlarm(hour:hour,minute:minute,recurrence:recurrence)} label: {
        Label("Add Alarm",systemImage:"plus").font(.system(size:21,weight:.medium))
          .frame(maxWidth:.infinity).padding(.vertical,17)
          .frame(minHeight:minimumHitSide)
          .background(.black.opacity(0.08),in:Capsule()).foregroundStyle(.primary)
      }.padding(.horizontal,32).accessibilityIdentifier("alarm.add")
      Text(
        "Times follow this device. Without a permitted iPhone/iPad system alert, alarms ring only while HomeView is active. Missed foreground alerts are not replayed."
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
