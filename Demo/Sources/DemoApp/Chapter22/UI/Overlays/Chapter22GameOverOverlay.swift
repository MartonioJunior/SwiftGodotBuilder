import SwiftGodot
import SwiftGodotBuilder

extension Chapter22 {
  struct GameOverOverlay: GView {
    let state: ObservableState<GameViewState>
    let transitionState: ObservableState<TransitionState>

    let palette = Palette.shared

    @State var firstButton: Button?

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
              BounceButton("Retry", width: 120, color: .cyan, ref: $firstButton) {
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
      .visible(state.isGameOver)
      .watch(state, \.gameState) { _, gameState in
        if gameState == .gameOver {
          firstButton?.grabFocus()
        }
      }
    }

    func retryLevel() {
      transitionState.wrappedValue.irisOutTransition(
        duration: 1.0,
        center: [0.5, 0.5],
        onMidpoint: {
          state.wrappedValue.restartLevel()
        }
      )
    }

    func goToMenu() {
      transitionState.wrappedValue.fadeTransition(
        duration: 0.6,
        onMidpoint: {
          state.wrappedValue.returnToLevelSelect()
        }
      )
    }
  }
}
