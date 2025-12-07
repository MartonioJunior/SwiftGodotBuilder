import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct GameOverOverlay: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<GameViewState>

    let palette = Palette.shared

    private var vm: GameViewState { state.wrappedValue }

    @State var firstResponder: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("GAME OVER", size: 48, color: palette.redLight)
            LiveInfoLabel(state.levelNameDisplay, color: palette.gray)

            Spacer()

            LiveInfoLabel(state.finalScoreDisplay, color: palette.yellow)
            LiveInfoLabel(state.coinsDisplay, color: palette.gold)
            LiveInfoLabel(state.playTimeDisplay, color: palette.lightGray)
            LiveInfoLabel(state.deathsDisplay, color: palette.redLight)

            Spacer()

            HBoxContainer$ {
              BounceButton("Retry", width: 120, color: .cyan, ref: $firstResponder) {
                retryLevel()
              }
              AnimatedButton("Menu", width: 120, color: .gray) {
                goToMenu()
              }
            }
            .theme(["separation": 8])

            InfoLabel("[A] Select  [D-Pad] Navigate")
          }
          .theme(["separation": 4])
        }
        .theme("panel", palette.gameOverPanelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .gameOver
        if scene == .gameOver {
          firstResponder?.grabFocus()
        }
      }
    }

    func retryLevel() {
      router.navigate(to: .playing, transition: .iris(duration: 1.0, center: [0.5, 0.5])) {
        vm.prepareLevel(vm.currentLevelId)
      }
    }

    func goToMenu() {
      router.navigate(to: .levelSelect, transition: .fade(duration: 0.6))
    }
  }
}
