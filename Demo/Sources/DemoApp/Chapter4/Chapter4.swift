import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter4Game: Node2D {
  override func _ready() {
    let rootNode = Chapter4GameView().toNode()
    addChild(node: rootNode)
  }
}

struct Chapter4GameView: GView {
  let screenWidth: Float = 800 // Wider level for camera scrolling
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  // Game state
  @State var gameState: Chapter4GameState = .menu
  @State var playerHealth: Int = 3
  @State var playerLives: Int = 3
  @State var score: Int = 0
  @State var playTime: Double = 0

  // Camera effects
  @State var cameraOffset: Vector2 = .zero
  @State var screenFlashAlpha: Float = 0

  var body: some GView {
    Node2D$ {
      // Ground platform - full width
      Chapter4Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Starting area platforms
      Chapter4Platform(x: 20, y: 120, width: 80, height: platformHeight, color: .gray)
      Chapter4Platform(x: 120, y: 90, width: 100, height: platformHeight, color: .gray)

      // Mid-section platforms
      Chapter4Platform(x: 250, y: 120, width: 100, height: platformHeight, color: .gray)
      Chapter4Platform(x: 380, y: 80, width: 80, height: platformHeight, color: .gray)
      Chapter4Platform(x: 490, y: 110, width: 90, height: platformHeight, color: .gray)

      // Upper platforms
      Chapter4Platform(x: 600, y: 90, width: 100, height: platformHeight, color: .gray)

      // Goal area (green) - at the far right
      Chapter4Goal(x: 760, y: 145, size: 20)

      // Player
      Chapter4Player(
        spawnPoint: [40, 110],
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        gravity: gravity,
        gameState: $gameState,
        health: $playerHealth,
        cameraOffset: $cameraOffset
      )

      // Enemies spread across the level
      Chapter4Enemy(
        spawnPoint: [180, 149],
        patrolLeft: 140,
        patrolRight: 220,
        gravity: gravity,
        gameState: $gameState
      )

      Chapter4Enemy(
        spawnPoint: [280, 104],
        patrolLeft: 250,
        patrolRight: 350,
        gravity: gravity,
        gameState: $gameState
      )

      Chapter4Enemy(
        spawnPoint: [520, 94],
        patrolLeft: 490,
        patrolRight: 580,
        gravity: gravity,
        gameState: $gameState
      )

      Chapter4Enemy(
        spawnPoint: [650, 74],
        patrolLeft: 600,
        patrolRight: 700,
        gravity: gravity,
        gameState: $gameState
      )

      // UI Overlay
      Chapter4GameUI(
        gameState: $gameState,
        playerHealth: $playerHealth,
        playerLives: $playerLives,
        score: $score,
        playTime: $playTime,
        maxHealth: 3,
        screenFlashAlpha: $screenFlashAlpha
      )
    }
    .onEvent(Chapter4Event.self) { _, event in
      switch event {
      case .goalReached:
        if gameState == .playing {
          score += 100 // Bonus for reaching goal
          gameState = .victory
        }
      case .playerDied:
        if gameState == .playing {
          playerLives -= 1
          if playerLives > 0 {
            // Respawn with new life
            playerHealth = 3
            Chapter4Event.resetGame.emit()
          } else {
            gameState = .gameOver
          }
        }
      case .enemyKilled:
        score += 10
        Chapter4Event.screenShake(intensity: 0.3).emit()
      case .playerHit:
        Chapter4Event.screenShake(intensity: 0.5).emit()
        Chapter4Event.screenFlash.emit()
      case .resetGame:
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
      if gameState == .playing {
        playTime += delta
      }

      // Decay camera shake
      if cameraOffset.length() > 0.01 {
        cameraOffset = cameraOffset.lerp(to: .zero, weight: 10.0 * delta)
      } else if cameraOffset != .zero {
        cameraOffset = .zero
      }

      // Decay screen flash
      if screenFlashAlpha > 0 {
        screenFlashAlpha = max(0, screenFlashAlpha - Float(delta) * 3.0)
      }
    }
  }
}

// MARK: - Game Logic

extension Chapter4GameView {
  func handleInput() {
    if Action("start").isJustPressed {
      switch gameState {
      case .menu, .gameOver:
        resetGame()
      case .victory:
        resetGame()
      case .playing:
        break
      }
    }
  }

  func resetGame() {
    Chapter4Event.resetGame.emit()
    playerHealth = 3
    playerLives = 3
    score = 0
    playTime = 0
    cameraOffset = .zero
    screenFlashAlpha = 0
    Engine.onNextFrame { gameState = .playing }
  }

  func applyScreenShake(intensity: Float) {
    // Random shake offset
    let angle = Float.random(in: 0 ..< Float.pi * 2)
    let distance = intensity * 10.0
    cameraOffset = Vector2(
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
    screenFlashAlpha = 0.5
  }
}
