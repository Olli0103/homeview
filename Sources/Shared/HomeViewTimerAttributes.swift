#if canImport(ActivityKit) && os(iOS) && !targetEnvironment(macCatalyst)
import ActivityKit
struct HomeViewTimerAttributes:ActivityAttributes {
  typealias ContentState=TimerActivityState
  let schemaVersion:Int
}
#endif
