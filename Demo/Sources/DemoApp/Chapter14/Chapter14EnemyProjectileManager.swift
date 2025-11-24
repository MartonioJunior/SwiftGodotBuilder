import SwiftGodot
import SwiftGodotBuilder

struct Chapter14EnemyProjectileManager: GView {
  var body: some GView {
    Node2D$()
      .onEvent(Chapter14Event.self) { node, event in
        if case let .enemyProjectileFired(position, direction) = event {
          spawnProjectile(at: position, direction: direction, parent: node)
        }
      }
  }

  func spawnProjectile(at position: Vector2, direction: Vector2, parent: Node) {
    let projectile = Chapter14EnemyProjectile(startPosition: position, direction: direction)
    let node = projectile.toNode()
    parent.addChild(node: node)
  }
}
