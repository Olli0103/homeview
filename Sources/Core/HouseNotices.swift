import Foundation
import Observation

enum NoticeHousehold:String,CaseIterable,Sendable {case demoHouse,demoCabin}
enum NoticeSource:String,Sendable {case demoSequence,demoSensor}
enum HouseNoticeKind:String,Sendable {
  case arrival,door,alarm
  var title:String {
    switch self {case .arrival:"Arrival";case .door:"Door event";case .alarm:"Alarm event"}
  }
}
struct HouseNoticeKey:Hashable,Sendable {
  let household:NoticeHousehold
  let source:NoticeSource
  let id:String
}
struct HouseNotice:Equatable,Sendable {
  let key:HouseNoticeKey
  let incident:String?
  let occurredAt:Date
  let kind:HouseNoticeKind
  var personalDetail:String? = nil
}
struct HouseNoticeRow:Identifiable,Equatable,Sendable {
  let id:HouseNoticeKey
  let title:String
  let occurredAt:Date
  let stale:Bool
}
struct HouseNoticeGroup:Identifiable,Equatable,Sendable {
  let id:HouseNoticeKey
  let household:NoticeHousehold
  let source:NoticeSource
  let rows:[HouseNoticeRow]
}
enum NoticeIngestResult:Equatable {case accepted(inserted:Int,duplicates:Int),invalid,conflict,capacity}
enum NoticeDestination:Equatable {case home,cameras,door}

/// Bounded synthetic inbox only. No OS notification subscription, HomeKit or network adapter.
@MainActor @Observable final class HouseNoticeInbox {
  private var records:[HouseNoticeKey:HouseNotice] = [:]
  private let maximum=200
  private let groupingWindow:TimeInterval=180
  private let freshness:TimeInterval=300
  private func validID(_ value:String)->Bool {
    !value.isEmpty && value.count<=100 && !value.unicodeScalars.contains {CharacterSet.controlCharacters.contains($0)}
  }
  @discardableResult func ingest(_ incoming:[HouseNotice],at now:Date)->NoticeIngestResult {
    guard now.timeIntervalSince1970.isFinite,incoming.count<=maximum else {return .invalid}
    var candidate=records,duplicates=0,inserted=0
    for event in incoming {
      guard validID(event.key.id),event.incident.map(validID) ?? true,
        event.occurredAt.timeIntervalSince1970.isFinite,event.occurredAt.timeIntervalSince(now)<=5,
        event.personalDetail.map({!$0.isEmpty && $0.count<=200 && !$0.unicodeScalars.contains {CharacterSet.controlCharacters.contains($0)}}) ?? true
      else {return .invalid}
      if let old=candidate[event.key] {
        guard old==event else {return .conflict}
        duplicates+=1
      } else {candidate[event.key]=event;inserted+=1}
    }
    guard candidate.count<=maximum else {return .capacity}
    records=candidate
    return .accepted(inserted:inserted,duplicates:duplicates)
  }
  func clear() {records=[:]}
  func groups(at now:Date,allowed:Set<NoticeHousehold>,personalAccess:Bool)->[HouseNoticeGroup] {
    guard now.timeIntervalSince1970.isFinite else {return []}
    let values=records.values.filter {allowed.contains($0.key.household)}.sorted {
      if $0.occurredAt != $1.occurredAt {return $0.occurredAt<$1.occurredAt}
      if $0.key.household != $1.key.household {return $0.key.household.rawValue<$1.key.household.rawValue}
      if $0.key.source != $1.key.source {return $0.key.source.rawValue<$1.key.source.rawValue}
      return $0.key.id<$1.key.id
    }
    var buckets:[[HouseNotice]]=[]
    for event in values {
      // Only explicit same-source correlation; never guess relatedness from proximity alone.
      if let incident=event.incident,let index=buckets.lastIndex(where: {items in
        guard let first=items.first else {return false}
        return first.key.household==event.key.household && first.key.source==event.key.source
          && first.incident==incident && event.occurredAt.timeIntervalSince(first.occurredAt)<=groupingWindow
      }) {buckets[index].append(event)} else {buckets.append([event])}
    }
    return buckets.map {items in
      let first=items[0]
      return HouseNoticeGroup(id:first.key,household:first.key.household,source:first.key.source,
        rows:items.map {event in
          HouseNoticeRow(id:event.key,title:personalAccess ? event.personalDetail ?? event.kind.title:event.kind.title,
            occurredAt:event.occurredAt,stale:!fresh(event,at:now))
        })
    }.sorted {
      let a=$0.rows.last!.occurredAt,b=$1.rows.last!.occurredAt
      if a != b {return a>b}
      return [$0.household.rawValue,$0.source.rawValue,$0.id.id].lexicographicallyPrecedes(
        [$1.household.rawValue,$1.source.rawValue,$1.id.id])
    }
  }
  private func fresh(_ event:HouseNotice,at now:Date)->Bool {
    let age=now.timeIntervalSince(event.occurredAt)
    return age.isFinite && age >= -5 && age<=freshness
  }
  /// A tap only selects a mock view. It can never unlock a door or acknowledge a real alarm.
  func destination(for key:HouseNoticeKey,at now:Date,allowed:Set<NoticeHousehold>,online:Bool)->NoticeDestination? {
    guard online,allowed.contains(key.household),let event=records[key],fresh(event,at:now) else {return nil}
    switch event.kind {case .arrival:return .cameras;case .door:return .door;case .alarm:return .home}
  }
  static func demoSequence(at now:Date)->[HouseNotice] {
    func make(_ id:String,_ seconds:Double,_ kind:HouseNoticeKind,_ incident:String?,house:NoticeHousehold = .demoHouse,detail:String?=nil)->HouseNotice {
      .init(key:.init(household:house,source:.demoSequence,id:id),incident:incident,
        occurredAt:now.addingTimeInterval(seconds),kind:kind,personalDetail:detail)
    }
    let arrival=make("arrival",-80,.arrival,"visit",detail:"Synthetic Alex arrived")
    return [arrival,make("door",-50,.door,"visit"),make("alarm",-20,.alarm,"visit"),arrival,
      make("unrelated",-10,.door,nil),make("old",-3600,.alarm,"old-incident"),
      make("other-house",-5,.arrival,"visit",house:.demoCabin,detail:"Withheld cabin detail")]
  }
}
