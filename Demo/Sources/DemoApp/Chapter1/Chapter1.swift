import Foundation
import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Chapter1Game: Node2D {
  override func _ready() {
    let rootNode = Chapter1GameView().toNode()
    addChild(node: rootNode)
  }
}

struct Chapter1GameView: GView {
  let screenWidth: Float = 320
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  // Game state
  @State var gameState: Chapter1GameState = .menu

  var body: some GView {
    Node2D$ {
      // Ground platform
      Chapter1Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Left platform
      Chapter1Platform(x: 20, y: 120, width: 80, height: platformHeight, color: .gray)

      // Center platform
      Chapter1Platform(x: 120, y: 90, width: 100, height: platformHeight, color: .gray)

      // Right platform (enemy patrol area)
      Chapter1Platform(x: 240, y: 120, width: 60, height: platformHeight, color: .gray)

      // Goal area (green)
      Chapter1Goal(x: 280, y: 145, size: 20)

      // Player
      Chapter1Player(
        spawnPoint: [40, 110],
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        gravity: gravity,
        gameState: $gameState
      )

      // Enemy
      Chapter1Enemy(
        spawnPoint: [180, 150],
        patrolLeft: 140,
        patrolRight: 220,
        gravity: gravity,
        gameState: $gameState
      )

      // UI Overlay
      Chapter1GameUI(gameState: $gameState)
    }
    .onEvent(Chapter1Event.self) { _, event in
      if case .goalReached = event {
        if gameState == .playing {
          gameState = .victory
        }
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

extension Chapter1GameView {
  func handleInput() {
    if Action("start").isJustPressed {
      switch gameState {
      case .menu:
        Engine.onNextFrame { gameState = .playing }
      case .victory:
        resetGame()
      case .playing:
        break
      }
    }
  }

  func resetGame() {
    Chapter1Event.resetPlayer.emit()
    gameState = .menu
  }
}
