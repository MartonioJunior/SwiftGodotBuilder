import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  struct LeaderboardOverlay: GView {
    let state: ObservableState<GameViewState>
    let progress: ObservableState<GameProgress>

    let palette = Palette.shared

    @State var firstButton: Button?
    @State var entries: [LeaderboardEntry] = []
    @State var levelName = ""
    @State var hasEntries = false

    func updateLeaderboard() {
      let levelId = state.wrappedValue.leaderboardLevelId
      levelName = Chapter21.getLevelData(levelId)?.name ?? "Level \(levelId)"
      entries = progress.wrappedValue.getLeaderboard(for: levelId)
      hasEntries = !entries.isEmpty
    }

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("LEADERBOARD", color: palette.gold)

            HBoxContainer$ {
              Button$()
                .text("<")
                .minSize([24, 0])
                .focusMode(.none)
                .styleBoxes(palette.grayButtonStylesWithFocus)
                .onSignal(\.pressed) { [state] _ in
                  let currentId = state.wrappedValue.leaderboardLevelId
                  let newId = currentId > 1 ? currentId - 1 : Chapter21.levels.count
                  state.wrappedValue.showLeaderboard(for: newId)
                }

              Label$()
                .text($levelName)
                .horizontalAlignment(.center)
                .sizeH(.expandFill)
                .theme(["fontSize": 16, "fontColor": palette.cyan])

              Button$()
                .text(">")
                .minSize([24, 0])
                .focusMode(.none)
                .styleBoxes(palette.grayButtonStylesWithFocus)
                .onSignal(\.pressed) { [state] _ in
                  let currentId = state.wrappedValue.leaderboardLevelId
                  let newId = currentId < Chapter21.levels.count ? currentId + 1 : 1
                  state.wrappedValue.showLeaderboard(for: newId)
                }
            }
            .theme(["separation": 8])

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

            MenuButton("Back", width: 150, color: .gray, ref: $firstButton) {
              state.wrappedValue.returnToLevelSelect()
            }

            InfoLabel("[LB/RB] Change Level  [B] Back")
          }
        }
        .theme("panel", palette.panelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .visible(state.isLeaderboard)
      .watch(state, \.gameState) { _, gameState in
        if gameState == .leaderboard {
          updateLeaderboard()
          firstButton?.grabFocus()
        }
      }
      .watch(state, \.leaderboardLevelId) { _, _ in
        guard state.wrappedValue.isLeaderboard else { return }
        updateLeaderboard()
      }
      .onProcess { [state] _, _ in
        guard state.wrappedValue.isLeaderboard else { return }
        if Action("ui_cancel").isJustPressed {
          state.wrappedValue.returnToLevelSelect()
        }
        if Action("ui_left").isJustPressed || Action("switch_weapon").isJustPressed {
          let currentId = state.wrappedValue.leaderboardLevelId
          let newId = currentId > 1 ? currentId - 1 : Chapter21.levels.count
          state.wrappedValue.showLeaderboard(for: newId)
        }
        if Action("ui_right").isJustPressed || Action("attack").isJustPressed {
          let currentId = state.wrappedValue.leaderboardLevelId
          let newId = currentId < Chapter21.levels.count ? currentId + 1 : 1
          state.wrappedValue.showLeaderboard(for: newId)
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
