import Foundation
import Observation
import SwiftGodot
import SwiftGodotBuilder

enum Chapter6GameState {
  case menu
  case playing
  case victory
  case gameOver
}

enum Chapter6Event: EmittableEvent {
  case goalReached
  case playerDied
  case playerHit(damage: Int)
  case enemyKilled
  case resetGame
  case screenShake(intensity: Float)
  case screenFlash
  case spawnParticles(type: Chapter6ParticleType, position: Vector2)
}

enum Chapter6ParticleType {
  case jumpDust
  case landingImpact
  case movementTrail
  case deathExplosion
  case enemyHit
  case coinSparkle
}

// MARK: - Observable Game State

@Observable
class Chapter6GameViewState {
  var gameState: Chapter6GameState = .menu
  var playerHealth: Int = 3
  var playerLives: Int = 3
  var score: Int = 0
  var playTime: Double = 0
  var cameraOffset: Vector2 = .zero
  var screenFlashAlpha: Float = 0

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
