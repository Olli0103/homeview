import Foundation

/// Closed, bundled display examples. Provider/user text is never decoded as a card or action.
enum AssistantResponseExample:String,CaseIterable,Identifiable,Sendable {
  case knowledge,agenda,recipe,loading,empty,failure
  var id:String {rawValue}
  var title:String {
    switch self {
    case .knowledge:"Knowledge and image"
    case .agenda:"Sample agenda"
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
    case .recipe:.init(text:"Here is the bundled butternut squash soup recipe.",content:.recipe,sources:[.bundled],followUps:[.knowledge])
    case .loading:.init(text:"Loading-state preview",content:.loading,sources:[],followUps:[.knowledge])
    case .empty:.init(text:"No results in this sample.",content:.empty,sources:[],followUps:[.agenda,.recipe])
    case .failure:.init(text:"This sample result is unavailable.",content:.failure,sources:[],followUps:[.knowledge])
    }
  }
}

struct AssistantResponseDocument:Equatable,Sendable {
  enum Content:Equatable,Sendable {case illustration,agenda([Event]),recipe,loading,empty,failure}
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
        : "Fictional agenda entries or the app’s bundled demo recipe. No personal calendar, message or account was searched."
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
}
