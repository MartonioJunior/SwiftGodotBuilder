import Foundation
import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Boss fight state - health, phase, stun status
  @Observable
  class BossState {
    var isBossFight = false
    var bossHealth = 0
    var bossMaxHealth = 100
    var bossPhase: BossPhase = .one
    var bossStunned = false

    /// Screen shake intensity - watched by PlayerView for reactive shake
    /// Set to > 0 when boss is hit/defeated, resets to 0 after being read
    var shakeIntensity: Float = 0

    // MARK: - Computed Properties

    var bossHealthPercent: Float {
      guard bossMaxHealth > 0 else { return 0 }
      return Float(bossHealth) / Float(bossMaxHealth)
    }

    var bossHealthDisplay: String { "Boss: \(bossHealth)/\(bossMaxHealth)" }

    // MARK: - Methods

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
        shakeIntensity = 1.0 // Phase change triggers bigger shake
        GameEvent.bossPhaseChanged(phase: newPhase).emit()
      }

      if bossHealth <= 0 {
        isBossFight = false
      }
    }

    func reset() {
      isBossFight = false
      bossHealth = 0
      bossPhase = .one
      bossStunned = false
    }
  }
}
