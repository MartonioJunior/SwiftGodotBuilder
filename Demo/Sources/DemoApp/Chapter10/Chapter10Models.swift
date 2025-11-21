import Foundation
import Observation
import SwiftGodot
import SwiftGodotBuilder

enum Chapter10GameState {
  case menu
  case playing
  case victory
  case gameOver
}

enum Chapter10Event: EmittableEvent {
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
  case keyCollected(position: Vector2)
  case doorUnlocked(position: Vector2)
  case ammoCollected(position: Vector2)

  // Weapon events
  case projectileFired(position: Vector2, direction: Vector2)
  case projectileHitWall(position: Vector2)
  case projectileHitEnemy(position: Vector2)
  case weaponSwitched(weaponType: WeaponType)
}

enum Chapter10ParticleType {
  case jumpDust
  case landingImpact
  case movementTrail
  case deathExplosion
  case enemyHit
  case coinSparkle
  case projectileTrail
}

enum WeaponType {
  case melee
  case ranged
}

// MARK: - Observable Game State

@Observable
class Chapter10GameViewState {
  var gameState: Chapter10GameState = .menu
  var playerHealth: Int = 3
  var playerLives: Int = 3
  var score: Int = 0
  var playTime: Double = 0
  var cameraOffset: Vector2 = .zero
  var screenFlashAlpha: Float = 0
  var musicVolume: Float = 0.7
  var sfxVolume: Float = 0.8

  // Inventory
  var coinsCollected: Int = 0
  var hasKey: Bool = false
  var totalCoins: Int = 10 // Total coins in level

  // Ammo and weapons
  var currentAmmo: Int = 10
  var maxAmmo: Int = 20
  var currentWeapon: WeaponType = .melee

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

  var coinsDisplay: String {
    "Coins: \(coinsCollected)/\(totalCoins)"
  }

  var inventoryDisplay: String {
    hasKey ? "🔑" : ""
  }

  var ammoDisplay: String {
    currentWeapon == .ranged ? "Ammo: \(currentAmmo)/\(maxAmmo)" : ""
  }

  var weaponDisplay: String {
    currentWeapon == .melee ? "⚔️ Melee" : "🔫 Ranged"
  }

  func reset() {
    playerHealth = 3
    playerLives = 3
    score = 0
    playTime = 0
    cameraOffset = .zero
    screenFlashAlpha = 0
    coinsCollected = 0
    hasKey = false
    currentAmmo = 10
    currentWeapon = .melee
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

  func handleCoinCollected() {
    coinsCollected += 1
    score += 5
  }

  func handleKeyCollected() {
    hasKey = true
    score += 20
  }

  func handleAmmoCollected() {
    currentAmmo = min(currentAmmo + 5, maxAmmo)
    score += 3
  }

  func consumeAmmo() -> Bool {
    guard currentAmmo > 0 else { return false }
    currentAmmo -= 1
    return true
  }

  func startGame() {
    reset()
    gameState = .playing
  }
}
