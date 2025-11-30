import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  struct ParticleSpawner: GView {
    let pool: ParticlePool

    var body: some GView {
      Node2D$()
        .onReady { node in
          pool.setup(parent: node)
        }
        .onEvent(Event.self) { _, event in
          switch event {
          case let .jumped(position):
            pool.spawn(type: .jumpDust, at: position)

          case let .landed(position, _):
            pool.spawn(type: .landingImpact, at: position)

          case let .playerDied(position):
            pool.spawn(type: .deathExplosion, at: position)

          case let .enemyKilled(position):
            pool.spawn(type: .enemyHit, at: position)

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

          default:
            break
          }
        }
    }
  }
}
