import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  typealias ParticlePool = TypedParticlePool<ParticleType, CPUParticles2D>

  struct ParticleSpawner: GView {
    let pool = TypedParticlePool<ParticleType, CPUParticles2D>(
      keys: ParticleType.allCases,
      config: .init(prewarmPerType: 15, defaultLifetime: 1.0),
      factory: { $0.makeNode() }
    )

    var body: some GView {
      Node2D$()
        .onReady { node in
          pool.setup(parent: node)
        }
        // Actor events (for ActorView-based views)
        .onEvent(ActorEvent.self) { _, event in
          switch event {
          case let .jumped(_, position):
            pool.spawn(type: .jumpDust, at: position)

          case let .landed(_, position, _):
            pool.spawn(type: .landingImpact, at: position)

          case let .died(_, position):
            pool.spawn(type: .deathExplosion, at: position)

          case let .meleeAttacked(_, position, facing):
            let scale: Vector2 = [facing.sign, 1]
            pool.spawn(type: .meleeSwoosh, at: position, scale: scale)

          case let .meleeHit(_, _, position, _):
            pool.spawn(type: .meleeImpact, at: position)

          case let .projectileFired(_, position, direction, _):
            // Muzzle flash - flip based on direction
            let scale: Vector2 = [direction.x >= 0 ? -1 : 1, 1]
            pool.spawn(type: .rangedMuzzleFlash, at: position, scale: scale)

          case let .projectileHitWall(_, position):
            pool.spawn(type: .projectileTrail, at: position)

          case let .projectileHitTarget(_, _, position, _):
            pool.spawn(type: .projectileTrail, at: position)

          default:
            break
          }
        }
        // Game events (for legacy PlayerView/EnemyView and item collection)
        .onEvent(GameEvent.self) { _, event in
          switch event {
          case let .playerJumped(position):
            pool.spawn(type: .jumpDust, at: position)

          case let .playerLanded(position, _):
            pool.spawn(type: .landingImpact, at: position)

          case let .playerDied(position):
            pool.spawn(type: .deathExplosion, at: position)

          case let .enemyKilled(position):
            pool.spawn(type: .enemyHit, at: position)

          case let .playerAttacked(position, facing):
            let scale: Vector2 = [facing.sign, 1]
            pool.spawn(type: .meleeSwoosh, at: position, scale: scale)

          case let .projectileFired(position, direction):
            // Muzzle flash - flip based on direction, center on arrow
            let scale: Vector2 = [direction.x >= 0 ? -1 : 1, 1]
            let arrowSize = AseSprite.frameSize(path: "Interactables", tag: "Arrow")
            let centeredPos = position + arrowSize / 2
            pool.spawn(type: .rangedMuzzleFlash, at: centeredPos, scale: scale)

          case let .consumableCollected(consumable, position):
            if consumable == .coin || consumable == .key {
              pool.spawn(type: .coinSparkle, at: position)
            }
            // No particle for health

          case let .weaponCollected(_, position):
            pool.spawn(type: .coinSparkle, at: position)

          case let .ammoCollected(_, _, position):
            pool.spawn(type: .coinSparkle, at: position)

          case let .projectileHitWall(position):
            pool.spawn(type: .projectileTrail, at: position)

          case let .enemyHitByProjectile(_, position):
            pool.spawn(type: .projectileTrail, at: position)

          case let .terrainDestroyed(position):
            pool.spawn(type: .terrainDebris, at: position)

          default:
            break
          }
        }
    }
  }
}
