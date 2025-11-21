import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter1Goal: GView {
  let x: Float
  let y: Float
  let size: Float

  var body: some GView {
    Area2D$ {
      ColorBox$()
        .size([size, size])
        .color(Color(r: 0.2, g: 0.8, b: 0.2))

      CollisionShape2D$()
        .shape(RectangleShape2D(w: size, h: size))
        .position([size / 2, size / 2])
    }
    .position([x, y])
    .onSignal(\.bodyEntered) { _, _ in
      Chapter1Event.goalReached.emit()
    }
  }
}
