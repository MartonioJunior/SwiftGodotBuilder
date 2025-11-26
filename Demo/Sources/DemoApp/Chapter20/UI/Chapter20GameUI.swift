import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  struct GameUI: GView {
    let state: ObservableState<GameViewState>
    let settings: ObservableState<GameSettings>
    let progress: ObservableState<GameProgress>

    let palette = Palette()

    var body: some GView {
      CanvasLayer$ {
        HUD(state: state)
        BossHealthBar(state: state)
        LevelSelectOverlay(state: state, progress: progress)
        LeaderboardOverlay(state: state, progress: progress)
        PauseOverlay(state: state)
        SettingsOverlay(state: state, settings: settings, progress: progress)
        CharacterOverlay(state: state)
        LevelCompleteOverlay(state: state, progress: progress)
        GameOverOverlay(state: state)
        DialogBox(state: state)

        // Screen flash effect
        ColorRect$()
          .color(palette.white)
          .anchorsAndOffsets(.fullRect)
          .watch(state, \.screenFlashAlpha) { [state] node, alpha in
            let isPlaying = state.wrappedValue.isPlaying
            let c = palette.white
            node.modulate = Color(r: c.red, g: c.green, b: c.blue, a: alpha)
            node.visible = alpha > 0 && isPlaying
          }
      }
      .processMode(.always)
      .onProcess { [state] _, _ in
        // Handle pause toggle
        if Action("pause").isJustPressed {
          switch state.wrappedValue.gameState {
          case .playing:
            state.wrappedValue.pauseGame()
          case .paused:
            state.wrappedValue.resumeGame()
          case .settings:
            // ESC closes settings and returns to paused state
            state.wrappedValue.gameState = .paused
          default:
            break
          }
        }
      }
    }
  }
}
