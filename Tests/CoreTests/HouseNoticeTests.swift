import XCTest
@testable import HomeViewCore

@MainActor final class HouseNoticeTests:XCTestCase {
  private let now=Date(timeIntervalSince1970:1792645200)
  private func event(_ id:String,_ age:Double,_ incident:String?="visit",house:NoticeHousehold = .demoHouse,
    source:NoticeSource = .demoSequence,kind:HouseNoticeKind = .door,detail:String?=nil)->HouseNotice {
    .init(key:.init(household:house,source:source,id:id),incident:incident,
      occurredAt:now.addingTimeInterval(-age),kind:kind,personalDetail:detail)
  }
  func testDemoReplayDeduplicatesWithoutLosingVisibleOrWithheldRecords() {
    let inbox=HouseNoticeInbox(),batch=HouseNoticeInbox.demoSequence(at:now)
    XCTAssertEqual(inbox.ingest(batch,at:now),.accepted(inserted:6,duplicates:1))
    let all=inbox.groups(at:now,allowed:Set(NoticeHousehold.allCases),personalAccess:false)
    XCTAssertEqual(all.flatMap(\.rows).count,6);XCTAssertEqual(all.count,4)
    let visible=inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false)
    XCTAssertEqual(visible.count,3);XCTAssertEqual(visible.flatMap(\.rows).count,5)
    XCTAssertEqual(Set(visible.flatMap(\.rows).map(\.id.id)),["arrival","door","alarm","unrelated","old"])
    XCTAssertEqual(visible.first(where:{$0.id.id=="arrival"})?.rows.map(\.id.id),["arrival","door","alarm"])
    XCTAssertEqual(inbox.ingest(batch,at:now),.accepted(inserted:0,duplicates:7))
    XCTAssertEqual(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false),visible)
  }
  func testGroupingIsPermutationIndependentAndNeverChainsPastWholeWindow() {
    let values=[event("first",400),event("middle",230),event("last",60),event("unrelated",59,nil)]
    let inbox=HouseNoticeInbox(),reverse=HouseNoticeInbox()
    _=inbox.ingest(values,at:now);_=reverse.ingest(values.reversed(),at:now)
    let a=inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false)
    XCTAssertEqual(a,reverse.groups(at:now,allowed:[.demoHouse],personalAccess:false))
    XCTAssertEqual(a.count,3)
    XCTAssertEqual(a.first(where:{$0.id.id=="first"})?.rows.map(\.id.id),["first","middle"])
    XCTAssertEqual(a.first(where:{$0.id.id=="last"})?.rows.count,1)
    XCTAssertEqual(a.flatMap(\.rows).count,4)
  }
  func testSameIncidentAndEventIDNeverMergeHouseholdsOrIndependentSources() {
    let inbox=HouseNoticeInbox()
    let batch=[event("same",5),event("same",5,house:.demoCabin),event("same",5,source:.demoSensor)]
    XCTAssertEqual(inbox.ingest(batch,at:now),.accepted(inserted:3,duplicates:0))
    let all=inbox.groups(at:now,allowed:Set(NoticeHousehold.allCases),personalAccess:false)
    XCTAssertEqual(all.count,3);XCTAssertEqual(all.flatMap(\.rows).count,3)
    XCTAssertEqual(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false).count,2)
    XCTAssertTrue(inbox.groups(at:now,allowed:[],personalAccess:true).isEmpty)
    XCTAssertNil(inbox.destination(for:batch[1].key,at:now,allowed:[.demoHouse],online:true))
  }
  func testConflictingDuplicateAndMalformedBatchesAreAtomic() {
    let inbox=HouseNoticeInbox();let good=event("good",4)
    _=inbox.ingest([good],at:now)
    let before=inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false)
    XCTAssertEqual(inbox.ingest([event("new",3),event("good",2)],at:now),.conflict)
    let bad=[event("",2),event("line\nbreak",2),event("huge",2,String(repeating:"x",count:101)),
      event("future", -6),event("name",2,detail:"secret\0control")]
    for invalid in bad {
      XCTAssertEqual(inbox.ingest([event("new",3),invalid],at:now),.invalid)
      XCTAssertEqual(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false),before)
    }
    XCTAssertEqual(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false),before)
  }
  func testCapacityRejectsWholeBatchAndDoesNotEvictOldHistory() {
    let inbox=HouseNoticeInbox()
    let batch=(0..<200).map {event("event-\($0)",Double($0),nil)}
    XCTAssertEqual(inbox.ingest(batch,at:now),.accepted(inserted:200,duplicates:0))
    let before=inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false)
    XCTAssertEqual(inbox.ingest([event("overflow",1)],at:now),.capacity)
    XCTAssertEqual(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false),before)
    XCTAssertEqual(inbox.ingest(batch,at:now),.accepted(inserted:0,duplicates:200))
    XCTAssertEqual(inbox.ingest(batch+[event("overflow",1)],at:now),.invalid)
    inbox.clear();XCTAssertTrue(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:true).isEmpty)
  }
  func testPrivateDetailIsRecomputedAndAbsentFromGuestPresentation() {
    let inbox=HouseNoticeInbox(),item=event("personal",1,kind:.arrival,detail:"PRIVATE_PERSON_CANARY")
    _=inbox.ingest([item],at:now)
    let guest=inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false)
    XCTAssertEqual(guest.first?.rows.first?.title,"Arrival")
    XCTAssertFalse(String(reflecting:guest).contains("PRIVATE_PERSON_CANARY"))
    XCTAssertEqual(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:true).first?.rows.first?.title,"PRIVATE_PERSON_CANARY")
    XCTAssertEqual(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false),guest)
    XCTAssertTrue(inbox.groups(at:now,allowed:[],personalAccess:true).isEmpty)
  }
  func testStaleFutureOfflineAndRevokedScopesCannotOpenAnyAction() {
    let inbox=HouseNoticeInbox()
    let items=[event("edge",300),event("old",300.001),event("future",-5),event("door",0),
      event("arrival",0,nil,kind:.arrival),event("alarm",0,nil,kind:.alarm)]
    _=inbox.ingest(items,at:now)
    XCTAssertNotNil(inbox.destination(for:items[0].key,at:now,allowed:[.demoHouse],online:true))
    XCTAssertNil(inbox.destination(for:items[1].key,at:now,allowed:[.demoHouse],online:true))
    XCTAssertNotNil(inbox.destination(for:items[2].key,at:now,allowed:[.demoHouse],online:true))
    for item in items {
      XCTAssertNil(inbox.destination(for:item.key,at:now,allowed:[],online:true))
      XCTAssertNil(inbox.destination(for:item.key,at:now,allowed:[.demoHouse],online:false))
      XCTAssertNil(inbox.destination(for:item.key,at:now.addingTimeInterval(306),allowed:[.demoHouse],online:true))
      XCTAssertNil(inbox.destination(for:item.key,at:now.addingTimeInterval(-1000),allowed:[.demoHouse],online:true))
    }
    XCTAssertEqual(inbox.destination(for:items[3].key,at:now,allowed:[.demoHouse],online:true),.door)
    XCTAssertEqual(inbox.destination(for:items[4].key,at:now,allowed:[.demoHouse],online:true),.cameras)
    XCTAssertEqual(inbox.destination(for:items[5].key,at:now,allowed:[.demoHouse],online:true),.home)
    XCTAssertTrue(inbox.groups(at:Date(timeIntervalSince1970:.nan),allowed:[.demoHouse],personalAccess:true).isEmpty)
    XCTAssertNil(inbox.destination(for:items[3].key,at:Date(timeIntervalSince1970:.nan),allowed:[.demoHouse],online:true))
  }
}
