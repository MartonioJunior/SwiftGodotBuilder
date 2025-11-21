import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter3Game: Node2D {
  override func _ready() {
    let rootNode = Chapter3GameView().toNode()
    addChild(node: rootNode)
  }
}

struct Chapter3GameView: GView {
  let screenWidth: Float = 320
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  // Game state
  @State var gameState: Chapter3GameState = .menu
  @State var playerHealth: Int = 3
  @State var playerLives: Int = 3
  @State var score: Int = 0
  @State var playTime: Double = 0

  var body: some GView {
    Node2D$ {
      // Ground platform
      Chapter3Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Left platform
      Chapter3Platform(x: 20, y: 120, width: 80, height: platformHeight, color: .gray)

      // Center platform
      Chapter3Platform(x: 120, y: 90, width: 100, height: platformHeight, color: .gray)

      // Right platform (enemy patrol area)
      Chapter3Platform(x: 240, y: 120, width: 60, height: platformHeight, color: .gray)

      // Goal area (green)
      Chapter3Goal(x: 280, y: 145, size: 20)

      // Player
      Chapter3Player(
        spawnPoint: [40, 110],
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        gravity: gravity,
        gameState: $gameState,
        health: $playerHealth
      )

      // Enemies
      Chapter3Enemy(
        spawnPoint: [180, 149],
        patrolLeft: 140,
        patrolRight: 220,
        gravity: gravity,
        gameState: $gameState
      )

      Chapter3Enemy(
        spawnPoint: [100, 74],
        patrolLeft: 120,
        patrolRight: 220,
        gravity: gravity,
        gameState: $gameState
      )

      // UI Overlay
      Chapter3GameUI(
        gameState: $gameState,
        playerHealth: $playerHealth,
        playerLives: $playerLives,
        score: $score,
        playTime: $playTime,
        maxHealth: 3
      )
    }
    .onEvent(Chapter3Event.self) { _, event in
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
            Chapter3Event.resetGame.emit()
          } else {
            gameState = .gameOver
          }
        }
      case .enemyKilled:
        score += 10
      case .playerHit:
        break // Player handles damage internally
      case .resetGame:
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
    }
  }
}

// MARK: - Game Logic

extension Chapter3GameView {
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
    Chapter3Event.resetGame.emit()
    playerHealth = 3
    playerLives = 3
    score = 0
    playTime = 0
    Engine.onNextFrame { gameState = .playing }
  }
}
