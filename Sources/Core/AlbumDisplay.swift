import Foundation
import Observation

/// Exported photos for this display are separate from the private album catalogue.
/// Only a device-authenticated, explicit display choice may create this grant.
struct DisplayAlbum: Codable, Equatable, Sendable, Identifiable {
  var id: String
  var title: String
  var valid: Bool {
    Self.validIdentifier(id) && !title.isEmpty && title.count <= 120 && title.utf8.count <= 2048
      && !title.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
  }
  static func validIdentifier(_ value: String) -> Bool {
    !value.isEmpty && value.count <= 1024 && value.utf8.count <= 2048
      && value == value.trimmingCharacters(in: .whitespacesAndNewlines)
      && !value.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
  }
}

enum PhotoSelectionKind: String, Codable, Sendable {
  // Only pre-existing snapshots may infer their selection from legacy files.
  case legacy, none, single, gallery, album
}
struct AlbumCacheReference: Codable, Equatable, Sendable {
  var assetID: String
  var revision: String
  var fileID: String
  var valid: Bool {
    DisplayAlbum.validIdentifier(assetID) && revision.count <= 128
      && UUID(uuidString: fileID) != nil
  }
}
struct AlbumDisplayGrant: Codable, Equatable, Sendable {
  var album: DisplayAlbum
  var approvedForDisplay: Bool
  var cache: [AlbumCacheReference] = []
  var valid: Bool {
    approvedForDisplay && album.valid && cache.count <= 10 && cache.allSatisfy(\.valid)
      && Set(cache.map(\.assetID)).count == cache.count
      && Set(cache.map(\.fileID)).count == cache.count
  }
}
struct AlbumPhoto: Equatable, Sendable {
  var id: String
  var revision: String
  var bytes: Data
  var valid: Bool {
    DisplayAlbum.validIdentifier(id) && revision.count <= 128
      && !bytes.isEmpty && bytes.count <= 5_000_000
  }
}
struct AlbumBatch: Sendable {
  // Complete ordered window, at most ten images, not a complete library listing.
  var orderedIDs: [String]
  var photos: [AlbumPhoto]
}
enum AlbumAccessError: Error, Equatable { case permissionDenied, noLongerAccessible, unavailable, invalidBatch }

@MainActor
protocol AlbumPhotoProvider: AnyObject {
  func authorizationGranted() -> Bool
  func requestPermission() async throws
  func catalogue() async throws -> [DisplayAlbum]
  func readAlbum(_ id: String, known: [AlbumPhoto]) async throws -> AlbumBatch
  func cancelReads()
  func observeChanges(_ handler: (@MainActor () -> Void)?)
}

/// Private catalogue: OS permission alone never authorizes an enumeration.
@MainActor @Observable
final class AlbumCatalogueSession {
  private let provider: any AlbumPhotoProvider
  private var generation = 0
  private(set) var albums: [DisplayAlbum] = []
  private(set) var busy = false
  private(set) var status = ""
  init(provider: any AlbumPhotoProvider) { self.provider = provider }
  func invalidate(locked: Bool = true) {
    generation += 1
    albums = []
    busy = false
    status = locked ? "Unlock to choose an album." : ""
  }
  func load(isCurrent: @escaping @MainActor () -> Bool) async {
    guard !busy else { return }
    guard isCurrent() else { status = "Unlock to choose an album."; return }
    generation += 1
    let ticket = generation
    busy = true
    defer { if generation == ticket { busy = false } }
    do {
      try await provider.requestPermission()
      guard ticket == generation, isCurrent(), !Task.isCancelled else { return }
      guard provider.authorizationGranted() else { throw AlbumAccessError.permissionDenied }
      let values = try await provider.catalogue()
      guard ticket == generation, isCurrent(), !Task.isCancelled else { return }
      guard provider.authorizationGranted() else { throw AlbumAccessError.permissionDenied }
      var seen = Set<String>()
      albums = values.filter { $0.valid && seen.insert($0.id).inserted }.prefix(50).map { $0 }
      status = albums.isEmpty ? "No accessible shared albums." : "Choose photos for this display."
    } catch {
      guard ticket == generation, isCurrent(), !Task.isCancelled else { return }
      albums = []
      status = "Albums unavailable. Check Photos access."
    }
  }
}

