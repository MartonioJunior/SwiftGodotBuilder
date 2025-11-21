import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter6Game: Node2D {
  override func _ready() {
    let rootNode = Chapter6GameView().toNode()
    addChild(node: rootNode)
  }
}

struct Chapter6GameView: GView {
  let screenWidth: Float = 800
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  @ObservableState var state = Chapter6GameViewState()

  var body: some GView {
    Node2D$ {
      // Ground platform - full width
      Chapter6Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Starting area platforms
      Chapter6Platform(x: 20, y: 120, width: 80, height: platformHeight, color: .gray)
      Chapter6Platform(x: 120, y: 90, width: 100, height: platformHeight, color: .gray)

      // Mid-section platforms
      Chapter6Platform(x: 250, y: 120, width: 100, height: platformHeight, color: .gray)
      Chapter6Platform(x: 380, y: 80, width: 80, height: platformHeight, color: .gray)
      Chapter6Platform(x: 490, y: 110, width: 90, height: platformHeight, color: .gray)

      // Upper platforms
      Chapter6Platform(x: 600, y: 90, width: 100, height: platformHeight, color: .gray)

      // Goal area (green) - at the far right
      Chapter6Goal(x: 760, y: 145, size: 20)

      // Player
      Chapter6Player(
        spawnPoint: [40, 110],
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        gravity: gravity,
        state: $state
      )

      // Enemies spread across the level
      Chapter6Enemy(
        spawnPoint: [180, 149],
        patrolLeft: 140,
        patrolRight: 220,
        gravity: gravity,
        state: $state
      )

      Chapter6Enemy(
        spawnPoint: [280, 104],
        patrolLeft: 250,
        patrolRight: 350,
        gravity: gravity,
        state: $state
      )

      Chapter6Enemy(
        spawnPoint: [520, 94],
        patrolLeft: 490,
        patrolRight: 580,
        gravity: gravity,
        state: $state
      )

      Chapter6Enemy(
        spawnPoint: [650, 74],
        patrolLeft: 600,
        patrolRight: 700,
        gravity: gravity,
        state: $state
      )

      // UI Overlay
      Chapter6GameUI(state: $state)

      // Particle spawner
      Chapter6ParticleSpawner()
    }
    .onEvent(Chapter6Event.self) { _, event in
      switch event {
      case .goalReached:
        state.handleGoalReached()
      case .playerDied:
        state.handlePlayerDied()
        if state.playerLives > 0 {
          Chapter6Event.resetGame.emit()
        }
      case .enemyKilled:
        state.handleEnemyKilled()
        Chapter6Event.screenShake(intensity: 0.3).emit()
      case .playerHit:
        Chapter6Event.screenShake(intensity: 0.5).emit()
        Chapter6Event.screenFlash.emit()
      case .resetGame, .spawnParticles:
        break
      case let .screenShake(intensity):
        applyScreenShake(intensity: intensity)
      case .screenFlash:
        applyScreenFlash()
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

extension Chapter6GameView {
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
    Chapter6Event.resetGame.emit()
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
