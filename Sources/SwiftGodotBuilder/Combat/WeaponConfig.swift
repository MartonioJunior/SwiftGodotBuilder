import SwiftGodot

/// Configuration for a melee weapon's hitbox and timing.
///
/// Use this to define weapon properties for melee combat systems with
/// startup, active, and recovery phases.
///
/// ### Example:
/// ```swift
/// let sword = WeaponConfig(
///   name: "Sword",
///   hitboxSize: [8, 8],
///   hitboxOffset: 7,
///   startupTime: 0.05,
///   activeTime: 0.1,
///   recoveryTime: 0.1,
///   damage: 1,
///   knockback: 80,
///   canHitMultiple: false,
///   sweepArc: nil
/// )
/// ```
public struct WeaponConfig: Sendable {
  public let name: String

  /// Hitbox dimensions (width, height)
  public let hitboxSize: Vector2

  /// Horizontal offset from player center
  public let hitboxOffset: Float

  /// Anticipation before hitbox activates (seconds)
  public let startupTime: Double

  /// How long hitbox stays active (seconds)
  public let activeTime: Double

  /// Cooldown after active frames (seconds)
  public let recoveryTime: Double

  /// Damage dealt on hit
  public let damage: Int

  /// Knockback force applied to hit targets
  public let knockback: Float

  /// Whether the weapon can hit multiple enemies (pierce) or stops on first hit
  public let canHitMultiple: Bool

  /// Arc sweep in degrees, or nil for static hitbox
  public let sweepArc: Float?

  /// Total attack duration (startup + active + recovery)
  public var totalDuration: Double { startupTime + activeTime + recoveryTime }

  public init(
    name: String,
    hitboxSize: Vector2,
    hitboxOffset: Float,
    startupTime: Double,
    activeTime: Double,
    recoveryTime: Double,
    damage: Int,
    knockback: Float,
    canHitMultiple: Bool,
    sweepArc: Float?
  ) {
    self.name = name
    self.hitboxSize = hitboxSize
    self.hitboxOffset = hitboxOffset
    self.startupTime = startupTime
    self.activeTime = activeTime
    self.recoveryTime = recoveryTime
    self.damage = damage
    self.knockback = knockback
    self.canHitMultiple = canHitMultiple
    self.sweepArc = sweepArc
  }
}
