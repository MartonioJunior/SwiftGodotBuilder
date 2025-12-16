import Foundation
import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Observable state for game/meta concerns - lives, score, progress.
  /// Combat state (health, facing, timers) is now in ActorState.
  @Observable
  class PlayerGameState {
    // Game configuration
    let maxLives = 3
    let maxHealth = 3
    let maxAmmo = 20
    let config = PlayerConfig()

    // Lives & Death tracking
    var playerLives = 3
    var livesDisplay: String { "Lives: \(playerLives)" }
    var livesCountDisplay: String { "x\(playerLives)" }
    var livesRemainingText: String { playerLives == 1 ? "LAST LIFE!" : "\(playerLives) LIVES LEFT" }

    var deathCount = 0
    var deathsDisplay: String { "Deaths: \(deathCount)" }

    // Score & Progress
    var score = 0
    var scoreDisplay: String { "Score: \(score)" }
    var finalScoreDisplay: String { "Final Score: \(score)" }

    var coinsCollected = 0
    var coinsCountDisplay: String { "x\(coinsCollected)" }
    var totalCoins = 10
    var coinsDisplay: String { "Coins: \(coinsCollected)/\(totalCoins)" }

    // Inventory (non-weapon items)
    var hasKey = false

    // Display values (synced from ActorState/ActorWeaponState for HUD)
    var playerHealth = 3

    var currentWeapon: ActorWeaponType = .unarmed
    var currentAmmo = 10
    var ammoDisplay: String { currentWeapon == .ranged ? "\(currentAmmo)/\(maxAmmo)" : "" }

    // MARK: - Display Strings (for HUD/UI)

    // MARK: - Methods

    func fullReset() {
      playerLives = maxLives
      hasKey = false
      deathCount = 0
      score = 0
      coinsCollected = 0
      // Reset display values
      playerHealth = maxHealth
      currentWeapon = .unarmed
      currentAmmo = 10
    }

    // MARK: - Sync from ActorState (called by PlayerActorView)

    func syncHealth(_ health: Int) {
      playerHealth = health
    }

    func syncWeapon(type: ActorWeaponType, ammo: Int) {
      currentWeapon = type
      currentAmmo = ammo
    }

    func handleEnemyKilled() {
      score += 10
    }

    func addScore(_ points: Int) {
      score += points
    }

    /// Called when player dies. Returns the scene to navigate to (.death or .gameOver)
    func handlePlayerDied() -> GameState {
      deathCount += 1
      playerLives -= 1
      return playerLives > 0 ? .death : .gameOver
    }
  }
}
