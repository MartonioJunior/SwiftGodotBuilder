import Observation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Chapter16 Namespace

enum Chapter16 {
  enum GameState {
    case levelSelect
    case playing
    case paused
    case settings
    case levelComplete
    case gameOver
  }

  enum Event: EmittableEvent {
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

    // Boss events
    case bossHit(damage: Int, position: Vector2)
    case bossPhaseChanged(phase: BossPhase)
    case bossDefeated(position: Vector2)
    case bossAttack(attackType: BossAttackType, position: Vector2)

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
    case weaponSwitched(weaponType: WeaponType)
  }

  // MARK: - Boss Types

  enum BossPhase: Int {
    case one = 1
    case two = 2
    case three = 3
    case defeated = 0
  }

  enum BossAttackType {
    case shoot      // Fires projectiles at player
    case jump       // Jumps and creates shockwave on landing
    case charge     // Charges horizontally at player
    case summon     // Summons minions (phase 3)
  }

  enum ParticleType {
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

  enum EnemyType {
    case patrol // Ground walking enemy
    case flyer // Flying shooting enemy
  }

  // MARK: - Level Data

  struct LevelData {
    let id: Int
    let name: String
    let totalCoins: Int
    let playerSpawnPoint: Vector2
  }

  struct LevelProgress: Codable, Equatable {
    let levelId: Int
    var completed: Bool = false
    var bestTime: Double = .infinity
    var coinsCollected: Int = 0

    init(levelId: Int, completed: Bool = false, bestTime: Double = .infinity, coinsCollected: Int = 0) {
      self.levelId = levelId
      self.completed = completed
      self.bestTime = bestTime
      self.coinsCollected = coinsCollected
    }

    mutating func update(time: Double, coins: Int) {
      completed = true
      if time < bestTime {
        bestTime = time
      }
      coinsCollected = max(coinsCollected, coins)
    }
  }

  // MARK: - Settings (@Observable for reactivity)

  @Observable
  class GameSettings: Persistable {
    static let PersistenceKey = "chapter16_settings"

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

  // MARK: - Game Progress (Persistent Level Data)

  @Observable
  class GameProgress: Persistable {
    static let PersistenceKey = "chapter16_progress"

    /// Array of level progress - reactive-friendly structure (no dictionaries)
    var levels: [LevelProgress] = []

    /// Currently selected level index (into `levels` array)
    var currentLevelIndex: Int = 0

    init() {
      loadPersistence()
    }

    func toDictionary() -> VariantDictionary {
      let dict = VariantDictionary()

      // Convert levels array to Variant array
      let levelsArray = VariantArray()
      for progress in levels {
        let levelDict = VariantDictionary()
        levelDict["levelId"] = Variant(progress.levelId)
        levelDict["completed"] = Variant(progress.completed)
        levelDict["bestTime"] = Variant(progress.bestTime)
        levelDict["coinsCollected"] = Variant(progress.coinsCollected)
        levelsArray.append(Variant(levelDict))
      }
      dict["levels"] = Variant(levelsArray)
      dict["currentLevelIndex"] = Variant(currentLevelIndex)

      return dict
    }

    func fromDictionary(_ dict: VariantDictionary) {
      if let levelsVariant = dict["levels"],
         let levelsArray = VariantArray(levelsVariant)
      {
        levels.removeAll()
        for i in 0 ..< levelsArray.size() {
          guard let levelDict = VariantDictionary(levelsArray[Int(i)]) else { continue }

          let levelId: Int = levelDict["levelId"]?.to() ?? (Int(i) + 1)
          var progress = LevelProgress(levelId: levelId)
          if let completed: Bool = levelDict["completed"]?.to() {
            progress.completed = completed
          }
          if let bestTime: Double = levelDict["bestTime"]?.to() {
            progress.bestTime = bestTime
          }
          if let coins: Int64 = levelDict["coinsCollected"]?.to() {
            progress.coinsCollected = Int(coins)
          }
          levels.append(progress)
        }
      }

      if let index: Int64 = dict["currentLevelIndex"]?.to() {
        currentLevelIndex = Int(index)
      }
    }

