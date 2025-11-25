import SwiftGodot
import SwiftGodotBuilder

// MARK: - Particle Spawner

extension Chapter16 {
  struct ParticleSpawner: GView {
    var body: some GView {
      Node2D$()
        .onEvent(Event.self) { node, event in
          switch event {
          case let .jumped(position):
            spawnParticle(type: .jumpDust, at: position, parent: node)

          case let .landed(position, _):
            spawnParticle(type: .landingImpact, at: position, parent: node)

          case let .playerDied(position):
            spawnParticle(type: .deathExplosion, at: position, parent: node)

          case let .enemyKilled(position):
            spawnParticle(type: .enemyHit, at: position, parent: node)

          case let .coinCollected(position):
            spawnParticle(type: .coinSparkle, at: position, parent: node)

          case let .keyCollected(position):
            spawnParticle(type: .coinSparkle, at: position, parent: node)

          case let .doorUnlocked(position):
            spawnParticle(type: .coinSparkle, at: position, parent: node)

          case let .ammoCollected(position):
            spawnParticle(type: .coinSparkle, at: position, parent: node)

          case let .projectileHitWall(position):
            spawnParticle(type: .projectileTrail, at: position, parent: node)

          case let .projectileHitEnemy(position):
            spawnParticle(type: .projectileTrail, at: position, parent: node)

          default:
            break
          }
        }
    }

    func spawnParticle(type: ParticleType, at position: Vector2, parent: Node) {
      let palette = Palette()
      let config = getParticleConfig(type: type, palette: palette)

      let particles = CPUParticles2D$()
        .position(position)
        .emitting(false)
        .oneShot(true)
        .amount(config.amount)
        .lifetime(config.lifetime)
        .explosiveness(config.explosiveness)
        .direction(config.direction)
        .spread(config.spread)
        .initialVelocityMin(config.initialVelocityMin)
        .initialVelocityMax(config.initialVelocityMax)
        .gravity(config.gravity)
        .color(config.color)
        .toNode() as CPUParticles2D

      parent.addChild(node: particles)
      particles.emitting = true

      // Auto-remove after lifetime
      if let tree = Engine.getSceneTree(),
         let timer = tree.createTimer(timeSec: particles.lifetime + 0.5)
      {
        _ = timer.timeout.connect {
          particles.queueFree()
        }
      }
    }

    func getParticleConfig(type: ParticleType, palette: Palette) -> ParticleConfig {
      switch type {
      case .jumpDust:
        return ParticleConfig(
          amount: 8,
          lifetime: 0.3,
          explosiveness: 1.0,
          direction: Vector2(x: 0, y: -1),
          spread: 45,
          initialVelocityMin: 20,
          initialVelocityMax: 50,
          gravity: Vector2(x: 0, y: 100),
          color: palette.particleGray
        )
      case .landingImpact:
        return ParticleConfig(
          amount: 12,
          lifetime: 0.4,
          explosiveness: 1.0,
          direction: Vector2(x: 0, y: -1),
          spread: 60,
          initialVelocityMin: 30,
          initialVelocityMax: 80,
          gravity: Vector2(x: 0, y: 150),
          color: palette.particleDarkGray
        )
      case .movementTrail:
        return ParticleConfig(
          amount: 3,
          lifetime: 0.2,
          explosiveness: 0.0,
          direction: Vector2(x: 0, y: 0),
          spread: 20,
          initialVelocityMin: 5,
          initialVelocityMax: 10,
          gravity: Vector2(x: 0, y: 0),
          color: palette.particleBlue
        )
      case .deathExplosion:
        return ParticleConfig(
          amount: 30,
          lifetime: 0.8,
          explosiveness: 1.0,
          direction: Vector2(x: 0, y: -1),
          spread: 180,
          initialVelocityMin: 80,
          initialVelocityMax: 150,
          gravity: Vector2(x: 0, y: 300),
          color: palette.particleRed
        )
      case .enemyHit:
        return ParticleConfig(
          amount: 8,
          lifetime: 0.3,
          explosiveness: 1.0,
          direction: Vector2(x: 0, y: -1),
          spread: 90,
          initialVelocityMin: 40,
          initialVelocityMax: 80,
          gravity: Vector2(x: 0, y: 200),
          color: palette.particleOrange
        )
      case .coinSparkle:
        return ParticleConfig(
          amount: 15,
          lifetime: 0.5,
          explosiveness: 1.0,
          direction: Vector2(x: 0, y: -1),
          spread: 360,
          initialVelocityMin: 20,
          initialVelocityMax: 60,
          gravity: Vector2(x: 0, y: -50),
          color: palette.particleYellow
        )
      case .projectileTrail:
        return ParticleConfig(
          amount: 8,
          lifetime: 0.3,
          explosiveness: 1.0,
          direction: Vector2(x: 0, y: 0),
          spread: 180,
          initialVelocityMin: 10,
          initialVelocityMax: 30,
          gravity: Vector2(x: 0, y: 0),
          color: palette.particleYellowAlt
        )
      }
    }
  }
}
