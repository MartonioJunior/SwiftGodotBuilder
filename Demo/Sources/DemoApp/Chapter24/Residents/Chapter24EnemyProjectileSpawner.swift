import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct EnemyProjectileSpawner: GView {
    static let enemyProjectileColor = Color(code: "#CC3333")

    let enemyProjectilePool = AreaPool {
      Area2D$ {
        Polygon2D$()
          .polygon([[4, 0], [0, -3], [-2, -2], [-2, 2], [0, 3]])
          .color(enemyProjectileColor)
        CollisionShape2D$().shape(RectangleShape2D(w: 6, h: 6))
      }
      .collisionLayer(Physics2DLayer.projectile.rawValue)
      .collisionMask(Physics2DLayer.player.rawValue)
      .onSignal(\.areaEntered) { node, _ in GameEvent.playerHit(damage: 1, position: node.position).emit() }
    }

    var body: some GView {
      Node2D$()
        .onReady { _ in enemyProjectilePool.start() }
        .onProcess { _, delta in enemyProjectilePool.update(delta: delta) }
        .onEvent(GameEvent.self) { node, event in
          if case let .enemyProjectileFired(position, direction) = event {
            enemyProjectilePool.fire(at: position, direction: direction, parent: node)
          }
        }
    }
  }
}
