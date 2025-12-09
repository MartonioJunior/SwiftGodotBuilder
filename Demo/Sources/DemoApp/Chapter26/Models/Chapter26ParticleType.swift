import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  enum ParticleType: CaseIterable {
    case jumpDust
    case landingImpact
    case movementTrail
    case deathExplosion
    case enemyHit
    case coinSparkle
    case projectileTrail
    case meleeSwoosh
    case meleeImpact
    case rangedMuzzleFlash
    case terrainDebris

    // Particle colors
    private static let gray = Color(code: "#CCCCCC99")
    private static let darkGray = Color(code: "#B3B3B3B3")
    private static let blue = Color(code: "#4D80E666")
    private static let red = Color(code: "#FF4D4DCC")
    private static let orange = Color(code: "#FF8000B3")
    private static let yellow = Color(code: "#FFFF66E6")
    private static let yellowAlt = Color(code: "#FFE64DCC")
    private static let white = Color(code: "#FFFFFFCC")
    private static let cyan = Color(code: "#66FFFFCC")
    private static let brown = Color(code: "#8B7355CC")

    var config: ParticleConfig {
      switch self {
      case .jumpDust:
        ParticleConfig(
          amount: 8, lifetime: 0.3, explosiveness: 1.0,
          direction: [0, -1], spread: 45,
          initialVelocityMin: 20, initialVelocityMax: 50,
          gravity: [0, 100], color: Self.gray
        )
      case .landingImpact:
        ParticleConfig(
          amount: 12, lifetime: 0.4, explosiveness: 1.0,
          direction: [0, -1], spread: 60,
          initialVelocityMin: 30, initialVelocityMax: 80,
          gravity: [0, 150], color: Self.darkGray
        )
      case .movementTrail:
        ParticleConfig(
          amount: 3, lifetime: 0.2, explosiveness: 0.0,
          direction: [0, 0], spread: 20,
          initialVelocityMin: 5, initialVelocityMax: 10,
          gravity: [0, 0], color: Self.blue
        )
      case .deathExplosion:
        ParticleConfig(
          amount: 30, lifetime: 0.8, explosiveness: 1.0,
          direction: [0, -1], spread: 180,
          initialVelocityMin: 80, initialVelocityMax: 150,
          gravity: [0, 300], color: Self.red
        )
      case .enemyHit:
        ParticleConfig(
          amount: 8, lifetime: 0.3, explosiveness: 1.0,
          direction: [0, -1], spread: 90,
          initialVelocityMin: 40, initialVelocityMax: 80,
          gravity: [0, 200], color: Self.orange
        )
      case .coinSparkle:
        ParticleConfig(
          amount: 15, lifetime: 0.5, explosiveness: 1.0,
          direction: [0, -1], spread: 360,
          initialVelocityMin: 20, initialVelocityMax: 60,
          gravity: [0, -50], color: Self.yellow
        )
      case .projectileTrail:
        ParticleConfig(
          amount: 8, lifetime: 0.3, explosiveness: 1.0,
          direction: [0, 0], spread: 180,
          initialVelocityMin: 10, initialVelocityMax: 30,
          gravity: [0, 0], color: Self.yellowAlt
        )
      case .meleeSwoosh:
        ParticleConfig(
          amount: 5, lifetime: 0.1, explosiveness: 1.0,
          direction: [1, 0], spread: 40,
          initialVelocityMin: 30, initialVelocityMax: 60,
          gravity: [0, 0], color: Color(code: "#FFFFFF66") // Subtle white
        )
      case .meleeImpact:
        ParticleConfig(
          amount: 10, lifetime: 0.2, explosiveness: 1.0,
          direction: [0, -1], spread: 60,
          initialVelocityMin: 50, initialVelocityMax: 100,
          gravity: [0, 150], color: Self.orange
        )
      case .rangedMuzzleFlash:
        ParticleConfig(
          amount: 6, lifetime: 0.1, explosiveness: 1.0,
          direction: [1, 0], spread: 20,
          initialVelocityMin: 80, initialVelocityMax: 120,
          gravity: [0, 0], color: Self.cyan
        )
      case .terrainDebris:
        ParticleConfig(
          amount: 12, lifetime: 0.5, explosiveness: 1.0,
          direction: [0, -1], spread: 120,
          initialVelocityMin: 40, initialVelocityMax: 100,
          gravity: [0, 400], color: Self.brown
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
}
