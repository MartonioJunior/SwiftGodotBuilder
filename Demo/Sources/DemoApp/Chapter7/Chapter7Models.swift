import Foundation
import Observation
import SwiftGodot
import SwiftGodotBuilder

enum Chapter7GameState {
  case menu
  case playing
  case victory
  case gameOver
}

enum Chapter7Event: EmittableEvent {
  // Game state events
  case goalReached
  case gameReset

  // Player action events
  case jumped(position: Vector2)
  case landed(position: Vector2, impact: Float)
  case attacked(position: Vector2)

  // Player state events
  case playerDied(position: Vector2)
  case playerHit(damage: Int, position: Vector2)

  // Enemy events
  case enemyKilled(position: Vector2)

  // Collectible events
  case coinCollected(position: Vector2)
}

enum Chapter7ParticleType {
  case jumpDust
  case landingImpact
  case movementTrail
  case deathExplosion
  case enemyHit
  case coinSparkle
}

// MARK: - Observable Game State

@Observable
class Chapter7GameViewState {
  var gameState: Chapter7GameState = .menu
  var playerHealth: Int = 3
  var playerLives: Int = 3
  var score: Int = 0
  var playTime: Double = 0
  var cameraOffset: Vector2 = .zero
  var screenFlashAlpha: Float = 0
  var musicVolume: Float = 0.7
  var sfxVolume: Float = 0.8

  let maxHealth: Int = 3

  var isPlaying: Bool {
    gameState == .playing
  }

  var isMenu: Bool {
    gameState == .menu
  }

  var isVictory: Bool {
    gameState == .victory
  }

  var isGameOver: Bool {
    gameState == .gameOver
  }

  var healthDisplay: String {
    (0 ..< maxHealth).map { i in i < playerHealth ? "♥" : "♡" }.joined(separator: " ")
  }

  var livesDisplay: String {
    "Lives: \(playerLives)"
  }

  var scoreDisplay: String {
    "Score: \(score)"
  }

  var finalScoreDisplay: String {
    "Final Score: \(score)"
  }

  var playTimeDisplay: String {
    String(format: "Time: %.1fs", playTime)
  }

  func reset() {
    playerHealth = 3
    playerLives = 3
    score = 0
    playTime = 0
    cameraOffset = .zero
    screenFlashAlpha = 0
  }

  func handleGoalReached() {
    if gameState == .playing {
      score += 100
      gameState = .victory
    }
  }

  func handlePlayerDied() {
    if gameState == .playing {
      playerLives -= 1
      if playerLives > 0 {
        playerHealth = 3
      } else {
        gameState = .gameOver
      }
    }
  }

  func handleEnemyKilled() {
    score += 10
  }

  func startGame() {
    reset()
    gameState = .playing
  }
}
