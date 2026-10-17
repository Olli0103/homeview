import Foundation
import XCTest
@testable import HomeViewCore

@MainActor
private final class ControlledAlbumProvider: AlbumPhotoProvider {
  var allowed = true
  var holdPermission = false
  var holdRead = false
  var permissionCalls = 0
  var catalogueReads = 0
  var readCalls = 0
  var cancellations = 0
  var readIDs: [String] = []
  var changeHandler: (@MainActor () -> Void)?
  var batch = AlbumBatch(orderedIDs: [], photos: [])
  var permissions: [Int: CheckedContinuation<Void, Error>] = [:]
  var reads: [Int: CheckedContinuation<AlbumBatch, Error>] = [:]
  private var permissionEntries: [Int: CheckedContinuation<Void, Never>] = [:]
  private var readEntries: [Int: CheckedContinuation<Void, Never>] = [:]
  func authorizationGranted() -> Bool { allowed }
  func requestPermission() async throws {
    permissionCalls += 1
    if holdPermission {
      let call = permissionCalls
      try await withCheckedThrowingContinuation { continuation in
        permissions[call] = continuation
        permissionEntries.removeValue(forKey: call)?.resume()
      }
    }
    if !allowed { throw AlbumAccessError.permissionDenied }
  }
  func catalogue() async throws -> [DisplayAlbum] {
    catalogueReads += 1
    return [DisplayAlbum(id: "chosen", title: "Synthetic album")]
  }
  func readAlbum(_ id: String, known: [AlbumPhoto]) async throws -> AlbumBatch {
    readCalls += 1
    readIDs.append(id)
    if holdRead {
      let call = readCalls
      return try await withCheckedThrowingContinuation { continuation in
        reads[call] = continuation
        readEntries.removeValue(forKey: call)?.resume()
      }
    }
    return batch
  }
  func cancelReads() { cancellations += 1 }
  func observeChanges(_ handler: (@MainActor () -> Void)?) { changeHandler = handler }
  func permissionStarted(_ call: Int) async {
    if permissions[call] != nil { return }
    await withCheckedContinuation { permissionEntries[call] = $0 }
  }
  func readStarted(_ call: Int) async {
    if reads[call] != nil { return }
    await withCheckedContinuation { readEntries[call] = $0 }
  }
}

