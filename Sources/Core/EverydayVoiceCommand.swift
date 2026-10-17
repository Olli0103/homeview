import Foundation

/// Bounded, local command grammar. Recognition produces a draft; only Send acts.
enum EverydayVoiceCommand: Equatable {
  case timer(seconds: Int, title: String)
  case step(Int), repeatStep
  case clarify(String)
  case unrelated
  init(_ input: String) {
    let raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
    let text = raw.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".!?"))
    let words = text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    if ["next step", "next cooking step", "nächster schritt", "weiter", "weiterer schritt"].contains(text) {
      self = .step(1); return
    }
    if ["previous step", "go back one step", "voriger schritt", "vorheriger schritt", "einen schritt zurück"].contains(text) {
      self = .step(-1); return
    }
    if ["repeat step", "repeat this step", "schritt wiederholen", "wiederhole den schritt"].contains(text) {
      self = .repeatStep; return
    }
    guard words.contains("timer") else { self = .unrelated; return }
    let help = "Specify one timer with a duration, for example ‘set a timer for 5 minutes’ or ‘Timer auf 90 Sekunden’."
    guard raw.count <= 300, !words.contains(where: { ["not","no","don't","dont","nicht","kein","keinen","keine","stop","cancel","delete","lösche","abbrechen"].contains($0) }) else {
      self = .clarify("No timer changed. Use the timer controls to pause, cancel or delete."); return
    }
    var durationText = text
    var title = ""
    if let range = raw.range(of: #"\s+(?:called|named|namens|mit dem namen)\s+"#, options: [.regularExpression, .caseInsensitive]) {
      title = String(raw[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
      durationText = String(raw[..<range.lowerBound]).lowercased()
      guard !title.isEmpty, title.count <= 80 else { self = .clarify(help); return }
    }
    let prefixes = ["set a timer for ", "set timer for ", "start a timer for ", "start timer for ",
                    "stelle einen timer auf ", "stell einen timer auf ", "starte einen timer für ",
                    "timer auf ", "timer für ", "timer for "]
    guard let prefix = prefixes.first(where: { durationText.hasPrefix($0) }) else {
      self = .clarify(help); return
    }
    durationText.removeFirst(prefix.count)
    let numbers: [String: Double] = ["a":1,"an":1,"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12,"thirteen":13,"fourteen":14,"fifteen":15,"sixteen":16,"seventeen":17,"eighteen":18,"nineteen":19,"twenty":20,"thirty":30,"forty":40,"fifty":50,"sixty":60,"eine":1,"einer":1,"eins":1,"zwei":2,"drei":3,"vier":4,"fünf":5,"sechs":6,"sieben":7,"acht":8,"neun":9,"zehn":10,"elf":11,"zwölf":12,"fünfzehn":15,"zwanzig":20,"dreißig":30,"dreissig":30,"vierzig":40,"fünfzig":50,"sechzig":60]
    let tokens = durationText.replacingOccurrences(of: ",", with: ".").split(whereSeparator: { $0.isWhitespace }).map(String.init)
    let units: [String: Double] = ["second":1,"seconds":1,"sec":1,"sekunde":1,"sekunden":1,"sek":1,"minute":60,"minutes":60,"min":60,"minuten":60,"hour":3600,"hours":3600,"hr":3600,"stunde":3600,"stunden":3600,"std":3600]
    var total = 0.0, index = 0
    var used = Set<Double>()
    while index < tokens.count {
      if index > 0, ["and","und"].contains(tokens[index]) {
        index += 1
        guard index < tokens.count else { self = .clarify(help); return }
      }
      guard index + 1 < tokens.count,
        let number = Double(tokens[index]) ?? numbers[tokens[index]], number.isFinite, number > 0,
        let unit = units[tokens[index+1]], used.insert(unit).inserted else {
        self = .clarify(help); return
      }
      total += number * unit
      index += 2
    }
    guard total.isFinite, total >= 1, total <= 86400, total.rounded() == total else {
      self = .clarify("Use a duration from 1 second to 24 hours, in whole seconds."); return
    }
    let seconds = Int(total)
    if title.isEmpty {
      title = seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds) sec"
    }
    self = .timer(seconds: seconds, title: title)
  }
}
