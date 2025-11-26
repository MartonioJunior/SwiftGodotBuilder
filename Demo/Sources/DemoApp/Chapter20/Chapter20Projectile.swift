import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
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
      position = startPosition
      velocity = self.direction * speed
    }

    var body: some GView {
      Area2D$ {
        Polygon2D$().polygon(arrowShape()).color(palette.projectile)
        CollisionShape2D$().shape(RectangleShape2D(w: size, h: size))
      }
      .position($position)
      .collisionLayer(.delta)
      .collisionMask([.alpha, .delta])
      .onSignal(\.bodyEntered) { node, _ in
        destroyProjectile(node, hitEnemy: false)
      }
      .onSignal(\.areaEntered) { node, _ in
        destroyProjectile(node, hitEnemy: true)
      }
      .onProcess { node, delta in
        guard !isDestroyed else { return }
        position += velocity * Float(delta)
        age += delta
        if age > lifetime || position.x < -50 || position.x > 850 || position.y < -50 || position.y > 230 {
          destroyProjectile(node, hitEnemy: false)
        }
      }
    }

    func destroyProjectile(_ node: Node, hitEnemy: Bool) {
      guard !isDestroyed else { return }
      isDestroyed = true

      if hitEnemy {
        Event.projectileHitEnemy(position: position).emit()
      } else {
        Event.projectileHitWall(position: position).emit()
      }
      node.queueFree()
    }

    func arrowShape() -> PackedVector2Array {
      if direction.x >= 0 {
        return PackedVector2Array([[4, 0], [0, -3], [-2, -2], [-2, 2], [0, 3]])
      } else {
        return PackedVector2Array([[-4, 0], [0, -3], [2, -2], [2, 2], [0, 3]])
      }
    }
  }
}
