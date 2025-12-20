import SwiftGodot

/// Unified weapon configuration with optional melee and ranged components
public struct ActorWeaponConfig: Sendable {
  /// Optional name for identifying the weapon
  public var name: String?

  /// Timing phases for attack
  public var startupDuration: Double
  public var activeDuration: Double
  public var recoveryDuration: Double

  /// Melee component (optional)
  public var melee: MeleeWeaponConfig?

  /// Ranged component (optional)
  public var ranged: RangedWeaponConfig?

  public init(
    name: String? = nil,
    startupDuration: Double = 0.1,
    activeDuration: Double = 0.15,
    recoveryDuration: Double = 0.1,
    melee: MeleeWeaponConfig? = nil,
    ranged: RangedWeaponConfig? = nil
  ) {
    self.name = name
    self.startupDuration = startupDuration
    self.activeDuration = activeDuration
    self.recoveryDuration = recoveryDuration
    self.melee = melee
    self.ranged = ranged
  }
}

// MARK: - Melee Component

public struct MeleeWeaponConfig: Sendable {
  public var size: Vector2
  public var offset: Float
  public var damage: Int
  public var knockback: Float

  /// When true, hitbox is always active (touch damage mode)
  public var alwaysActive: Bool

  public init(
    size: Vector2 = [12, 8],
    offset: Float = 10,
    damage: Int = 1,
    knockback: Float = 100,
    alwaysActive: Bool = false
  ) {
    self.size = size
    self.offset = offset
    self.damage = damage
    self.knockback = knockback
    self.alwaysActive = alwaysActive
  }
}

// MARK: - Ranged Component

public struct RangedWeaponConfig: Sendable {
  public var damage: Int
  public var knockback: Float
  public var speed: Float
  public var size: Vector2
  public var lifetime: Double
  public var spawnOffset: Vector2

  // Visuals
  public var spriteAsset: String?
  public var spriteAnimation: String?
  public var color: Color?

  public init(
    damage: Int = 1,
    knockback: Float = 0,
    speed: Float = 200,
    size: Vector2 = [4, 2],
    lifetime: Double = 3.0,
    spawnOffset: Vector2 = [8, 0],
    spriteAsset: String? = nil,
    spriteAnimation: String? = nil,
    color: Color? = nil
  ) {
    self.damage = damage
    self.knockback = knockback
    self.speed = speed
    self.size = size
    self.lifetime = lifetime
    self.spawnOffset = spawnOffset
    self.spriteAsset = spriteAsset
    self.spriteAnimation = spriteAnimation
    self.color = color
  }
}
