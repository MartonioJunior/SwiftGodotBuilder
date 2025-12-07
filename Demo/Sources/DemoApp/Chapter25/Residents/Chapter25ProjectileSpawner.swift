import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct ProjectileSpawner: GView {
    static let projectileColor = Color(code: "#4DFF66")

    let projectilePool = AreaPool {
      Area2D$ {
        ColorBox$()
          .size([2, 2])
          .color(projectileColor)

        CollisionShape2D$()
          .shape(RectangleShape2D(w: 2, h: 2))
          .position([1, 1])
      }
      .collisionLayer(Physics2DLayer.combat.rawValue)
      .collisionMask(Physics2DLayer([.terrain, .combat]).rawValue)
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
          if case let .projectileFired(position, direction) = event {
            projectilePool.fire(at: position, direction: direction, parent: node)
          }
        }
    }
  }
}
