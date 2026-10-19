import Foundation
import Observation

#if !os(watchOS)
@MainActor @Observable
final class RecipeHandoffController {
  private var activity:NSUserActivity?
  private var offeredDocument:String?
  private(set) var incoming:RecipeTransfer?
  private(set) var generation=0
  var busy=false
  var status="Only a recipe identifier and step are shared. The same recipe must already be saved on the other device."
  static var canPublish:Bool {
    if ProcessInfo.processInfo.arguments.contains("--uitesting") { return false }
    #if targetEnvironment(simulator)
      return false
    #elseif os(iOS) || os(macOS)
      return true
    #else
      return false
    #endif
  }
  var offering:Bool { activity != nil }
  func offer(_ transfer:RecipeTransfer) throws {
    guard Self.canPublish else {
      status="Handoff is unavailable here. Use two configured, signed HomeView apps on supported devices. No recipe was sent."
      return
    }
    let bytes=try RecipeContinuity.encode(transfer)
    stop()
    let item=NSUserActivity(activityType:RecipeContinuity.activityType)
    item.title="Continue cooking"
    item.isEligibleForHandoff=true
    item.isEligibleForSearch=false
    item.isEligibleForPublicIndexing=false
    item.requiredUserInfoKeys=["payload"]
    item.userInfo=["payload":bytes]
    activity=item;offeredDocument=transfer.document
    item.becomeCurrent()
    status="Offered while HomeView is active. A receiving app is not confirmed; nothing is marked delivered."
  }
  func update(recipe:RecipeDocument,step:Int) {
    guard let activity else { return }
    do {
      let transfer=try RecipeContinuity.make(recipe:recipe,step:step)
      guard transfer.document==offeredDocument else { stop();status="Recipe changed. Offer it again explicitly.";return }
      activity.addUserInfoEntries(from:["payload":try RecipeContinuity.encode(transfer)])
      activity.needsSave=true
    } catch { stop();status="Cooking ended. No recipe is being offered." }
  }
  func receive(type:String,data:Data) {
    stop()
    do {
      incoming=try RecipeContinuity.decode(data,activityType:type)
      status="A recipe handoff is ready. Unlock this device to continue using its local recipe."
    } catch { status=(error as? LocalizedError)?.errorDescription ?? "Recipe handoff is unavailable." }
  }
  func cancelPending() { generation+=1;incoming=nil;busy=false }
  func stopOffering() {
    guard activity != nil else { return }
    activity?.resignCurrent();activity?.invalidate();activity=nil;offeredDocument=nil
    status="No recipe is being offered."
  }
  func stop() {
    generation+=1;incoming=nil;busy=false
    stopOffering();status="No recipe is being offered."
  }
}
#endif
