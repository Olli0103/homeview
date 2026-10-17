import ImageIO
import SwiftUI
import UniformTypeIdentifiers

#if os(macOS)
  import AppKit
#elseif canImport(UIKit)
  import UIKit
#endif
#if canImport(PhotosUI) && !os(tvOS) && !os(watchOS)
  import PhotosUI
#endif

struct ImportedPhoto: View {
  let data: Data
  var body: some View {
    #if os(macOS)
      if let image = NSImage(data: data) { Image(nsImage: image).resizable().scaledToFill() }
    #elseif canImport(UIKit)
      if let image = UIImage(data: data) { Image(uiImage: image).resizable().scaledToFill() }
    #endif
  }
}
struct NativePhotoControls: View {
  @Environment(AppModel.self) private var model
  #if canImport(PhotosUI) && !os(tvOS) && !os(watchOS)
    @State private var selection: [PhotosPickerItem] = []
    @State private var loadTask: Task<Void, Never>?
  #endif
  var body: some View {
    VStack(alignment: .leading, spacing: 15) {
      Text("Photos face").font(.system(size: 24, weight: .semibold))
      Text(
        "The system photo picker shares only the image you choose. Mock tests never open your photo library."
      ).font(.system(size: 17)).foregroundStyle(.gray)
      #if canImport(PhotosUI) && !os(tvOS) && !os(watchOS)
        PhotosPicker(selection: $selection, maxSelectionCount: 10, matching: .images) {
          Label("Choose Photos", systemImage: "photo.on.rectangle")
        }.font(.system(size: 21))
          .onChange(of: selection) { _, items in
            loadTask?.cancel()
            loadTask = Task {
              do {
                var images: [Data] = []
                for item in items {
                  try Task.checkCancellation()
                  guard let bytes = try await item.loadTransferable(type: Data.self),
                    bytes.count <= 40_000_000
                  else {
                    model.error = "Could not load a photo smaller than 40 MB."
                    return
                  }
                  let resized = try await Task.detached(priority: .utility) {
                    try PhotoThumbnail.make(bytes)
                  }.value
                  images.append(resized)
                }
                try Task.checkCancellation()
                if !images.isEmpty { model.setGallery(images) }
              } catch is CancellationError {} catch {
                model.error = "Could not load the selected photos."
              }
            }
          }.onDisappear { loadTask?.cancel() }
      #endif
      SharedAlbumControls()
      Button("Use Demo Photo") {
        #if os(macOS)
          if let image = NSImage(named: "Soup"), let bytes = image.tiffRepresentation {
            model.setPhoto(bytes)
          }
        #elseif canImport(UIKit)
          if let bytes = UIImage(named: "Soup")?.pngData() { model.setPhoto(bytes) }
        #endif
      }.font(.system(size: 21)).accessibilityIdentifier("photos.demo")
      Button("Use Demo Gallery") {
        #if os(macOS)
          let images = ["Soup", "AlbumArt"].compactMap { name -> Data? in
            guard let bytes = NSImage(named: name)?.tiffRepresentation else { return nil }
            return try? PhotoThumbnail.make(bytes)
          }
        #elseif canImport(UIKit)
          let images = ["Soup", "AlbumArt"].compactMap { name -> Data? in
            UIImage(named: name)?.jpegData(compressionQuality: 0.8)
          }
        #else
          let images: [Data] = []
        #endif
        model.setGallery(images)
      }.font(.system(size: 21)).accessibilityIdentifier("photos.gallery")
      if model.photoCount > 1 {
        Toggle(
          "Rotate every 30 seconds",
          isOn: Binding(
            get: { model.data.rotatePhotos },
            set: {
              model.data.rotatePhotos = $0
              model.persist()
            }))
      }
      if model.photoData != nil {
        Button("Remove Selected Photo") { model.setPhoto(nil) }.font(.system(size: 21))
      }
    }
  }
}

#if canImport(Vision) && (os(iOS) || os(macOS) || os(visionOS))
  import Vision
  import CoreImage
  import CoreImage.CIFilterBuiltins

  enum NativeSubjectExtractor {
    /// Runs only for an explicitly selected image, never for camera surveillance.
    static func foreground(_ bytes: Data) throws -> Data? {
      guard let original = CIImage(data: bytes, options: [.applyOrientationProperty: true]) else {
        return nil
      }
      let context = CIContext(options: [.cacheIntermediates: false])
      guard let cg = context.createCGImage(original, from: original.extent) else { return nil }
      let handler = VNImageRequestHandler(cgImage: cg, options: [:])
      let request = VNGenerateForegroundInstanceMaskRequest()
      try handler.perform([request])
      guard let result = request.results?.first, !result.allInstances.isEmpty else { return nil }
      let pixelBuffer = try result.generateScaledMaskForImage(
        forInstances: result.allInstances, from: handler)
      let filter = CIFilter.blendWithMask()
      filter.inputImage = original
      filter.backgroundImage = CIImage(color: .clear).cropped(to: original.extent)
      filter.maskImage = CIImage(cvPixelBuffer: pixelBuffer)
      guard let output = filter.outputImage else { return nil }
      return context.pngRepresentation(
        of: output, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
    }
  }
#endif

/// Decode only explicitly selected input; cap image memory before rendering.
enum PhotoThumbnail {
  static func make(_ bytes: Data) throws -> Data {
    guard let source = CGImageSourceCreateWithData(bytes as CFData, nil),
      let image = CGImageSourceCreateThumbnailAtIndex(
        source, 0,
        [
          kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: 1600,
        ] as CFDictionary)
    else { throw CocoaError(.fileReadCorruptFile) }
    let output = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        output, UTType.jpeg.identifier as CFString, 1, nil)
    else {
      throw CocoaError(.fileWriteUnknown)
    }
    CGImageDestinationAddImage(
      destination, image, [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
    return output as Data
  }
}
