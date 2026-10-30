import SwiftUI

#if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
  @preconcurrency import Photos
  #if os(macOS)
    import AppKit
  #else
    import UIKit
  #endif

  private final class PhotoRequestWaiter: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Data?, Never>?
    private var id: PHImageRequestID?
    private var finished = false
    private var cancelled = false
    private let manager = PHImageManager.default()
    init(_ continuation: CheckedContinuation<Data?, Never>) { self.continuation = continuation }
    func setID(_ id: PHImageRequestID) {
      lock.lock()
      self.id = id
      let cancelled = self.cancelled
      lock.unlock()
      if cancelled { manager.cancelImageRequest(id) }
    }
    func finish(_ bytes: Data?) {
      lock.lock()
      guard !finished else {
        lock.unlock()
        return
      }
      finished = true
      let c = continuation
      continuation = nil
      lock.unlock()
      c?.resume(returning: bytes)
    }
    func cancel() {
      lock.lock()
      guard !finished else {
        lock.unlock()
        return
      }
      cancelled = true
      finished = true
      let id = id
      let c = continuation
      continuation = nil
      lock.unlock()
      if let id { manager.cancelImageRequest(id) }
      c?.resume(returning: nil)
    }

  }
#endif


#if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
private final class AlbumImageCancellation: @unchecked Sendable {
  private let lock = NSLock()
  private var waiter: PhotoRequestWaiter?
  private var cancelled = false
  func install(_ value: PhotoRequestWaiter) {
    lock.lock(); waiter = value; let stop = cancelled; lock.unlock()
    if stop { value.cancel() }
  }
  func cancel() {
    lock.lock(); cancelled = true; let value = waiter; lock.unlock()
    value?.cancel()
  }
}
@MainActor
private final class AlbumLibraryObserver: NSObject, PHPhotoLibraryChangeObserver {
  let changed: @MainActor () -> Void
  init(changed: @escaping @MainActor () -> Void) { self.changed = changed }
  nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
    // No PHChange contents or other album metadata cross this callback.
    Task { @MainActor [weak self] in self?.changed() }
  }
}
#endif

