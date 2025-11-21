import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter12Game: Node2D {
  override func _ready() {
    let rootNode = Chapter12GameView().toNode()
    addChild(node: rootNode)
  }
}

struct Chapter12GameView: GView {
  let screenWidth: Float = 800
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  @ObservableState var state = Chapter12GameViewState()

  var body: some GView {
    Node2D$ {
      // Ground platform - full width
      Chapter12Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Starting area platforms
      Chapter12Platform(x: 20, y: 120, width: 80, height: platformHeight, color: .gray)
      Chapter12Platform(x: 120, y: 90, width: 100, height: platformHeight, color: .gray)

      // Mid-section platforms
      Chapter12Platform(x: 250, y: 120, width: 100, height: platformHeight, color: .gray)
      Chapter12Platform(x: 380, y: 80, width: 80, height: platformHeight, color: .gray)
      Chapter12Platform(x: 490, y: 110, width: 90, height: platformHeight, color: .gray)

      // Upper platforms
      Chapter12Platform(x: 600, y: 90, width: 100, height: platformHeight, color: .gray)

      // Coins scattered across the level
      Chapter12Coin(position: [60, 100])
      Chapter12Coin(position: [170, 70])
      Chapter12Coin(position: [290, 100])
      Chapter12Coin(position: [320, 100])
      Chapter12Coin(position: [395, 60])
      Chapter12Coin(position: [540, 90])
      Chapter12Coin(position: [650, 70])
      Chapter12Coin(position: [680, 70])
      Chapter12Coin(position: [200, 145])
      Chapter12Coin(position: [450, 145])

      // Key on upper platform
      Chapter12Key(position: [420, 64])

      // Ammo pickups scattered across the level
      Chapter12Ammo(position: [100, 145])
      Chapter12Ammo(position: [250, 100])
      Chapter12Ammo(position: [380, 60])
      Chapter12Ammo(position: [490, 90])
      Chapter12Ammo(position: [600, 70])

      // Door at end of level (unlocking it triggers victory)
      Chapter12Door(position: [760, 148], state: $state)

      // Player
      Chapter12Player(
        spawnPoint: [40, 100],
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        gravity: gravity,
        state: $state
      )

      // Enemies spread across the level

      // Ground patrol enemies (with spawners)
      Chapter12EnemySpawner(
        enemyType: .patrol,
        position: [180, 149],
        patrolLeft: 140,
        patrolRight: 220,
        gravity: gravity,
        state: $state
      )

      Chapter12Enemy(
        type: .patrol,
        spawnPoint: [520, 94],
        patrolLeft: 490,
        patrolRight: 580,
        gravity: gravity,
        state: $state
      )

      // Flying enemies (shoot projectiles)
      Chapter12Enemy(
        type: .flyer,
        spawnPoint: [300, 50],
        patrolLeft: 250,
        patrolRight: 370,
        gravity: gravity,
        state: $state
      )

      Chapter12EnemySpawner(
        enemyType: .flyer,
        position: [650, 40],
        patrolLeft: 600,
        patrolRight: 720,
        gravity: gravity,
        state: $state
      )

      // UI Overlay
      Chapter12GameUI(state: $state)

      // Particle spawner
      Chapter12ParticleSpawner()

      // Projectile manager (player)
      Chapter12ProjectileManager()

      // Enemy projectile manager
      Chapter12EnemyProjectileManager()

      // Health drop manager
      Chapter12HealthDropManager()

      // Audio manager
      Chapter12AudioManager(state: $state)
    }
    .onEvent(Chapter12Event.self) { _, event in
      switch event {
      case .goalReached:
        state.handleGoalReached()
      case .playerDied:
        state.handlePlayerDied()
        if state.playerLives > 0 {
          Chapter12Event.gameReset.emit()
        }
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
        state.playerHealth = min(state.playerHealth + 1, state.maxHealth)
      default:
        break
      }
    }
    .onReady { _ in
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

extension Chapter12GameView {
  func handleInput() {
    if Action("start").isJustPressed {
      switch state.gameState {
      case .menu, .gameOver, .victory:
        resetGame()
      case .playing:
        break
      }
    }
  }

  func resetGame() {
    Chapter12Event.gameReset.emit()
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
