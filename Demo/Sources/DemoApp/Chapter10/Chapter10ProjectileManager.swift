import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Projectile Manager

struct Chapter10ProjectileManager: GView {
  var body: some GView {
    Node2D$()
      .onEvent(Chapter10Event.self) { node, event in
        if case let .projectileFired(position, direction) = event {
          spawnProjectile(at: position, direction: direction, parent: node)
        }
      }
  }

  func spawnProjectile(at position: Vector2, direction: Vector2, parent: Node) {
    let projectile = Chapter10Projectile(
      startPosition: position,
      direction: direction
    ).toNode()

    parent.addChild(node: projectile)
  }
}
