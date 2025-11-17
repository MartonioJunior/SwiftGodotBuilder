export default `import SwiftGodot
import SwiftGodotBuilder

struct CollectibleItem: GView {
  let position: Vector2
  let itemType: Item

  var body: some GView {
    Area2D$ {
      ColorBox$()
        .color(.yellow)
        .size([16, 16])
        .position([-8, -8])

      CollisionShape2D$()
        .shape(RectangleShape2D(w: 16, h: 16))
    }
    .position(position)
  }
}`;
