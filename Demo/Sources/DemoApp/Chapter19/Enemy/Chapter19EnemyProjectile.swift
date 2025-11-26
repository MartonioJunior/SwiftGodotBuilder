import SwiftGodot
import SwiftGodotBuilder

extension Chapter19 {
  struct EnemyProjectile: GView {
    let startPosition: Vector2
    let direction: Vector2
    let speed: Float = 250
    let size: Float = 6
    let lifetime: Double = 3.0

    @State var position: Vector2
    @State var velocity: Vector2
    @State var age = 0.0
    @State var isDestroyed = false

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
          Event.projectileHitWall(position: position).emit()
        } else if body is CharacterBody2D {
          // Hit player
          Event.playerHit(damage: 1, position: position).emit()
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
      let halfSize = size / 2
      return PackedVector2Array([
        [0, -halfSize], // Top
        [halfSize, 0], // Right
        [0, halfSize], // Bottom
        [-halfSize, 0], // Left
      ])
    }
  }
}
