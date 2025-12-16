import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  enum EnemyType: String, LDExported {
    case patrol = "Patrol"
    case flyer = "Flyer"

    // This pattern is needed because LDtk enums can't store associated values
    // so we map to definitions here
    var definition: EnemyDefinition {
      switch self {
      case .patrol: .patrol
      case .flyer: .flyer
      }
    }
  }

  struct EnemyDefinition {
    let size: Float
    let speed: Float
    let maxHealth: Int
    let touchDamage: Int
    let deathFadeDuration: Double
    let knockbackForce: Float
    let knockbackDuration: Double
    let shootInterval: Double?
    let healthDropChance: Float
    let colorHex: String
    let damagedColorHex: String
    let flies: Bool
    let moveAnimation: String
    let hitAnimation: String
    let deathAnimation: String
    let attackAnimation: String?
    let startingWeapons: [ActorWeapon]

    /// Convert to ActorAnimations for use with ActorView
    var animations: ActorAnimations {
      ActorAnimations.perAction(
        idle: moveAnimation,
        walk: moveAnimation,
        jump: moveAnimation,
        attack: attackAnimation,
        hit: hitAnimation,
        death: deathAnimation
      )
    }

    init(
      size: Float,
      speed: Float,
      maxHealth: Int,
      touchDamage: Int,
      deathFadeDuration: Double,
      knockbackForce: Float,
      knockbackDuration: Double,
      shootInterval: Double?,
      healthDropChance: Float,
      colorHex: String,
      damagedColorHex: String,
      flies: Bool,
      moveAnimation: String,
      hitAnimation: String,
      deathAnimation: String,
      attackAnimation: String? = nil,
      startingWeapons: [ActorWeapon] = [Chapter27.WeaponRegistry.claws]
    ) {
      self.size = size
      self.speed = speed
      self.maxHealth = maxHealth
      self.touchDamage = touchDamage
      self.deathFadeDuration = deathFadeDuration
      self.knockbackForce = knockbackForce
      self.knockbackDuration = knockbackDuration
      self.shootInterval = shootInterval
      self.healthDropChance = healthDropChance
      self.colorHex = colorHex
      self.damagedColorHex = damagedColorHex
      self.flies = flies
      self.moveAnimation = moveAnimation
      self.hitAnimation = hitAnimation
      self.deathAnimation = deathAnimation
      self.attackAnimation = attackAnimation
      self.startingWeapons = startingWeapons
    }
  }
}

// MARK: - Enemy Definitions

extension Chapter27.EnemyDefinition {
  static let patrol = Chapter27.EnemyDefinition(
    size: 8,
    speed: 40,
    maxHealth: 2,
    touchDamage: 1,
    deathFadeDuration: 0.5,
    knockbackForce: 150,
    knockbackDuration: 0.2,
    shootInterval: nil,
    healthDropChance: 0.25,
    colorHex: "#E64D4D",
    damagedColorHex: "#993333",
    flies: false,
    moveAnimation: "EmberRedMove",
    hitAnimation: "EmberHit",
    deathAnimation: "EmberHit"
  )

  static let flyer = Chapter27.EnemyDefinition(
    size: 8,
    speed: 40,
    maxHealth: 2,
    touchDamage: 1,
    deathFadeDuration: 0.5,
    knockbackForce: 150,
    knockbackDuration: 0.2,
    shootInterval: 2.5,
    healthDropChance: 0.25,
    colorHex: "#CC4DE6",
    damagedColorHex: "#9933B3",
    flies: true,
    moveAnimation: "BugYellowMove",
    hitAnimation: "BugHit",
    deathAnimation: "BugDeath",
    startingWeapons: [Chapter27.WeaponRegistry.claws, Chapter27.WeaponRegistry.fireball]
  )
}