@MainActor
final class SystemAlbumPhotoProvider: AlbumPhotoProvider {
  private var generation = 0
  #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
    private var observer: AlbumLibraryObserver?
    private var pending: [UUID:PhotoRequestWaiter] = [:]
  #endif
  init() {
    precondition(!ProcessInfo.processInfo.arguments.contains("--uitesting"),
      "Synthetic UI tests must construct only the fixture album provider")
    // No PHPhotoLibrary/PHImageManager construction or reads here.
  }
  func authorizationGranted() -> Bool {
    #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
      let status = PHPhotoLibrary.authorizationStatus(for:.readWrite)
      return status == .authorized || status == .limited
    #else
      return false
    #endif
  }
  func requestPermission() async throws {
    try Task.checkCancellation()
    #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
      let status = await PHPhotoLibrary.requestAuthorization(for:.readWrite)
      try Task.checkCancellation()
      guard status == .authorized || status == .limited else { throw AlbumAccessError.permissionDenied }
    #else
      throw AlbumAccessError.unavailable
    #endif
  }
  func catalogue() async throws -> [DisplayAlbum] {
    try Task.checkCancellation()
    guard authorizationGranted() else { throw AlbumAccessError.permissionDenied }
    #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
      let result = PHAssetCollection.fetchAssetCollections(with:.album,subtype:.albumCloudShared,options:nil)
      return (0..<min(50,result.count)).compactMap { index in
        let collection = result.object(at:index)
        let title = String((collection.localizedTitle ?? "Shared album").prefix(120))
        let album = DisplayAlbum(id:collection.localIdentifier,title:title)
        return album.valid ? album:nil
      }
    #else
      throw AlbumAccessError.unavailable
    #endif
  }
  func readAlbum(_ id: String, known: [AlbumPhoto]) async throws -> AlbumBatch {
    guard DisplayAlbum.validIdentifier(id) else { throw AlbumAccessError.invalidBatch }
    guard authorizationGranted() else { throw AlbumAccessError.permissionDenied }
    try Task.checkCancellation()
    let ticket = generation
    #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
      let collections = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers:[id],options:nil)
      guard let collection = collections.firstObject,
            collection.assetCollectionType == .album,
            collection.assetCollectionSubtype == .albumCloudShared else {
        throw AlbumAccessError.noLongerAccessible
      }
      let options = PHFetchOptions()
      options.predicate = NSPredicate(format:"mediaType == %d",PHAssetMediaType.image.rawValue)
      options.sortDescriptors = [NSSortDescriptor(key:"creationDate",ascending:false)]
      options.fetchLimit = 10
      let result = PHAsset.fetchAssets(in:collection,options:options)
      let assets = (0..<min(10,result.count)).map { result.object(at:$0) }
      let old = Dictionary(known.filter(\.valid).map { ($0.id,$0) },uniquingKeysWith:{ first,_ in first })
      let clock = ContinuousClock()
      let deadline = clock.now.advanced(by:.seconds(45))
      var photos: [AlbumPhoto] = []
      for asset in assets {
        guard generation == ticket else { throw CancellationError() }
        try Task.checkCancellation()
        guard authorizationGranted() else { throw AlbumAccessError.permissionDenied }
        // A missing revision is deliberately unstable: never infer freshness.
        let revision = asset.modificationDate.map { String($0.timeIntervalSince1970) }
          ?? "unknown-" + UUID().uuidString
        if let cached = old[asset.localIdentifier],cached.revision == revision {
          photos.append(cached); continue
        }
        let left = clock.now.duration(to:deadline).components
        let remaining = Double(left.seconds) + Double(left.attoseconds)/1e18
        if remaining <= 0 { break }
        if let bytes = await image(asset,timeout:min(20,remaining)),
           !bytes.isEmpty,bytes.count <= 5_000_000 {
          photos.append(AlbumPhoto(id:asset.localIdentifier,revision:revision,bytes:bytes))
        }
      }
      guard generation == ticket else { throw CancellationError() }
      try Task.checkCancellation()
      guard authorizationGranted() else { throw AlbumAccessError.permissionDenied }
      return AlbumBatch(orderedIDs:assets.map(\.localIdentifier),photos:photos)
    #else
      throw AlbumAccessError.unavailable
    #endif
  }
  #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
  private func image(_ asset: PHAsset, timeout: TimeInterval) async -> Data? {
    let control = AlbumImageCancellation()
    let token = UUID()
    defer { pending.removeValue(forKey:token) }
    return await withTaskCancellationHandler {
      await withCheckedContinuation { continuation in
        let waiter = PhotoRequestWaiter(continuation)
        pending[token] = waiter
        control.install(waiter)
        guard !Task.isCancelled else { waiter.cancel(); return }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        let request = PHImageManager.default().requestImage(for:asset,
          targetSize:CGSize(width:1600,height:1600),contentMode:.aspectFit,options:options) { image,info in
          if info?[PHImageResultIsDegradedKey] as? Bool == true { return }
          #if os(macOS)
            let data = image?.tiffRepresentation.flatMap { try? PhotoThumbnail.make($0) }
          #else
            let data = image?.jpegData(compressionQuality:0.82)
          #endif
          waiter.finish(data)
        }
        waiter.setID(request)
        DispatchQueue.global().asyncAfter(deadline:.now()+timeout) { waiter.cancel() }
      }
    } onCancel: { control.cancel() }
  }
  #endif
  func cancelReads() {
    generation += 1
    #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
      pending.values.forEach { $0.cancel() }
      pending = [:]
    #endif
  }
  func observeChanges(_ handler: (@MainActor () -> Void)?) {
    #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
      if let observer { PHPhotoLibrary.shared().unregisterChangeObserver(observer) }
      observer = nil
      guard let handler,authorizationGranted() else { return }
      let value = AlbumLibraryObserver(changed:handler)
      observer = value
      PHPhotoLibrary.shared().register(value)
    #endif
  }
}

/// No PhotoKit objects, library permission requests or real albums in this path.
@MainActor @Observable
final class FixtureAlbumPhotoProvider: AlbumPhotoProvider {
  var allowed: Bool
  private(set) var catalogueReads = 0
  private(set) var permissionRequests = 0
  private(set) var readCalls = 0
  private(set) var window = 0
  private(set) var lastID = ""
  private var changed: (@MainActor () -> Void)?
  private var images: [String:Data] = [:]
  init() {
    let args = ProcessInfo.processInfo.arguments
    allowed = !args.contains("--album-fixture-denied")
    if let i=args.firstIndex(of:"--album-fixture-window"),args.indices.contains(i+1) {
      window = args[i+1] == "changed" ? 1:args[i+1] == "empty" ? 2:0
    }
  }
  var report: String { "fixture-only;catalogue=\(catalogueReads);permission=\(permissionRequests);reads=\(readCalls);window=\(window);album=\(lastID)" }
  func authorizationGranted() -> Bool { allowed }
  func requestPermission() async throws {
    permissionRequests += 1
    guard allowed else { throw AlbumAccessError.permissionDenied }
  }
  func catalogue() async throws -> [DisplayAlbum] {
    catalogueReads += 1
    guard allowed else { throw AlbumAccessError.permissionDenied }
    return [DisplayAlbum(id:"fixture",title:"Synthetic shared album"),
      DisplayAlbum(id:"second",title:"Second synthetic album")]
  }
  func readAlbum(_ id: String, known: [AlbumPhoto]) async throws -> AlbumBatch {
    guard allowed else { throw AlbumAccessError.permissionDenied }
    readCalls += 1; lastID = id
    let ids = id == "second" ? ["fixture-c"] : window == 2 ? [] :
      window == 1 ? ["fixture-b","fixture-c"] : ["fixture-a","fixture-b"]
    let old = Dictionary(known.map { ($0.id,$0) },uniquingKeysWith:{ first,_ in first })
    let revision = "v\(window)"
    let values = ids.compactMap { assetID -> AlbumPhoto? in
      if let old=old[assetID],old.revision == revision { return old }
      let name = assetID == "fixture-a" ? DemoPhotoAssets.portrait :
        assetID == "fixture-b" ? DemoPhotoAssets.landscape : "DemoCameraLivingRoomV1"
      if images[name] == nil {
        #if os(macOS)
          images[name] = NSImage(named:name)?.tiffRepresentation.flatMap { try? PhotoThumbnail.make($0) }
        #elseif canImport(UIKit)
          images[name] = UIImage(named:name)?.jpegData(compressionQuality:0.8)
        #endif
      }
      return images[name].map { AlbumPhoto(id:assetID,revision:revision,bytes:$0) }
    }
    return AlbumBatch(orderedIDs:ids,photos:values)
  }
  func cancelReads() {}
  func observeChanges(_ handler: (@MainActor () -> Void)?) { changed = handler }
  func changeWindow() { window = (window+1)%3; changed?() }
  func revoke() { allowed = false; changed?() }
}
@MainActor
func makeAlbumPhotoProvider() -> any AlbumPhotoProvider {
  if ProcessInfo.processInfo.arguments.contains("--uitesting") { return FixtureAlbumPhotoProvider() }
  return SystemAlbumPhotoProvider()
}

