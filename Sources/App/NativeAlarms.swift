import SwiftUI

#if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
  import AlarmKit

  @available(iOS 26.1, *)
  struct HomeViewAlarmMetadata: AlarmMetadata {}

  /// Real OS-owned alarms; never reads or modifies Apple's Clock app alarms.
  /// Mock tests never invoke this through normal timer actions.
  @available(iOS 26.1, *)
  @MainActor
  final class NativeAlarmService {
    func scheduleTimer(id: UUID, seconds: TimeInterval, title: String) async throws {
      let deadline = Date().addingTimeInterval(seconds)
      let manager = AlarmManager.shared
      guard try await manager.requestAuthorization() == .authorized else {
        throw NativeServiceError.permissionDenied
      }
      let attributes = AlarmAttributes(
        presentation: AlarmPresentation(alert: .init(title: "\(title)")),
        metadata: HomeViewAlarmMetadata(), tintColor: .orange)
      _ = try await manager.schedule(
        id: id,
        configuration: .timer(
          duration: max(1, deadline.timeIntervalSinceNow), attributes: attributes))
    }
    func scheduleAlarm(id: UUID, hour: Int, minute: Int) async throws {
      guard (0...23).contains(hour), (0...59).contains(minute) else { throw HomeError.invalidValue }
      let manager = AlarmManager.shared
      guard try await manager.requestAuthorization() == .authorized else {
        throw NativeServiceError.permissionDenied
      }
      let attributes = AlarmAttributes(
        presentation: AlarmPresentation(alert: .init(title: "HomeView alarm")),
        metadata: HomeViewAlarmMetadata(), tintColor: .orange)
      let schedule = Alarm.Schedule.relative(.init(time: .init(hour: hour, minute: minute)))
      _ = try await manager.schedule(
        id: id, configuration: .alarm(schedule: schedule, attributes: attributes))
    }
    func activeIDs() throws -> Set<UUID> { Set(try AlarmManager.shared.alarms.map(\.id)) }
    func scheduleTest(seconds: TimeInterval = 60) async throws -> UUID {
      let id = UUID()
      try await scheduleTimer(id: id, seconds: seconds, title: "HomeView test timer")
      return id
    }
    func cancel(_ id: UUID) throws {
      guard try AlarmManager.shared.alarms.contains(where: { $0.id == id }) else { return }
      try AlarmManager.shared.cancel(id: id)
    }
    func pause(_ id: UUID) throws { try AlarmManager.shared.pause(id: id) }
    func resume(_ id: UUID) throws { try AlarmManager.shared.resume(id: id) }

  }
#endif

struct NativeAlarmControls: View {
  @State private var status =
    "System alarm test is optional. Mock timers do not request authorization."
  #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
    @State private var service = NativeAlarmService()
    @State private var alarmID: UUID?
  #endif
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("AlarmKit").font(.system(size: 22, weight: .semibold))
      Text(status).font(.system(size: 17)).foregroundStyle(.gray)
      #if canImport(AlarmKit) && os(iOS) && !targetEnvironment(macCatalyst)
        Button(alarmID == nil ? "Schedule 60-second system test alarm" : "Cancel system test alarm")
        {
          Task {
            do {
              if let id = alarmID {
                try service.cancel(id)
                alarmID = nil
                status = "System test alarm cancelled."
              } else {
                let args = ProcessInfo.processInfo.arguments
                var seconds = 60.0
                if args.contains("--uitesting"),
                  let i = args.firstIndex(of: "--alarm-test-seconds"), args.indices.contains(i + 1),
                  let n = Double(args[i + 1])
                {
                  seconds = max(1, min(60, n))
                }
                alarmID = try await service.scheduleTest(seconds: seconds)
                status = "System timer scheduled. Lock the simulator to verify OS delivery."
              }
            } catch { status = "System alarm unavailable: \(error.localizedDescription)" }
          }
        }.font(.system(size: 19)).accessibilityIdentifier("native.alarm")
      #else
        Text("AlarmKit is not exposed on this target by the installed SDK.").font(.system(size: 17))
          .foregroundStyle(.gray)
      #endif
    }
  }
}
