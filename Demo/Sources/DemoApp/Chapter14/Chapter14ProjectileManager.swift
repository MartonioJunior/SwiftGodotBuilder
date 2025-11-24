import SwiftGodot
import SwiftGodotBuilder

// MARK: - Projectile Manager

struct Chapter14ProjectileManager: GView {
  var body: some GView {
    Node2D$()
      .onEvent(Chapter14Event.self) { node, event in
        if case let .projectileFired(position, direction) = event {
          spawnProjectile(at: position, direction: direction, parent: node)
        }
      }
  }

  func spawnProjectile(at position: Vector2, direction: Vector2, parent: Node) {
    let projectile = Chapter14Projectile(
      startPosition: position,
      direction: direction
    ).toNode()

    parent.addChild(node: projectile)
  }
}
