import SwiftGodot
import SwiftGodotBuilder

// MARK: - Level Select Overlay

extension Chapter19 {
  struct LevelSelectOverlay: GView {
    let state: ObservableState<GameViewState>
    let progress: ObservableState<GameProgress>

    let palette = Palette()

    @State var firstButton: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            Label$()
              .text("CHAPTER 19")
              .horizontalAlignment(.center)
              .theme(["fontSize": 32, "fontColor": palette.cyan])

            Label$()
              .text("SPEEDRUN & TIME ATTACK")
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.gold])

            Label$()
              .text("New Features:")
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.white])

            Label$()
              .text("• Time-based medals\n• Best time tracking\n• Local leaderboards\n• Medal targets in HUD")
              .horizontalAlignment(.center)
              .theme(["fontColor": palette.lightGray])

            Control$().minSize([0, 4])

            LevelRow(levelData: Chapter19.levels[0], state: state, progress: progress, isFirst: true, firstButtonRef: $firstButton)
            LevelRow(levelData: Chapter19.levels[1], state: state, progress: progress)
            LevelRow(levelData: Chapter19.levels[2], state: state, progress: progress)
            LevelRow(levelData: Chapter19.levels[3], state: state, progress: progress)

            Control$().minSize([0, 4])

            Button$()
              .text("[Y] Settings")
              .minSize([150, 0])
              .focusMode(.all)
              .styleBoxes(palette.grayButtonStylesWithFocus)
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.gameState = .settings
              }

            Label$()
              .text("[A] Select  [X] Leaderboard  [D-Pad] Navigate")
              .horizontalAlignment(.center)
              .theme(["fontColor": palette.darkGray])
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
      }
    }
  }

  // MARK: - Level Row Component

  struct LevelRow: GView {
    let levelData: LevelData
    let state: ObservableState<GameViewState>
    let progress: ObservableState<GameProgress>
    var isFirst = false
    var firstButtonRef: State<Button?>? = nil

    @State var isDisabled = false
    @State var bestTime = "--:--.--"
    @State var medal = ""
    @State var buttonRef: Button?

    let palette = Palette()

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
      HBoxContainer$ {
        Button$()
          .text(levelData.name)
          .disabled($isDisabled)
          .minSize([150, 0])
          .focusMode(.all)
          .theme("normal", normalStyleBox)
          .styleBoxes(palette.cyanButtonStylesWithFocus)
          .onSignal(\.pressed) { [state] _ in
            state.wrappedValue.startLevel(levelData.id, totalCoins: levelData.totalCoins)
          }
          .ref($buttonRef)

        Label$()
          .text($medal)
          .minSize([24, 0])

        Label$()
          .text($bestTime)
          .minSize([64, 0])
          .theme(["fontColor": palette.white])

        Button$()
          .text("LB")
          .disabled($isDisabled)
          .minSize([32, 0])
          .focusMode(.all)
          .styleBoxes(palette.yellowButtonStylesWithFocus)
          .onSignal(\.pressed) { [state] _ in
            state.wrappedValue.showLeaderboard(for: levelData.id)
          }
      }
      .theme(["separation": 4])
      .watch(progress, \.levels) { [self] _, _ in
        updateFromProgress()
      }
      .onReady { [self] _ in
        updateFromProgress()
        if isFirst {
          firstButtonRef?.wrappedValue = buttonRef
        }
      }
    }

    func updateFromProgress() {
      isDisabled = !progress.wrappedValue.isLevelUnlocked(levelData.id)
      let levelProgress = progress.wrappedValue.getProgress(for: levelData.id)
      bestTime = levelProgress.bestTimeFormatted
      medal = levelProgress.bestMedal.rawValue
    }
  }
}
