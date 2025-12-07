import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct ParticleSpawner: GView {
    let pool = TypedParticlePool(
      keys: ParticleType.allCases,
      config: .init(prewarmPerType: 5, defaultLifetime: 1.0),
      factory: { $0.makeNode() }
    )

    var body: some GView {
      Node2D$()
        .onReady { node in
          pool.setup(parent: node)
        }
        .onEvent(GameEvent.self) { _, event in
          switch event {
          case let .jumped(position):
            pool.spawn(type: .jumpDust, at: position)

          case let .landed(position, _):
            pool.spawn(type: .landingImpact, at: position)

          case let .playerDied(position):
            pool.spawn(type: .deathExplosion, at: position)

          case let .enemyKilled(position):
            pool.spawn(type: .enemyHit, at: position)

          case let .attacked(position, facing):
            // Melee swoosh effect - flip based on facing direction
            let swooshPos = position + [facing.isRight ? 8 : 0, 4]
            let scale: Vector2 = [facing.sign, 1]
            pool.spawn(type: .meleeSwoosh, at: swooshPos, scale: scale)

          case let .meleeHitEnemy(position):
            pool.spawn(type: .meleeImpact, at: position)

          case let .projectileFired(position, direction):
            // Muzzle flash - flip based on direction
            let scale: Vector2 = [direction.x >= 0 ? 1 : -1, 1]
            pool.spawn(type: .rangedMuzzleFlash, at: position, scale: scale)

          case let .coinCollected(position):
            pool.spawn(type: .coinSparkle, at: position)

          case let .keyCollected(position):
            pool.spawn(type: .coinSparkle, at: position)

          case let .doorUnlocked(position):
            pool.spawn(type: .coinSparkle, at: position)

          case let .ammoCollected(position):
            pool.spawn(type: .coinSparkle, at: position)

          case let .projectileHitWall(position):
            pool.spawn(type: .projectileTrail, at: position)

          case let .projectileHitEnemy(position):
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
