import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct ProjectileSpawner: GView {
    static let projectileColor = Color(code: "#4DFF66")

    let projectilePool = AreaPool {
      Area2D$ {
        Polygon2D$()
          .polygon([[4, 0], [0, -3], [-2, -2], [-2, 2], [0, 3]])
          .color(projectileColor)
        CollisionShape2D$().shape(RectangleShape2D(w: 6, h: 6))
      }
      .collisionLayer(Physics2DLayer.combat.rawValue)
      .collisionMask(Physics2DLayer([.terrain, .combat]).rawValue)
      // End of projectile life: notify that it hit something
      // AreaPool will automatically free the projectile
      .onSignal(\.bodyEntered) { node, _ in
        GameEvent.projectileHitWall(position: node.position).emit()
      }
      .onSignal(\.areaEntered) { node, _ in
        GameEvent.projectileHitEnemy(position: node.position).emit()
      }
    }

    var body: some GView {
      Node2D$()
        .onReady { _ in projectilePool.start() }
        .onProcess { _, delta in projectilePool.update(delta: delta) }
        .onEvent(GameEvent.self) { node, event in
          // Start of projectile life: launch it from the pool on event
          if case let .projectileFired(position, direction) = event {
            projectilePool.fire(at: position, direction: direction, parent: node)
          }
        }
    }
  }
}
