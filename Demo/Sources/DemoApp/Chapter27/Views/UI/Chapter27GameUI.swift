import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct GameUI: GView {
    let router: ObservableState<GameRouter>
    let state: ObservableState<ProjectState>
    let player: ObservableState<PlayerGameState>
    let boss: ObservableState<BossState>
    let dialog: ObservableState<DialogGameState>
    let settings: ObservableState<UserSettings>
    let progress: ObservableState<GameProgress>

    let palette = Palette.shared

    var screenSize: Vector2 {
      let w = ProjectSettings.getSetting(name: "display/window/size/viewport_width", defaultValue: Variant(240))
      let h = ProjectSettings.getSetting(name: "display/window/size/viewport_height", defaultValue: Variant(135))
      return [Float(Int(w) ?? 240), Float(Int(h) ?? 135)]
    }

    var body: some GView {
      CanvasLayer$ {
        HUD(router: router, player: player)
        BossHealthBarView(boss: boss)
        SplashOverlay(router: router)
        WelcomeOverlay(router: router)
        LevelSelectOverlay(router: router, state: state, player: player, progress: progress)
        LeaderboardOverlay(router: router, state: state, progress: progress)
        PauseOverlay(router: router)
        SettingsOverlay(router: router, settings: settings, progress: progress)
        LevelCompleteOverlay(router: router, state: state, player: player, progress: progress)
        DeathOverlay(
          router: router,
          livesText: player.wrappedValue.livesRemainingText,
          onRespawn: {
            router.navigate(to: .playing, transition: .iris(duration: 0.8, center: [0.5, 0.5])) {
              state.wrappedValue.respawnAfterDeath()
            }
          }
        )
        GameOverOverlay(router: router, state: state, player: player)
        CreditsOverlay(router: router)
        DialogBox(router: router, dialog: dialog)

        // Screen flash effect - triggered by events, uses tween for smooth fade
        ColorRect$()
          .color(palette.white)
          .anchorsAndOffsets(.fullRect)
          .visible(false)
          .onEvent(GameEvent.self) { node, event in
            let shouldFlash: Bool
            switch event {
            case .playerTookDamage, .bossPhaseChanged:
              shouldFlash = router.scene == .playing
            case .gameReset:
              node.visible = false
              return
            default:
              shouldFlash = false
            }
            if shouldFlash {
              node.visible = true
              node.modulate = Color(r: 1, g: 1, b: 1, a: 0.5)
              node.tween(.alpha(0), duration: 0.17)
                .onFinished { node.visible = false }
            }
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
