import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct SplashOverlay: GView {
    let router: ObservableState<GameRouter>

    @State var isVisible = false

    var body: some GView {
      Control$ {
        SwiftGodotBuilder.SplashOverlay(
          isVisible: $isVisible,
          title: "SwiftGodotBuilder"
        ) {
          router.navigate(to: .welcome, transition: .fade())
        }
      }
      .watch(router, \.scene) { _, scene in
        isVisible = scene == .splash
      }
    }
  }
}
