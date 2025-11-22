import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter13Game: Node2D {
  override func _ready() {
    let rootNode = Chapter13GameView().toNode()
    addChild(node: rootNode)
  }
}

struct Chapter13GameView: GView {
  let screenWidth: Float = 800
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  @ObservableState var state = Chapter13GameViewState()

  var body: some GView {
    Node2D$ {
      // Ground platform - full width
      Chapter13Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Starting area platforms
      Chapter13Platform(x: 20, y: 120, width: 80, height: platformHeight, color: .gray)
      Chapter13Platform(x: 120, y: 90, width: 100, height: platformHeight, color: .gray)

      // Mid-section platforms
      Chapter13Platform(x: 250, y: 120, width: 100, height: platformHeight, color: .gray)
      Chapter13Platform(x: 380, y: 80, width: 80, height: platformHeight, color: .gray)
      Chapter13Platform(x: 490, y: 110, width: 90, height: platformHeight, color: .gray)

      // Upper platforms
      Chapter13Platform(x: 600, y: 90, width: 100, height: platformHeight, color: .gray)

      // Coins scattered across the level
      Chapter13Coin(position: [60, 100])
      Chapter13Coin(position: [170, 70])
      Chapter13Coin(position: [290, 100])
      Chapter13Coin(position: [320, 100])
      Chapter13Coin(position: [395, 60])
      Chapter13Coin(position: [540, 90])
      Chapter13Coin(position: [650, 70])
      Chapter13Coin(position: [680, 70])
      Chapter13Coin(position: [200, 145])
      Chapter13Coin(position: [450, 145])

      // Key on upper platform
      Chapter13Key(position: [420, 64])

      // Ammo pickups scattered across the level
      Chapter13Ammo(position: [100, 145])
      Chapter13Ammo(position: [250, 100])
      Chapter13Ammo(position: [380, 60])
      Chapter13Ammo(position: [490, 90])
      Chapter13Ammo(position: [600, 70])

      // Door at end of level (unlocking it triggers victory)
      Chapter13Door(position: [760, 148], state: $state)

      // Player
      Chapter13Player(
        spawnPoint: [40, 100],
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        gravity: gravity,
        state: $state
      )

      // Enemies spread across the level

      // Ground patrol enemies (with spawners)
      Chapter13EnemySpawner(
        enemyType: .patrol,
        position: [180, 149],
        patrolLeft: 140,
        patrolRight: 220,
        gravity: gravity,
        state: $state
      )

      Chapter13Enemy(
        type: .patrol,
        spawnPoint: [520, 94],
        patrolLeft: 490,
        patrolRight: 580,
        gravity: gravity,
        state: $state
      )

      // Flying enemies (shoot projectiles)
      Chapter13Enemy(
        type: .flyer,
        spawnPoint: [300, 50],
        patrolLeft: 250,
        patrolRight: 370,
        gravity: gravity,
        state: $state
      )

      Chapter13EnemySpawner(
        enemyType: .flyer,
        position: [650, 40],
        patrolLeft: 600,
        patrolRight: 720,
        gravity: gravity,
        state: $state
      )

      // UI Overlay
      Chapter13GameUI(state: $state)

      // Particle spawner
      Chapter13ParticleSpawner()

      // Projectile manager (player)
      Chapter13ProjectileManager()

      // Enemy projectile manager
      Chapter13EnemyProjectileManager()

      // Health drop manager
      Chapter13HealthDropManager()

      // Audio manager
      Chapter13AudioManager(state: $state)
    }
    .onEvent(Chapter13Event.self) { _, event in
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
        Engine.getSceneTree()?.paused = false

      default:
        break
      }
    }
    .watch($state, \.gameState) { _, gameState in
      // Sync Engine pause state with game state
      Engine.getSceneTree()?.paused = (gameState == .paused)
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

extension Chapter13GameView {
  func handleInput() {
    // Pause toggle (only when playing or paused)
    if Action("pause").isJustPressed {
      switch state.gameState {
      case .playing:
        state.pauseGame()
      case .paused:
        state.resumeGame()
      default:
        break
      }
    }

    // Start/restart from menu, game over, or victory
    if Action("start").isJustPressed {
      switch state.gameState {
      case .menu, .gameOver, .victory:
        resetGame()
      case .playing:
        break
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
