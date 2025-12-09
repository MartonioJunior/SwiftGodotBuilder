import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  enum EnemyType: String, LDExported {
    case patrol = "Patrol"
    case flyer = "Flyer"

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
  }
}

// MARK: - Enemy Definitions

extension Chapter26.EnemyDefinition {
  static let patrol = Chapter26.EnemyDefinition(
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

  static let flyer = Chapter26.EnemyDefinition(
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
    deathAnimation: "BugDeath"
  )
}
