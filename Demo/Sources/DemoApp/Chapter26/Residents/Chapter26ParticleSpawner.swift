import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
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
            let scale: Vector2 = [facing.sign, 1]
            pool.spawn(type: .meleeSwoosh, at: position, scale: scale)

          case let .meleeHitEnemy(position):
            pool.spawn(type: .meleeImpact, at: position)

          case let .projectileFired(position, direction):
            // Muzzle flash - flip based on direction, center on arrow
            let scale: Vector2 = [direction.x >= 0 ? -1 : 1, 1]
            let arrowSize = AseSprite.frameSize(path: "Interactables", tag: "ArrowGray")
            let centeredPos = position + arrowSize / 2
            pool.spawn(type: .rangedMuzzleFlash, at: centeredPos, scale: scale)

          case let .collected(item, position):
            switch item {
            case .coin, .key, .ammo:
              pool.spawn(type: .coinSparkle, at: position)
            case .health:
              break // No particle for health
            }

          case let .doorUnlocked(position):
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
