import SwiftGodot
import SwiftGodotBuilder

// MARK: - Level Select Overlay

extension Chapter27 {
  struct LevelSelectOverlay: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<ProjectState>
    let player: ObservableState<PlayerGameState>
    let progress: ObservableState<GameProgress>

    let palette = Palette.shared

    var vm: ProjectState { state.wrappedValue }

    @State var firstResponder: Button?

    var levelIds: [String] {
      vm.project.allLevels.map { $0.identifier }
    }

    var levels: [LevelData] {
      levelIds.compactMap { LevelData.data(for: $0, in: vm.project) }
    }

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("SELECT LEVEL", size: 16, color: palette.cyan)

            Spacer(4)

            // Dynamically list all levels from LDtk
            for (index, levelData) in levels.enumerated() {
              LevelRow(
                levelData: levelData,
                levelIds: levelIds,
                router: router,
                state: state,
                player: player,
                progress: progress,
                firstResponder: index == 0 ? $firstResponder : nil
              )
            }

            Spacer(4)

            AnimatedButton("Settings", width: 150, color: .gray) {
              router.scene = .settings
            }

            AnimatedButton("Leaderboard", width: 150, color: .yellow) {
              if let firstLevel = levels.first?.id {
                vm.setLeaderboardLevel(firstLevel)
              }
              router.scene = .leaderboard
            }
          }
          .theme(["separation": 2])
        }
        .theme("panel", palette.panelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .levelSelect
        if scene == .levelSelect {
          firstResponder?.grabFocus()
        }
      }
    }
  }

  // MARK: - Level Row Component

  struct LevelRow: GView {
    let levelData: LevelData
    let levelIds: [String]
    let router: ObservableState<GameRouter>
    let state: ObservableState<ProjectState>
    let player: ObservableState<PlayerGameState>
    let progress: ObservableState<GameProgress>
    var firstResponder: State<Button?>? = nil

    var vm: ProjectState { state.wrappedValue }
    var pgs: PlayerGameState { player.wrappedValue }
    var gp: GameProgress { progress.wrappedValue }

    @State var isDisabled = false
    @State var buttonRef: Button?

    let palette = Palette.shared
    let normalStyleBox: GState<StyleBoxFlat>

    init(
      levelData: LevelData,
      levelIds: [String],
      router: ObservableState<GameRouter>,
      state: ObservableState<ProjectState>,
      player: ObservableState<PlayerGameState>,
      progress: ObservableState<GameProgress>,
      firstResponder: State<Button?>? = nil
    ) {
      self.levelData = levelData
      self.levelIds = levelIds
      self.router = router
      self.state = state
      self.player = player
      self.progress = progress
      self.firstResponder = firstResponder

      normalStyleBox = _isDisabled.computed { [palette] locked in
        let isUnlocked = !locked
        return StyleBoxFlat$()
          .bgColor(isUnlocked ? palette.gray.withAlpha(0.2) : palette.darkGray.withAlpha(0.2))
          .borderColor(isUnlocked ? palette.cyan : palette.gray)
          .borderWidth(2)
          .cornerRadius(4)
          .toObject()
      }
    }

    var body: some GView {
      Button$()
        .text(levelData.name)
        .disabled($isDisabled)
        .minSize([150, 0])
        .focusMode(.all)
        .theme("normal", normalStyleBox)
        .styleBoxes(palette.cyanButtonStylesWithFocus)
        .onSignal(\.pressed) { _ in
          // Fade transition into level
          router.navigate(to: .playing, transition: .fade(duration: 0.6)) {
            vm.prepareLevel(levelData.id)
            pgs.fullReset()
          }
        }
        .ref($buttonRef)
        .watch(progress, \.levels) { _, _ in
          updateFromProgress()
        }
        .onReady { _ in
          updateFromProgress()
          // The first row will have firstResponder set, so we give focus to it
          // by setting its wrapped value here
          if firstResponder != nil {
            firstResponder?.wrappedValue = buttonRef
          }
        }
    }

    func updateFromProgress() {
      isDisabled = !gp.isLevelUnlocked(levelData.id, levelIds: levelIds)
    }
  }
}
