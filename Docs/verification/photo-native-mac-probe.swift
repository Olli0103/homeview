import AppKit
import Foundation
import CryptoKit
import CoreImage
import ImageIO
import Darwin

@main struct OwnNativePhotoProbe {
  static func main() {
    do {
      let output=URL(fileURLWithPath:CommandLine.arguments[2])
      guard !FileManager.default.fileExists(atPath:output.path),
        let image=NSImage(named:NSImage.Name("DemoPhotoPortraitV1")),
        let input=image.tiffRepresentation else { throw NSError(domain:"OwnFixture",code:1) }
      try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
      try input.write(to:output.appendingPathComponent("portrait-input.tiff"),options:.atomic)
      guard let analysis=try NativeSubjectExtractor.analyze(input) else {
        throw NSError(domain:"OwnAnalysis",code:2)
      }
      if let foreground=analysis.foreground {
        try foreground.write(to:output.appendingPathComponent("portrait-foreground.png"),options:.atomic)
      }
      let composition=PhotoPlacement.choose(aspect:analysis.aspect,mask:analysis.mask,
        protectedRegions:analysis.protectedRegions,foregroundAvailable:analysis.foreground != nil)
      func rect(_ r:PhotoRect) -> [Double] {[r.x,r.y,r.width,r.height]}
      var coverages:[String:Double]=[:]
      for position in [PhotoClockPosition.top,.middle,.bottom] {
        coverages[position.rawValue]=analysis.mask?.coverage(position.rect) ?? -1
      }
      coverages["full_band"]=analysis.mask?.coverage(.init(x:0.05,y:0.05,width:0.9,height:0.9)) ?? -1
      let result:[String:Any]=[
        "scope":"Mac commandline adapter on own built demo asset; not launched app/iOS/hardware acceptance",
        "input_preparation":"Own probe bundle NSImage(named: DemoPhotoPortraitV1).tiffRepresentation; copied built own asset catalog, same demo API path, no thumbnail for single selection",
        "input_sha256":SHA256.hash(data:input).map {String(format:"%02x",$0)}.joined(),
        "input_bytes":input.count,"aspect":analysis.aspect,"diagnostic":analysis.diagnostic,
        "protected_regions":analysis.protectedRegions.map(rect),
        "mask_present":analysis.mask != nil,"mask_total":analysis.mask?.total ?? 0,
        "mask_width":analysis.mask?.width ?? 0,"mask_height":analysis.mask?.height ?? 0,
        "foreground_present":analysis.foreground != nil,
        "foreground_bytes":analysis.foreground?.count ?? 0,
        "candidate_band_coverages":coverages,
        "composition":["anchor":composition.clock.rawValue,"clock_rect":rect(composition.clockRect),
          "crop":rect(composition.crop),"destination":rect(composition.destination),
          "coverage":composition.coverage,"depth_enabled":composition.depthEnabled,
          "protected_coverage":composition.protectedCoverage,"retention":composition.retention]
      ]
      let bytes=try JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys])
      try bytes.write(to:output.appendingPathComponent("result.json"),options:.atomic)
      print(String(data:bytes,encoding:.utf8)!)
    } catch {
      let e=error as NSError
      print("OWN_NATIVE_PHOTO_ERROR domain=\(e.domain) code=\(e.code)")
      exit(1)
    }
  }
}
