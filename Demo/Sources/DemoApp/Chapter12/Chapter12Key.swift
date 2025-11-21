import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Key Collectible

struct Chapter12Key: GView {
  let position: Vector2
  let size: Float = 12

  @State var collected: Bool = false

  var body: some GView {
    Area2D$ {
      // Visual representation - key shape
      Polygon2D$()
        .polygon(keyShape())
        .color(Color(r: 1.0, g: 0.9, b: 0.2))

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
      Chapter12Event.keyCollected(position: position).emit()
    }
    .onEvent(Chapter12Event.self) { _, event in
      if case .gameReset = event {
        collected = false
      }
    }
  }

  func keyShape() -> PackedVector2Array {
    // Simple square shape
    var points: [Vector2] = []

    points.append(Vector2(x: -2, y: -4)) // Top left
    points.append(Vector2(x: 2, y: -4)) // Top right
    points.append(Vector2(x: 2, y: 4)) // Bottom right
    points.append(Vector2(x: -2, y: 4)) // Bottom left

    return PackedVector2Array(points)
  }
}
