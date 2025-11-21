import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Key Collectible

struct Chapter11Key: GView {
  let position: Vector2
  let size: Float = 12

  @State var collected: Bool = false

  var body: some GView {
    Area2D$ {
      // Visual representation (golden key)
      ColorBox$()
        .size([size, size])
        .position([-size / 2, -size / 2])
        .color(Color(r: 1.0, g: 0.8, b: 0.0))

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
      Chapter11Event.keyCollected(position: position).emit()
    }
    .onEvent(Chapter11Event.self) { _, event in
      if case .gameReset = event {
        collected = false
      }
    }
  }
}
