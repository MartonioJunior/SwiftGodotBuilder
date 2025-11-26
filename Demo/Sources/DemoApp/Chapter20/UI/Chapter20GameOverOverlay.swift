import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  struct GameOverOverlay: GView {
    let state: ObservableState<GameViewState>

    let palette = Palette()

    @State var firstButton: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            Label$()
              .text("GAME OVER")
              .horizontalAlignment(.center)
              .theme(["fontSize": 48, "fontColor": palette.redLight])

            Label$()
              .text(state.levelNameDisplay)
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.gray])

            Control$().minSize([0, 8])

            Label$()
              .text(state.finalScoreDisplay)
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.yellow])

            Label$()
              .text(state.coinsDisplay)
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.gold])

            Label$()
              .text(state.playTimeDisplay)
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.lightGray])

            Label$()
              .text(state.deathsDisplay)
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.redLight])

            Control$().minSize([0, 8])

            HBoxContainer$ {
              Button$()
                .text("Retry")
                .minSize([120, 0])
                .focusMode(.all)
                .styleBoxes(palette.cyanButtonStylesWithFocus)
                .onSignal(\.pressed) { [state] _ in
                  state.wrappedValue.restartLevel()
                }
                .onReady { btn in
                  firstButton = btn
                }

              Button$()
                .text("Menu")
                .minSize([120, 0])
                .focusMode(.all)
                .styleBoxes(palette.grayButtonStylesWithFocus)
                .onSignal(\.pressed) { [state] _ in
                  state.wrappedValue.returnToLevelSelect()
                }
            }
            .theme(["separation": 8])

            Label$()
              .text("[A] Select  [D-Pad] Navigate")
              .horizontalAlignment(.center)
              .theme(["fontColor": palette.darkGray])
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