@MainActor
final class AlbumDisplayTests: XCTestCase {
  private let chosen = DisplayAlbum(id: "chosen", title: "Synthetic album")
  private func photo(_ id: String, _ byte: UInt8 = 1) -> AlbumPhoto {
    AlbumPhoto(id: id, revision: "v1", bytes: Data([byte]))
  }
  func testPermissionWithoutAuthenticationNeverEnumeratesAndOldCleanupCannotClearNewLoad() async {
    let provider = ControlledAlbumProvider()
    let catalogue = AlbumCatalogueSession(provider: provider)
    var authenticated = false
    await catalogue.load { authenticated }
    XCTAssertEqual(provider.catalogueReads, 0)
    provider.holdPermission = true
    authenticated = true
    let first = Task { await catalogue.load { authenticated } }
    await provider.permissionStarted(1)
    authenticated = false
    catalogue.invalidate()
    authenticated = true
    let second = Task { await catalogue.load { authenticated } }
    await provider.permissionStarted(2)
    provider.permissions.removeValue(forKey: 1)!.resume()
    await first.value
    XCTAssertEqual(provider.catalogueReads, 0)
    XCTAssertTrue(catalogue.busy)
    provider.permissions.removeValue(forKey: 2)!.resume()
    await second.value
    XCTAssertEqual(provider.catalogueReads, 1)
    XCTAssertFalse(catalogue.busy)
    XCTAssertEqual(catalogue.albums.map(\.id), ["chosen"])
  }
  func testExplicitAuthenticatedDisplayGrantReadsOnlyTheChosenAlbum() async {
    let provider = ControlledAlbumProvider()
    provider.batch = AlbumBatch(orderedIDs: ["a"], photos: [photo("a")])
    let session = AlbumDisplaySession(provider: provider)
    session.setActive(true)
    XCTAssertFalse(session.select(chosen, deviceAuthenticated: false, explicitDisplayConsent: true))
    XCTAssertFalse(session.select(chosen, deviceAuthenticated: true, explicitDisplayConsent: false))
    await session.refresh(force: true)
    XCTAssertEqual(provider.readCalls, 0)
    XCTAssertTrue(session.select(chosen, deviceAuthenticated: true, explicitDisplayConsent: true))
    await session.refresh(force: true)
    XCTAssertEqual(provider.readIDs, ["chosen"])
    XCTAssertEqual(provider.catalogueReads, 0)
    XCTAssertEqual(provider.permissionCalls, 0)
    XCTAssertEqual(session.photos.map(\.id), ["a"])
  }
  func testChangedWindowDropsRemovedPhotosAndRetainsOnlyStillListedOfflineCopies() async {
    let provider = ControlledAlbumProvider()
    let session = AlbumDisplaySession(provider: provider)
    session.setActive(true)
    _ = session.select(chosen, deviceAuthenticated: true, explicitDisplayConsent: true)
    provider.batch = AlbumBatch(orderedIDs: ["a", "b"], photos: [photo("a"), photo("b", 2)])
    await session.refresh(force: true)
    provider.batch = AlbumBatch(orderedIDs: ["b", "c"], photos: [photo("c", 3)])
    await session.refresh(force: true)
    XCTAssertEqual(session.photos.map(\.id), ["b", "c"])
    XCTAssertEqual(session.photos.first?.bytes, Data([2]))
    XCTAssertTrue(session.status.contains("some photos unavailable"))
    XCTAssertFalse(session.photos.contains { $0.id == "a" })
  }
  func testLateReadAfterDisconnectCannotRestoreScopeOrDisplay() async {
    let provider = ControlledAlbumProvider(); provider.holdRead = true
    let session = AlbumDisplaySession(provider: provider)
    var visible: [AlbumPhoto] = []
    session.apply = { _, photos in visible = photos; return true }
    session.setActive(true)
    _ = session.select(chosen, deviceAuthenticated: true, explicitDisplayConsent: true)
    let request = Task { await session.refresh(force: true) }
    await provider.readStarted(1)
    session.stop()
    provider.reads.removeValue(forKey: 1)!.resume(returning: AlbumBatch(orderedIDs: ["old"], photos: [photo("old")]))
    await request.value
    XCTAssertNil(session.album)
    XCTAssertTrue(session.photos.isEmpty)
    XCTAssertTrue(visible.isEmpty)
    XCTAssertNil(provider.changeHandler)
    XCTAssertFalse(session.busy)
  }
  func testOldResultCannotReplaceNewAlbumOrClearItsBusyState() async {
    let provider = ControlledAlbumProvider(); provider.holdRead = true
    let session = AlbumDisplaySession(provider: provider)
    session.setActive(true)
    _ = session.select(chosen, deviceAuthenticated: true, explicitDisplayConsent: true)
    let first = Task { await session.refresh(force: true) }
    await provider.readStarted(1)
    let secondAlbum = DisplayAlbum(id: "second", title: "Another synthetic album")
    _ = session.select(secondAlbum, deviceAuthenticated: true, explicitDisplayConsent: true)
    let second = Task { await session.refresh(force: true) }
    await provider.readStarted(2)
    provider.reads.removeValue(forKey: 1)!.resume(returning: AlbumBatch(orderedIDs: ["old"], photos: [photo("old")]))
    await first.value
    XCTAssertEqual(session.album?.id, "second")
    XCTAssertTrue(session.photos.isEmpty)
    XCTAssertTrue(session.busy)
    provider.reads.removeValue(forKey: 2)!.resume(returning: AlbumBatch(orderedIDs: ["new"], photos: [photo("new")]))
    await second.value
    XCTAssertEqual(session.photos.map(\.id), ["new"])
  }
  func testNoBackgroundReadsAndPermissionRevocationRemovesLinkedCopies() async {
    let provider = ControlledAlbumProvider()
    provider.batch = AlbumBatch(orderedIDs: ["a"], photos: [photo("a")])
    let session = AlbumDisplaySession(provider: provider)
    var visible = [AlbumPhoto]()
    session.apply = { _, photos in visible = photos; return true }
    session.setActive(true)
    _ = session.select(chosen, deviceAuthenticated: true, explicitDisplayConsent: true)
    await session.refresh(force: true)
    session.setActive(false)
    session.markChanged()
    await session.refresh(force: true)
    XCTAssertEqual(provider.readCalls, 1)
    XCTAssertNil(provider.changeHandler)
    session.setActive(true)
    provider.allowed = false
    await session.refresh(force: true)
    XCTAssertEqual(provider.readCalls, 1)
    XCTAssertNil(session.album)
    XCTAssertTrue(visible.isEmpty)
    XCTAssertTrue(session.status.contains("revoked"))
  }
  func testMalformedOversizeAndFailedLocalCommitKeepThePreviousCopies() async {
    let provider = ControlledAlbumProvider()
    let session = AlbumDisplaySession(provider: provider)
    session.setActive(true)
    _ = session.select(chosen, deviceAuthenticated: true, explicitDisplayConsent: true)
    provider.batch = AlbumBatch(orderedIDs: ["a"], photos: [photo("a")])
    await session.refresh(force: true)
    provider.batch = AlbumBatch(orderedIDs: ["b"], photos: [photo("foreign")])
    await session.refresh(force: true)
    XCTAssertEqual(session.photos.map(\.id), ["a"])
    let bytes = Data(repeating: 1, count: 5_000_000)
    let large = (0..<8).map { AlbumPhoto(id: "large-\($0)", revision: "v1", bytes: bytes) }
    provider.batch = AlbumBatch(orderedIDs: large.map(\.id), photos: large)
    await session.refresh(force: true)
    XCTAssertEqual(session.photos.map(\.id), ["a"])
    session.apply = { _, _ in false }
    XCTAssertFalse(session.select(DisplayAlbum(id: "second", title: "Another"), deviceAuthenticated: true, explicitDisplayConsent: true))
    XCTAssertEqual(session.album?.id, "chosen")
    provider.batch = AlbumBatch(orderedIDs: ["b"], photos: [photo("b")])
    await session.refresh(force: true)
    XCTAssertEqual(session.photos.map(\.id), ["a"])
  }
  func testAutomaticChangesCoalesceAgainstMonotonicTimeWithoutPolling() async {
    let provider = ControlledAlbumProvider()
    provider.batch = AlbumBatch(orderedIDs:["a"],photos:[photo("a")])
    let session = AlbumDisplaySession(provider:provider)
    session.setActive(true)
    _ = session.select(chosen,deviceAuthenticated:true,explicitDisplayConsent:true)
    await session.refresh(at:100)
    for _ in 0..<20 { provider.changeHandler?() }
    XCTAssertFalse(session.shouldRefresh(at:129))
    await session.refresh(at:129)
    XCTAssertEqual(provider.readCalls,1)
    XCTAssertTrue(session.shouldRefresh(at:130))
    await session.refresh(at:130)
    XCTAssertEqual(provider.readCalls,2)
    XCTAssertFalse(session.shouldRefresh(at:10000),"No changes means no periodic library enumeration")
    XCTAssertFalse(session.shouldRefresh(at:.nan))
  }
  func testLatePermissionErrorFromOldAlbumCannotRevokeNewScope() async {
    let provider = ControlledAlbumProvider();provider.holdRead=true
    let session = AlbumDisplaySession(provider:provider)
    session.setActive(true)
    _ = session.select(chosen,deviceAuthenticated:true,explicitDisplayConsent:true)
    let old = Task { await session.refresh(force:true) }
    await provider.readStarted(1)
    _ = session.select(DisplayAlbum(id:"second",title:"Another"),deviceAuthenticated:true,explicitDisplayConsent:true)
    let current = Task { await session.refresh(force:true) }
    await provider.readStarted(2)
    provider.reads.removeValue(forKey:1)!.resume(throwing:AlbumAccessError.permissionDenied)
    await old.value
    XCTAssertEqual(session.album?.id,"second")
    XCTAssertTrue(session.busy)
    provider.reads.removeValue(forKey:2)!.resume(returning:AlbumBatch(orderedIDs:["new"],photos:[photo("new")]))
    await current.value
    XCTAssertEqual(session.photos.map(\.id),["new"])
  }
  func testSourceRemovalStopsObserverAndClearsOnlyItsLinkedExport() async {
    let provider = ControlledAlbumProvider();provider.holdRead=true
    let session = AlbumDisplaySession(provider:provider)
    var linked = true
    session.apply = { album,_ in linked = album != nil;return true }
    session.setActive(true)
    _ = session.select(chosen,deviceAuthenticated:true,explicitDisplayConsent:true)
    let request = Task { await session.refresh(force:true) }
    await provider.readStarted(1)
    provider.reads.removeValue(forKey:1)!.resume(throwing:AlbumAccessError.noLongerAccessible)
    await request.value
    XCTAssertNil(session.album)
    XCTAssertFalse(linked)
    XCTAssertNil(provider.changeHandler)
    XCTAssertFalse(session.shouldRefresh(at:10000))
  }
  func testRestoreRequiresValidGrantAndCacheScopeWithoutReadingTheLibrary() {
    let provider = ControlledAlbumProvider()
    let session = AlbumDisplaySession(provider: provider)
    let grant = AlbumDisplayGrant(album: chosen, approvedForDisplay: true,
      cache: [AlbumCacheReference(assetID: "a", revision: "v1", fileID: UUID().uuidString)])
    session.restore(grant, photos: [photo("foreign")])
    XCTAssertNil(session.album)
    session.restore(grant, photos: [photo("a")])
    XCTAssertEqual(session.photos.map(\.id), ["a"])
    XCTAssertFalse(session.shouldRefresh(at: 100))
    XCTAssertEqual(provider.readCalls, 0)
    XCTAssertEqual(provider.catalogueReads, 0)
    XCTAssertEqual(provider.permissionCalls, 0)
    XCTAssertNil(provider.changeHandler)
  }
}

