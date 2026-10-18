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

/// Project-generated fixtures only; selecting these never opens the photo library.
enum DemoPhotoAssets {
  static let portrait = "DemoPhotoPortraitV1"
  static let landscape = "DemoPhotoLandscapeV1"
  static let gallery = [portrait, landscape]
}

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

/// Only explicitly exported photos are shared with this display.
struct SelectedPhotoPreview: View {
  @Environment(AppModel.self) private var model
  var body: some View {
    GeometryReader { geometry in
      if let bytes=model.photoData {
        ImportedPhoto(data:bytes).frame(width:geometry.size.width,height:geometry.size.height).clipped()
      } else if model.hasPhotoSelection {
        ZStack {
          Color.black
          Image(systemName:"photo.on.rectangle").font(.system(size:38)).foregroundStyle(.gray)
        }
      } else {
        LandscapeArt()
      }
    }
  }
}

/// Public runtime font coverage, refracting the same explicitly selected photo.
/// No saved font outlines and no foreground/Depth approximation.
struct PhotoGlassClock: View {
  let time: String
  let spokenTime: String
  let bytes: Data?
  let composition: PhotoComposition
  @State private var texture: Image?
  @State private var renderedBytes: Data?
  private var testMode: String {
    let args = ProcessInfo.processInfo.arguments
    guard args.contains("--uitesting"), let i = args.firstIndex(of: "--photo-clock-test-mode"),
          args.indices.contains(i + 1) else { return "glass" }
    return args[i + 1]
  }
  private var glyphs: some View {
    Text(time).font(.system(size: 181, weight: .regular, design: .rounded))
      .tracking(-10).lineLimit(1).minimumScaleFactor(0.65)
      // Taller public runtime glyphs, still inside the existing protected clock
      // band. Full-height Original typography needs its separate matte contract.
      .scaleEffect(x: 1, y: 1.4)
      .frame(width: 540, height: 200).foregroundStyle(.white)
  }
  var body: some View {
    Group {
      if testMode == "background" {
        glyphs.opacity(0)
      } else if testMode == "stencil" {
        glyphs
      } else if let texture, renderedBytes == bytes {
        glyphs.blur(radius: 1).visualEffect { content, geometry in
          let bounds = geometry.frame(in: .named("photo-face"))
          return content.layerEffect(ShaderLibrary.photoGlassGlyph(
            .image(texture), .float2(Float(bounds.minX), Float(bounds.minY)),
            .float2(Float(composition.crop.x), Float(composition.crop.y)),
            .float2(Float(composition.crop.width), Float(composition.crop.height)),
            .float2(Float(composition.destination.x), Float(composition.destination.y)),
            .float2(Float(composition.destination.width), Float(composition.destination.height))),
            maxSampleOffset: CGSize(width: 12, height: 12))
        }
      } else {
        glyphs.opacity(0.8)
      }
    }
    .accessibilityIdentifier("photo.clock")
    .accessibilityLabel(spokenTime)
    .accessibilityValue(composition.clock.rawValue)
    .task(id: bytes) {
      if let bytes {
        #if os(macOS)
          texture = NSImage(data: bytes).map { Image(nsImage: $0) }
        #elseif canImport(UIKit)
          texture = UIImage(data: bytes).map { Image(uiImage: $0) }
        #endif
      } else {
        texture = Image(DemoPhotoAssets.landscape)
      }
      // Never show the previous selection inside the next photo's clock while
      // its image texture is being prepared.
      renderedBytes = bytes
    }
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
          if let image = NSImage(named: DemoPhotoAssets.portrait), let bytes = image.tiffRepresentation {
            model.setPhoto(bytes)
          }
        #elseif canImport(UIKit)
          if let bytes = UIImage(named: DemoPhotoAssets.portrait)?.pngData() { model.setPhoto(bytes) }
        #endif
      }.font(.system(size: 21)).accessibilityIdentifier("photos.demo")
      Button("Use Demo Gallery") {
        #if os(macOS)
          let images = DemoPhotoAssets.gallery.compactMap { name -> Data? in
            guard let bytes = NSImage(named: name)?.tiffRepresentation else { return nil }
            return try? PhotoThumbnail.make(bytes)
          }
        #elseif canImport(UIKit)
          let images = DemoPhotoAssets.gallery.compactMap { name -> Data? in
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
        if model.photoAnalysisFinished && model.photoForegroundData == nil {
          Text("Depth effect is unavailable for this photo. You can adjust the clock position below.")
            .font(.system(size:16)).foregroundStyle(.secondary)
        }
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
      guard let cg = context.createCGImage(original, from: original.extent) else {
        return PhotoAnalysis(aspect:original.extent.width/original.extent.height,
                             mask:nil,foreground:nil,diagnostic:"cg_unavailable")
      }
      // Local rectangles protect a head when no usable foreground matte exists.
      // They are never treated as alpha pixels or used for identity recognition.
      let faceRequest = VNDetectFaceRectanglesRequest()
      func protect(_ face:PhotoRect) -> PhotoRect {
        PhotoRect(x:face.x-face.width*0.15,y:face.y-face.height*0.45,
                  width:face.width*1.3,height:face.height*1.55).intersection(.full)
      }
      var faces: [PhotoRect]
      var faceStatus: String
      var headDetectionCompleted = false
      do {
        try VNImageRequestHandler(cgImage: cg, options: [:]).perform([faceRequest])
        let results = faceRequest.results ?? []
        headDetectionCompleted = true
        faces = results.filter { $0.confidence >= 0.5 }.map {
          let b = $0.boundingBox
          return protect(PhotoRect(x:b.minX,y:1-b.maxY,width:b.width,height:b.height))
        }.filter { $0.valid }
        faceStatus = "face_results_\(results.count)_accepted_\(faces.count)"
      } catch {
        faces = []
        faceStatus = "face_request_error_\((error as NSError).code)"
      }
      if faces.isEmpty {
        // Independent public CPU detector when Vision cannot provide head bounds.
        let cpuContext = CIContext(options:[.useSoftwareRenderer:true,.cacheIntermediates:false])
        if let detector = CIDetector(ofType:CIDetectorTypeFace,context:cpuContext,
                                     options:[CIDetectorAccuracy:CIDetectorAccuracyHigh]) {
          let extent=original.extent
          faces = detector.features(in:original,options:[CIDetectorImageOrientation:1])
            .compactMap { $0 as? CIFaceFeature }.map {
              let b=$0.bounds
              return protect(PhotoRect(x:(b.minX-extent.minX)/extent.width,
                y:1-(b.maxY-extent.minY)/extent.height,width:b.width/extent.width,height:b.height/extent.height))
            }.filter { $0.valid }
          headDetectionCompleted = true
          faceStatus += "_ci_faces_\(faces.count)"
        } else { faceStatus += "_ci_unavailable" }
      }
      func fallback(_ stage:String,conservative:Bool=false) -> PhotoAnalysis {
        // A completed detector with zero faces is not a detected full-image
        // subject. Keep the normal framing; reserve the separate clock band
        // for unavailable analysis, not every landscape without a matte.
        let preserveWholeImage = conservative && faces.isEmpty && !headDetectionCompleted
        return PhotoAnalysis(aspect:original.extent.width/original.extent.height,mask:nil,foreground:nil,
          protectedRegions:preserveWholeImage ? [.full]:faces,
          diagnostic:faceStatus+"_"+stage+(preserveWholeImage ? "_conservative_full_image":""))
      }
      let handler = VNImageRequestHandler(cgImage: cg, options: [:])
      let request = VNGenerateForegroundInstanceMaskRequest()
      do {
        try handler.perform([request])
        guard let result = request.results?.first, !result.allInstances.isEmpty else { return fallback("no_instances") }
        let pixelBuffer = try result.generateScaledMaskForImage(
          forInstances: result.allInstances, from: handler)
        let filter = CIFilter.blendWithMask()
        filter.inputImage = original
        filter.backgroundImage = CIImage(color: .clear).cropped(to: original.extent)
        let maskImage = CIImage(cvPixelBuffer: pixelBuffer)
        filter.maskImage = maskImage
        guard let output = filter.outputImage,
              let foreground = context.pngRepresentation(
                of: output, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
        else { return fallback("foreground_encoding_unavailable",conservative:true) }
        return PhotoAnalysis(aspect: original.extent.width/original.extent.height,
                             mask: PhotoMaskRasterizer.make(maskImage, context: context),
                             foreground: foreground, protectedRegions: faces,
                             diagnostic:faceStatus+"_foreground_encoded")
      } catch { return fallback("foreground_error_\((error as NSError).code)",conservative:true) }
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
