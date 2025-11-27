import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  struct LevelCompleteOverlay: GView {
    let state: ObservableState<GameViewState>
    let progress: ObservableState<GameProgress>

    let palette = Palette.shared

    @State var firstButton: Button?
    @State var isNewBest = false
    @State var previousBest = ""
    @State var medalColorValue = Color.white

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("LEVEL COMPLETE!", size: 48, color: palette.green)
            LiveInfoLabel(state.levelNameDisplay, color: palette.cyan)

            Spacer(4)

            // Medal display
            HBoxContainer$ {
              Label$()
                .text(state.currentMedalDisplay)
                .theme(["fontSize": 32])

              VBoxContainer$ {
                Label$()
                  .bind(\.text, to: state, \.currentMedal) { "\($0.name) Medal" }
                  .theme(["fontSize": 16, "fontColor": $medalColorValue])

                Label$()
                  .text(state.playTimeDisplay)
                  .theme(["fontSize": 16, "fontColor": palette.white])
              }

              // New best indicator
              If($isNewBest) {
                Label$()
                  .text("NEW BEST TIME!")
                  .horizontalAlignment(.center)
                  .theme(["fontSize": 16, "fontColor": palette.gold])
              }
              .Else {
                Label$()
                  .bind(\.text, to: $previousBest) { "Best: \($0)" }
                  .horizontalAlignment(.center)
                  .theme(["fontSize": 8, "fontColor": palette.gray])
              }
            }
            .theme(["separation": 8])

            Spacer(4)

            HBoxContainer$ {
              Label$()
                .text(state.coinsDisplay)
                .theme(["fontColor": palette.yellow])

              Label$()
                .text(state.deathsDisplay)
                .theme(["fontColor": palette.redLight])

              Label$()
                .text(state.finalScoreDisplay)
                .theme(["fontColor": palette.white])
            }
            .theme(["separation": 16])

            Spacer(4)

            HBoxContainer$ {
              Button$()
                .text("Next Level")
                .minSize([100, 0])
                .focusMode(.all)
                .bind(\.disabled, to: state, \.currentLevelId) { levelId in
                  Chapter21.getLevelData(levelId + 1) == nil
                }
                .styleBoxes(palette.greenButtonStylesWithFocus)
                .onSignal(\.pressed) { [state] _ in
                  state.wrappedValue.nextLevel()
                }
                .ref($firstButton)

              Button$()
                .text("Retry")
                .minSize([100, 0])
                .focusMode(.all)
                .styleBoxes(palette.cyanButtonStylesWithFocus)
                .onSignal(\.pressed) { [state] _ in
                  state.wrappedValue.restartLevel()
                }

              Button$()
                .text("Leaderboard")
                .minSize([100, 0])
                .focusMode(.all)
                .styleBoxes(palette.yellowButtonStylesWithFocus)
                .onSignal(\.pressed) { [state] _ in
                  state.wrappedValue.showLeaderboard(for: state.wrappedValue.currentLevelId)
                }

              Button$()
                .text("Menu")
                .minSize([100, 0])
                .focusMode(.all)
                .styleBoxes(palette.grayButtonStylesWithFocus)
                .onSignal(\.pressed) { [state] _ in
                  state.wrappedValue.returnToLevelSelect()
                }
            }
            .theme(["separation": 4])

            InfoLabel("[A] Select  [D-Pad] Navigate")
          }
          .theme(["separation": 2])
        }
        .theme("panel", palette.victoryPanelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .visible(state.isLevelComplete)
      .watch(state, \.gameState) { _, gameState in
        if gameState == .levelComplete {
          let levelProgress = progress.wrappedValue.getProgress(for: state.wrappedValue.currentLevelId)
          let currentTime = state.wrappedValue.playTime
          let medal = state.wrappedValue.currentMedal

          // Update medal color
          medalColorValue = Color(code: medal.color)

          // Check if this is a new best (leaderboard has the new time, so compare to 2nd best or check if only 1 entry)
          if levelProgress.leaderboard.count <= 1 {
            isNewBest = true
            previousBest = "--:--.--"
          } else if currentTime <= levelProgress.leaderboard[0].time {
            isNewBest = true
            previousBest = levelProgress.leaderboard[1].timeFormatted
          } else {
            isNewBest = false
            previousBest = levelProgress.bestTimeFormatted
          }

          firstButton?.grabFocus()
        }
      }
    }
  }
}