    /// Get the index in `levels` array for a given levelId, or nil if not found
    private func index(for levelId: Int) -> Int? {
      levels.firstIndex { $0.levelId == levelId }
    }

    func getProgress(for levelId: Int) -> LevelProgress {
      if let idx = index(for: levelId) {
        return levels[idx]
      }
      return LevelProgress(levelId: levelId)
    }

    func updateProgress(for levelId: Int, time: Double, coins: Int) {
      if let idx = index(for: levelId) {
        // Update existing entry - must reassign to trigger @Observable
        var progress = levels[idx]
        progress.update(time: time, coins: coins)
        levels[idx] = progress
      } else {
        // Create new entry
        var progress = LevelProgress(levelId: levelId)
        progress.update(time: time, coins: coins)
        levels.append(progress)
      }
      GD.print(arg1: Variant("Saving progress for level \(levelId): completed=\(getProgress(for: levelId).completed)"))
      savePersistence()
      GD.print(arg1: Variant("Progress saved to: \(persistencePath)"))
    }

    func isLevelUnlocked(_ levelId: Int) -> Bool {
      // Level 1 is always unlocked
      if levelId == 1 { return true }

      // Check if previous level is completed
      let previousProgress = getProgress(for: levelId - 1)
      return previousProgress.completed
    }

    func clearProgress() {
      levels.removeAll()
      currentLevelIndex = 0
      deletePersistence()
    }
  }

  // MARK: - Observable Game State

  @Observable
  class GameViewState {
    var gameState: GameState = .levelSelect
    var playerHealth: Int = 3
    var playerLives: Int = 3
    var score: Int = 0
    var playTime: Double = 0
    var cameraOffset: Vector2 = .zero
    var screenFlashAlpha: Float = 0

    // Level progression
    var currentLevelId: Int = 1

    // Inventory
    var coinsCollected: Int = 0
    var hasKey: Bool = false
    var totalCoins: Int = 10 // Total coins in level

    // Ammo and weapons
    var currentAmmo: Int = 10
    var maxAmmo: Int = 20
    var currentWeapon: WeaponType = .melee

    // Boss state
    var isBossFight: Bool = false
    var bossHealth: Int = 0
    var bossMaxHealth: Int = 100
    var bossPhase: BossPhase = .one
    var bossStunned: Bool = false

    let maxHealth: Int = 3

    var isPlaying: Bool {
      gameState == .playing
    }

    var isPaused: Bool {
      gameState == .paused
    }

    var isLevelSelect: Bool {
      gameState == .levelSelect
    }

    var isLevelComplete: Bool {
      gameState == .levelComplete
    }

    var isGameOver: Bool {
      gameState == .gameOver
    }

    var isSettings: Bool {
      gameState == .settings
    }

    var isLevel1: Bool {
      currentLevelId == 1
    }

    var isLevel2: Bool {
      currentLevelId == 2
    }

    var isLevel3: Bool {
      currentLevelId == 3
    }

    var isLevel4: Bool {
      currentLevelId == 4
    }

    var bossHealthPercent: Float {
      guard bossMaxHealth > 0 else { return 0 }
      return Float(bossHealth) / Float(bossMaxHealth)
    }

    var bossHealthDisplay: String {
      "Boss: \(bossHealth)/\(bossMaxHealth)"
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
      Event.gameReset.emit()
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
      // Boss state reset
      isBossFight = false
      bossHealth = 0
      bossPhase = .one
      bossStunned = false
    }

    func handleGoalReached(progress: GameProgress) {
      if gameState == .playing {
        score += 100

        // Save level progress
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
      if let levelData = Chapter16.getLevelData(nextId) {
        startLevel(nextId, totalCoins: levelData.totalCoins)
      } else {
        // No more levels, return to level select
        returnToLevelSelect()
      }
    }

    func restartLevel() {
      if let levelData = Chapter16.getLevelData(currentLevelId) {
        startLevel(currentLevelId, totalCoins: levelData.totalCoins)
      }
    }

    func handlePlayerDied() {
      if gameState == .playing {
        playerLives -= 1
        if playerLives > 0 {
          playerHealth = 3
          Event.gameReset.emit()
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

      // Check for phase transitions
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
}
