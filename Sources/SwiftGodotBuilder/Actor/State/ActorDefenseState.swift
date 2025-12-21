import Foundation
import SwiftGodot

/// Defense capability state for actors that can take damage
@Observable
public class ActorDefenseState {
  // MARK: - Config

  public let config: ActorDefenseConfig

  // MARK: - Health

  public var health: Int
  public var maxHealth: Int

  // MARK: - Invincibility

  public var isInvincible = false
  public var invincibilityTimer: Double = 0

  // MARK: - Death

  public var isDying = false

  // MARK: - Initialization

  public init(config: ActorDefenseConfig) {
    self.config = config
    health = config.maxHealth
    maxHealth = config.maxHealth
  }

  // MARK: - Timer Updates

  public func updateTimers(_ delta: Double) {
    if invincibilityTimer > 0 {
      invincibilityTimer -= delta
      if invincibilityTimer <= 0 {
        isInvincible = false
      }
    }
  }

  // MARK: - Damage

  public func takeDamage(
    _ amount: Int,
    knockback: Vector2? = nil,
    coreState: ActorState,
    physicsState: ActorPhysicsState?
  ) {
    guard !isDying, !isInvincible else { return }

    health -= amount

    ActorEvent.tookDamage(actorId: coreState.id, damage: amount).emit()

    if health <= 0 {
      health = 0
      isDying = true
      ActorEvent.died(actorId: coreState.id).emit()
      coreState.onDeath?()
    } else {
      // Start invincibility if configured
      if config.invincibilityDuration > 0 {
        isInvincible = true
        invincibilityTimer = config.invincibilityDuration
      }
    }

    // Apply knockback if provided and physics capability exists
    if let knockback, let physics = physicsState {
      physics.knockbackVelocity = knockback
      physics.knockbackTimer = 0.2
    }
  }

  // MARK: - Healing

  public func heal(_ amount: Int) {
    health = min(health + amount, maxHealth)
  }
}
