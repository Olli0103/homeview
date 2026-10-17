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
        PhotoLayoutControls()
        Button("Remove Selected Photo") { model.setPhoto(nil) }.font(.system(size: 21))
      }
    }
  }
}

struct PhotoLayoutControls: View {
  @Environment(AppModel.self) private var model
  private func change(_ edit: (inout PhotoAdjustment) -> Void) {
    var value = model.photoAdjustment
    edit(&value)
    model.adjustPhoto(value)
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Clock position").font(.system(size: 21, weight: .semibold))
      HStack {
        ForEach(PhotoClockPosition.allCases) { position in
          Button(position == .automatic ? "Auto" : position.rawValue.capitalized) {
            change { $0.clock = position }
          }.padding(10)
            .background(model.photoAdjustment.clock == position ? Color.blue.opacity(0.18) : .gray.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 10))
            .accessibilityIdentifier("photos.clock.\(position.rawValue)")
            .accessibilityValue(model.photoAdjustment.clock == position ? "Selected" : "Not selected")
        }
      }
      Toggle("Automatic framing", isOn: Binding(get: { model.photoAdjustment.automaticCrop },
                                                set: { value in change { $0.automaticCrop = value } }))
        .accessibilityIdentifier("photos.crop.auto")
      if !model.photoAdjustment.automaticCrop {
        Text("Adjust the crop for this photo. Automatic framing preserves detected subjects.")
          .font(.system(size: 16)).foregroundStyle(.gray)
        #if !os(tvOS)
          Slider(value: Binding(get: { model.photoAdjustment.horizontal },
                                set: { value in change { $0.horizontal = value } }), in: 0...1) {
            Text("Horizontal crop")
          }.accessibilityIdentifier("photos.crop.horizontal")
          Slider(value: Binding(get: { model.photoAdjustment.vertical },
                                set: { value in change { $0.vertical = value } }), in: 0...1) {
            Text("Vertical crop")
          }.accessibilityIdentifier("photos.crop.vertical")
        #endif
      }
      Button("Reset photo layout") { model.adjustPhoto(.init()) }
        .accessibilityIdentifier("photos.layout.reset")
    }.font(.system(size: 18))
  }
}

#if canImport(Vision) && (os(iOS) || os(macOS) || os(visionOS))
  import Vision
  import CoreImage
  import CoreImage.CIFilterBuiltins

  enum NativeSubjectExtractor {
    /// Runs only for an explicitly selected image, never for camera surveillance.
    static func analyze(_ bytes: Data) throws -> PhotoAnalysis? {
      guard let original = CIImage(data: bytes, options: [.applyOrientationProperty: true]) else {
        return nil
      }
      let context = CIContext(options: [.cacheIntermediates: false])
      guard let cg = context.createCGImage(original, from: original.extent) else { return nil }
      let fallback = PhotoAnalysis(aspect: original.extent.width / original.extent.height,
                                   mask: nil, foreground: nil)
      let handler = VNImageRequestHandler(cgImage: cg, options: [:])
      let request = VNGenerateForegroundInstanceMaskRequest()
      do { try handler.perform([request]) } catch { return fallback }
      guard let result = request.results?.first, !result.allInstances.isEmpty else { return fallback }
      let pixelBuffer = try result.generateScaledMaskForImage(
        forInstances: result.allInstances, from: handler)
      let filter = CIFilter.blendWithMask()
      filter.inputImage = original
      filter.backgroundImage = CIImage(color: .clear).cropped(to: original.extent)
      let maskImage = CIImage(cvPixelBuffer: pixelBuffer)
      filter.maskImage = maskImage
      guard let output = filter.outputImage else { return fallback }
      let foreground = context.pngRepresentation(
        of: output, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
      return PhotoAnalysis(aspect: fallback.aspect,
                           mask: PhotoMaskRasterizer.make(maskImage, context: context),
                           foreground: foreground)
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
