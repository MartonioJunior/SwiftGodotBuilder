import SwiftGodot

extension Chapter25 {
  /// Configuration for a melee weapon's hitbox and timing
  struct WeaponConfig {
    let name: String

    // Hitbox dimensions
    let hitboxSize: Vector2
    let hitboxOffset: Float // Horizontal offset from player center

    // Timing (in seconds, at 60fps: 1 frame ≈ 0.017s)
    let startupTime: Double // Anticipation before hitbox activates
    let activeTime: Double // How long hitbox stays active
    let recoveryTime: Double // Cooldown after active frames

    // Combat properties
    let damage: Int
    let knockback: Float
    let canHitMultiple: Bool // Pierce through enemies or stop on first hit

    // Visual feedback
    let sweepArc: Float? // nil = static, value = degrees to sweep

    /// Total attack duration (startup + active + recovery)
    var totalDuration: Double { startupTime + activeTime + recoveryTime }
  }

  /// Attack phase for timing system
  enum AttackPhase {
    case idle
    case startup // Anticipation, no hitbox
    case active // Hitbox is live
    case recovery // Commitment window, no hitbox

    var isAttacking: Bool {
      switch self {
      case .idle: false
      case .startup, .active, .recovery: true
      }
    }

    var hitboxActive: Bool { self == .active }
  }

  /// Available melee weapon types
  enum MeleeWeapon: String, CaseIterable {
    case sword
    case spear
    case hammer
    case dagger

    var config: WeaponConfig {
      switch self {
      case .sword: .sword
      case .spear: .spear
      case .hammer: .hammer
      case .dagger: .dagger
      }
    }
  }
}

// MARK: - Weapon Definitions

extension Chapter25.WeaponConfig {
  /// Balanced starter weapon - medium speed, medium range
  static let sword = Chapter25.WeaponConfig(
    name: "Sword",
    hitboxSize: [8, 8],
    hitboxOffset: 7,
    startupTime: 0.05, // ~3 frames
    activeTime: 0.1, // ~6 frames
    recoveryTime: 0.1, // ~6 frames
    damage: 1,
    knockback: 80,
    canHitMultiple: false,
    sweepArc: nil
  )

  /// Long reach, quick thrust, narrow hitbox
  static let spear = Chapter25.WeaponConfig(
    name: "Spear",
    hitboxSize: [12, 4],
    hitboxOffset: 8,
    startupTime: 0.05, // ~3 frames
    activeTime: 0.067, // ~4 frames
    recoveryTime: 0.117, // ~7 frames
    damage: 1,
    knockback: 60,
    canHitMultiple: true, // Pierces through
    sweepArc: nil
  )

  /// Slow but powerful, wide arc
  static let hammer = Chapter25.WeaponConfig(
    name: "Hammer",
    hitboxSize: [10, 12],
    hitboxOffset: 6,
    startupTime: 0.133, // ~8 frames - big windup
    activeTime: 0.1, // ~6 frames
    recoveryTime: 0.167, // ~10 frames - heavy recovery
    damage: 2,
    knockback: 150,
    canHitMultiple: true,
    sweepArc: 90 // Overhead swing
  )

  /// Very fast, short range, rapid attacks
  static let dagger = Chapter25.WeaponConfig(
    name: "Dagger",
    hitboxSize: [5, 5],
    hitboxOffset: 5,
    startupTime: 0.017, // ~1 frame
    activeTime: 0.05, // ~3 frames
    recoveryTime: 0.05, // ~3 frames
    damage: 1,
    knockback: 30,
    canHitMultiple: false,
    sweepArc: nil
  )
}
