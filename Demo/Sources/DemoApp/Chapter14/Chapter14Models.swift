import Observation
import SwiftGodot
import SwiftGodotBuilder

enum Chapter14GameState {
  case menu
  case playing
  case paused
  case settings
  case victory
  case gameOver
}

enum Chapter14Event: EmittableEvent {
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
  case enemyProjectileFired(position: Vector2, direction: Vector2)
  case healthDropSpawned(position: Vector2)

  // Collectible events
  case healthCollected(position: Vector2)
  case coinCollected(position: Vector2)
  case keyCollected(position: Vector2)
  case doorUnlocked(position: Vector2)
  case ammoCollected(position: Vector2)

  // Weapon events
  case projectileFired(position: Vector2, direction: Vector2)
  case projectileHitWall(position: Vector2)
  case projectileHitEnemy(position: Vector2)
  case weaponSwitched(weaponType: Chapter14WeaponType)
}

enum Chapter14ParticleType {
  case jumpDust
  case landingImpact
  case movementTrail
  case deathExplosion
  case enemyHit
  case coinSparkle
  case projectileTrail
}

enum Chapter14WeaponType {
  case melee
  case ranged
}

enum Chapter14EnemyType {
  case patrol // Ground walking enemy
  case flyer // Flying shooting enemy
}

// MARK: - Settings (@Observable for reactivity)

@Observable
class GameSettings: Persistable {
  static let PersistenceKey = "settings"

  var masterVolume: Double = 0.7
  var musicVolume: Double = 0.6
  var sfxVolume: Double = 0.8
  var fullscreen: Bool = false

  var moveLeftKey: String = "a"
  var moveRightKey: String = "d"
  var jumpKey: String = "space"
  var attackKey: String = "x"
  var dashKey: String = "shift"
  var switchWeaponKey: String = "q"

  init() {
    loadPersistence()
  }

  func toDictionary() -> VariantDictionary {
    let dict = VariantDictionary()
    dict["masterVolume"] = Variant(masterVolume)
    dict["musicVolume"] = Variant(musicVolume)
    dict["sfxVolume"] = Variant(sfxVolume)
    dict["fullscreen"] = Variant(fullscreen)
    dict["moveLeftKey"] = Variant(moveLeftKey)
    dict["moveRightKey"] = Variant(moveRightKey)
    dict["jumpKey"] = Variant(jumpKey)
    dict["attackKey"] = Variant(attackKey)
    dict["dashKey"] = Variant(dashKey)
    dict["switchWeaponKey"] = Variant(switchWeaponKey)
    return dict
  }

  func fromDictionary(_ dict: VariantDictionary) {
    if let value: Double = dict["masterVolume"]?.to() { masterVolume = value }
    if let value: Double = dict["musicVolume"]?.to() { musicVolume = value }
    if let value: Double = dict["sfxVolume"]?.to() { sfxVolume = value }
    if let value: Bool = dict["fullscreen"]?.to() { fullscreen = value }
    if let value: String = dict["moveLeftKey"]?.to() { moveLeftKey = value }
    if let value: String = dict["moveRightKey"]?.to() { moveRightKey = value }
    if let value: String = dict["jumpKey"]?.to() { jumpKey = value }
    if let value: String = dict["attackKey"]?.to() { attackKey = value }
    if let value: String = dict["dashKey"]?.to() { dashKey = value }
    if let value: String = dict["switchWeaponKey"]?.to() { switchWeaponKey = value }
  }

  var masterVolumeDisplay: String {
    String(format: "%.0f%%", masterVolume * 100)
  }

  var musicVolumeDisplay: String {
    String(format: "%.0f%%", musicVolume * 100)
  }

  var sfxVolumeDisplay: String {
    String(format: "%.0f%%", sfxVolume * 100)
  }

  func resetToDefaults() {
    masterVolume = 0.7
    musicVolume = 0.6
    sfxVolume = 0.8
    fullscreen = false
    moveLeftKey = "a"
    moveRightKey = "d"
    jumpKey = "space"
    attackKey = "x"
    dashKey = "shift"
    switchWeaponKey = "q"
  }
}

// MARK: - Observable Game State

@Observable
class Chapter14GameViewState {
  var gameState: Chapter14GameState = .menu
  var playerHealth: Int = 3
  var playerLives: Int = 3
  var score: Int = 0
  var playTime: Double = 0
  var cameraOffset: Vector2 = .zero
  var screenFlashAlpha: Float = 0

  // Inventory
  var coinsCollected: Int = 0
  var hasKey: Bool = false
  var totalCoins: Int = 10 // Total coins in level

  // Ammo and weapons
  var currentAmmo: Int = 10
  var maxAmmo: Int = 20
  var currentWeapon: Chapter14WeaponType = .melee

  let maxHealth: Int = 3

  var isPlaying: Bool {
    gameState == .playing
  }

  var isPaused: Bool {
    gameState == .paused
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

  var isSettings: Bool {
    gameState == .settings
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
    Chapter14Event.gameReset.emit()
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
        Chapter14Event.gameReset.emit()
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

  func handleHealthCollected() {
    playerHealth = min(playerHealth + 1, maxHealth)
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

  func togglePause() {
    switch gameState {
    case .playing:
      gameState = .paused
    case .paused:
      gameState = .playing
    default:
      break
    }
  }

  func pauseGame() {
    if gameState == .playing {
      gameState = .paused
    }
  }

  func resumeGame() {
    if gameState == .paused {
      gameState = .playing
    }
  }
}
