import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
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

extension WeaponConfig {
  /// Balanced starter weapon - medium speed, medium range
  static let sword = WeaponConfig(
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

  /// Slow but powerful, wide arc
  static let axe = WeaponConfig(
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
}
