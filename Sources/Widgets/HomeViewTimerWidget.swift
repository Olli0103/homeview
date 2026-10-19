import ActivityKit
import SwiftUI
import WidgetKit

private struct TimerActivityValue:View {
  let state:TimerActivityState
  let stale:Bool
  var body:some View {
    let now=Date()
    if stale { Text("Check timers") }
    else if let deadline=state.deadline,deadline>now {
      Text(timerInterval:now...deadline,countsDown:true).monospacedDigit()
    } else if let seconds=state.pausedSeconds {
      Text(Duration.seconds(seconds).formatted(.time(pattern:.hourMinuteSecond)))
        .monospacedDigit()
    } else {Text("Check timers")}
  }
}
struct HomeViewTimerWidget:Widget {
  var body:some WidgetConfiguration {
    ActivityConfiguration(for:HomeViewTimerAttributes.self) { context in
      VStack(alignment:.leading,spacing:8) {
        Label("HomeView timers",systemImage:"timer").font(.headline)
        TimerActivityValue(state:context.state,stale:context.isStale).font(.title)
        if context.isStale { Text("Open HomeView for current timers.").font(.caption) }
        else {Text("\(context.state.runningCount) running · \(context.state.pausedCount) paused").font(.caption)}
      }.padding().activityBackgroundTint(.black).activitySystemActionForegroundColor(.white)
        .foregroundStyle(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {Label("Timers",systemImage:"timer")}
        DynamicIslandExpandedRegion(.trailing) {
          TimerActivityValue(state:context.state,stale:context.isStale).frame(maxWidth:130)
        }
        DynamicIslandExpandedRegion(.bottom) {
          if context.isStale {Text("Open HomeView for current timers.")}
          else {Text("\(context.state.runningCount) running · \(context.state.pausedCount) paused")}
        }
      } compactLeading: {Image(systemName:"timer")}
        compactTrailing: {TimerActivityValue(state:context.state,stale:context.isStale).frame(maxWidth:70)}
        minimal: {Image(systemName:context.isStale ? "timer.circle":"timer")}
    }
  }
}
@main struct HomeViewTimerWidgetBundle:WidgetBundle {
  var body:some Widget {HomeViewTimerWidget()}
}
