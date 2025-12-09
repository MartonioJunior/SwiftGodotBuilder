import SwiftGodot

extension Chapter26.PlayerState {
  // MARK: - Combat

  /// Apply damage to player, triggering invincibility or death
  /// - Parameters:
  ///   - amount: Damage amount to apply
  ///   - collisionHeight: Player collision height (for death position calculation)
  /// - Note: Emits `playerDied` event if health reaches zero
  func takeDamage(_ amount: Int, collisionHeight: Float) {
    guard !overlay.contains(.invincible) else { return }

    playerHealth -= amount
    damage = .hit
    hitTimer = config.combat.hitAnimDuration

    if playerHealth <= 0 {
      playerHealth = 0
      damage = .dead
      playerRotation = Float.pi * 4 // Death spin
      let deathPos = position - [0, collisionHeight / 2]
      Chapter26.GameEvent.playerDied(position: deathPos).emit()
    } else {
      playerRotation = Float.pi / 8 // Hit wobble
      overlay.insert(.invincible)
      invincibilityTimer = config.combat.invincibilityDuration
    }
  }

  /// Begin melee attack sequence (startup -> active -> recovery -> idle)
  func startAttack() {
    attackPhase = .startup
    attackPhaseTimer = weaponConfig.startupTime
    overlay.insert(.attacking)
  }

  /// Advance to next attack phase when timer expires
  /// - Note: Emits `attacked` event when entering active phase
  func advanceAttackPhase() {
    switch attackPhase {
    case .startup:
      attackPhase = .active
      attackPhaseTimer = weaponConfig.activeTime
      let hitboxCenter = position + [0, -collisionHeight / 2]
      Chapter26.GameEvent.attacked(position: hitboxCenter, facing: facing).emit()

    case .active:
      attackPhase = .recovery
      attackPhaseTimer = weaponConfig.recoveryTime

    case .recovery:
      attackPhase = .idle
      attackPhaseTimer = 0
      overlay.remove(.attacking)

    case .idle:
      break
    }
  }
}
