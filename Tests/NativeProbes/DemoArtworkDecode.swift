import AVFoundation
import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

@main struct DemoArtworkDecode {
  static func main() async throws {
    guard CommandLine.arguments.count==3 else { throw Failure.arguments }
    let url=URL(fileURLWithPath:CommandLine.arguments[1]),output=URL(fileURLWithPath:CommandLine.arguments[2])
    let data=try Data(contentsOf:url)
    guard url.isFileURL,!data.isEmpty,data.count<=ArtworkMotionPolicy.maximumBundledBytes else {throw Failure.size}
    let asset=AVURLAsset(url:url),duration=try await asset.load(.duration)
    let video=try await asset.loadTracks(withMediaType:.video),audio=try await asset.loadTracks(withMediaType:.audio)
    guard try await asset.load(.isPlayable),video.count==1,audio.isEmpty,
      abs(duration.seconds-4)<0.01 else {throw Failure.metadata}
    let dimensions=try await video[0].load(.naturalSize),fps=try await video[0].load(.nominalFrameRate)
    guard dimensions.width==512,dimensions.height==512,abs(fps-12)<0.01 else {throw Failure.metadata}
    try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
    let generator=AVAssetImageGenerator(asset:asset)
    generator.requestedTimeToleranceBefore = .zero;generator.requestedTimeToleranceAfter = .zero
    var frames:[[String:Any]]=[],hashes=Set<String>()
    for second in 0..<4 {
      let generated=try await generator.image(at:CMTime(value:Int64(second),timescale:1))
      guard abs(generated.actualTime.seconds-Double(second))<0.01 else {throw Failure.timing}
      let image=generated.image
      var pixels=[UInt8](repeating:0,count:image.width*image.height*4)
      pixels.withUnsafeMutableBytes {
        let context=CGContext(data:$0.baseAddress,width:image.width,height:image.height,
          bitsPerComponent:8,bytesPerRow:image.width*4,space:CGColorSpaceCreateDeviceRGB(),
          bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue)!
        context.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height))
      }
      let hash=SHA256.hash(data:Data(pixels)).map {String(format:"%02x",$0)}.joined();hashes.insert(hash)
      let visible=stride(from:0,to:pixels.count,by:4).reduce(0) {
        $0+(max(pixels[$1],max(pixels[$1+1],pixels[$1+2]))>20 ? 1:0)
      }
      guard visible>image.width*image.height/2 else {throw Failure.frame}
      let file=output.appendingPathComponent("frame-\(second).png")
      guard let destination=CGImageDestinationCreateWithURL(file as CFURL,UTType.png.identifier as CFString,1,nil)
        else {throw Failure.frame}
      CGImageDestinationAddImage(destination,image,nil);guard CGImageDestinationFinalize(destination) else {throw Failure.frame}
      frames.append(["requested_seconds":second,"actual_seconds":generated.actualTime.seconds,
        "width":image.width,"height":image.height,"decoded_RGBA_sha256":hash,
        "nonblack_RGB_fraction":Double(visible)/Double(image.width*image.height)])
    }
    guard hashes.count==4 else {throw Failure.frame}
    let result:[String:Any]=["local_file":true,"bytes":data.count,
      "file_sha256":SHA256.hash(data:data).map{String(format:"%02x",$0)}.joined(),
      "duration_seconds":duration.seconds,"fps":fps,"video_tracks":video.count,"audio_tracks":audio.count,
      "frames":frames,"distinct_decoded_frames":hashes.count,"account_or_library_access":false]
    print(String(data:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),encoding:.utf8)!)
  }
  enum Failure:Error {case arguments,size,metadata,timing,frame}
}
