import SwiftGodot
import SwiftGodotBuilder

extension Chapter18 {
  /// A lava zone that damages the player on contact
  struct LavaZone: GView {
    let position: Vector2
    let width: Float
    let height: Float
    let damagePerSecond: Int
    let instantKill: Bool

    let palette = Palette()

    init(
      position: Vector2,
      width: Float,
      height: Float,
      damagePerSecond: Int = 1,
      instantKill: Bool = false
    ) {
      self.position = position
      self.width = width
      self.height = height
      self.damagePerSecond = damagePerSecond
      self.instantKill = instantKill
    }

    var body: some GView {
      Area2D$ {
        // Main lava body
        ColorBox$()
          .size([width, height])
          .color(palette.lava)

        // Surface glow/highlight
        ColorBox$()
          .size([width, 4])
          .color(palette.lavaGlow)

        // Collision for damage
        CollisionShape2D$()
          .shape(RectangleShape2D(w: width, h: height - 4))
          .position([width / 2, height / 2 + 2])
      }
      .position(position)
      .collisionLayer(.zeta) // Hazard layer
      .collisionMask(.beta) // Player layer
      .onSignal(\.bodyEntered) { _, body in
        if body is CharacterBody2D {
          if instantKill {
            Event.playerHit(damage: 999, position: position).emit()
          } else {
            Event.playerHit(damage: damagePerSecond, position: position).emit()
          }
        }
      }
    }
  }
}
