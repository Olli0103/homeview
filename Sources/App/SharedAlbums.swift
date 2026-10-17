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

@MainActor @Observable
final class SharedAlbumReader {
  struct Album: Identifiable {
    let id: String
    let name: String
  }
  var albums: [Album] = []
  var status = ""
  var busy = false
  private var generation = 0
  private let testing = ProcessInfo.processInfo.arguments.contains("--uitesting")
  #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
    private var collections: [String: PHAssetCollection] = [:]
    private var pending: PhotoRequestWaiter?
  #endif
  func load() async {
    guard !busy else { return }
    busy = true
    generation += 1
    let ticket = generation
    defer { busy = false }
    if testing {
      albums = [Album(id: "fixture", name: "Synthetic shared album")]
      return
    }
    #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
      let access = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
      guard generation == ticket, !Task.isCancelled else { return }
      guard access == .authorized || access == .limited else {
        status = "Photos access was not granted."
        return
      }
      collections = [:]
      albums = []
      let fetched = PHAssetCollection.fetchAssetCollections(
        with: .album, subtype: .albumCloudShared, options: nil)
      for i in 0..<min(50, fetched.count) {
        let c = fetched.object(at: i)
        collections[c.localIdentifier] = c
        albums.append(Album(id: c.localIdentifier, name: c.localizedTitle ?? "Shared album"))
      }
      status =
        albums.isEmpty
        ? "No accessible shared albums. You can use Choose Photos instead."
        : "Choose an album to import up to ten photos."
    #else
      status = "Shared albums are unavailable on this target."
    #endif
  }
  func images(_ id: String) async -> [Data] {
    guard !busy else { return [] }
    busy = true
    defer { busy = false }
    generation += 1
    let ticket = generation
    if testing {
      #if os(macOS)
        return DemoPhotoAssets.gallery.compactMap { NSImage(named: $0)?.tiffRepresentation }.compactMap
        { try? PhotoThumbnail.make($0) }
      #elseif canImport(UIKit)
        return DemoPhotoAssets.gallery.compactMap {
          UIImage(named: $0)?.jpegData(compressionQuality: 0.8)
        }
      #else
        return []
      #endif
    }
    #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
      guard let collection = collections[id] else { return [] }
      let options = PHFetchOptions()
      options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
      options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      options.fetchLimit = 10
      let assets = PHAsset.fetchAssets(in: collection, options: options)
      var values: [Data] = []
      for i in 0..<min(10, assets.count) {
        guard !Task.isCancelled, generation == ticket else { return [] }
        let asset = assets.object(at: i)
        let bytes: Data? = await withCheckedContinuation { continuation in
          let waiter = PhotoRequestWaiter(continuation)
          pending = waiter
          let options = PHImageRequestOptions()
          options.deliveryMode = .highQualityFormat
          options.resizeMode = .exact
          options.isNetworkAccessAllowed = true
          let request = PHImageManager.default().requestImage(
            for: asset, targetSize: CGSize(width: 1600, height: 1600), contentMode: .aspectFit,
            options: options
          ) { image, info in
            if info?[PHImageResultIsDegradedKey] as? Bool == true { return }
            #if os(macOS)
              let data = image?.tiffRepresentation.flatMap { try? PhotoThumbnail.make($0) }
            #else
              let data = image?.jpegData(compressionQuality: 0.82)
            #endif
            waiter.finish(data)
          }
          waiter.setID(request)
          DispatchQueue.global().asyncAfter(deadline: .now() + 20) { waiter.cancel() }
        }
        pending = nil
        if let bytes, bytes.count <= 5_000_000 { values.append(bytes) }
      }
      guard !Task.isCancelled, generation == ticket else { return [] }
      status =
        values.isEmpty
        ? "No photos could be loaded." : "Imported \(values.count) selected-album photos."
      return values
    #else
      return []
    #endif
  }
  func cancel() {
    generation += 1
    #if canImport(Photos) && (os(iOS) || os(macOS) || os(visionOS))
      pending?.cancel()
      pending = nil
    #endif
  }
}
struct SharedAlbumControls: View {
  @Environment(AppModel.self) private var model
  @Environment(\.scenePhase) private var scenePhase
  @State private var reader = SharedAlbumReader()
  @State private var task: Task<Void, Never>?
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Button("Import Shared Album") { task = Task { await reader.load() } }
        .disabled(reader.busy).accessibilityIdentifier("photos.shared.load")
      ForEach(reader.albums) { album in
        Button(album.name) {
          task = Task {
            let images = await reader.images(album.id)
            if !Task.isCancelled, !images.isEmpty { model.setGallery(images) }
          }
        }.disabled(reader.busy).accessibilityIdentifier("photos.shared.\(album.id)")
      }
      if !reader.status.isEmpty {
        Text(reader.status).font(.system(size: 16)).foregroundStyle(.gray)
      }
    }.font(.system(size: 21)).onChange(of: scenePhase) { _, phase in
      if phase == .background {
        task?.cancel()
        reader.cancel()
      }
    }.onDisappear {
      task?.cancel()
      reader.cancel()
    }
  }
}
