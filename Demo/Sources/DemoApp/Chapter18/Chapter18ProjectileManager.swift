import SwiftGodot
import SwiftGodotBuilder

extension Chapter18 {
  struct ProjectileManager: GView {
    var body: some GView {
      Node2D$()
        .onEvent(Event.self) { node, event in
          if case let .projectileFired(position, direction) = event {
            spawnProjectile(at: position, direction: direction, parent: node)
          }
        }
    }

    func spawnProjectile(at position: Vector2, direction: Vector2, parent: Node) {
      let projectile = Projectile(
        startPosition: position,
        direction: direction
      ).toNode()

      parent.addChild(node: projectile)
    }
  }
}
