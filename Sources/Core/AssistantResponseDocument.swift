import Foundation

/// Closed, bundled display examples. Provider/user text is never decoded as a card or action.
enum AssistantResponseExample:String,CaseIterable,Identifiable,Sendable {
  case knowledge,agenda,message,recipe,loading,empty,failure
  var id:String {rawValue}
  var title:String {
    switch self {
    case .knowledge:"Knowledge and image"
    case .agenda:"Sample agenda"
    case .message:"Sample message"
    case .recipe:"Recipe card"
    case .loading:"Loading preview"
    case .empty:"No results"
    case .failure:"Unavailable result"
    }
  }
  var document:AssistantResponseDocument {
    switch self {
    case .knowledge:.init(text:"The cyanotype process was invented by John Herschel in 1842. Light-sensitive iron salts produce its distinctive blue prints.",content:.illustration,sources:[.museum],followUps:[.agenda,.recipe])
    case .agenda:.init(text:"Here are three events in the sample agenda.",content:.agenda([
      .init(day:"Wednesday, April 1",title:"Riley’s birthday",detail:"All day",kind:.birthday),
      .init(day:"Friday, April 17",title:"Studio celebration",detail:"3:00–4:00 PM",kind:.event),
      .init(day:"Tuesday, April 28",title:"Sam’s birthday",detail:"All day",kind:.birthday)
    ]),sources:[.bundled],followUps:[.recipe])
    case .message:.init(text:"In this fictional example, Avery’s train arrives at 6:30 PM on Friday, October 16.",
      content:.message(.init(sender:"Avery Morgan",timestamp:"Today, 9:41 AM",
        text:"I’ll arrive at Central Station at 6:30 PM on Friday, October 16.")),
      sources:[.bundled],followUps:[.agenda,.knowledge])
    case .recipe:.init(text:"Here is the bundled butternut squash soup recipe.",content:.recipe,sources:[.bundled],followUps:[.knowledge])
    case .loading:.init(text:"Loading-state preview",content:.loading,sources:[],followUps:[.knowledge])
    case .empty:.init(text:"No results in this sample.",content:.empty,sources:[],followUps:[.agenda,.recipe])
    case .failure:.init(text:"This sample result is unavailable.",content:.failure,sources:[],followUps:[.knowledge])
    }
  }
}

struct AssistantResponseDocument:Equatable,Sendable {
  enum Content:Equatable,Sendable {case illustration,agenda([Event]),message(MessageExcerpt),recipe,loading,empty,failure}
  /// Display-only evidence, with no recipient, URL or executable action.
  struct MessageExcerpt:Equatable,Sendable {
    let sender:String,timestamp:String,text:String
  }
  struct Event:Equatable,Sendable {
    enum Kind:Equatable,Sendable {case birthday,event}
    let day:String,title:String,detail:String
    let kind:Kind
  }
  enum Source:String,Identifiable,Sendable {
    case museum,bundled
    var id:String {rawValue}
    var title:String {self == .museum ? "Science Museum Group":"Bundled sample"}
    var detail:String {
      self == .museum
        ? "Album of cyanotypes of British and Foreign Ferns. This saved factual example was checked on 20 October 2026; it is not a live search. The illustration is drawn by HomeView, not a museum image."
        : "Fictional agenda/message entries or the app’s bundled demo recipe. No personal calendar, message or account was searched."
    }
    var url:URL? {
      self == .museum ? URL(string:"https://collection.sciencemuseumgroup.org.uk/objects/co416960/album-of-cyanotypes-of-british-and-foreign-ferns"):nil
    }
  }
  let text:String
  let content:Content
  let sources:[Source]
  let followUps:[AssistantResponseExample]
  var recipeActionAvailable:Bool {content == .recipe}
  /// Manual Read covers the visible answer/card, not hidden source sheets,
  /// follow-up controls, recipe ingredients or executable links.
  var readoutText:String {
    let card:String
    switch content {
    case .illustration:
      card="Illustration: pale fern-like branches on a deep-blue background. HomeView illustration. Not a historical print."
    case .agenda(let events):
      card=events.map {[$0.day,$0.title,$0.detail].joined(separator:". ")}.joined(separator:"\n")
    case .message(let message):
      card="Fictional message from \(message.sender). \(message.timestamp). \(message.text)\nFictional message. Read-only excerpt."
    case .recipe:
      let recipe=RecipeDocument.soup
      card="Illustration of a bowl of soup.\n\(recipe.title). \(recipe.source). \(recipe.durationMinutes) min. \(recipe.servingsLabel)."
    case .loading:
      card="Loading preview. Preview only. No request is running; choose another example below."
    case .empty:
      card="No matching sample. Try a different example. No personal sources were searched."
    case .failure:
      card="Result unavailable. Nothing was changed. Choose another example; there is no automatic retry."
    }
    let sourceNames=sources.map {"Source: "+$0.title+"."}.joined(separator:"\n")
    return ["Bundled answer example. Not a live or personal result.",text,card,sourceNames]
      .filter {!$0.isEmpty}.joined(separator:"\n")
  }
}
