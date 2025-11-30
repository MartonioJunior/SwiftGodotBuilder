import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  /// Typealias for the game's scene router
  typealias GameRouter = SceneRouter<GameState>

  @Observable
  class GameViewState {
    // Note: Scene state is now managed by SceneRouter, not here.
    // Use router.scene for the current scene, router.navigate() for transitions.

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

    // Note: Boolean state checks are now done via state groups on GameState
    // Use: router.scene.is(.playing) or router.scene.isIn(.inGame)
    // See Chapter23Types.swift for state group definitions

    var bossHealthPercent: Float {
      guard bossMaxHealth > 0 else { return 0 }
      return Float(bossHealth) / Float(bossMaxHealth)
    }

    var bossHealthDisplay: String { "Boss: \(bossHealth)/\(bossMaxHealth)" }
    var healthDisplay: String { (0 ..< maxHealth).map { i in i < playerHealth ? "♥" : "♡" }.joined(separator: " ") }
    var livesDisplay: String { "Lives: \(playerLives)" }
    var scoreDisplay: String { "Score: \(score)" }
    var finalScoreDisplay: String { "Final Score: \(score)" }
    var playTimeDisplay: String { Chapter23.formatTime(playTime) }
    var deathsDisplay: String { "Deaths: \(deathCount)" }
    var coinsDisplay: String { "Coins: \(coinsCollected)/\(totalCoins)" }
    var inventoryDisplay: String { hasKey ? "🔑" : "" }
    var ammoDisplay: String { currentWeapon == .ranged ? "Ammo: \(currentAmmo)/\(maxAmmo)" : "" }
    var weaponDisplay: String { currentWeapon == .melee ? "⚔️ Melee" : "🔫 Ranged" }

    var leaderboardLevelId: Int = 1

    // Dialog state
    var dialogRunner: DialogRunner?
    var currentNPCId: String?
    var storyProgress = StoryProgress()
    var npcVisitCounts: [String: Int] = [:]

    /// Increment and return the visit count for an NPC (1 = first visit)
    func beginDialogVisit(npcId: String) -> Int {
      npcVisitCounts[npcId, default: 0] += 1
      return npcVisitCounts[npcId]!
    }

    var currentMedal: Medal {
      guard let levelData = Chapter23.getLevelData(currentLevelId) else { return .none }
      return levelData.medal(for: playTime)
    }

    var currentMedalDisplay: String { currentMedal.rawValue }

    var medalTargetsDisplay: String {
      guard let levelData = Chapter23.getLevelData(currentLevelId) else { return "" }
      return "🥇 \(Chapter23.formatTime(levelData.goldTime))  🥈 \(Chapter23.formatTime(levelData.silverTime))  🥉 \(Chapter23.formatTime(levelData.bronzeTime))"
    }

    var nextMedalTarget: String {
      guard let levelData = Chapter23.getLevelData(currentLevelId) else { return "" }
      if playTime <= levelData.goldTime { return "" }
      if playTime <= levelData.silverTime { return "🥇 -\(Chapter23.formatTime(playTime - levelData.goldTime))" }
      if playTime <= levelData.bronzeTime { return "🥈 -\(Chapter23.formatTime(playTime - levelData.silverTime))" }
      return "🥉 -\(Chapter23.formatTime(playTime - levelData.bronzeTime))"
    }

    var levelNameDisplay: String {
      if let levelData = Chapter23.getLevelData(currentLevelId) {
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

    /// Handle goal reached - updates score and progress. Returns true if in playing state.
    /// Caller should navigate to .levelComplete after this returns true.
    func handleGoalReached(progress: GameProgress, currentScene: GameState) -> Bool {
      guard currentScene == .playing else { return false }
      score += 100

      progress.updateProgress(
        for: currentLevelId,
        time: playTime,
        coins: coinsCollected,
        deaths: deathCount
      )
      return true
    }

    func setLeaderboardLevel(_ levelId: Int) {
      leaderboardLevelId = levelId
    }

    /// Prepare state for starting a level. Caller should navigate to .playing.
    func prepareLevel(_ levelId: Int, totalCoins: Int) {
      currentLevelId = levelId
      self.totalCoins = totalCoins
      reset()
    }

    /// Get the next level ID, or nil if at end
    var nextLevelId: Int? {
      let nextId = currentLevelId + 1
      return Chapter23.getLevelData(nextId) != nil ? nextId : nil
    }

    /// Handle player death - updates death count and lives.
    /// Returns the scene to navigate to (.death if lives remain, .gameOver if not), or nil if not playing.
    func handlePlayerDied(currentScene: GameState) -> GameState? {
      guard currentScene == .playing else { return nil }
      deathCount += 1
      playerLives -= 1
      return playerLives > 0 ? .death : .gameOver
    }

    func respawnAfterDeath() {
      playerHealth = 3
      Event.gameReset.emit()
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

    // Dialog methods
    // Note: DialogBox will call dialogRunner.start() after setting up callbacks

    /// Prepare dialog state. Caller should navigate to .dialog.
    func prepareDialog(npcId: String, dialog: DialogDefinition, branchId: String? = nil, currentScene: GameState) -> Bool {
      guard currentScene == .playing else { return false }
      currentNPCId = npcId
      dialogRunner = DialogRunner(dialog: dialog)
      dialogRunner?.pendingBranchId = branchId
      return true
    }

    /// Clean up dialog state. Caller should navigate to .playing.
    func cleanupDialog() {
      if let npcId = currentNPCId {
        storyProgress.markTalkedTo(npcId)
      }
      if let dialogId = dialogRunner?.dialog.id {
        storyProgress.markDialogComplete(dialogId)
      }
      dialogRunner = nil
      currentNPCId = nil
    }
  }
}
