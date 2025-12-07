import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  // MARK: - Hazard Effect Types

  enum HazardEffect: String, LDExported {
    case damage = "Damage"
    case instantKill = "InstantKill"
    case water = "Water"
  }

  // MARK: - Generic Hazard Zone

  struct HazardZoneView: GView {
    let position: Vector2
    let size: Vector2
    let effect: HazardEffect
    let damageAmount: Int
    let color: Color
    let collisionLayer: Physics2DLayer

    // Hazard colors
    static let lava = Color(code: "#FF4400")
    static let water = Color(code: "#3366CC")
    static let damageRed = Color(code: "#FF3333")

    init(entity: LDEntity) {
      position = entity.positionTopLeft
      size = entity.size
      effect = entity.field("effect")?.asEnum() ?? .instantKill
      damageAmount = entity.field("damageAmount")?.asInt() ?? 1

      switch effect {
      case .instantKill:
        color = Self.lava
      case .damage:
        color = Self.damageRed
      case .water:
        color = Self.water.withAlpha(0.6)
      }
      collisionLayer = .hazard
    }

    var body: some GView {
      Area2D$ {
        // Main body
        ColorBox$()
          .size(size)
          .color(color)

        // Collision
        CollisionShape2D$()
          .shape(RectangleShape2D(size: size))
          .position(size / 2)
      }
      .position(position)
      .collisionLayer(collisionLayer)
      .collisionMask(.player)
      .onSignal(\.bodyEntered) { _, body in
        guard body is CharacterBody2D else { return }
        switch effect {
        case .damage:
          GameEvent.playerHit(damage: damageAmount, position: position).emit()
        case .instantKill:
          GameEvent.playerHit(damage: 999, position: position).emit()
        case .water:
          GameEvent.enteredWater.emit()
        }
      }
      .onSignal(\.bodyExited) { _, body in
        guard body is CharacterBody2D else { return }
        if case .water = effect {
          GameEvent.exitedWater.emit()
        }
      }
    }
  }
}
