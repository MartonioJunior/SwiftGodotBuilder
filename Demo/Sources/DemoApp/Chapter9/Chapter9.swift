import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter9Game: Node2D {
  override func _ready() {
    let rootNode = Chapter9GameView().toNode()
    addChild(node: rootNode)
  }
}

struct Chapter9GameView: GView {
  let screenWidth: Float = 800
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  @ObservableState var state = Chapter9GameViewState()

  var body: some GView {
    Node2D$ {
      // Ground platform - full width
      Chapter9Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Starting area platforms
      Chapter9Platform(x: 20, y: 120, width: 80, height: platformHeight, color: .gray)
      Chapter9Platform(x: 120, y: 90, width: 100, height: platformHeight, color: .gray)

      // Mid-section platforms
      Chapter9Platform(x: 250, y: 120, width: 100, height: platformHeight, color: .gray)
      Chapter9Platform(x: 380, y: 80, width: 80, height: platformHeight, color: .gray)
      Chapter9Platform(x: 490, y: 110, width: 90, height: platformHeight, color: .gray)

      // Upper platforms
      Chapter9Platform(x: 600, y: 90, width: 100, height: platformHeight, color: .gray)

      // Coins scattered across the level
      Chapter9Coin(position: [60, 100])
      Chapter9Coin(position: [170, 70])
      Chapter9Coin(position: [290, 100])
      Chapter9Coin(position: [320, 100])
      Chapter9Coin(position: [420, 60])
      Chapter9Coin(position: [540, 90])
      Chapter9Coin(position: [650, 70])
      Chapter9Coin(position: [680, 70])
      Chapter9Coin(position: [200, 145])
      Chapter9Coin(position: [450, 145])

      // Key on upper platform
      Chapter9Key(position: [420, 64])

      // Door at end of level (unlocking it triggers victory)
      Chapter9Door(position: [760, 133], state: $state)

      // Player
      Chapter9Player(
        spawnPoint: [40, 110],
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        gravity: gravity,
        state: $state
      )

      // Enemies spread across the level
      Chapter9Enemy(
        spawnPoint: [180, 149],
        patrolLeft: 140,
        patrolRight: 220,
        gravity: gravity,
        state: $state
      )

      Chapter9Enemy(
        spawnPoint: [280, 104],
        patrolLeft: 250,
        patrolRight: 350,
        gravity: gravity,
        state: $state
      )

      Chapter9Enemy(
        spawnPoint: [520, 94],
        patrolLeft: 490,
        patrolRight: 580,
        gravity: gravity,
        state: $state
      )

      Chapter9Enemy(
        spawnPoint: [650, 74],
        patrolLeft: 600,
        patrolRight: 700,
        gravity: gravity,
        state: $state
      )

      // UI Overlay
      Chapter9GameUI(state: $state)

      // Particle spawner
      Chapter9ParticleSpawner()

      // Audio manager
      Chapter9AudioManager(state: $state)
    }
    .onEvent(Chapter9Event.self) { _, event in
      switch event {
      case .goalReached:
        state.handleGoalReached()
      case .playerDied:
        state.handlePlayerDied()
        if state.playerLives > 0 {
          Chapter9Event.gameReset.emit()
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
      case .gameReset, .jumped, .landed, .attacked, .doorUnlocked:
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

extension Chapter9GameView {
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
    Chapter9Event.gameReset.emit()
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
