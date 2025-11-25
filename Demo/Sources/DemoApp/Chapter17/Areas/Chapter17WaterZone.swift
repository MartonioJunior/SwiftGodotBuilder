import SwiftGodot
import SwiftGodotBuilder

extension Chapter17 {
  /// A water zone that slows the player and allows swimming
  struct WaterZone: GView {
    let position: Vector2
    let width: Float
    let height: Float

    let palette = Palette()

    init(position: Vector2, width: Float, height: Float) {
      self.position = position
      self.width = width
      self.height = height
    }

    var body: some GView {
      Area2D$ {
        // Main water body (semi-transparent)
        ColorBox$()
          .size([width, height])
          .color(palette.water.withAlpha(0.6))

        // Surface highlight
        ColorBox$()
          .size([width, 3])
          .color(palette.waterSurface.withAlpha(0.8))

        // Collision for water effect
        CollisionShape2D$()
          .shape(RectangleShape2D(w: width, h: height))
          .position([width / 2, height / 2])
      }
      .position(position)
      .collisionLayer(.eta) // Water layer
      .collisionMask(.beta) // Player layer
      .onSignal(\.bodyEntered) { _, body in
        if body is CharacterBody2D {
          Event.enteredWater.emit()
        }
      }
      .onSignal(\.bodyExited) { _, body in
        if body is CharacterBody2D {
          Event.exitedWater.emit()
        }
      }
    }
  }
}
