export default `import SwiftGodot
import SwiftGodotBuilder

struct CollectibleView: GView {
  let position: Vector2
  let itemType: Item
  @State var isCollected = false

  var body: some GView {
    Area2D$ {
      // Visual representation
      ColorBox$()
        .color(.yellow)
        .size([24, 24])
        .position([-12, -12])

      // Collision shape for pickup detection
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 24, h: 24))
    }
    .position(position)
    .onSignal(\\.bodyEntered) { node, _ in
      guard !isCollected else { return }
      isCollected = true
      GameEvent.itemCollected(itemType).emit()
      node.queueFree()
    }
  }
}`;
