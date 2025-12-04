import SwiftGodot
import SwiftGodotBuilder

enum Chapter24 {
  enum GameState {
    case splash
    case welcome
    case levelSelect
    case playing
    case paused
    case settings
    case levelComplete
    case gameOver
    case leaderboard
    case dialog
    case death
    case credits
  }
}

// MARK: - State Groups

extension Chapter24.GameState {
  /// States where the game content and HUD should be visible
  static let inGame: Set<Self> = [
    .playing, .paused, .levelComplete, .death, .dialog, .gameOver,
  ]

  /// States where gameplay is active (not paused/dead/etc)
  static let active: Set<Self> = [.playing, .dialog]

  /// Menu states (non-gameplay)
  static let menu: Set<Self> = [
    .splash, .welcome, .levelSelect, .credits, .leaderboard, .settings,
  ]

  var isInGame: Bool { Self.inGame.contains(self) }
  var isActive: Bool { Self.active.contains(self) }
  var isMenu: Bool { Self.menu.contains(self) }
}

extension Chapter24 {
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

  enum ParticleType: CaseIterable {
    case jumpDust
    case landingImpact
    case movementTrail
    case deathExplosion
    case enemyHit
    case coinSparkle
    case projectileTrail

    // Particle colors
    private static let gray = Color(code: "#CCCCCC99")
    private static let darkGray = Color(code: "#B3B3B3B3")
    private static let blue = Color(code: "#4D80E666")
    private static let red = Color(code: "#FF4D4DCC")
    private static let orange = Color(code: "#FF8000B3")
    private static let yellow = Color(code: "#FFFF66E6")
    private static let yellowAlt = Color(code: "#FFE64DCC")

    var config: ParticleConfig {
      switch self {
      case .jumpDust:
        return ParticleConfig(
          amount: 8, lifetime: 0.3, explosiveness: 1.0,
          direction: [0, -1], spread: 45,
          initialVelocityMin: 20, initialVelocityMax: 50,
          gravity: [0, 100], color: Self.gray
        )
      case .landingImpact:
        return ParticleConfig(
          amount: 12, lifetime: 0.4, explosiveness: 1.0,
          direction: [0, -1], spread: 60,
          initialVelocityMin: 30, initialVelocityMax: 80,
          gravity: [0, 150], color: Self.darkGray
        )
      case .movementTrail:
        return ParticleConfig(
          amount: 3, lifetime: 0.2, explosiveness: 0.0,
          direction: [0, 0], spread: 20,
          initialVelocityMin: 5, initialVelocityMax: 10,
          gravity: [0, 0], color: Self.blue
        )
      case .deathExplosion:
        return ParticleConfig(
          amount: 30, lifetime: 0.8, explosiveness: 1.0,
          direction: [0, -1], spread: 180,
          initialVelocityMin: 80, initialVelocityMax: 150,
          gravity: [0, 300], color: Self.red
        )
      case .enemyHit:
        return ParticleConfig(
          amount: 8, lifetime: 0.3, explosiveness: 1.0,
          direction: [0, -1], spread: 90,
          initialVelocityMin: 40, initialVelocityMax: 80,
          gravity: [0, 200], color: Self.orange
        )
      case .coinSparkle:
        return ParticleConfig(
          amount: 15, lifetime: 0.5, explosiveness: 1.0,
          direction: [0, -1], spread: 360,
          initialVelocityMin: 20, initialVelocityMax: 60,
          gravity: [0, -50], color: Self.yellow
        )
      case .projectileTrail:
        return ParticleConfig(
          amount: 8, lifetime: 0.3, explosiveness: 1.0,
          direction: [0, 0], spread: 180,
          initialVelocityMin: 10, initialVelocityMax: 30,
          gravity: [0, 0], color: Self.yellowAlt
        )
      }
    }

    func makeNode() -> CPUParticles2D {
      let c = config
      return CPUParticles2D$()
        .oneShot(true)
        .emitting(false)
        .amount(c.amount)
        .lifetime(c.lifetime)
        .explosiveness(c.explosiveness)
        .direction(c.direction)
        .spread(c.spread)
        .initialVelocityMin(c.initialVelocityMin)
        .initialVelocityMax(c.initialVelocityMax)
        .gravity(c.gravity)
        .color(c.color)
        .toNode() as! CPUParticles2D
    }
  }

  enum WeaponType {
    case melee
    case ranged
  }

  enum EnemyType: String, LDExported {
    case patrol = "Patrol"
    case flyer = "Flyer"
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

extension Chapter24.EnemyDefinition {
  static var patrol: Chapter24.EnemyDefinition { Chapter24.EnemyDefinition(
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
    flies: false
  ) }

  static var flyer: Chapter24.EnemyDefinition { Chapter24.EnemyDefinition(
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
    flies: true
  ) }
}

// MARK: - Player State Types

extension Chapter24 {
  /// Mutually exclusive movement/action states
  enum ActionState {
    case idle
    case walking
    case jumping
    case falling
    case wallSliding
    case dashing
    case swimming
  }

  /// Mutually exclusive damage states
  enum DamageState {
    case normal
    case hit
    case dead
  }

  /// Player facing direction
  enum Facing {
    case left
    case right

    var isRight: Bool { self == .right }
    var sign: Float { self == .right ? 1 : -1 }

    mutating func flip() {
      self = self == .right ? .left : .right
    }
  }

  /// Overlay states that can combine with any action
  enum ActionOverlay {
    case crouching
    case attacking
    case invincible
  }

  typealias ActionOverlayState = Set<ActionOverlay>
}
