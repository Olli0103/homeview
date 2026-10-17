import XCTest
@testable import HomeViewCore

final class EverydayVoiceCommandTests: XCTestCase {
  func testEnglishAndGermanDurationsAndNames() {
    XCTAssertEqual(EverydayVoiceCommand("set a timer for 5 minutes"),.timer(seconds:300,title:"5 min"))
    XCTAssertEqual(EverydayVoiceCommand("Timer auf 90 Sekunden namens Tee"),.timer(seconds:90,title:"Tee"))
    XCTAssertEqual(EverydayVoiceCommand("set a timer for one hour and thirty minutes"),.timer(seconds:5400,title:"90 min"))
    XCTAssertEqual(EverydayVoiceCommand("set a timer for 1 hour and 30 minutes named Pasta"),.timer(seconds:5400,title:"Pasta"))
    XCTAssertEqual(EverydayVoiceCommand("stelle einen timer auf zwei Minuten und 5 Sekunden"),.timer(seconds:125,title:"125 sec"))
    XCTAssertEqual(EverydayVoiceCommand("timer für 0,5 Minuten"),.timer(seconds:30,title:"30 sec"))
  }
  func testAmbiguityNegationRangesAndMalformedRecognitionNeverStartTimer() {
    for input in ["timer", "timer for zero minutes", "set a timer for 0 minutes", "set a timer for -5 minutes", "set a timer for 24 hours and 1 second", "set a timer for 1 second and", "set a timer for 5 minutes or 10 minutes", "don't set a timer for 5 minutes", "stelle keinen timer auf 5 minuten", "set a timer for 0.1 seconds", "timer for 1e300 hours", "set a timer for 5 minutes 5 minutes", "set a timer for 5 minutes and start music", "cancel timer", "start a timer for nan seconds"] {
      guard case .clarify = EverydayVoiceCommand(input) else { return XCTFail(input) }
    }
  }
  func testCookingCommandsOnlyMatchAnEntireIntent() {
    XCTAssertEqual(EverydayVoiceCommand("next step"),.step(1))
    XCTAssertEqual(EverydayVoiceCommand("Nächster Schritt!"),.step(1))
    XCTAssertEqual(EverydayVoiceCommand("vorheriger schritt"),.step(-1))
    XCTAssertEqual(EverydayVoiceCommand("repeat this step"),.repeatStep)
    XCTAssertEqual(EverydayVoiceCommand("show recipe"),.unrelated)
    XCTAssertEqual(EverydayVoiceCommand("don't go to the next step"),.unrelated)
    XCTAssertEqual(EverydayVoiceCommand("next step and unlock the door"),.unrelated)
  }
}
