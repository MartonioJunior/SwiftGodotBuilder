import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Ammo Collectible

struct Chapter10Ammo: GView {
  let position: Vector2
  let size: Float = 8

  @State var collected: Bool = false

  var body: some GView {
    Area2D$ {
      // Visual representation - cyan/blue color for ammo
      ColorBox$()
        .size([size, size])
        .position([-size / 2, -size / 2])
        .color(Color(r: 0.3, g: 0.8, b: 1.0))

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
      Chapter10Event.ammoCollected(position: position).emit()
    }
    .onEvent(Chapter10Event.self) { _, event in
      if case .gameReset = event {
        collected = false
      }
    }
  }
}
