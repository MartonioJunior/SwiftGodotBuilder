export default `import SwiftGodot
import SwiftGodotBuilder

@Godot
class Item: Area2D {
}

struct ItemView: GView {
  var body: some GView {
    Item$ {
      ColorBox$()
        .color(.yellow)
        .size([16, 16])
        .position([-8, -8]) // Center the box

      CollisionShape2D$()
        .shape(RectangleShape2D(w: 16, h: 16))
    }
    .monitoringEnabled(true)
  }
}`;
