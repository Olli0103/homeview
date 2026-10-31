import AppKit

/// Synthetic provider selected only by the external native probe runner.
@MainActor final class AlbumImportProbeProvider: AlbumPhotoProvider {
  static let shared = AlbumImportProbeProvider()
  var allowed = true
  var readCalls = 0
  var reads: [Int: CheckedContinuation<AlbumBatch, Error>] = [:]
  func authorizationGranted() -> Bool { allowed }
  func requestPermission() async throws {
    guard allowed else { throw AlbumAccessError.permissionDenied }
  }
  func catalogue() async throws -> [DisplayAlbum] { [Self.album] }
  func readAlbum(_ id: String, known: [AlbumPhoto]) async throws -> AlbumBatch {
    readCalls += 1
    let call = readCalls
    return try await withCheckedThrowingContinuation { reads[call] = $0 }
  }
  func cancelReads() {} // Intentionally permits a late completion.
  func observeChanges(_ handler: (@MainActor () -> Void)?) {}
  static let album = DisplayAlbum(id: "owned", title: "Synthetic album")
}

@main struct AlbumImportBoundaryProbe {
  @MainActor static func main() async throws {
    let args = ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"), let i = args.firstIndex(of: "--persistence-test"),
      args.indices.contains(i + 1), let own = UUID(uuidString: args[i + 1]),
      let c = args.firstIndex(of: "--case"), args.indices.contains(c + 1),
      Bundle.main.url(forResource: "demo-tone", withExtension: "wav") == nil
    else { fatalError("Fresh synthetic test process required") }
    let name = args[c + 1], p = AlbumImportProbeProvider.shared, m = AppModel()
    let store = m.albumProbeStoreURL
    guard store.deletingLastPathComponent().lastPathComponent == "test-" + own.uuidString,
      !FileManager.default.fileExists(atPath: store.path) else { fatalError("Owned UUID required") }
    var checks: [String: Bool] = [:]
    func image(_ value: UInt8) -> Data {
      let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 8, pixelsHigh: 8,
        bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 24, bitsPerPixel: 24)!
      rep.bitmapData!.initialize(repeating: value, count: 192)
      return rep.representation(using: .png, properties: [:])!
    }
    func waitForRead(_ call: Int) async throws {
      let clock = ContinuousClock(), end = clock.now.advanced(by: .seconds(5))
      while p.reads[call] == nil {
        guard clock.now < end else { throw CocoaError(.coderReadCorrupt) }
        await Task.yield()
      }
    }
    func batch(_ bytes: Data) -> AlbumBatch {
      AlbumBatch(orderedIDs: ["owned-image"], photos: [AlbumPhoto(id: "owned-image", revision: "v1", bytes: bytes)])
    }
    checks["synthetic_unlock"] = await m.connections.unlock()
    let original = image(30), imported = image(100), latest = image(200)
    checks["initial_gallery_saved"] = m.setGallery([original], title: "OLD")
    await m.loadAlbumChoices()
    checks["catalogue_loaded"] = m.albumCatalogue.albums == [AlbumImportProbeProvider.album]
    m.error = nil
    if name == "revoked_before_read" {
      p.allowed = false
      await m.importAlbumOnce(AlbumImportProbeProvider.album)
      checks["no_read_after_revocation"] = p.readCalls == 0
      // Drain a noncompliant original implementation without hanging the probe.
    } else {
      let first = Task { await m.importAlbumOnce(AlbumImportProbeProvider.album) }
      try await waitForRead(1)
      switch name {
      case "disconnect", "disconnect_error": m.disconnectDisplayAlbum()
      case "manual_selection": m.setPhoto(latest)
      case "revoked_success", "revoked_error": p.allowed = false
      case "newer_import":
        let second = Task { await m.importAlbumOnce(AlbumImportProbeProvider.album) }
        try await waitForRead(2)
        p.reads.removeValue(forKey: 2)!.resume(returning: batch(latest))
        await second.value
      case "positive": break
      default: fatalError("Unknown case")
      }
      if name.hasSuffix("error") {
        p.reads.removeValue(forKey: 1)!.resume(throwing: AlbumAccessError.unavailable)
      } else { p.reads.removeValue(forKey: 1)!.resume(returning: batch(imported)) }
      await first.value
    }
    switch name {
    case "positive": checks["current_import_saved"] = m.albumProbeGallery == [imported] && m.data.photoSelection == .gallery
    case "disconnect", "disconnect_error":
      checks["disconnection_not_undone"] = m.albumProbeGallery.isEmpty && m.data.photoSelection == .none && m.data.albumDisplay == nil
      checks["stale_error_not_published"] = m.error == nil
    case "manual_selection": checks["new_photo_preserved"] = m.albumProbeGallery == [latest] && m.data.photoSelection == .single
    case "newer_import": checks["newer_import_preserved"] = m.albumProbeGallery == [latest]
    default: checks["previous_copies_preserved"] = m.albumProbeGallery == [original]
    }
    checks["disk_matches_memory"] = try Snapshot.canonicalBytes(Data(contentsOf: store))
      == Snapshot.canonicalBytes(JSONEncoder().encode(m.data))
    let failed = checks.filter { !$0.value }.map(\.key).sorted()
    print(String(decoding: try JSONSerialization.data(withJSONObject: ["case": name, "checks": checks,
      "failed": failed, "verdict": failed.isEmpty ? "PASS" : "FAIL", "real_photo_library": false],
      options: [.sortedKeys]), as: UTF8.self))
  }
}
