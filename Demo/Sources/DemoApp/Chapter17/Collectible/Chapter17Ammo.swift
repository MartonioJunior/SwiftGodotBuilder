import SwiftGodot
import SwiftGodotBuilder

// MARK: - Ammo Collectible

extension Chapter17 {
  struct Ammo: GView {
    let position: Vector2
    let size: Float = 8

    @State var collected = false

    let palette = Palette()

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
      .bind(\.visible, to: $collected) { !$0 }
      .onSignal(\.bodyEntered) { _, body in
        guard !collected, body is CharacterBody2D else { return }
        collected = true
        Event.ammoCollected(position: position).emit()
      }
      .onEvent(Event.self) { _, event in
        if case .gameReset = event {
          collected = false
        }
      }
    }

    func arrowShape() -> PackedVector2Array {
      // Arrow pointing right (matches projectile shape)
      PackedVector2Array([
        [4, 0],   // Tip
        [0, -3],  // Top back
        [-2, -2], // Top shaft
        [-2, 2],  // Bottom shaft
        [0, 3]    // Bottom back
      ])
    }
  }
}
