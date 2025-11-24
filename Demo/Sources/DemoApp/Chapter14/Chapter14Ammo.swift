import SwiftGodot
import SwiftGodotBuilder

// MARK: - Ammo Collectible

struct Chapter14Ammo: GView {
  let position: Vector2
  let size: Float = 8

  @State var collected: Bool = false

  let palette = Chapter14Palette()

  var body: some GView {
    Area2D$ {
      // Visual representation - arrow shape (matches HUD ammo color)
      Polygon2D$()
        .polygon(arrowShape())
        .color(palette.ammo)

      // Collision shape
      CollisionShape2D$().shape(RectangleShape2D(size: [size, size]))
    }

    .position(position)
    .collisionLayer(.gamma) // Collectible layer
    .collisionMask(.beta) // Player layer
    .watch($collected) { node, isCollected in
      node.visible = !isCollected
    }
    .onSignal(\.bodyEntered) { _, body in
      guard !collected, body is CharacterBody2D else { return }
      collected = true
      Chapter14Event.ammoCollected(position: position).emit()
    }
    .onEvent(Chapter14Event.self) { _, event in
      if case .gameReset = event {
        collected = false
      }
    }
  }

  func arrowShape() -> PackedVector2Array {
    // Arrow pointing right (matches projectile shape)
    var points: [Vector2] = []

    points.append(Vector2(x: 4, y: 0))      // Tip
    points.append(Vector2(x: 0, y: -3))     // Top back
    points.append(Vector2(x: -2, y: -2))    // Top shaft
    points.append(Vector2(x: -2, y: 2))     // Bottom shaft
    points.append(Vector2(x: 0, y: 3))      // Bottom back

    return PackedVector2Array(points)
  }
}
