export default `import SwiftGodot
import SwiftGodotBuilder

struct GameView: GView {
  var body: some GView {
    Node2D$ {
      // Ground platform
      StaticBody2D$ {
        ColorBox$()
          .color(.gray)
          .size([800, 50])
          .position([0, 500])

        CollisionShape2D$()
          .shape(RectangleShape2D(w: 800, h: 50))
          .position([400, 525])
      }

      // Player character
      PlayerView()

      // Items scattered in the world
      ItemView()
        .position([300, 400])

      ItemView()
        .position([500, 300])

      ItemView()
        .position([200, 200])
    }
  }
}`;
