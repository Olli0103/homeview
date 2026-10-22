import Foundation
@main struct NoticeGate {
  @MainActor static func main() {
    var count=0
    func check(_ value:Bool,_ code:String) {count+=1;if !value {print("FAIL "+code);exit(1)}}
    let now=Date(timeIntervalSince1970:1792645200)
    func item(_ id:String,_ age:Double,incident:String?="same",house:NoticeHousehold = .demoHouse,source:NoticeSource = .demoSequence,kind:HouseNoticeKind = .door,detail:String?=nil)->HouseNotice {
      .init(key:.init(household:house,source:source,id:id),incident:incident,
        occurredAt:now.addingTimeInterval(-age),kind:kind,personalDetail:detail)
    }
    let inbox=HouseNoticeInbox(),raw=[item("arrival",180,kind:.arrival,detail:"HIDDEN_IDENTITY_CANARY"),item("door",90),item("alarm",0,kind:.alarm)]
    check(inbox.ingest(raw,at:now) == .accepted(inserted:3,duplicates:0),"complete-batch")
    let publicView=inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false)
    check(publicView.count==1 && publicView[0].rows.count==3,"explicit-whole-window-correlation")
    check(!String(reflecting:publicView).contains("HIDDEN_IDENTITY_CANARY"),"redacted-data-not-in-presentation")
    check(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:true)[0].rows[0].title=="HIDDEN_IDENTITY_CANARY","explicit-personal-gate")
    check(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false)==publicView,"lock-recomputes-public-values")
    check(inbox.groups(at:now,allowed:[],personalAccess:true).isEmpty,"authentication-cannot-grant-household")
    for _ in 0..<3 {check(inbox.ingest(raw,at:now) == .accepted(inserted:0,duplicates:3),"idempotent-replay")}
    check(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false)==publicView,"no-duplicate-rows")
    let conflicting=item("arrival",179)
    check(inbox.ingest([item("new",0),conflicting],at:now) == .conflict,"conflict-atomic-rejection")
    check(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false)==publicView,"conflict-no-partial-success")
    for bad in [item("",0),item("\0",0),item("x",0,incident:""),item("x", -5.01),item("x",0,detail:String(repeating:"s",count:201))] {
      check(inbox.ingest([item("new",0),bad],at:now) == .invalid,"malformed-atomic-rejection")
      check(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false)==publicView,"malformed-no-effect")
    }
    let separate=HouseNoticeInbox()
    let distinct=[item("same",0),item("same",0,house:.demoCabin),item("same",0,source:.demoSensor),item("uncorrelated",0,incident:nil)]
    _=separate.ingest(distinct,at:now)
    let all=separate.groups(at:now,allowed:Set(NoticeHousehold.allCases),personalAccess:false)
    check(all.count==4 && all.flatMap(\.rows).count==4,"no-cross-house-source-or-proximity-merge")
    check(separate.groups(at:now,allowed:[.demoHouse],personalAccess:false).count==3,"scope-filters-independently")
    let permutations=[[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]
    for order in permutations {
      let instance=HouseNoticeInbox()
      for index in order {_=instance.ingest([raw[index]],at:now)}
      check(instance.groups(at:now,allowed:[.demoHouse],personalAccess:false)==publicView,"arrival-order-independent")
    }
    let noChain=HouseNoticeInbox()
    _=noChain.ingest([item("first",362),item("middle",181),item("last",0)],at:now)
    check(noChain.groups(at:now,allowed:[.demoHouse],personalAccess:false).count==3,"no-time-chain-merge")
    let targets:[NoticeDestination]=[.cameras,.door,.home]
    for (index,event) in raw.enumerated() {
      check(inbox.destination(for:event.key,at:now,allowed:[.demoHouse],online:true)==targets[index],"typed-mock-view-only")
      check(inbox.destination(for:event.key,at:now,allowed:[],online:true)==nil,"revoked-scope-denied")
      check(inbox.destination(for:event.key,at:now,allowed:[.demoHouse],online:false)==nil,"offline-denied")
      check(inbox.destination(for:event.key,at:now.addingTimeInterval(301),allowed:[.demoHouse],online:true)==nil,"old-action-denied")
      check(inbox.destination(for:event.key,at:now.addingTimeInterval(-1000),allowed:[.demoHouse],online:true)==nil,"future-action-denied")
    }
    check(inbox.groups(at:now,allowed:[.demoHouse],personalAccess:false)==publicView,"navigation-does-not-mutate-records")
    let large=HouseNoticeInbox(),many=(0..<200).map {item("e-\($0)",Double($0),incident:nil)}
    check(large.ingest(many,at:now) == .accepted(inserted:200,duplicates:0),"maximum-complete-batch")
    let before=large.groups(at:now,allowed:[.demoHouse],personalAccess:false)
    check(Set(before.flatMap(\.rows).map(\.id.id))==Set(many.map(\.key.id)),"all-accepted-ids-preserved")
    check(large.ingest([item("overflow",0)],at:now) == .capacity,"capacity-explicit-failure")
    check(large.groups(at:now,allowed:[.demoHouse],personalAccess:false)==before,"no-old-record-eviction")
    large.clear();check(large.groups(at:now,allowed:[.demoHouse],personalAccess:true).isEmpty,"explicit-clear")
    print("PASS independent house-notice gate assertions=\(count)")
  }
}
