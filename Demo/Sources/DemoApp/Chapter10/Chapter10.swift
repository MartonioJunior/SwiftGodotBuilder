import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter10Game: Node2D {
  override func _ready() {
    let rootNode = Chapter10GameView().toNode()
    addChild(node: rootNode)
  }
}

struct Chapter10GameView: GView {
  let screenWidth: Float = 800
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  @ObservableState var state = Chapter10GameViewState()

  var body: some GView {
    Node2D$ {
      // Ground platform - full width
      Chapter10Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Starting area platforms
      Chapter10Platform(x: 20, y: 120, width: 80, height: platformHeight, color: .gray)
      Chapter10Platform(x: 120, y: 90, width: 100, height: platformHeight, color: .gray)

      // Mid-section platforms
      Chapter10Platform(x: 250, y: 120, width: 100, height: platformHeight, color: .gray)
      Chapter10Platform(x: 380, y: 80, width: 80, height: platformHeight, color: .gray)
      Chapter10Platform(x: 490, y: 110, width: 90, height: platformHeight, color: .gray)

      // Upper platforms
      Chapter10Platform(x: 600, y: 90, width: 100, height: platformHeight, color: .gray)

      // Coins scattered across the level
      Chapter10Coin(position: [60, 100])
      Chapter10Coin(position: [170, 70])
      Chapter10Coin(position: [290, 100])
      Chapter10Coin(position: [320, 100])
      Chapter10Coin(position: [420, 60])
      Chapter10Coin(position: [540, 90])
      Chapter10Coin(position: [650, 70])
      Chapter10Coin(position: [680, 70])
      Chapter10Coin(position: [200, 145])
      Chapter10Coin(position: [450, 145])

      // Key on upper platform
      Chapter10Key(position: [420, 64])

      // Ammo pickups scattered across the level
      Chapter10Ammo(position: [100, 145])
      Chapter10Ammo(position: [250, 100])
      Chapter10Ammo(position: [380, 60])
      Chapter10Ammo(position: [490, 90])
      Chapter10Ammo(position: [600, 70])

      // Door at end of level (unlocking it triggers victory)
      Chapter10Door(position: [760, 133], state: $state)

      // Player
      Chapter10Player(
        spawnPoint: [40, 110],
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        gravity: gravity,
        state: $state
      )

      // Enemies spread across the level
      Chapter10Enemy(
        spawnPoint: [180, 149],
        patrolLeft: 140,
        patrolRight: 220,
        gravity: gravity,
        state: $state
      )

      Chapter10Enemy(
        spawnPoint: [280, 104],
        patrolLeft: 250,
        patrolRight: 350,
        gravity: gravity,
        state: $state
      )

      Chapter10Enemy(
        spawnPoint: [520, 94],
        patrolLeft: 490,
        patrolRight: 580,
        gravity: gravity,
        state: $state
      )

      Chapter10Enemy(
        spawnPoint: [650, 74],
        patrolLeft: 600,
        patrolRight: 700,
        gravity: gravity,
        state: $state
      )

      // UI Overlay
      Chapter10GameUI(state: $state)

      // Particle spawner
      Chapter10ParticleSpawner()

      // Projectile manager
      Chapter10ProjectileManager()

      // Audio manager
      Chapter10AudioManager(state: $state)
    }
    .onEvent(Chapter10Event.self) { _, event in
      switch event {
      case .goalReached:
        state.handleGoalReached()
      case .playerDied:
        state.handlePlayerDied()
        if state.playerLives > 0 {
          Chapter10Event.gameReset.emit()
        }
      case .enemyKilled:
        state.handleEnemyKilled()
        applyScreenShake(intensity: 0.3)
      case .playerHit:
        applyScreenShake(intensity: 0.5)
        applyScreenFlash()
      case .coinCollected:
        state.handleCoinCollected()
      case .keyCollected:
        state.handleKeyCollected()
      case .ammoCollected:
        state.handleAmmoCollected()
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

extension Chapter10GameView {
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
    Chapter10Event.gameReset.emit()
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
