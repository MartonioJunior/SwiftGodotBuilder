import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct ProjectileSpawner: GView {
    static let arrowSize = AseSprite.frameSize(path: "Interactables", tag: "ArrowGray")

    let projectilePool = AreaPool {
      let size = ProjectileSpawner.arrowSize
      return Area2D$ {
        AseSprite$(path: "Interactables")
          .autoplay("ArrowGray")
          .centered(false)

        CollisionShape2D$()
          .shape(RectangleShape2D(w: size.x, h: size.y * 0.375)) // Thin collision for arrow
          .position(size / 2)
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