final class AlbumSnapshotTests: XCTestCase {
  func testOldSnapshotsKeepLegacySelectionButMalformedNewSourceDoesNotReviveIt() throws {
    var original = Snapshot()
    original.home.temperature = 73
    var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as! [String:Any]
    object.removeValue(forKey: "photoSelection")
    let legacy = try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject: object))
    XCTAssertEqual(legacy.photoSelection, .legacy)
    XCTAssertEqual(legacy.home.temperature, 73)
    object["photoSelection"] = "future-unknown"
    let invalid = try Snapshot.decodeMigrating(JSONSerialization.data(withJSONObject: object))
    XCTAssertEqual(invalid.photoSelection, .none)
    // A bad photo field must not reset unrelated household values.
    XCTAssertEqual(invalid.home.temperature, 73)
    XCTAssertNil(invalid.albumDisplay)
  }
  func testSelectedAlbumCacheRoundTripsButForeignFileReferencesCannotBecomeAnActiveGrant() throws {
    var snapshot = Snapshot()
    snapshot.home.temperature = 73
    snapshot.photoSelection = .album
    let fileID = UUID().uuidString
    snapshot.photoIDs = [fileID]
    snapshot.albumDisplay = AlbumDisplayGrant(album: DisplayAlbum(id:"chosen",title:"Synthetic album"),
      approvedForDisplay:true,cache:[AlbumCacheReference(assetID:"a",revision:"v1",fileID:fileID)])
    let restored = try Snapshot.decodeMigrating(JSONEncoder().encode(snapshot))
    XCTAssertEqual(restored.albumDisplay, snapshot.albumDisplay)
    XCTAssertEqual(restored.photoSelection, .album)
    snapshot.albumDisplay!.cache[0].fileID = UUID().uuidString
    let damaged = try Snapshot.decodeMigrating(JSONEncoder().encode(snapshot))
    XCTAssertNil(damaged.albumDisplay)
    XCTAssertEqual(damaged.photoSelection, .none)
    XCTAssertTrue(damaged.photoIDs.isEmpty)
    XCTAssertEqual(damaged.home.temperature, 73)
  }
  func testExplicitRemovalClearsOnlyPhotoSelectionMetadataAndNoConsentGrantIsRejected() throws {
    var snapshot = Snapshot()
    snapshot.photoSelection = .none
    snapshot.photoIDs = [UUID().uuidString]
    snapshot.photoGalleryTitle = "Old album"
    snapshot.home.temperature = 74
    snapshot.albumDisplay = AlbumDisplayGrant(album:DisplayAlbum(id:"chosen",title:"Synthetic"),approvedForDisplay:false)
    let restored = try Snapshot.decodeMigrating(JSONEncoder().encode(snapshot))
    XCTAssertEqual(restored.photoSelection, .none)
    XCTAssertTrue(restored.photoIDs.isEmpty)
    XCTAssertNil(restored.photoGalleryTitle)
    XCTAssertNil(restored.albumDisplay)
    XCTAssertEqual(restored.home.temperature, 74)
  }
}

