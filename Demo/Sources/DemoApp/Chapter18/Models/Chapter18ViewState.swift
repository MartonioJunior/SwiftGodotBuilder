import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter18 {
  @Observable
  class GameViewState {
    var gameState: GameState = .levelSelect
    var playerHealth: Int = 3
    var playerLives: Int = 3
    var deathCount: Int = 0
    var score: Int = 0
    var playTime: Double = 0
    var cameraOffset: Vector2 = .zero
    var screenFlashAlpha: Float = 0

    var currentLevelId: Int = 1

    var coinsCollected: Int = 0
    var hasKey = false
    var totalCoins: Int = 10

    var currentAmmo: Int = 10
    var maxAmmo: Int = 20
    var currentWeapon: WeaponType = .melee

    var isBossFight = false
    var bossHealth: Int = 0
    var bossMaxHealth: Int = 100
    var bossPhase: BossPhase = .one
    var bossStunned = false

    var lastCheckpointPosition: Vector2?
    var activatedCheckpointIds: Set<Int> = []

    var gamepadConnected = false

    let maxHealth: Int = 3
    let maxLives: Int = 3

    var isPlaying: Bool { gameState == .playing }
    var isPaused: Bool { gameState == .paused }
    var isLevelSelect: Bool { gameState == .levelSelect }
    var isLevelComplete: Bool { gameState == .levelComplete }
    var isGameOver: Bool { gameState == .gameOver }
    var isSettings: Bool { gameState == .settings }

    var isLevel1: Bool { currentLevelId == 1 }
    var isLevel2: Bool { currentLevelId == 2 }
    var isLevel3: Bool { currentLevelId == 3 }
    var isLevel4: Bool { currentLevelId == 4 }

    var bossHealthPercent: Float {
      guard bossMaxHealth > 0 else { return 0 }
      return Float(bossHealth) / Float(bossMaxHealth)
    }

    var bossHealthDisplay: String { "Boss: \(bossHealth)/\(bossMaxHealth)" }
    var healthDisplay: String { (0 ..< maxHealth).map { i in i < playerHealth ? "♥" : "♡" }.joined(separator: " ") }
    var livesDisplay: String { "Lives: \(playerLives)" }
    var scoreDisplay: String { "Score: \(score)" }
    var finalScoreDisplay: String { "Final Score: \(score)" }
    var playTimeDisplay: String { String(format: "Time: %.1fs", playTime) }
    var deathsDisplay: String { "Deaths: \(deathCount)" }
    var coinsDisplay: String { "Coins: \(coinsCollected)/\(totalCoins)" }
    var inventoryDisplay: String { hasKey ? "🔑" : "" }
    var ammoDisplay: String { currentWeapon == .ranged ? "Ammo: \(currentAmmo)/\(maxAmmo)" : "" }
    var weaponDisplay: String { currentWeapon == .melee ? "⚔️ Melee" : "🔫 Ranged" }

    var levelNameDisplay: String {
      if let levelData = Chapter18.getLevelData(currentLevelId) {
        return levelData.name
      }
      return "Level \(currentLevelId)"
    }

    func reset() {
      lastCheckpointPosition = nil
      activatedCheckpointIds = []

      playerHealth = maxHealth
      playerLives = maxLives
      deathCount = 0
      score = 0
      playTime = 0
      cameraOffset = .zero
      screenFlashAlpha = 0
      coinsCollected = 0
      hasKey = false
      currentAmmo = 10
      currentWeapon = .melee

      isBossFight = false
      bossHealth = 0
      bossPhase = .one
      bossStunned = false

      Event.gameReset.emit()
    }

    func handleGoalReached(progress: GameProgress) {
      if gameState == .playing {
        score += 100

        progress.updateProgress(
          for: currentLevelId,
          time: playTime,
          coins: coinsCollected
        )

        gameState = .levelComplete
      }
    }

    func startLevel(_ levelId: Int, totalCoins: Int) {
      currentLevelId = levelId
      self.totalCoins = totalCoins
      reset()
      gameState = .playing
    }

    func returnToLevelSelect() {
      gameState = .levelSelect
    }

    func nextLevel() {
      let nextId = currentLevelId + 1
      if let levelData = Chapter18.getLevelData(nextId) {
        startLevel(nextId, totalCoins: levelData.totalCoins)
      } else {
        returnToLevelSelect()
      }
    }

    func restartLevel() {
      if let levelData = Chapter18.getLevelData(currentLevelId) {
        startLevel(currentLevelId, totalCoins: levelData.totalCoins)
      }
    }

    func handlePlayerDied() {
      if gameState == .playing {
        deathCount += 1
        playerLives -= 1
        if playerLives > 0 {
          playerHealth = 3
          Event.gameReset.emit()
        } else {
          gameState = .gameOver
        }
      }
    }

    func handleEnemyKilled() { score += 10 }
    func handleCoinCollected() { coinsCollected += 1; score += 5 }
    func handleKeyCollected() { hasKey = true; score += 20 }
    func handleAmmoCollected() { currentAmmo = min(currentAmmo + 5, maxAmmo); score += 3 }
    func handleHealthCollected() { playerHealth = min(playerHealth + 1, maxHealth) }

    func handleCheckpointActivated(id: Int, position: Vector2) {
      guard !activatedCheckpointIds.contains(id) else { return }
      activatedCheckpointIds.insert(id)
      lastCheckpointPosition = position
      score += 25
    }

    func startBossFight(maxHealth: Int) {
      isBossFight = true
      bossHealth = maxHealth
      bossMaxHealth = maxHealth
      bossPhase = .one
      bossStunned = false
    }

    func handleBossHit(damage: Int) {
      guard isBossFight, bossHealth > 0 else { return }

      bossHealth = max(0, bossHealth - damage)

      let healthPercent = bossHealthPercent
      let newPhase: BossPhase
      if healthPercent <= 0 {
        newPhase = .defeated
      } else if healthPercent <= 0.33 {
        newPhase = .three
      } else if healthPercent <= 0.66 {
        newPhase = .two
      } else {
        newPhase = .one
      }

      if newPhase != bossPhase {
        bossPhase = newPhase
        Event.bossPhaseChanged(phase: newPhase).emit()
      }

      if bossHealth <= 0 {
        isBossFight = false
        score += 500
      }
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
      case .playing: gameState = .paused
      case .paused: gameState = .playing
      default: break
      }
    }

    func pauseGame() {
      if gameState == .playing { gameState = .paused }
    }

    func resumeGame() {
      if gameState == .paused { gameState = .playing }
    }
  }
}
