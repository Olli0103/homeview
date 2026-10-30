import AVFoundation
import CoreGraphics
import CoreVideo
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Original procedural demo art: no photographs, textures, fonts or audio.
/// Output is a four-second, 512-square, 12fps H.264 loop and its first frame.
@main struct GenerateDemoArtwork {
  static func main() async throws {
    guard CommandLine.arguments.count == 3 else { throw Failure.invalidArguments }
    let movie=URL(fileURLWithPath:CommandLine.arguments[1])
    let poster=URL(fileURLWithPath:CommandLine.arguments[2])
    guard !FileManager.default.fileExists(atPath:movie.path),
          !FileManager.default.fileExists(atPath:poster.path) else { throw Failure.alreadyExists }
    let edge=512,rate:Int32=12,count=48
    let writer=try AVAssetWriter(outputURL:movie,fileType:.mp4)
    let input=AVAssetWriterInput(mediaType:.video,outputSettings:[
      AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:edge,AVVideoHeightKey:edge,
      AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:600_000,
        AVVideoExpectedSourceFrameRateKey:rate,AVVideoMaxKeyFrameIntervalKey:rate,
        AVVideoProfileLevelKey:AVVideoProfileLevelH264MainAutoLevel]])
    let attributes:[String:Any]=[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA,
      kCVPixelBufferWidthKey as String:edge,kCVPixelBufferHeightKey as String:edge,
      kCVPixelBufferCGImageCompatibilityKey as String:true,kCVPixelBufferCGBitmapContextCompatibilityKey as String:true]
    let adaptor=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:attributes)
    guard writer.canAdd(input) else { throw Failure.encoder }
    writer.add(input);guard writer.startWriting() else { throw Failure.encoder }
    writer.startSession(atSourceTime:.zero)
    let deadline=ContinuousClock.now.advanced(by:.seconds(60))
    for index in 0..<count {
      while !input.isReadyForMoreMediaData {
        guard ContinuousClock.now<deadline,writer.status == .writing else { throw Failure.encoder }
        try await Task.sleep(for:.milliseconds(2))
      }
      var output:CVPixelBuffer?
      guard CVPixelBufferCreate(kCFAllocatorDefault,edge,edge,kCVPixelFormatType_32BGRA,
        attributes as CFDictionary,&output)==kCVReturnSuccess,let pixel=output else { throw Failure.buffer }
      CVPixelBufferLockBaseAddress(pixel,[])
      guard let context=CGContext(data:CVPixelBufferGetBaseAddress(pixel),width:edge,height:edge,
        bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(pixel),
        space:CGColorSpace(name:CGColorSpace.sRGB)!,
        bitmapInfo:CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue)
        else { throw Failure.buffer }
      draw(context,edge:Double(edge),phase:Double(index)/Double(count)*2*Double.pi)
      if index==0 {
        guard let image=context.makeImage(),let destination=CGImageDestinationCreateWithURL(
          poster as CFURL,UTType.png.identifier as CFString,1,nil) else { throw Failure.buffer }
        CGImageDestinationAddImage(destination,image,nil)
        guard CGImageDestinationFinalize(destination) else { throw Failure.buffer }
      }
      CVPixelBufferUnlockBaseAddress(pixel,[])
      guard adaptor.append(pixel,withPresentationTime:CMTime(value:Int64(index),timescale:rate)) else {
        throw Failure.encoder
      }
    }
    writer.endSession(atSourceTime:CMTime(value:Int64(count),timescale:rate));input.markAsFinished()
    await writer.finishWriting();guard writer.status == .completed else { throw Failure.encoder }
    print("Generated own video: 48 frames, 12fps, 512x512, 4s, no audio/fonts/reference pixels")
  }
  static func draw(_ context:CGContext,edge:Double,phase:Double) {
    context.translateBy(x:0,y:edge);context.scaleBy(x:1,y:-1)
    let colors=[CGColor(red:1,green:0.58,blue:0,alpha:1),CGColor(red:1,green:0.18,blue:0.42,alpha:1),
      CGColor(red:0.22,green:0.16,blue:0.55,alpha:1)] as CFArray
    let gradient=CGGradient(colorsSpace:CGColorSpace(name:CGColorSpace.sRGB),colors:colors,locations:[0,0.5,1])!
    context.drawLinearGradient(gradient,start:.zero,end:CGPoint(x:edge,y:edge),options:[.drawsBeforeStartLocation,.drawsAfterEndLocation])
    let x=edge*(0.70+0.05*sin(phase)),y=edge*(0.26+0.03*(cos(phase)-1)),radius=edge*0.325
    context.setFillColor(CGColor(gray:1,alpha:0.25));context.fillEllipse(in:CGRect(x:x-radius,y:y-radius,width:radius*2,height:radius*2))
    context.move(to:CGPoint(x:-edge*0.1,y:edge*0.7))
    context.addCurve(to:CGPoint(x:edge*1.1,y:edge*0.48),
      control1:CGPoint(x:edge*0.3,y:edge*(0.18+0.045*sin(phase))),
      control2:CGPoint(x:edge*0.65,y:edge*(1.1+0.02*sin(phase))))
    context.setStrokeColor(CGColor(gray:1,alpha:0.65));context.setLineWidth(edge*0.045)
    context.setLineCap(.round);context.strokePath()
  }
  enum Failure:Error { case invalidArguments,alreadyExists,encoder,buffer }
}