extension AlbumDisplayTests {
  func testRevokedGrantAtRestoreClearsExportsBeforeAnyLibraryRead() {
    let provider = ControlledAlbumProvider();provider.allowed=false
    let session = AlbumDisplaySession(provider:provider)
    var cleared=false
    session.apply = { album,photos in cleared = album == nil && photos.isEmpty;return true }
    let grant=AlbumDisplayGrant(album:chosen,approvedForDisplay:true,
      cache:[AlbumCacheReference(assetID:"a",revision:"v1",fileID:UUID().uuidString)])
    session.restore(grant,photos:[photo("a")])
    XCTAssertTrue(cleared)
    XCTAssertNil(session.album)
    XCTAssertTrue(session.photos.isEmpty)
    XCTAssertEqual(provider.readCalls,0)
    XCTAssertEqual(provider.permissionCalls,0)
  }
}
extension AlbumSnapshotTests {
  func testSingleSelectionUsesOnlyItsCommittedIdentityInsteadOfAnUnrelatedLegacyFile() throws {
    var value=Snapshot()
    value.photoSelection = .single
    value.photoIDs=[UUID().uuidString,UUID().uuidString]
    value.photoGalleryTitle="Old gallery"
    let restored=try Snapshot.decodeMigrating(JSONEncoder().encode(value))
    XCTAssertEqual(restored.photoSelection,.single)
    XCTAssertEqual(restored.photoIDs,[value.photoIDs[0]])
    XCTAssertNil(restored.photoGalleryTitle)
  }
}

