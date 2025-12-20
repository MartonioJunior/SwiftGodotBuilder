import SwiftGodot

// MARK: - Defense Config

/// Configuration for an actor's defense capability
public struct ActorDefenseConfig: Sendable {
  public var maxHealth: Int
  public var invincibilityDuration: Double

  public init(
    maxHealth: Int = 1,
    invincibilityDuration: Double = 0.0
  ) {
    self.maxHealth = maxHealth
    self.invincibilityDuration = invincibilityDuration
  }
}
