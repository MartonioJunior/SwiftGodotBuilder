import SwiftGodot
import SwiftGodotBuilder

struct Chapter13EnemyProjectile: GView {
  let startPosition: Vector2
  let direction: Vector2
  let speed: Float = 250
  let size: Float = 6
  let lifetime: Double = 3.0

  @State var position: Vector2
  @State var velocity: Vector2
  @State var age: Double = 0
  @State var isDestroyed: Bool = false

  let palette = Palette()

  init(startPosition: Vector2, direction: Vector2) {
    self.startPosition = startPosition
    self.direction = direction.normalized()
    position = startPosition
    velocity = self.direction * speed
  }

  var body: some GView {
    Area2D$ {
      // Diamond shape for enemy projectiles
      Polygon2D$()
        .polygon(diamondShape())
        .color(palette.enemyProjectile) // Red/orange for enemy projectiles

      CollisionShape2D$()
        .shape(RectangleShape2D(w: size, h: size))
        .position([size / 2, size / 2])
    }
    .position($position)
    .collisionLayer(.gamma) // Enemy attacks
    .collisionMask([.alpha, .beta]) // Hit walls and player
    .onSignal(\.bodyEntered) { node, body in
      // Hit wall or player body
      if body is TileMap || body is StaticBody2D {
        Chapter13Event.projectileHitWall(position: position).emit()
      } else if body is CharacterBody2D {
        // Hit player
        Chapter13Event.playerHit(damage: 1, position: position).emit()
      }
      node.queueFree()
    }
    .onProcess { node, delta in
      age += delta

      // Despawn after lifetime
      if age >= lifetime {
        node.queueFree()
        return
      }

      // Move projectile
      position += velocity * Float(delta)
    }
  }

  func diamondShape() -> PackedVector2Array {
    // Diamond shape (4 points)
    var points: [Vector2] = []
    let halfSize = size / 2

    points.append(Vector2(x: 0, y: -halfSize))         // Top
    points.append(Vector2(x: halfSize, y: 0))          // Right
    points.append(Vector2(x: 0, y: halfSize))          // Bottom
    points.append(Vector2(x: -halfSize, y: 0))         // Left

    return PackedVector2Array(points)
  }
}