extension AlbumDisplayTests {
  func testRevokedPermissionBeforeSelectionCannotReplaceThePreviousCommittedChoice() {
    let provider=ControlledAlbumProvider()
    let session=AlbumDisplaySession(provider:provider)
    var commits=0
    session.apply = { _,_ in commits += 1;return true }
    XCTAssertTrue(session.select(chosen,deviceAuthenticated:true,explicitDisplayConsent:true))
    provider.allowed=false
    XCTAssertFalse(session.select(DisplayAlbum(id:"other",title:"Other"),
      deviceAuthenticated:true,explicitDisplayConsent:true))
    XCTAssertEqual(commits,1)
    XCTAssertEqual(session.album,chosen)
    XCTAssertEqual(provider.readCalls,0)
    XCTAssertEqual(provider.permissionCalls,0)
  }
}
extension AlbumSnapshotTests {
  func testAlbumCacheOrderAndMultiplicityMustMatchCommittedPhotoIdentities() throws {
    var value=Snapshot();value.home.temperature=73
    value.photoSelection = .album
    let a=UUID().uuidString,b=UUID().uuidString
    value.photoIDs=[a,b]
    value.albumDisplay=AlbumDisplayGrant(album:DisplayAlbum(id:"chosen",title:"Synthetic"),
      approvedForDisplay:true,cache:[
        AlbumCacheReference(assetID:"a",revision:"v1",fileID:a),
        AlbumCacheReference(assetID:"b",revision:"v1",fileID:b)])
    let valid=try Snapshot.decodeMigrating(JSONEncoder().encode(value))
    XCTAssertNotNil(valid.albumDisplay)
    value.photoIDs=[b,a]
    let reordered=try Snapshot.decodeMigrating(JSONEncoder().encode(value))
    XCTAssertNil(reordered.albumDisplay)
    XCTAssertTrue(reordered.photoIDs.isEmpty)
    XCTAssertEqual(reordered.home.temperature,73)
    value.photoIDs=[a,a,b]
    let duplicated=try Snapshot.decodeMigrating(JSONEncoder().encode(value))
    XCTAssertNil(duplicated.albumDisplay)
    XCTAssertTrue(duplicated.photoIDs.isEmpty)
    XCTAssertEqual(duplicated.home.temperature,73)
  }
}

extension AlbumDisplayTests {
  func testPermissionRevocationOnForegroundClearsCopiesBeforeTheRefreshThrottle() async {
    let provider=ControlledAlbumProvider()
    provider.batch=AlbumBatch(orderedIDs:["a"],photos:[photo("a")])
    let session=AlbumDisplaySession(provider:provider)
    var removals=0
    session.apply = { album,_ in if album == nil { removals += 1 };return true }
    session.setActive(true)
    _=session.select(chosen,deviceAuthenticated:true,explicitDisplayConsent:true)
    await session.refresh(force:true,at:100)
    XCTAssertEqual(session.photos.count,1)
    session.setActive(false)
    provider.allowed=false
    session.setActive(true)
    XCTAssertNil(session.album)
    XCTAssertTrue(session.photos.isEmpty)
    XCTAssertEqual(removals,1)
    XCTAssertEqual(provider.readCalls,1)
    XCTAssertEqual(provider.permissionCalls,0)
    XCTAssertNil(provider.changeHandler)
  }
  func testActivePermissionRevocationClearsCopiesBeforeTheReadinessCheckCanThrottleIt() async {
    let provider=ControlledAlbumProvider()
    provider.batch=AlbumBatch(orderedIDs:["a"],photos:[photo("a")])
    let session=AlbumDisplaySession(provider:provider)
    var removals=0
    session.apply = { album,_ in if album == nil { removals += 1 };return true }
    session.setActive(true)
    _=session.select(chosen,deviceAuthenticated:true,explicitDisplayConsent:true)
    await session.refresh(force:true,at:100)
    provider.allowed=false
    XCTAssertFalse(session.shouldRefresh(at:101))
    XCTAssertNil(session.album)
    XCTAssertTrue(session.photos.isEmpty)
    XCTAssertEqual(removals,1)
    XCTAssertEqual(provider.readCalls,1)
    XCTAssertEqual(provider.permissionCalls,0)
  }
}
