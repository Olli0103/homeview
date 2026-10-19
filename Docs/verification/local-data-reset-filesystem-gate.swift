import Foundation
@main struct FilesystemGate {
 static func main() throws {
  let root=URL(fileURLWithPath:CommandLine.arguments[1],isDirectory:true)
  let raw=try Data(contentsOf:root.appendingPathComponent("mock-state.json"))
  var result:[String:Any]=[:]
  do {
   let outcome=try LocalStateReset.reset(directory:root)
   let current=(try? Data(contentsOf:root.appendingPathComponent("mock-state.json"))).flatMap {try? Snapshot.decodeMigrating($0)}
   result=["committed":true,"oldFilesRemoved":outcome.oldFilesRemoved,"storagePathOwned":outcome.storagePathOwned,
    "currentPathHasDefault":current?.connectionConsent == [],"originalBytesStillAtInputPath":(try? Data(contentsOf:root.appendingPathComponent("mock-state.json")))==raw]
  } catch {
   result=["committed":false,"originalBytesStillAtInputPath":(try? Data(contentsOf:root.appendingPathComponent("mock-state.json")))==raw]
  }
  print(String(decoding:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),as:UTF8.self))
 }
}
