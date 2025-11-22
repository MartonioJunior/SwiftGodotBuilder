import SwiftGodot
import SwiftGodotBuilder

struct Chapter13Platform: GView {
  let x: Float
  let y: Float
  let width: Float
  let height: Float
  let color: Color

  var body: some GView {
    StaticBody2D$ {
      ColorBox$()
        .size([width, height])
        .color(color)

      CollisionShape2D$()
        .shape(RectangleShape2D(w: width, h: height))
        .position([width / 2, height / 2])
    }
    .position([x, y])
  }
}
