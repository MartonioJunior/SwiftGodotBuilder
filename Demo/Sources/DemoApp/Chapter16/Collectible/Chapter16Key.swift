import SwiftGodot
import SwiftGodotBuilder

// MARK: - Key Collectible

extension Chapter16 {
  struct KeyPickup: GView {
    let position: Vector2
    let size: Float = 12

    @State var collected = false

    let palette = Palette()

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
      .bind(\.visible, to: $collected) { !$0 }
      .onSignal(\.bodyEntered) { _, body in
        guard !collected, body is CharacterBody2D else { return }
        collected = true
        Event.keyCollected(position: position).emit()
      }
      .onEvent(Event.self) { _, event in
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
}
