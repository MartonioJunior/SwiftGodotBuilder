import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Coin Collectible

struct Chapter9Coin: GView {
  let position: Vector2
  let size: Float = 8

  @State var collected: Bool = false

  var body: some GView {
    Area2D$ {
      // Visual representation
      ColorBox$()
        .size([size, size])
        .position([-size / 2, -size / 2])
        .color(Color(r: 1.0, g: 0.9, b: 0.3))

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
      Chapter9Event.coinCollected(position: position).emit()
    }
    .onEvent(Chapter9Event.self) { _, event in
      if case .gameReset = event {
        collected = false
      }
    }
  }
}