/// Ongoing, narrowly scoped export chosen explicitly for the shared display.
/// Never requests OS permission, enumerates the catalogue, or fetches in background.
@MainActor @Observable
final class AlbumDisplaySession {
  private let provider: any AlbumPhotoProvider
  private var generation = 0
  private var dirty = false
  private var lastAttempt = -TimeInterval.infinity
  private(set) var active = false
  private(set) var album: DisplayAlbum?
  private(set) var photos: [AlbumPhoto] = []
  private(set) var busy = false
  private(set) var status = ""
  private(set) var lastSuccess: Date?
  var minimumInterval: TimeInterval = 30
  // Synchronous atomic local-store commit. A failed commit retains the old state.
  var apply: (@MainActor (DisplayAlbum?, [AlbumPhoto]) -> Bool)?
  init(provider: any AlbumPhotoProvider) { self.provider = provider }
  func restore(_ grant: AlbumDisplayGrant, photos values: [AlbumPhoto]) {
    guard grant.valid, values.count <= 10, values.allSatisfy(\.valid),
          Set(values.map(\.id)).count == values.count,
          values.reduce(0, { $0 + $1.bytes.count }) <= 30_000_000 else { return }
    let permitted = Dictionary(uniqueKeysWithValues: grant.cache.map { ($0.assetID, $0.revision) })
    guard values.allSatisfy({ permitted[$0.id] == $0.revision }) else { return }
    guard provider.authorizationGranted() else {
      stop()
      status = "Album disconnected · Photos access is required."
      return
    }
    stop(clearDisplay: false)
    album = grant.album
    photos = values
    dirty = true
    status = values.isEmpty ? "Waiting for album update." : "Imported copies · update pending"
    reconcileObserver()
  }
  @discardableResult
  func select(_ value: DisplayAlbum, deviceAuthenticated: Bool, explicitDisplayConsent: Bool) -> Bool {
    guard value.valid, deviceAuthenticated, explicitDisplayConsent else {
      status = "Unlock and choose an album for this display."
      return false
    }
    guard provider.authorizationGranted() else {
      status = "Photos access is required before choosing an album."
      return false
    }
    guard apply?(value, []) != false else { status = "Could not save the album choice."; return false }
    generation += 1
    provider.cancelReads()
    provider.observeChanges(nil)
    busy = false
    album = value
    photos = []
    dirty = true
    lastAttempt = -.infinity
    lastSuccess = nil
    status = "Waiting for album update."
    reconcileObserver()
    return true
  }
  func stop(clearDisplay: Bool = true) {
    generation += 1
    provider.cancelReads()
    provider.observeChanges(nil)
    busy = false
    album = nil
    photos = []
    dirty = false
    lastSuccess = nil
    lastAttempt = -.infinity
    status = "Album updates stopped."
    if clearDisplay, apply?(nil, []) == false {
      status = "Updates stopped for this session; the saved choice could not be cleared."
    }
  }
  func setActive(_ value: Bool) {
    guard active != value else { return }
    active = value
    generation += 1
    provider.cancelReads()
    provider.observeChanges(nil)
    busy = false
    // Permission status is separate from a library read and is never throttled.
    // Reconcile before an active scene can show a revoked cached export.
    if value, revokeIfDenied() { return }
    if album != nil {
      dirty = true
      status = value ? "Album update pending." : "Updates paused while HomeView is inactive."
    }
    reconcileObserver()
  }
  private func reconcileObserver() {
    guard active, album != nil, provider.authorizationGranted() else { return }
    provider.observeChanges { [weak self] in self?.markChanged() }
  }
  func markChanged() { if album != nil { dirty = true } }
  private func revokeIfDenied() -> Bool {
    guard album != nil, !provider.authorizationGranted() else { return false }
    stop()
    // Keep any local-store cleanup failure visible as well.
    status = "Photos access was revoked. " + status
    return true
  }
  func shouldRefresh(at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Bool {
    guard active, !revokeIfDenied() else { return false }
    return uptime.isFinite && album != nil && dirty && !busy && uptime-lastAttempt >= minimumInterval
  }
  func refresh(force: Bool = false, at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) async {
    guard uptime.isFinite, active, let selected = album, !busy, !Task.isCancelled,
          force || shouldRefresh(at: uptime) else { return }
    let ticket = generation
    busy = true
    dirty = false
    lastAttempt = uptime
    status = "Updating album…"
    defer { if generation == ticket { busy = false } }
    do {
      guard provider.authorizationGranted() else { throw AlbumAccessError.permissionDenied }
      let batch = try await provider.readAlbum(selected.id, known: photos)
      guard ticket == generation else { return }
      // A suspended provider may return cached bytes or an unrelated failure
      // after access changed. Never admit them using the pre-read permission.
      guard !revokeIfDenied(), !Task.isCancelled else { return }
      guard batch.orderedIDs.count <= 10,
            batch.orderedIDs.allSatisfy(DisplayAlbum.validIdentifier),
            Set(batch.orderedIDs).count == batch.orderedIDs.count,
            batch.photos.count <= 10, batch.photos.allSatisfy(\.valid),
            Set(batch.photos.map(\.id)).count == batch.photos.count,
            Set(batch.photos.map(\.id)).isSubset(of: Set(batch.orderedIDs)) else {
        throw AlbumAccessError.invalidBatch
      }
      let old = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0) })
      let fetched = Dictionary(uniqueKeysWithValues: batch.photos.map { ($0.id, $0) })
      let merged = batch.orderedIDs.compactMap { fetched[$0] ?? old[$0] }
      guard merged.reduce(0, { $0 + $1.bytes.count }) <= 30_000_000 else { throw AlbumAccessError.invalidBatch }
      guard apply?(selected, merged) != false else {
        status = "Could not save updated photos. Previous copies are unchanged."
        return
      }
      photos = merged
      lastSuccess = Date()
      let partial = batch.orderedIDs.contains { fetched[$0] == nil }
      status = batch.orderedIDs.isEmpty ? "The selected album has no photos."
        : partial ? "Imported copies · some photos unavailable"
        : "Updated \(photos.count) album photos."
    } catch {
      guard ticket == generation else { return }
      guard !revokeIfDenied(), !Task.isCancelled else { return }
      if let reason = error as? AlbumAccessError,
         reason == .permissionDenied || reason == .noLongerAccessible {
        stop()
        status = reason == .permissionDenied ? "Album disconnected · Photos access was revoked."
          : "Album disconnected · the source is no longer accessible."
      } else {
        status = "Imported copies · update unavailable. Try Update now."
      }
    }
  }
}
