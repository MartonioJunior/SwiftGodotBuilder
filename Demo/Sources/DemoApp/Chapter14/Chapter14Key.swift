import SwiftGodot
import SwiftGodotBuilder

// MARK: - Key Collectible

struct Chapter14Key: GView {
  let position: Vector2
  let size: Float = 12

  @State var collected: Bool = false

  let palette = Chapter14Palette()

  var body: some GView {
    Area2D$ {
      // Visual representation - key shape
      Polygon2D$()
        .polygon(keyShape())
        .color(palette.key)

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
      Chapter14Event.keyCollected(position: position).emit()
    }
    .onEvent(Chapter14Event.self) { _, event in
      if case .gameReset = event {
        collected = false
      }
    }
  }

  func keyShape() -> PackedVector2Array {
    // Simple square shape
    var points: [Vector2] = []

    points.append(Vector2(x: -2, y: -4)) // Top left
    points.append(Vector2(x: 2, y: -4)) // Top right
    points.append(Vector2(x: 2, y: 4)) // Bottom right
    points.append(Vector2(x: -2, y: 4)) // Bottom left

    return PackedVector2Array(points)
  }
}
