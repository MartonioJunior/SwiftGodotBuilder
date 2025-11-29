import SwiftGodot
import SwiftGodotBuilder

enum Chapter22 {
  enum GameState {
    case welcome
    case levelSelect
    case playing
    case paused
    case settings
    case levelComplete
    case gameOver
    case leaderboard
    case dialog
  }

  enum Medal: String, Codable {
    case gold = "🥇"
    case silver = "🥈"
    case bronze = "🥉"
    case none = ""

    var color: String {
      switch self {
      case .gold: "#FFD700"
      case .silver: "#C0C0C0"
      case .bronze: "#CD7F32"
      case .none: "#808080"
      }
    }

    var name: String {
      switch self {
      case .gold: "Gold"
      case .silver: "Silver"
      case .bronze: "Bronze"
      case .none: "No Medal"
      }
    }
  }

  enum Event: EmittableEvent {
    case goalReached
    case gameReset

    case jumped(position: Vector2)
    case landed(position: Vector2, impact: Float)
    case attacked(position: Vector2)

    case playerDied(position: Vector2)
    case playerHit(damage: Int, position: Vector2)

    case enemyKilled(position: Vector2)
    case enemyProjectileFired(position: Vector2, direction: Vector2)
    case healthDropSpawned(position: Vector2)

    case bossHit(damage: Int, position: Vector2)
    case bossPhaseChanged(phase: BossPhase)
    case bossDefeated(position: Vector2)
    case bossAttack(attackType: BossAttackType, position: Vector2)

    case healthCollected(position: Vector2)
    case coinCollected(position: Vector2)
    case keyCollected(position: Vector2)
    case doorUnlocked(position: Vector2)
    case ammoCollected(position: Vector2)

    case projectileFired(position: Vector2, direction: Vector2)
    case projectileHitWall(position: Vector2)
    case projectileHitEnemy(position: Vector2)
    case weaponSwitched(weaponType: WeaponType)

    case enteredWater
    case exitedWater

    case checkpointActivated(id: Int, position: Vector2)
  }

  enum BossPhase: Int {
    case one = 1
    case two = 2
    case three = 3
    case defeated = 0
  }

  enum BossAttackType {
    case shoot
    case jump
    case charge
    case summon
  }

  enum ParticleType {
    case jumpDust
    case landingImpact
    case movementTrail
    case deathExplosion
    case enemyHit
    case coinSparkle
    case projectileTrail
  }

  enum WeaponType {
    case melee
    case ranged
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
  }
}

extension Chapter22.EnemyDefinition {
  static var patrol: Chapter22.EnemyDefinition { Chapter22.EnemyDefinition(
    size: 16,
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
    flies: false
  )}

  static var flyer: Chapter22.EnemyDefinition { Chapter22.EnemyDefinition(
    size: 16,
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
    flies: true
  )}
}

extension Chapter22 {
  // MARK: - Layout Spacers

  struct SpacerV: GView {
    var body: some GView {
      Control$().sizeV(.expandFill)
    }
  }

  struct SpacerH: GView {
    var body: some GView {
      Control$().sizeH(.expandFill)
    }
  }
}
