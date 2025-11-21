import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter11Goal: GView {
  let x: Float
  let y: Float
  let size: Float

  var body: some GView {
    Area2D$ {
      ColorBox$()
        .size([size, size])
        .color(Color(r: 0.2, g: 0.8, b: 0.2))

      CollisionShape2D$()
        .shape(RectangleShape2D(size: [size, size]))
        .position([size / 2, size / 2])
    }
    .position([x, y])
    .collisionMask(.beta) // Can't detect player without this
    .onSignal(\.bodyEntered) { _, _ in
      Chapter11Event.goalReached.emit()
    }
  }
}
