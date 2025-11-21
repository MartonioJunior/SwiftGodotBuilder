import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Particle Spawner

struct Chapter5ParticleSpawner: GView {
  var body: some GView {
    Node2D$()
      .onEvent(Chapter5Event.self) { node, event in
        guard case let .spawnParticles(type, position) = event else {
          return
        }
        spawnParticle(type: type, at: position, parent: node)
      }
  }

  func spawnParticle(type: Chapter5ParticleType, at position: Vector2, parent: Node) {
    let config = getChapter5ParticleConfig(type: type)

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

  func getChapter5ParticleConfig(type: Chapter5ParticleType) -> ParticleConfig {
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
        color: Color(r: 0.8, g: 0.8, b: 0.8, a: 0.6)
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
        color: Color(r: 0.7, g: 0.7, b: 0.7, a: 0.7)
      )
    case .movementTrail:
      // Custom config for Chapter 5's blue player trail
      return ParticleConfig(
        amount: 3,
        lifetime: 0.2,
        explosiveness: 0.0,
        direction: Vector2(x: 0, y: 0),
        spread: 20,
        initialVelocityMin: 5,
        initialVelocityMax: 10,
        gravity: Vector2(x: 0, y: 0),
        color: Color(r: 0.3, g: 0.5, b: 0.9, a: 0.4)
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
        color: Color(r: 1.0, g: 0.3, b: 0.3, a: 0.8)
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
        color: Color(r: 1.0, g: 0.5, b: 0.0, a: 0.7)
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
        color: Color(r: 1.0, g: 0.9, b: 0.3, a: 0.9)
      )
    }
  }
}
