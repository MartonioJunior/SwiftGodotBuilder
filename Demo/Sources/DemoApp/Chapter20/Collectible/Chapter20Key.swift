import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  struct KeyPickup: GView {
    let position: Vector2
    let size: Float = 12

    @State var collected = false

    let palette = Palette()

    var body: some GView {
      Area2D$ {
        Polygon2D$().polygon(keyShape()).color(palette.key)
        CollisionShape2D$().shape(RectangleShape2D(size: [size, size]))
      }
      .position(position)
      .collisionLayer(.gamma)
      .collisionMask(.beta)
      .bind(\.visible, to: $collected) { !$0 }
      .onSignal(\.bodyEntered) { _, body in
        guard !collected, body is CharacterBody2D else { return }
        collected = true
        Event.keyCollected(position: position).emit()
      }
      .onEvent(Event.self) { _, event in
        if case .gameReset = event { collected = false }
      }
    }

    func keyShape() -> PackedVector2Array {
      PackedVector2Array([[-2, -4], [2, -4], [2, 4], [-2, 4]])
    }
  }
}
