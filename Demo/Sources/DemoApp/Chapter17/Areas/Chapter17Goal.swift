import SwiftGodot
import SwiftGodotBuilder

extension Chapter17 {
  struct Goal: GView {
    let x: Float
    let y: Float
    let size: Float

    let palette = Palette()

    var body: some GView {
      Area2D$ {
        ColorBox$()
          .size([size, size])
          .color(palette.goal)

        CollisionShape2D$()
          .shape(RectangleShape2D(size: [size, size]))
          .position([size / 2, size / 2])
      }
      .position([x, y])
      .collisionMask(.beta) // Can't detect player without this
      .onSignal(\.bodyEntered) { _, _ in
        Event.goalReached.emit()
      }
    }
  }
}
