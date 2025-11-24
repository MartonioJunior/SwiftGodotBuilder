import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter14Game: Node2D {
  override func _ready() {
    let rootNode = Chapter14GameView().toNode()
    addChild(node: rootNode)
  }
}

struct Chapter14GameView: GView {
  let screenWidth: Float = 800
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  @ObservableState var state = Chapter14GameViewState()
  @ObservableState var settings = GameSettings()

  var body: some GView {
    Node2D$ {
      // Ground platform - full width
      Chapter14Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Starting area platforms
      Chapter14Platform(x: 20, y: 120, width: 80, height: platformHeight, color: .gray)
      Chapter14Platform(x: 120, y: 90, width: 100, height: platformHeight, color: .gray)

      // Mid-section platforms
      Chapter14Platform(x: 250, y: 120, width: 100, height: platformHeight, color: .gray)
      Chapter14Platform(x: 380, y: 80, width: 80, height: platformHeight, color: .gray)
      Chapter14Platform(x: 490, y: 110, width: 90, height: platformHeight, color: .gray)

      // Upper platforms
      Chapter14Platform(x: 600, y: 90, width: 100, height: platformHeight, color: .gray)

      // Coins scattered across the level
      Chapter14Coin(position: [60, 100])
      Chapter14Coin(position: [170, 70])
      Chapter14Coin(position: [290, 100])
      Chapter14Coin(position: [320, 100])
      Chapter14Coin(position: [395, 60])
      Chapter14Coin(position: [540, 90])
      Chapter14Coin(position: [650, 70])
      Chapter14Coin(position: [680, 70])
      Chapter14Coin(position: [200, 145])
      Chapter14Coin(position: [450, 145])

      // Key on upper platform
      Chapter14Key(position: [420, 64])

      // Ammo pickups scattered across the level
      Chapter14Ammo(position: [100, 145])
      Chapter14Ammo(position: [250, 100])
      Chapter14Ammo(position: [380, 60])
      Chapter14Ammo(position: [490, 90])
      Chapter14Ammo(position: [600, 70])

      // Door at end of level (unlocking it triggers victory)
      Chapter14Door(position: [760, 148], state: $state)

      // Player
      Chapter14Player(
        spawnPoint: [40, 100],
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        gravity: gravity,
        state: $state
      )

      // Enemies spread across the level

      // Ground patrol enemies (with spawners)
      Chapter14EnemySpawner(
        enemyType: .patrol,
        position: [180, 149],
        patrolLeft: 140,
        patrolRight: 220,
        gravity: gravity,
        state: $state
      )

      Chapter14Enemy(
        type: .patrol,
        spawnPoint: [520, 94],
        patrolLeft: 490,
        patrolRight: 580,
        gravity: gravity,
        state: $state
      )

      // Flying enemies (shoot projectiles)
      Chapter14Enemy(
        type: .flyer,
        spawnPoint: [300, 50],
        patrolLeft: 250,
        patrolRight: 370,
        gravity: gravity,
        state: $state
      )

      Chapter14EnemySpawner(
        enemyType: .flyer,
        position: [650, 40],
        patrolLeft: 600,
        patrolRight: 720,
        gravity: gravity,
        state: $state
      )

      // UI Overlay
      Chapter14GameUI(state: $state, settings: $settings)

      // Particle spawner
      Chapter14ParticleSpawner()

      // Projectile manager (player)
      Chapter14ProjectileManager()

      // Enemy projectile manager
      Chapter14EnemyProjectileManager()

      // Health drop manager
      Chapter14HealthDropManager()

      // Audio manager
      Chapter14AudioManager(state: $state, settings: $settings)
    }
    .onEvent(Chapter14Event.self) { _, event in
      switch event {
      case .goalReached:
        state.handleGoalReached()
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

      // Engine synchronization - keep state pure by handling runtime here
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
      // Sync Engine pause state with game state
      Engine.getSceneTree()?.paused = (gameState == .paused)
    }
    .onReady { _ in
      // Apply fullscreen setting on startup
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

// MARK: - Game Logic

extension Chapter14GameView {
  func handleInput() {
    // Start/restart from menu, game over, or victory
    if Action("start").isJustPressed {
      switch state.gameState {
      case .menu, .gameOver, .victory:
        resetGame()
      default:
        break
      }
    }
  }

  func resetGame() {
    state.reset()
    Engine.onNextFrame {
      state.gameState = .playing
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
