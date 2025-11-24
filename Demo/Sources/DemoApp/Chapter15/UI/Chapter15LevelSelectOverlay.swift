import SwiftGodot
import SwiftGodotBuilder

// MARK: - Level Select Overlay

struct Chapter15LevelSelectOverlay: GView {
  let state: ObservableState<Chapter15GameViewState>
  let progress: ObservableState<GameProgress>

  let palette = Chapter15Palette()

  var body: some GView {
    CenterContainer$ {
      PanelContainer$ {
        VBoxContainer$ {
          Label$()
            .text("CHAPTER 15")
            .horizontalAlignment(.center)
            .theme(["fontSize": 32, "fontColor": palette.cyan])

          Label$()
            .text("MULTIPLE LEVELS & LEVEL SELECT")
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.gray])

          Label$()
            .text("New Features:")
            .horizontalAlignment(.center)
            .theme(["fontSize": 16, "fontColor": palette.white])

          Label$()
            .text("• 3 Unique Handcrafted Levels\n• Level Progression System\n• Persistent Level Progress")
            .horizontalAlignment(.center)
            .theme(["fontColor": palette.lightGray])

          Chapter15LevelButton(levelData: Chapter15.levels[0], state: state, progress: progress)
          Chapter15LevelButton(levelData: Chapter15.levels[1], state: state, progress: progress)
          Chapter15LevelButton(levelData: Chapter15.levels[2], state: state, progress: progress)

          Button$()
            .text("Settings")
            .minSize([150, 0])
            .styleBoxes(palette.grayButtonStyles)
            .onSignal(\.pressed) { [state] _ in
              state.wrappedValue.gameState = .settings
            }
        }
        .theme(["separation": 3])
      }
      .styleBox("panel", palette.panelStyle)
    }
    .anchorsAndOffsets(.fullRect)
    .visible(state.isLevelSelect)
  }
}

// MARK: - Level Button Component

struct Chapter15LevelButton: GView {
  let levelData: LevelData
  let state: ObservableState<Chapter15GameViewState>
  let progress: ObservableState<GameProgress>

  let palette = Chapter15Palette()

  var isLocked: GState<Bool> {
    progress.computed { _ in
      !progress.wrappedValue.isLevelUnlocked(levelData.id)
    }
  }

  var normalStyleBox: GState<StyleBoxFlat> {
    progress.computed { _ in
      let isUnlocked = progress.wrappedValue.isLevelUnlocked(levelData.id)

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
      .disabled(isLocked)
      .minSize([200, 0])
      .theme("normal", normalStyleBox)
      .styleBoxes(palette.cyanButtonStyles)
      .onSignal(\.pressed) { [state] _ in
        state.wrappedValue.startLevel(levelData.id, totalCoins: levelData.totalCoins)
      }
  }
}
