import SwiftGodot
import SwiftGodotBuilder

// MARK: - Level Select Overlay

extension Chapter18 {
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
              .text("CHAPTER 18")
              .horizontalAlignment(.center)
              .theme(["fontSize": 32, "fontColor": palette.cyan])

            Label$()
              .text("CHECKPOINTS, LIVES, GAMEPAD SUPPORT")
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.gray])

            Label$()
              .text("New Features:")
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.white])

            Label$()
              .text("• Checkpoint flags\n• Respawn at last checkpoint\n• Lives system\n• Full gamepad support")
              .horizontalAlignment(.center)
              .theme(["fontColor": palette.lightGray])

            LevelButton(levelData: Chapter18.levels[0], state: state, progress: progress, isFirst: true, firstButtonRef: $firstButton)
            LevelButton(levelData: Chapter18.levels[1], state: state, progress: progress)
            LevelButton(levelData: Chapter18.levels[2], state: state, progress: progress)
            LevelButton(levelData: Chapter18.levels[3], state: state, progress: progress)

            Button$()
              .text("[Y] Settings")
              .minSize([150, 0])
              .focusMode(.all)
              .styleBoxes(palette.grayButtonStylesWithFocus)
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.gameState = .settings
              }

            Label$()
              .text("[A] Select  [D-Pad] Navigate")
              .horizontalAlignment(.center)
              .theme(["fontColor": palette.darkGray])
          }
          .theme(["separation": 3])
        }
        .theme("panel", palette.panelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .visible(state.isLevelSelect)
      .watch(state, \.gameState) { _, gameState in
        // Grab focus on first button when level select becomes visible
        if gameState == .levelSelect {
          firstButton?.grabFocus()
        }
      }
      .onProcess { [state] _, _ in
        guard state.wrappedValue.isLevelSelect else { return }
        if Action("switch_weapon").isJustPressed {
          // Y button - Settings
          state.wrappedValue.gameState = .settings
        }
      }
    }
  }

  // MARK: - Level Button Component

  struct LevelButton: GView {
    let levelData: LevelData
    let state: ObservableState<GameViewState>
    let progress: ObservableState<GameProgress>
    var isFirst = false
    var firstButtonRef: State<Button?>? = nil

    @State var isDisabled = false

    let palette = Palette()

    var normalStyleBox: GState<StyleBoxFlat> {
      $isDisabled.computed { locked in
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
        .minSize([200, 0])
        .focusMode(.all)
        .theme("normal", normalStyleBox)
        .styleBoxes(palette.cyanButtonStylesWithFocus)
        .onSignal(\.pressed) { [state] _ in
          state.wrappedValue.startLevel(levelData.id, totalCoins: levelData.totalCoins)
        }
        .watch(progress, \.levels) { [self] _, _ in
          isDisabled = !progress.wrappedValue.isLevelUnlocked(levelData.id)
        }
        .onReady { [self] button in
          isDisabled = !progress.wrappedValue.isLevelUnlocked(levelData.id)
          if isFirst, let btn = button as? Button {
            firstButtonRef?.wrappedValue = btn
          }
        }
    }
  }
}
