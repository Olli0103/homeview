import XCTest
@testable import HomeViewCore

final class LocalStateFileReaderTests:XCTestCase {
  private func withRoot(_ body:(URL)throws->Void) throws {
    let fm=FileManager.default
    let base=ProcessInfo.processInfo.environment["HOMEVIEW_FILE_READER_TEST_ROOT"]
      .map {URL(fileURLWithPath:$0,isDirectory:true)} ?? fm.temporaryDirectory
    let root=base.appendingPathComponent("state-reader-"+UUID().uuidString,isDirectory:true)
    try fm.createDirectory(at:root,withIntermediateDirectories:true)
    defer {try? fm.removeItem(at:root)}
    try body(root)
  }
  func testHealthyEmptyAndMissingFilesKeepByteAndAbsenceSemantics() throws {
    try withRoot { root in
      let file=root.appendingPathComponent("state.json"),bytes=Data([0,1,2,255])+Data("Own synthetic bytes".utf8)
      XCTAssertNil(try LocalStateFileReader.read(file))
      try bytes.write(to:file)
      XCTAssertEqual(try LocalStateFileReader.read(file),bytes)
      try Data().write(to:file)
      XCTAssertEqual(try LocalStateFileReader.read(file),Data())
    }
  }
  func testDirectoriesLinksAndNonFileURLsAreNotMissingOrReadableState() throws {
    try withRoot { root in
      let fm=FileManager.default,canary=root.appendingPathComponent("canary.json")
      let bytes=Data("SYNTHETIC_CANARY".utf8);try bytes.write(to:canary)
      let link=root.appendingPathComponent("linked.json"),dangling=root.appendingPathComponent("dangling.json")
      try fm.createSymbolicLink(at:link,withDestinationURL:canary)
      try fm.createSymbolicLink(at:dangling,withDestinationURL:root.appendingPathComponent("absent.json"))
      for url in [root,link,dangling,URL(string:"https://example.invalid/state.json")!] {
        XCTAssertThrowsError(try LocalStateFileReader.read(url)) { error in
          XCTAssertEqual(error as? LocalStateFileReadError,.invalidFile)
        }
      }
      XCTAssertEqual(try Data(contentsOf:canary),bytes)
    }
  }
  func testExactByteLimitIsReadableAndOneAdditionalByteIsRejected() throws {
    try withRoot { root in
      let file=root.appendingPathComponent("boundary.json")
      let bytes=Data(repeating:120,count:LocalStateFileReader.maximumBytes)
      try bytes.write(to:file)
      XCTAssertEqual(try LocalStateFileReader.read(file),bytes)
      let handle=try FileHandle(forWritingTo:file)
      try handle.seekToEnd();try handle.write(contentsOf:Data([121]));try handle.close()
      XCTAssertThrowsError(try LocalStateFileReader.read(file)) { error in
        XCTAssertEqual(error as? LocalStateFileReadError,.oversized)
      }
    }
  }
  func testLargeSparseStateIsRejectedWithoutChangingItsSize() throws {
    try withRoot { root in
      let fm=FileManager.default,file=root.appendingPathComponent("oversized.json")
      XCTAssertTrue(fm.createFile(atPath:file.path,contents:Data()))
      let handle=try FileHandle(forWritingTo:file),size=UInt64(LocalStateFileReader.maximumBytes)*4+1
      try handle.truncate(atOffset:size);try handle.close()
      XCTAssertThrowsError(try LocalStateFileReader.read(file)) { error in
        XCTAssertEqual(error as? LocalStateFileReadError,.oversized)
      }
      XCTAssertEqual((try fm.attributesOfItem(atPath:file.path)[.size] as? NSNumber)?.uint64Value,size)
    }
  }
}
