import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  /// Configuration for a melee weapon's hitbox and timing
  struct WeaponConfig {
    let name: String
    let hitboxSize: Vector2
    let hitboxOffset: Float
    let startupTime: Double
    let activeTime: Double
    let recoveryTime: Double
    let damage: Int
    let knockback: Float
    let canHitMultiple: Bool
    let sweepArc: Float?

    var totalDuration: Double { startupTime + activeTime + recoveryTime }
  }

  /// Attack phase for timing system
  enum AttackPhase {
    case idle
    case startup
    case active
    case recovery

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
    case axe

    var config: WeaponConfig {
      switch self {
      case .sword: .sword
      case .axe: .axe
      }
    }
  }
}

// MARK: - Weapon Definitions

extension Chapter26.WeaponConfig {
  /// Balanced starter weapon - medium speed, medium range
  static let sword = Chapter26.WeaponConfig(
    name: "Sword",
    hitboxSize: [8, 8],
    hitboxOffset: 7,
    startupTime: 0.05,
    activeTime: 0.1,
    recoveryTime: 0.1,
    damage: 1,
    knockback: 80,
    canHitMultiple: false,
    sweepArc: nil
  )

  /// Slow but powerful, wide arc
  static let axe = Chapter26.WeaponConfig(
    name: "Hammer",
    hitboxSize: [10, 12],
    hitboxOffset: 6,
    startupTime: 0.133,
    activeTime: 0.1,
    recoveryTime: 0.167,
    damage: 2,
    knockback: 150,
    canHitMultiple: true,
    sweepArc: 90
  )
}
