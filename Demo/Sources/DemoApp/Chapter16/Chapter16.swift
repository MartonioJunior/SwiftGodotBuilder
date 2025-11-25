import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter16Game: Node2D {
  override func _ready() {
    let rootNode = Chapter16.GameView().toNode()
    addChild(node: rootNode)
  }
}

extension Chapter16 {
  struct GameView: GView {
    let screenWidth: Float = 800
    let screenHeight: Float = 180
    let platformHeight: Float = 8
    let gravity: Float = 400

    @ObservableState var state = GameViewState()
    @ObservableState var settings = GameSettings()
    @ObservableState var progress = GameProgress()

    var playerSpawnPoint: Vector2 {
      Chapter16.getLevelData(state.currentLevelId)?.playerSpawnPoint ?? [40, 100]
    }

    var body: some GView {
      Node2D$ {
        // Levels
        Switch($state.currentLevelId) {
          Case(1) {
            Level1(state: $state)
          }
          Case(2) {
            Level2(state: $state)
          }
          Case(3) {
            Level3(state: $state)
          }
          Case(4) {
            Level4(state: $state)
          }
        }
        .mode(.destroy)

        // Shared player that works across all levels
        Player(
          spawnPoint: playerSpawnPoint,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          gravity: gravity,
          state: $state
        )

        // UI Overlay
        GameUI(state: $state, settings: $settings, progress: $progress)

        // Particle spawner
        ParticleSpawner()

        // Projectile manager (player)
        ProjectileManager()

        // Enemy projectile manager
        EnemyProjectileManager()

        // Health drop manager
        HealthDropManager()

        // Audio manager
        AudioManager(state: $state, settings: $settings)
      }
      .onEvent(Event.self) { _, event in
        switch event {
        case .goalReached:
          state.handleGoalReached(progress: progress)
        case .playerDied:
          state.handlePlayerDied()
        case .enemyKilled:
          state.handleEnemyKilled()
        case .playerHit:
          applyScreenShake(intensity: 0.5)
          applyScreenFlash()
        case .coinCollected:
          state.handleCoinCollected()
        case .keyCollected:
          state.handleKeyCollected()
        case .ammoCollected:
          state.handleAmmoCollected()
        case .healthCollected:
          state.handleHealthCollected()
        case .bossHit:
          applyScreenShake(intensity: 0.3)
        case .bossPhaseChanged:
          applyScreenShake(intensity: 1.0)
          applyScreenFlash()
        case .bossDefeated:
          applyScreenShake(intensity: 1.5)
        case .gameReset:
          // Pause physics briefly during reset to prevent collisions while repositioning
          Engine.getSceneTree()?.paused = true
          Engine.onNextFrame {
            Engine.getSceneTree()?.paused = false
          }
        default:
          break
        }
      }
      .watch($state, \.gameState) { _, gameState in
        Engine.getSceneTree()?.paused = (gameState == .paused)
      }
      .onReady { _ in
        DisplayServer.windowSetMode(settings.fullscreen ? .fullscreen : .windowed)

        Actions {
          Action("move_left") {
            Key(.a)
            Key(.left)
          }

          Action("move_right") {
            Key(.d)
            Key(.right)
          }

          Action("jump") {
            Key(.space)
            Key(.w)
            Key(.up)
          }

          Action("attack") {
            Key(.x)
          }

          Action("dash") {
            Key(.shift)
          }

          Action("switch_weapon") {
            Key(.q)
          }

          Action("start") {
            Key(.space)
          }

          Action("pause") {
            Key(.escape)
          }

          Action("character_sheet") {
            Key(.tab)
          }
        }.install()
      }
      .onProcess { _, delta in
        handleInput()
        if state.isPlaying {
          state.playTime += delta
        }

        // Decay camera shake
        if state.cameraOffset.length() > 0.01 {
          state.cameraOffset = state.cameraOffset.lerp(to: .zero, weight: 10.0 * delta)
        } else if state.cameraOffset != .zero {
          state.cameraOffset = .zero
        }

        // Decay screen flash
        if state.screenFlashAlpha > 0 {
          state.screenFlashAlpha = max(0, state.screenFlashAlpha - Float(delta) * 3.0)
        }
      }
    }
  }
}

// MARK: - Game Logic

extension Chapter16.GameView {
  func handleInput() {
    // Start/restart from level select, game over, or level complete
    if Action("start").isJustPressed {
      switch state.gameState {
      case .levelSelect, .gameOver, .levelComplete:
        if let levelData = Chapter16.getLevelData(state.currentLevelId) {
          state.startLevel(state.currentLevelId, totalCoins: levelData.totalCoins)
        }
      default:
        break
      }
    }
  }

  func applyScreenShake(intensity: Float) {
    // Random shake offset
    let angle = Float.random(in: 0 ..< Float.pi * 2)
    let distance = intensity * 10.0
    state.cameraOffset = Vector2(
      x: cos(angle) * distance,
      y: sin(angle) * distance
    )

    // Hit pause/freeze frame effect
    Engine.timeScale = 0.0
    Engine.onNextFrame {
      Engine.timeScale = 1.0
    }
  }

  func applyScreenFlash() {
    state.screenFlashAlpha = 0.5
  }
}
