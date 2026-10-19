import Foundation
#if canImport(Darwin)
import Darwin
#endif

enum LocalStateFileReadError:Error,Equatable { case invalidFile,oversized }

/// Own saved-state reads. Leaf symlinks/special nodes are rejected; callers keep
/// their existing decode/recovery policy. Not an ancestor or concurrent-writer lock.
enum LocalStateFileReader {
  static let maximumBytes=32_000_000
  static func read(_ url:URL) throws -> Data? {
    guard url.isFileURL else { throw LocalStateFileReadError.invalidFile }
    #if canImport(Darwin)
      let descriptor=Darwin.open(url.path,O_RDONLY|O_NOFOLLOW|O_NONBLOCK|O_CLOEXEC)
      guard descriptor>=0 else {
        if errno==ENOENT { return nil }
        throw LocalStateFileReadError.invalidFile
      }
      let handle=FileHandle(fileDescriptor:descriptor,closeOnDealloc:true)
      defer { try? handle.close() }
      var info=stat()
      guard fstat(descriptor,&info)==0,(info.st_mode & mode_t(S_IFMT))==mode_t(S_IFREG)
        else { throw LocalStateFileReadError.invalidFile }
      guard info.st_size>=0,info.st_size<=Int64(maximumBytes) else { throw LocalStateFileReadError.oversized }
      let bytes=try handle.read(upToCount:maximumBytes+1) ?? Data()
      guard bytes.count<=maximumBytes else { throw LocalStateFileReadError.oversized }
      return bytes
    #else
      throw LocalStateFileReadError.invalidFile
    #endif
  }
}
