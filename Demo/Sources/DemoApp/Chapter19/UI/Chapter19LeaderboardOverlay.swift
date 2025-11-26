import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter19 {
  struct LeaderboardOverlay: GView {
    let state: ObservableState<GameViewState>
    let progress: ObservableState<GameProgress>

    let palette = Palette()

    @State var firstButton: Button?
    @State var entries: [LeaderboardEntry] = []
    @State var levelName = ""
    @State var hasEntries = false

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            VBoxContainer$ {
              Label$()
                .text("LEADERBOARD")
                .horizontalAlignment(.center)
                .theme(["fontSize": 32, "fontColor": palette.gold])

              Label$()
                .text($levelName)
                .horizontalAlignment(.center)
                .theme(["fontSize": 16, "fontColor": palette.cyan])
            }

            Control$().minSize([0, 8]).sizeV(.expandFill)

            // Header row
            HBoxContainer$ {
              Label$()
                .text("#")
                .minSize([24, 0])
                .theme(["fontColor": palette.gray])

              Label$()
                .text("Time")
                .sizeH(.expandFill)
                .theme(["fontColor": palette.gray])

              Label$()
                .text("Coins")
                .minSize([48, 0])
                .theme(["fontColor": palette.gray])

              Label$()
                .text("Deaths")
                .minSize([48, 0])
                .theme(["fontColor": palette.gray])
            }
            .theme(["separation": 8])

            VBoxContainer$ {
              // Leaderboard entries
              ForEach($entries) { entry in
                LeaderboardRow(
                  entry: entry,
                  rank: (entries.firstIndex { $0 == entry.wrappedValue } ?? 0) + 1,
                  palette: palette
                )
              }
            }

            // Show empty state if no entries
            If($hasEntries.computed { !$0 }) {
              Label$()
                .text("No times recorded yet!")
                .horizontalAlignment(.center)
                .theme(["fontColor": palette.gray])
            }
            .mode(.destroy)

            Control$().minSize([0, 8]).sizeV(.expandFill)

            Button$()
              .text("Back")
              .minSize([150, 0])
              .focusMode(.all)
              .styleBoxes(palette.grayButtonStylesWithFocus)
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.returnToLevelSelect()
              }
              .ref($firstButton)

            Label$()
              .text("[B] Back")
              .horizontalAlignment(.center)
              .theme(["fontColor": palette.darkGray])
          }
        }
        .theme("panel", palette.panelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .visible(state.isLeaderboard)
      .watch(state, \.gameState) { [self] _, gameState in
        if gameState == .leaderboard {
          let levelId = state.wrappedValue.leaderboardLevelId
          levelName = Chapter19.getLevelData(levelId)?.name ?? "Level \(levelId)"
          entries = progress.wrappedValue.getLeaderboard(for: levelId)
          hasEntries = !entries.isEmpty
          firstButton?.grabFocus()
        }
      }
      .onProcess { [state] _, _ in
        guard state.wrappedValue.isLeaderboard else { return }
        if Action("ui_cancel").isJustPressed {
          state.wrappedValue.returnToLevelSelect()
        }
      }
    }
  }

  struct LeaderboardRow: GView {
    let entry: State<LeaderboardEntry>
    let rank: Int
    let palette: Palette

    var rankColor: Color {
      switch rank {
      case 1: Color(code: "#FFD700")
      case 2: Color(code: "#C0C0C0")
      case 3: Color(code: "#CD7F32")
      default: palette.white
      }
    }

    var body: some GView {
      HBoxContainer$ {
        Label$()
          .text("\(rank)")
          .minSize([24, 0])
          .theme(["fontColor": rankColor])

        Label$()
          .text(entry.wrappedValue.timeFormatted)
          .sizeH(.expandFill)
          .theme(["fontColor": palette.white])

        Label$()
          .text("\(entry.wrappedValue.coins)")
          .minSize([48, 0])
          .theme(["fontColor": palette.yellow])

        Label$()
          .text("\(entry.wrappedValue.deaths)")
          .minSize([48, 0])
          .theme(["fontColor": palette.redLight])
      }
      .theme(["separation": 8])
    }
  }
}
