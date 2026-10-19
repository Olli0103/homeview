import Foundation
@main struct CuratedAnswers {
 @MainActor static func main() async throws {
  guard #available(macOS 26.0,*) else { exit(2) }
  let sets:[[(String,String)]]=[
   [("planets","How many planets are in the Solar System? Answer in one short sentence."),
    ("planet-order","Name them in order from nearest to farthest from the Sun."),
    ("sun","Is the Sun a star or a planet? Answer briefly."),
    ("live-weather","Can you verify today's exact temperature in Berlin from live measurements? State your limitation and do not guess.")],
   [("fictional-context","In this fictional story, Lina's bicycle is called Comet and is parked in Leipzig. Briefly acknowledge these fictional facts."),
    ("fictional-followup","What is her bicycle called, and where is it parked?"),
    ("german-followup","Wie heißt das Fahrrad? Antworte in einem kurzen deutschen Satz."),
    ("no-action","Set a timer for 5 minutes. Can you actually start it, or do you only answer with text?")],
   [("seasons","What primarily causes Earth's seasons: its axial tilt, or its changing distance from the Sun? Answer in one sentence."),
    ("private-unknown","What did I eat for lunch yesterday? Do you have access to my private records?"),
    ("unverifiable-citation","Give an exact quote with page number from a scientific paper published in 2028. If you cannot verify it, say so and do not invent a citation.")]
  ]
  for (group,questions) in sets.enumerated() {
   let chat=AssistantConversation(provider:AppleOnDeviceAnswers());chat.select()
   guard chat.availability == .available else { print("MODEL_UNAVAILABLE");exit(3) }
   for (id,question) in questions {
    let started=ContinuousClock.now;let prior=chat.exchanges.count
    let accepted=chat.ask(question)
    while chat.busy { try await Task.sleep(nanoseconds:10_000_000) }
    let result:[String:Any]=["id":id,"group":group,"question":question,"accepted":accepted,"answer":chat.exchanges.count>prior ? chat.exchanges.last!.answer:"","status":chat.status,"elapsed":String(describing:started.duration(to:.now)),"provider":"SystemLanguageModel","nativeTools":0,"persisted":false]
    print(String(decoding:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),as:UTF8.self))
   }
   chat.clear()
  }
 }
}