struct SharedAlbumControls: View {
  @Environment(AppModel.self) private var model
  @ScaledMetric(relativeTo:.body) private var actionSize:CGFloat=21
  @ScaledMetric(relativeTo:.footnote) private var statusSize:CGFloat=16
  @ScaledMetric(relativeTo:.headline) private var albumTitleSize:CGFloat=19
  @State private var task: Task<Void,Never>?
  @State private var importing = false
  private func importOnce(_ album: DisplayAlbum) {
    guard !importing else { return }
    importing = true
    task = Task {
      await model.importAlbumOnce(album)
      importing = false
    }
  }
  var body: some View {
    VStack(alignment:.leading,spacing:12) {
      if !model.connections.personalUnlocked {
        Button("Unlock shared albums") { model.requestAlbumUnlock() }
          .accessibilityIdentifier("photos.shared.load")
      } else {
        Button("Import Shared Album") { task = Task { await model.loadAlbumChoices() } }
          .disabled(model.albumCatalogue.busy || importing)
          .accessibilityIdentifier("photos.shared.load")
        if !model.albumCatalogue.albums.isEmpty {
          Text("Keep updated lets new photos from the chosen album appear on this shared display while HomeView is active. Up to ten copies are kept until you disconnect.")
            .font(.system(size:statusSize)).foregroundStyle(.black.opacity(0.65))
            .accessibilityIdentifier("photos.shared.display.notice")
        }
        ForEach(model.albumCatalogue.albums) { album in
          Menu {
            Button("Import once") { importOnce(album) }
            Button("Keep updated on this display") { model.linkAlbumForDisplay(album) }
              .accessibilityIdentifier("photos.shared.link.\(album.id)")
          } label: { Text(album.title) } primaryAction: { importOnce(album) }
            .disabled(importing).accessibilityIdentifier("photos.shared.\(album.id)")
        }
      }
      if !model.albumCatalogue.status.isEmpty {
        Text(model.albumCatalogue.status).font(.system(size:statusSize)).foregroundStyle(.black.opacity(0.65))
      }
      if let grant=model.data.albumDisplay {
        Text(grant.album.title).font(.system(size:albumTitleSize,weight:.semibold))
        Text("New photos from this album appear on this shared display while HomeView is active. Up to ten photos are kept.")
          .font(.system(size:statusSize)).foregroundStyle(.black.opacity(0.65))
        Button("Update now") { model.refreshDisplayAlbum() }
          .disabled(model.albumUpdates.busy).accessibilityIdentifier("photos.shared.refresh")
        Button("Disconnect and remove linked copies") { model.disconnectDisplayAlbum() }
          .accessibilityIdentifier("photos.shared.disconnect")
      }
      if !model.albumUpdates.status.isEmpty {
        Text(model.albumUpdates.status).font(.system(size:statusSize)).foregroundStyle(.black.opacity(0.65))
          .accessibilityIdentifier("photos.shared.status")
      }
      if let report=model.albumFixtureReport {
        Text(report).font(.system(size:10)).accessibilityIdentifier("photos.shared.fixture.report")
        Button("Change synthetic album") { model.changeAlbumFixture() }
          .accessibilityIdentifier("photos.shared.fixture.change")
        Button("Revoke synthetic Photos access") { model.revokeAlbumFixture() }
          .accessibilityIdentifier("photos.shared.fixture.revoke")
      }
    }.font(.system(size:actionSize))
      .onChange(of:model.connections.personalUnlocked) { _,unlocked in
        if !unlocked { task?.cancel(); model.albumCatalogue.invalidate() }
      }
      .onDisappear { task?.cancel(); model.albumCatalogue.invalidate(locked:false) }
  }
}
