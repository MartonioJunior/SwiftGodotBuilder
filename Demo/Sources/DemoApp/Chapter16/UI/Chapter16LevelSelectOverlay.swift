import SwiftGodot
import SwiftGodotBuilder

// MARK: - Level Select Overlay

extension Chapter16 {
  struct LevelSelectOverlay: GView {
    let state: ObservableState<GameViewState>
    let progress: ObservableState<GameProgress>

    let palette = Palette()

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            Label$()
              .text("CHAPTER 16")
              .horizontalAlignment(.center)
              .theme(["fontSize": 32, "fontColor": palette.cyan])

            Label$()
              .text("BOSS FIGHT")
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.gray])

            Label$()
              .text("New Features:")
              .horizontalAlignment(.center)
              .theme(["fontSize": 16, "fontColor": palette.white])

            Label$()
              .text("• 4 Unique Levels + Boss Fight\n• Level Progression System\n• Persistent Level Progress")
              .horizontalAlignment(.center)
              .theme(["fontColor": palette.lightGray])

            LevelButton(levelData: Chapter16.levels[0], state: state, progress: progress)
            LevelButton(levelData: Chapter16.levels[1], state: state, progress: progress)
            LevelButton(levelData: Chapter16.levels[2], state: state, progress: progress)
            LevelButton(levelData: Chapter16.levels[3], state: state, progress: progress)

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
        .theme("panel", palette.panelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .visible(state.isLevelSelect)
    }
  }

  // MARK: - Level Button Component

  struct LevelButton: GView {
    let levelData: LevelData
    let state: ObservableState<GameViewState>
    let progress: ObservableState<GameProgress>

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
        .theme("normal", normalStyleBox)
        .styleBoxes(palette.cyanButtonStyles)
        .onSignal(\.pressed) { [state] _ in
          state.wrappedValue.startLevel(levelData.id, totalCoins: levelData.totalCoins)
        }
        .watch(progress, \.levels) { [self] _, _ in
          isDisabled = !progress.wrappedValue.isLevelUnlocked(levelData.id)
        }
        .onReady { [self] _ in
          isDisabled = !progress.wrappedValue.isLevelUnlocked(levelData.id)
        }
    }
  }
}
