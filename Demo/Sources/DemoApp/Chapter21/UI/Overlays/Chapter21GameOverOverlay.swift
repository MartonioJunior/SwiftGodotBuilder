import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  struct GameOverOverlay: GView {
    let state: ObservableState<GameViewState>

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
              MenuButton("Retry", width: 120, color: .cyan, ref: _firstButton) {
                state.wrappedValue.restartLevel()
              }
              MenuButton("Menu", width: 120, color: .gray) {
                state.wrappedValue.returnToLevelSelect()
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
  }
}
