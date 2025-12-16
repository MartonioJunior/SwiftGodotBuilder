import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct LeaderboardOverlay: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<ProjectState>
    let progress: ObservableState<GameProgress>

    let palette = Palette.shared

    var vm: ProjectState { state.wrappedValue }
    var gp: GameProgress { progress.wrappedValue }

    @State var firstResponder: Button?
    @State var entries: [LeaderboardEntry] = []
    @State var levelName = ""
    @State var hasEntries = false

    func updateLeaderboard() {
      guard let levelId = vm.leaderboardLevelId else { return }
      levelName = LevelData.data(for: levelId, in: vm.project)?.name ?? "Level \(levelId)"
      entries = gp.getLeaderboard(for: levelId)
      hasEntries = !entries.isEmpty
    }

    var body: some GView {
      Node2D$ {
        OverlayPanel {
          HeaderLabel("LEADERBOARD", color: palette.gold)

          HBoxContainer$ {
            Button$()
              .text("<")
              .minSize([24, 0])
              .focusMode(.none)
              .styleBoxes(palette.grayButtonStylesWithFocus)
              .onSignal(\.pressed) { _ in
                navigateToPreviousLevel()
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
              .onSignal(\.pressed) { _ in
                navigateToNextLevel()
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
                rank: (entries.firstIndex { $0 == entry.wrappedValue } ?? 0) + 1,
                entry: entry.wrappedValue,
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

          MenuButton("Back", width: 150, color: .gray, ref: $firstResponder) {
            router.scene = .levelSelect
          }

          InfoLabel("[LB/RB] Change Level  [B] Back")
        }
      }
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .leaderboard
        if scene == .leaderboard {
          updateLeaderboard()
          firstResponder?.grabFocus()
        }
      }
      .watch(state, \.leaderboardLevelId) { _, _ in
        guard router.scene == .leaderboard else { return }
        updateLeaderboard()
      }
      .onProcess { _, _ in
        guard router.scene == .leaderboard else { return }
        if Action("ui_cancel").isJustPressed {
          router.scene = .levelSelect
        }
        if Action("ui_left").isJustPressed || Action("switch_weapon").isJustPressed {
          navigateToPreviousLevel()
        }
        if Action("ui_right").isJustPressed || Action("attack").isJustPressed {
          navigateToNextLevel()
        }
      }
    }

    var levelIds: [String] {
      vm.project.allLevels.map { $0.identifier }
    }

    func navigateToPreviousLevel() {
      guard let leaderboardLevelId = vm.leaderboardLevelId, !levelIds.isEmpty else { return }
      guard let currentIndex = levelIds.firstIndex(of: leaderboardLevelId) else {
        vm.setLeaderboardLevel(levelIds[0])
        return
      }
      let newIndex = currentIndex > 0 ? currentIndex - 1 : levelIds.count - 1
      vm.setLeaderboardLevel(levelIds[newIndex])
    }

    func navigateToNextLevel() {
      guard let leaderboardLevelId = vm.leaderboardLevelId, !levelIds.isEmpty else { return }
      guard let currentIndex = levelIds.firstIndex(of: leaderboardLevelId) else {
        vm.setLeaderboardLevel(levelIds[0])
        return
      }
      let newIndex = currentIndex < levelIds.count - 1 ? currentIndex + 1 : 0
      vm.setLeaderboardLevel(levelIds[newIndex])
    }
  }

  struct LeaderboardRow: GView {
    let rank: Int
    let entry: LeaderboardEntry
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
          .text(entry.timeFormatted)
          .sizeH(.expandFill)
          .theme(["fontColor": palette.white])

        Label$()
          .text("\(entry.coins)")
          .minSize([48, 0])
          .theme(["fontColor": palette.yellow])

        Label$()
          .text("\(entry.deaths)")
          .minSize([48, 0])
          .theme(["fontColor": palette.redLight])
      }
      .theme(["separation": 8])
    }
  }
}
