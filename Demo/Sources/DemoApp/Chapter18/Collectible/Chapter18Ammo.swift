import SwiftGodot
import SwiftGodotBuilder

extension Chapter18 {
  struct Ammo: GView {
    let position: Vector2
    let size: Float = 8

    @State var collected = false

    let palette = Palette()

    var body: some GView {
      Area2D$ {
        Polygon2D$().polygon(arrowShape()).color(palette.ammo)
        CollisionShape2D$().shape(RectangleShape2D(size: [size, size]))
      }
      .position(position)
      .collisionLayer(.gamma)
      .collisionMask(.beta)
      .bind(\.visible, to: $collected) { !$0 }
      .onSignal(\.bodyEntered) { _, body in
        guard !collected, body is CharacterBody2D else { return }
        collected = true
        Event.ammoCollected(position: position).emit()
      }
      .onEvent(Event.self) { _, event in
        if case .gameReset = event { collected = false }
      }
    }

    func arrowShape() -> PackedVector2Array {
      PackedVector2Array([
        [4, 0],
        [0, -3],
        [-2, -2],
        [-2, 2],
        [0, 3],
      ])
    }
  }
}
