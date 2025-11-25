import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Coin Collectible

extension Chapter17 {
  struct Coin: GView {
    let position: Vector2
    let size: Float = 8

    @State var collected = false

    let palette = Palette()

    var body: some GView {
      Area2D$ {
        // Visual representation - octagon shape
        Polygon2D$()
          .polygon(octagonShape(radius: size / 2))
          .color(palette.coin)

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
        Event.coinCollected(position: position).emit()
      }
      .onEvent(Event.self) { _, event in
        if case .gameReset = event {
          collected = false
        }
      }
    }

    func octagonShape(radius: Float) -> PackedVector2Array {
      // Create an 8-sided polygon (circle approximation)
      var points: [Vector2] = []
      for i in 0..<8 {
        let angle = Float(i) * .pi * 2 / 8
        points.append(Vector2(
          x: cos(angle) * radius,
          y: sin(angle) * radius
        ))
      }
      return PackedVector2Array(points)
    }
  }
}
