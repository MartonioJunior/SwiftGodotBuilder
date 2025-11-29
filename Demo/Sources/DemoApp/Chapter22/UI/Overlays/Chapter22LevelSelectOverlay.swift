import SwiftGodot
import SwiftGodotBuilder

// MARK: - Level Select Overlay

extension Chapter22 {
  struct LevelSelectOverlay: GView {
    let state: ObservableState<GameViewState>
    let progress: ObservableState<GameProgress>
    let transitionState: ObservableState<TransitionState>

    let palette = Palette.shared

    @State var firstButton: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("SELECT LEVEL", size: 16, color: palette.cyan)

            Spacer(4)

            LevelRow(levelData: Chapter22.levels[0], state: state, progress: progress, transitionState: transitionState, isFirst: true, firstButtonRef: $firstButton)
            LevelRow(levelData: Chapter22.levels[1], state: state, progress: progress, transitionState: transitionState)
            LevelRow(levelData: Chapter22.levels[2], state: state, progress: progress, transitionState: transitionState)
            LevelRow(levelData: Chapter22.levels[3], state: state, progress: progress, transitionState: transitionState)

            Spacer(4)

            AnimatedButton("[Y] Settings", width: 150, color: .gray) {
              state.wrappedValue.gameState = .settings
            }

            AnimatedButton("[X] Leaderboard", width: 150, color: .yellow) {
              state.wrappedValue.showLeaderboard(for: 1)
            }

            InfoLabel("[A] Select  [D-Pad] Navigate")
          }
          .theme(["separation": 2])
        }
        .theme("panel", palette.panelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .visible(state.isLevelSelect)
      .watch(state, \.gameState) { _, gameState in
        if gameState == .levelSelect {
          firstButton?.grabFocus()
        }
      }
      .onProcess { [state] _, _ in
        guard state.wrappedValue.isLevelSelect else { return }
        if Action("switch_weapon").isJustPressed {
          state.wrappedValue.gameState = .settings
        }
        if Action("attack").isJustPressed {
          state.wrappedValue.showLeaderboard(for: 1)
        }
      }
    }
  }

  // MARK: - Level Row Component

  struct LevelRow: GView {
    let levelData: LevelData
    let state: ObservableState<GameViewState>
    let progress: ObservableState<GameProgress>
    let transitionState: ObservableState<TransitionState>
    var isFirst = false
    var firstButtonRef: State<Button?>? = nil

    @State var isDisabled = false
    @State var buttonRef: Button?

    let palette = Palette.shared

    var normalStyleBox: GState<StyleBoxFlat> {
      $isDisabled.computed { [palette] locked in
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
        .onSignal(\.pressed) { [state, transitionState, levelData] _ in
          // Fade transition into level
          transitionState.wrappedValue.fadeTransition(
            duration: 0.6,
            onMidpoint: {
              state.wrappedValue.startLevel(levelData.id, totalCoins: levelData.totalCoins)
            }
          )
        }
        .ref($buttonRef)
        .watch(progress, \.levels) { _, _ in
          updateFromProgress()
        }
        .onReady { _ in
          updateFromProgress()
          if isFirst {
            firstButtonRef?.wrappedValue = buttonRef
          }
        }
    }

    func updateFromProgress() {
      isDisabled = !progress.wrappedValue.isLevelUnlocked(levelData.id)
    }
  }
}
