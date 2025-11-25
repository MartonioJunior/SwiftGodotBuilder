import SwiftGodot
import SwiftGodotBuilder

extension Chapter18 {
  struct LevelCompleteOverlay: GView {
    let state: ObservableState<GameViewState>
    let progress: ObservableState<GameProgress>

    let palette = Palette()

    @State var firstButton: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            Label$()
              .text("LEVEL COMPLETE!")
              .horizontalAlignment(.center)
              .theme(["fontSize": 48, "fontColor": palette.green])

            Label$()
              .text(state.levelNameDisplay)
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.cyan])

            Control$().minSize([0, 8])

            Label$()
              .text(state.coinsDisplay)
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.yellow])

            Label$()
              .text(state.playTimeDisplay)
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.gray])

            Label$()
              .text(state.deathsDisplay)
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.redLight])

            Label$()
              .text(state.finalScoreDisplay)
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.white])

            Control$().minSize([0, 8])

            HBoxContainer$ {
              Button$()
                .text("Next Level")
                .minSize([120, 0])
                .focusMode(.all)
                .bind(\.disabled, to: state, \.currentLevelId) { levelId in
                  Chapter18.getLevelData(levelId + 1) == nil
                }
                .styleBoxes(palette.greenButtonStylesWithFocus)
                .onSignal(\.pressed) { [state] _ in
                  state.wrappedValue.nextLevel()
                }
                .onReady { [self] node in
                  if let btn = node as? Button {
                    firstButton = btn
                  }
                }

              Button$()
                .text("Retry")
                .minSize([120, 0])
                .focusMode(.all)
                .styleBoxes(palette.cyanButtonStylesWithFocus)
                .onSignal(\.pressed) { [state] _ in
                  state.wrappedValue.restartLevel()
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
        .theme("panel", palette.victoryPanelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .visible(state.isLevelComplete)
      .watch(state, \.gameState) { _, gameState in
        if gameState == .levelComplete {
          firstButton?.grabFocus()
        }
      }
    }
  }
}
