import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  // MARK: - Hazard Effect Types

  enum HazardEffect {
    case damage(Int)
    case instantKill
    case water
  }

  // MARK: - Generic Hazard Zone

  struct HazardZone: GView {
    let position: Vector2
    let size: Vector2
    let effect: HazardEffect
    let color: Color
    let highlightColor: Color?
    let highlightHeight: Float
    let collisionLayer: Physics2DLayer

    let palette = Palette.shared

    init(
      position: Vector2,
      size: Vector2,
      effect: HazardEffect,
      color: Color,
      highlightColor: Color? = nil,
      highlightHeight: Float = 4,
      collisionLayer: Physics2DLayer = .zeta
    ) {
      self.position = position
      self.size = size
      self.effect = effect
      self.color = color
      self.highlightColor = highlightColor
      self.highlightHeight = highlightHeight
      self.collisionLayer = collisionLayer
    }

    var body: some GView {
      Area2D$ {
        // Main body
        ColorBox$()
          .size(size)
          .color(color)

        // Optional surface highlight
        if let highlight = highlightColor {
          ColorBox$()
            .size([size.x, highlightHeight])
            .color(highlight)
        }

        // Collision
        CollisionShape2D$()
          .shape(RectangleShape2D(size: size))
          .position(size / 2)
      }
      .position(position)
      .collisionLayer(collisionLayer)
      .collisionMask(.beta)
      .onSignal(\.bodyEntered) { _, body in
        guard body is CharacterBody2D else { return }
        switch effect {
        case .damage(let amount):
          Event.playerHit(damage: amount, position: position).emit()
        case .instantKill:
          Event.playerHit(damage: 999, position: position).emit()
        case .water:
          Event.enteredWater.emit()
        }
      }
      .onSignal(\.bodyExited) { _, body in
        guard body is CharacterBody2D else { return }
        if case .water = effect {
          Event.exitedWater.emit()
        }
      }
    }
  }
}
