import SwiftGodot
import SwiftGodotBuilder

// MARK: - Key Collectible

extension Chapter17 {
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
      PackedVector2Array([
        [-2, -4], // Top left
        [2, -4],  // Top right
        [2, 4],   // Bottom right
        [-2, 4]   // Bottom left
      ])
    }
  }
}
