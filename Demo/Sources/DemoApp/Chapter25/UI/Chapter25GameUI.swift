import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct GameUI: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<GameViewState>
    let settings: ObservableState<GameSettings>
    let progress: ObservableState<GameProgress>

    let palette = Palette.shared

    var screenSize: Vector2 {
      let w = ProjectSettings.getSetting(name: "display/window/size/viewport_width", defaultValue: Variant(240))
      let h = ProjectSettings.getSetting(name: "display/window/size/viewport_height", defaultValue: Variant(135))
      return [Float(Int(w) ?? 240), Float(Int(h) ?? 135)]
    }

    var body: some GView {
      CanvasLayer$ {
        HUD(router: router, state: state)
        BossHealthBarView(router: router, state: state)
        SplashOverlay(router: router)
        WelcomeOverlay(router: router)
        LevelSelectOverlay(router: router, state: state, progress: progress)
        LeaderboardOverlay(router: router, state: state, progress: progress)
        PauseOverlay(router: router)
        SettingsOverlay(router: router, settings: settings, progress: progress)
        LevelCompleteOverlay(router: router, state: state, progress: progress)
        DeathOverlay(router: router, state: state)
        GameOverOverlay(router: router, state: state)
        CreditsOverlay(router: router)
        DialogBox(router: router, state: state)

        // Screen flash effect
        ColorRect$()
          .color(palette.white)
          .anchorsAndOffsets(.fullRect)
          .watch(state, \.screenFlashAlpha) { node, alpha in
            let isPlaying = router.scene == .playing
            let c = palette.white
            node.modulate = Color(r: c.red, g: c.green, b: c.blue, a: alpha)
            node.visible = alpha > 0 && isPlaying
          }

        // Transition overlay (on top of everything)
        SwiftGodotBuilder.TransitionManager(router: router, screenSize: screenSize)
      }
      .processMode(.always)
      .onProcess { _, _ in
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
