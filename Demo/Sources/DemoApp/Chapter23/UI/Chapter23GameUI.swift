import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  struct GameUI: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<GameViewState>
    let settings: ObservableState<GameSettings>
    let progress: ObservableState<GameProgress>

    let palette = Palette.shared

    var body: some GView {
      CanvasLayer$ {
        HUD(router: router, state: state)
        BossHealthBar(router: router, state: state)
        SplashOverlay(router: router)
        WelcomeOverlay(router: router)
        LevelSelectOverlay(router: router, state: state, progress: progress)
        LeaderboardOverlay(router: router, state: state, progress: progress)
        PauseOverlay(router: router)
        SettingsOverlay(router: router, settings: settings, progress: progress)
        CharacterOverlay(router: router, state: state)
        LevelCompleteOverlay(router: router, state: state, progress: progress)
        DeathOverlay(router: router, state: state)
        GameOverOverlay(router: router, state: state)
        CreditsOverlay(router: router)
        DialogBox(router: router, state: state)

        // Screen flash effect
        ColorRect$()
          .color(palette.white)
          .anchorsAndOffsets(.fullRect)
          .watch(state, \.screenFlashAlpha) { [router] node, alpha in
            let isPlaying = router.scene == .playing
            let c = palette.white
            node.modulate = Color(r: c.red, g: c.green, b: c.blue, a: alpha)
            node.visible = alpha > 0 && isPlaying
          }

        // Transition overlay (on top of everything)
        SwiftGodotBuilder.TransitionManager(router: router, screenSize: [428, 240])
      }
      .processMode(.always)
      .onProcess { [router] _, _ in
        // Handle pause toggle
        if Action("pause").isJustPressed {
          switch router.scene {
          case .playing:
            router.scene = .paused
          case .paused:
            router.scene = .playing
          case .settings:
            // ESC closes settings and returns to paused state
            router.scene = .paused
          default:
            break
          }
        }
      }
    }
  }
}
