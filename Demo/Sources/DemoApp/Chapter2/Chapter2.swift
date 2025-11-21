import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter2Game: Node2D {
  override func _ready() {
    let rootNode = Chapter2GameView().toNode()
    addChild(node: rootNode)
  }
}

struct Chapter2GameView: GView {
  let screenWidth: Float = 320
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  // Game state
  @State var gameState: Chapter2GameState = .menu
  @State var playerHealth: Int = 3
  @State var enemiesKilled: Int = 0

  var body: some GView {
    Node2D$ {
      // Ground platform
      Chapter2Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Left platform
      Chapter2Platform(x: 20, y: 120, width: 80, height: platformHeight, color: .gray)

      // Center platform
      Chapter2Platform(x: 120, y: 90, width: 100, height: platformHeight, color: .gray)

      // Right platform (enemy patrol area)
      Chapter2Platform(x: 240, y: 120, width: 60, height: platformHeight, color: .gray)

      // Goal area (green)
      Chapter2Goal(x: 280, y: 145, size: 20)

      // Player
      Chapter2Player(
        spawnPoint: [40, 110],
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        gravity: gravity,
        gameState: $gameState,
        health: $playerHealth
      )

      // Enemies
      Chapter2Enemy(
        spawnPoint: [180, 149],
        patrolLeft: 140,
        patrolRight: 220,
        gravity: gravity,
        gameState: $gameState
      )

      Chapter2Enemy(
        spawnPoint: [100, 74],
        patrolLeft: 120,
        patrolRight: 220,
        gravity: gravity,
        gameState: $gameState
      )

      // UI Overlay
      Chapter2GameUI(
        gameState: $gameState,
        playerHealth: $playerHealth,
        maxHealth: 3
      )
    }
    .onEvent(Chapter2Event.self) { _, event in
      switch event {
      case .goalReached:
        if gameState == .playing {
          gameState = .victory
        }
      case .playerDied:
        if gameState == .playing {
          gameState = .gameOver
        }
      case .enemyKilled:
        enemiesKilled += 1
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
    .onProcess { _, _ in
      handleInput()
    }
  }
}

// MARK: - Game Logic

extension Chapter2GameView {
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
    Chapter2Event.resetGame.emit()
    playerHealth = 3
    enemiesKilled = 0
    Engine.onNextFrame { gameState = .playing }
  }
}
