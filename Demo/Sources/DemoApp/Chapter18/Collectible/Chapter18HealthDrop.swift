import SwiftGodot
import SwiftGodotBuilder

extension Chapter18 {
  struct HealthDrop: GView {
    let spawnPosition: Vector2
    let despawnTime: Double = 10.0

    @State var position: Vector2
    @State var velocity: Vector2 = [0, -50] // Float up initially
    @State var lifetime = 0.0
    @State var collected = false

    let palette = Palette()

    init(spawnPosition: Vector2) {
      self.spawnPosition = spawnPosition
      position = spawnPosition
    }

    var body: some GView {
      CharacterBody2D$ {
        // Heart shape polygon
        Polygon2D$()
          .polygon(heartShape())
          .color(palette.healthDrop)

        CollisionShape2D$()
          .shape(RectangleShape2D(w: 12, h: 12))
          .position([6, 6])

        // Detection area for player pickup
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(w: 12, h: 12))
            .position([6, 6])
        }
        .collisionLayer(.epsilon) // Pickup detection layer (not targeted by projectiles)
        .collisionMask(.beta) // Player only
        .onSignal(\.bodyEntered) { node, body in
          guard !collected else { return }
          if body is CharacterBody2D {
            collected = true
            Event.healthCollected(position: position).emit()
            node.getParent()?.queueFree()
          }
        }
      }
      .position($position)
      .velocity($velocity)
      .collisionLayer(.gamma)
      .collisionMask(.alpha) // Collide with terrain
      .onProcess { body, delta in
        guard !collected else { return }

        lifetime += delta

        // Despawn after timeout
        if lifetime >= despawnTime {
          body.queueFree()
          return
        }

        // Float up briefly, then fall
        if lifetime < 0.3 {
          velocity.y = -50
        } else {
          velocity.y += 300 * Float(delta) // Gravity
        }

        // Apply velocity and move
        body.velocity = velocity
        body.moveAndSlide()
        velocity = body.velocity
        position = body.position
      }
    }

    func heartShape() -> PackedVector2Array {
      // Heart shape centered around origin
      PackedVector2Array([
        // Top left curve
        [0, 2],
        [-3, -1],
        [-5, 0],
        [-5, 2],
        [-4, 4],
        // Top middle
        [-2, 5],
        [0, 5],
        [2, 5],
        // Top right curve
        [4, 4],
        [5, 2],
        [5, 0],
        [3, -1],
        // Bottom point
        [0, -6],
        // Finish shape
        [-3, -1],
      ])
    }
  }
}
