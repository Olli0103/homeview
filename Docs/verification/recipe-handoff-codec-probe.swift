import Foundation
@testable import HomeViewCore
@main struct CodecGate {
 static func main() throws {
  let valid=try RecipeContinuity.make(recipe:.soup,step:2)
  let document=valid.document
  let plain="{\"version\":1,\"document\":\""+document+"\",\"step\":2}"
  let vectors:[(String,Data,Bool)]=[
   ("valid",Data(plain.utf8),true),
   ("reordered",Data((" {\"step\":2,\"document\":\""+document+"\",\"version\":1}\n").utf8),true),
   ("nul",Data((plain+"\0").utf8),false),
   ("trailing",Data((plain+"true").utf8),false),
   ("array",Data(("["+plain+"]").utf8),false),
   ("boolean-version",Data(plain.replacingOccurrences(of:"\"version\":1",with:"\"version\":true").utf8),false),
   ("null-step",Data(plain.replacingOccurrences(of:"\"step\":2",with:"\"step\":null").utf8),false),
   ("fractional-step",Data(plain.replacingOccurrences(of:"\"step\":2",with:"\"step\":2.5").utf8),false),
   ("unicode-fingerprint",Data(plain.replacingOccurrences(of:document,with:String(repeating:"ａ",count:64)).utf8),false),
   ("negative-step",Data(plain.replacingOccurrences(of:"\"step\":2",with:"\"step\":-1").utf8),false),
   ("upper-bound-step",Data(plain.replacingOccurrences(of:"\"step\":2",with:"\"step\":100").utf8),false),
   ("truncated",Data(plain.dropLast().utf8),false)]
  var results:[[String:Any]]=[]
  for (name,bytes,expected) in vectors {
   let result=try? RecipeContinuity.decode(bytes,activityType:RecipeContinuity.activityType)
   results.append(["name":name,"bytes":bytes.count,"accepted":result != nil,"passed":(result != nil)==expected])
  }
  // Duplicate property names normalize through Foundation's typed decoder.
  // No second parser supplies an independent effect-bearing interpretation.
  let duplicate=Data(("{\"version\":1,\"version\":99,\"document\":\""+document+"\",\"step\":2}").utf8)
  let duplicateResult=try? RecipeContinuity.decode(duplicate,activityType:RecipeContinuity.activityType)
  let report:[String:Any]=["cases":results,"duplicatePropertyObservation":duplicateResult.map { "typed version \($0.version)" } ?? "rejected","duplicateQualification":"Not a canonical-JSON or duplicate-key rejection guarantee; only the decoded typed transfer feeds resolution and acceptance."]
  print(String(decoding:try JSONSerialization.data(withJSONObject:report,options:[.sortedKeys]),as:UTF8.self))
  exit(results.allSatisfy { $0["passed"] as? Bool == true } ? 0:1)
 }
}
