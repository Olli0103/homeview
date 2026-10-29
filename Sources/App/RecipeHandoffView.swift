import SwiftUI

struct RecipeHandoffView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.nativeCanvasScale) private var canvasScale
  private var minimumHitSide:CGFloat {(44 / max(0.01,canvasScale)).rounded(.up)}
  var body:some View {
    VStack(alignment:.leading,spacing:24) {
      HStack {
        Text("Recipe Handoff").font(.system(size:27,weight:.semibold))
        Spacer()
        Button { model.closeRecipeHandoff() } label: {
          Text("Done").frame(minWidth:minimumHitSide,minHeight:minimumHitSide).contentShape(Rectangle())
        }.accessibilityIdentifier("recipe.handoff.done")
      }
      Text("Continue cooking in HomeView on another device.").font(.system(size:27))
      Text("Recipe text, ingredients and source URLs are not copied. Save the same recipe on both devices first.")
        .font(.system(size:19)).foregroundStyle(.secondary)
      Text(model.recipeHandoff.status).font(.system(size:21))
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
    }.font(.system(size:22,weight:.medium)).padding(32)
      .background(.white).foregroundStyle(.black).buttonStyle(.plain)
  }
}
