import SwiftUI

struct RecipeHandoffView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  @Environment(\.dynamicTypeSize) private var textSize
  @ScaledMetric(relativeTo:.title2) private var titleSize:CGFloat=27
  @ScaledMetric(relativeTo:.body) private var policySize:CGFloat=19
  @ScaledMetric(relativeTo:.body) private var statusSize:CGFloat=21
  @ScaledMetric(relativeTo:.body) private var actionSize:CGFloat=22
  private var minimumHitSide:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  var body:some View {
    Group {
      if textSize.isAccessibilitySize {ScrollView {content}.accessibilityIdentifier("recipe.handoff.accessible.content")}
      else {content}
    }.background(.white).foregroundStyle(.black).buttonStyle(.plain)
  }
  private var content:some View {
    VStack(alignment:.leading,spacing:24) {
      HStack {
        Text("Recipe Handoff").font(.system(size:titleSize,weight:.semibold))
        Spacer()
        Button { model.closeRecipeHandoff() } label: {
          Text("Done").frame(minWidth:minimumHitSide,minHeight:minimumHitSide).contentShape(Rectangle())
        }.accessibilityIdentifier("recipe.handoff.done")
      }
      Text("Continue cooking in HomeView on another device.").font(.system(size:titleSize))
      Text("Recipe text, ingredients and source URLs are not copied. Save the same recipe on both devices first.")
        .font(.system(size:policySize)).foregroundStyle(.black.opacity(0.65))
      Text(model.recipeHandoff.status).font(.system(size:statusSize))
        .accessibilityIdentifier("recipe.handoff.status")
      if model.recipeHandoff.incoming != nil {
        Button("Unlock and continue") { Task { await model.acceptRecipeHandoff() } }
          .accessibilityIdentifier("recipe.handoff.accept").disabled(model.recipeHandoff.busy)
      } else if model.cookingInProgress {
        Button("Offer via Handoff") { Task { await model.offerRecipeHandoff() } }
          .accessibilityIdentifier("recipe.handoff.offer").disabled(model.recipeHandoff.busy)
      }
      if model.recipeHandoff.offering {
        Button("Stop offering") { model.recipeHandoff.stop() }
          .accessibilityIdentifier("recipe.handoff.stop")
      }
      Spacer(minLength:0)
    }.font(.system(size:actionSize,weight:.medium)).padding(32)
  }
}
