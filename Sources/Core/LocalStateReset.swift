import Foundation
#if canImport(Darwin)
import Darwin

enum LocalResetError:Error { case invalidScope,unavailable,preparationFailed,storagePathChanged,cleanupPending }
struct LocalResetOutcome {
  let snapshot:Snapshot
  let oldFilesRemoved:Bool
  let storagePathOwned:Bool
}
/// Own app storage only. No source-library, OS permission or system-alarm changes.
/// Atomic directory exchange commits the new state; cleanup failure is explicit.
enum LocalStateReset {
  private static let marker="reset-cleanup.json"
  private struct Journal:Codable { let stage:String;let device:UInt64;let inode:UInt64 }
  private final class FD {
    let raw:Int32
    init(_ raw:Int32)throws { guard raw>=0 else { throw LocalResetError.unavailable };self.raw=raw }
    deinit { Darwin.close(raw) }
  }
  private static func info(_ fd:Int32)throws->stat {
    var value=stat();guard fstat(fd,&value)==0 else { throw LocalResetError.unavailable };return value
  }
  private static func same(_ fd:Int32,_ parent:Int32,_ name:String)->Bool {
    guard let captured=try? info(fd) else { return false };var current=stat()
    return fstatat(parent,name,&current,AT_SYMLINK_NOFOLLOW)==0 && current.st_dev==captured.st_dev && current.st_ino==captured.st_ino
  }
  private static func pathNames(_ descriptor:Int32,_ url:URL)->Bool {
    guard let current=try? FD(open(url.path,O_RDONLY|O_DIRECTORY|O_NOFOLLOW)),
      let actual=try? info(current.raw),let expected=try? info(descriptor) else { return false }
    return actual.st_dev==expected.st_dev && actual.st_ino==expected.st_ino
  }
  private static func scope(_ directory:URL)throws->(FD,String) {
    let leaf=directory.lastPathComponent
    guard directory.isFileURL,directory.standardizedFileURL.path==directory.path,
      leaf=="HomeViewReplica" || (leaf.hasPrefix("test-") && UUID(uuidString:String(leaf.dropFirst(5))) != nil)
    else { throw LocalResetError.invalidScope }
    let parent=try FD(open(directory.deletingLastPathComponent().path,O_RDONLY|O_DIRECTORY|O_NOFOLLOW))
    return (parent,leaf)
  }
  private static func directory(_ parent:Int32,_ name:String)throws->FD {
    try FD(openat(parent,name,O_RDONLY|O_DIRECTORY|O_NOFOLLOW))
  }
  private static func write(_ bytes:Data,_ name:String,_ root:Int32)throws {
    let file=try FD(openat(root,name,O_WRONLY|O_CREAT|O_EXCL|O_NOFOLLOW,mode_t(0o600)))
    try bytes.withUnsafeBytes { raw in
      guard let base=raw.baseAddress else { throw LocalResetError.preparationFailed }
      var offset=0
      while offset<raw.count {
        let size=Darwin.write(file.raw,base.advanced(by:offset),raw.count-offset)
        if size<0 && errno==EINTR { continue }
        guard size>0 else { throw LocalResetError.preparationFailed };offset+=size
      }
    }
    guard fsync(file.raw)==0 else { throw LocalResetError.preparationFailed }
  }
  /// Never follows a child symlink; every recursion stays on a retained descriptor.
  private static func empty(_ root:Int32,_ remaining:inout Int,_ depth:Int=0)->Bool {
    guard depth<=16,remaining>0 else { return false }
    let duplicate=dup(root);guard duplicate>=0 else { return false }
    guard let stream=fdopendir(duplicate) else { Darwin.close(duplicate);return false }
    defer { closedir(stream) }
    while true {
      errno=0;guard let entry=readdir(stream) else { return errno==0 }
      let name=withUnsafePointer(to:&entry.pointee.d_name) {
        String(cString:UnsafeRawPointer($0).assumingMemoryBound(to:CChar.self))
      }
      if name=="." || name==".." { continue }
      remaining-=1;guard remaining>=0 else { return false }
      var value=stat();guard fstatat(root,name,&value,AT_SYMLINK_NOFOLLOW)==0 else { return false }
      let kind=value.st_mode & S_IFMT
      if kind==S_IFDIR {
        guard let child=try? directory(root,name),let captured=try? info(child.raw),
          captured.st_dev==value.st_dev,captured.st_ino==value.st_ino,same(child.raw,root,name),
          empty(child.raw,&remaining,depth+1),same(child.raw,root,name),
          unlinkat(root,name,AT_REMOVEDIR)==0 else { return false }
      } else if kind==S_IFREG || kind==S_IFLNK {
        guard unlinkat(root,name,0)==0 else { return false }
      } else { return false } // FIFOs/devices/sockets are not opened or silently ignored.
    }
  }
  private static func clean(_ old:FD,_ parent:Int32,_ stage:String)->Bool {
    // A replaced public name is never used to select what gets recursively removed.
    guard same(old.raw,parent,stage) else { return false }
    var nodes=4096
    guard empty(old.raw,&nodes),same(old.raw,parent,stage) else { return false }
    return unlinkat(parent,stage,AT_REMOVEDIR)==0
  }
  static func reset(directory url:URL)throws->LocalResetOutcome {
    let (parent,leaf)=try scope(url),old=try directory(parent.raw,leaf)
    let captured=try info(old.raw)
    guard pathNames(old.raw,url) else { throw LocalResetError.storagePathChanged }
    var pending=stat()
    if fstatat(old.raw,marker,&pending,AT_SYMLINK_NOFOLLOW)==0 { throw LocalResetError.cleanupPending }
    guard errno==ENOENT else { throw LocalResetError.unavailable }
    var fresh=Snapshot();fresh.photoSelection = .none;fresh.connectionConsent=[]
    let bytes=try JSONEncoder().encode(fresh)
    guard bytes.count<=32_000_000 else { throw LocalResetError.preparationFailed }
    let stage=".homeview-reset-"+UUID().uuidString
    guard mkdirat(parent.raw,stage,mode_t(0o700))==0 else { throw LocalResetError.preparationFailed }
    let prepared=try directory(parent.raw,stage)
    var committed=false
    defer { if !committed { _ = clean(prepared,parent.raw,stage) } }
    try write(bytes,"mock-state.json",prepared.raw)
    let journal=Journal(stage:stage,device:UInt64(truncatingIfNeeded:captured.st_dev),inode:UInt64(captured.st_ino))
    try write(try JSONEncoder().encode(journal),marker,prepared.raw)
    guard pathNames(old.raw,url) else { throw LocalResetError.storagePathChanged }
    guard same(old.raw,parent.raw,leaf),same(prepared.raw,parent.raw,stage),
      renameatx_np(parent.raw,leaf,parent.raw,stage,UInt32(RENAME_SWAP))==0
    else { throw LocalResetError.preparationFailed }
    committed=true
    // On a namespace race preserve unknown/replacement data and keep the journal.
    let removed=clean(old,parent.raw,stage)
    let complete=removed && unlinkat(prepared.raw,marker,0)==0
    return LocalResetOutcome(snapshot:fresh,oldFilesRemoved:complete,storagePathOwned:pathNames(prepared.raw,url))
  }
  /// Retry only the exact journaled retired directory, never a lookalike name.
  static func retryCleanup(directory url:URL)->Bool {
    do {
      let (parent,leaf)=try scope(url),current=try directory(parent.raw,leaf)
      let file=try FD(openat(current.raw,marker,O_RDONLY|O_NOFOLLOW|O_NONBLOCK))
      let size=try info(file.raw)
      guard size.st_mode & S_IFMT==S_IFREG,size.st_size>0,size.st_size<=2048 else { return false }
      var buffer=[UInt8](repeating:0,count:2049)
      let count=buffer.withUnsafeMutableBytes { Darwin.read(file.raw,$0.baseAddress,2049) }
      guard count==Int(size.st_size),count<=2048 else { return false }
      let journal=try JSONDecoder().decode(Journal.self,from:Data(buffer.prefix(count)))
      guard journal.stage.hasPrefix(".homeview-reset-"),
        UUID(uuidString:String(journal.stage.dropFirst(".homeview-reset-".count))) != nil,
        let old=try? directory(parent.raw,journal.stage),let captured=try? info(old.raw),
        UInt64(truncatingIfNeeded:captured.st_dev)==journal.device,UInt64(captured.st_ino)==journal.inode,
        clean(old,parent.raw,journal.stage) else { return false }
      return unlinkat(current.raw,marker,0)==0
    } catch { return false }
  }
}
#endif
