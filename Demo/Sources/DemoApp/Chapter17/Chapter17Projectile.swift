import SwiftGodot
import SwiftGodotBuilder

// MARK: - Projectile Entity

extension Chapter17 {
  struct Projectile: GView {
    let startPosition: Vector2
    let direction: Vector2
    let speed: Float = 300
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
      self.position = startPosition
      self.velocity = self.direction * speed
    }

    var body: some GView {
      Area2D$ {
        // Visual representation - arrow shape
        Polygon2D$()
          .polygon(arrowShape())
          .color(palette.projectile)

        CollisionShape2D$()
          .shape(RectangleShape2D(w: size, h: size))
      }
      .position($position)
      .collisionLayer(.delta) // Projectile layer (same as attack)
      .collisionMask([.alpha, .delta]) // Hit environment and enemies
      .onSignal(\.bodyEntered) { node, _ in
        // Hit something solid (walls, platforms)
        destroyProjectile(node, hitEnemy: false)
      }
      .onSignal(\.areaEntered) { node, _ in
        // Hit enemy (they will take damage from their own collision handler)
        destroyProjectile(node, hitEnemy: true)
      }
      .onProcess { node, delta in
        guard !isDestroyed else { return }

        // Update position
        position += velocity * Float(delta)
        age += delta

        // Destroy if too old or off screen
        if age > lifetime || position.x < -50 || position.x > 850 || position.y < -50 || position.y > 230 {
          destroyProjectile(node, hitEnemy: false)
        }
      }
    }

    func destroyProjectile(_ node: Node, hitEnemy: Bool) {
      guard !isDestroyed else { return }
      isDestroyed = true

      // Emit appropriate event based on what was hit
      if hitEnemy {
        Event.projectileHitEnemy(position: position).emit()
      } else {
        Event.projectileHitWall(position: position).emit()
      }

      // Remove from scene
      node.queueFree()
    }

    func arrowShape() -> PackedVector2Array {
      // Arrow shape pointing in the direction of movement
      let pointingRight = direction.x >= 0

      if pointingRight {
        // Arrow pointing right
        return PackedVector2Array([
          [4, 0],   // Tip
          [0, -3],  // Top back
          [-2, -2], // Top shaft
          [-2, 2],  // Bottom shaft
          [0, 3]    // Bottom back
        ])
      } else {
        // Arrow pointing left
        return PackedVector2Array([
          [-4, 0],  // Tip
          [0, -3],  // Top back
          [2, -2],  // Top shaft
          [2, 2],   // Bottom shaft
          [0, 3]    // Bottom back
        ])
      }
    }
  }
}
