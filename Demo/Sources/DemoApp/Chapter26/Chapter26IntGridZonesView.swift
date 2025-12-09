import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  /// Builds Area2D zones from an IntGrid layer for hazards and environment effects.
  /// Supports value identifiers: "Damage", "Kill", "Water"
  struct IntGridZonesView: GView {
    let layer: LDLayer
    let project: LDProject

    var body: some GView {
      LDIntGridZonesView(layer: layer, project: project)
        .collisionLayer(Physics2DLayer.hazard.rawValue)
        .collisionMask(Physics2DLayer.player.rawValue)
        .onZoneEnter { zone, body in
          guard body is CharacterBody2D else { return }
          switch zone.identifier {
          case "damage":
            GameEvent.playerHit(damage: 1, position: zone.position).emit()
          case "kill":
            GameEvent.playerHit(damage: 999, position: zone.position).emit()
          case "water":
            GameEvent.enteredWater.emit()
          default:
            break
          }
        }
        .onZoneExit { zone, body in
          guard body is CharacterBody2D else { return }
          if zone.identifier == "water" {
            GameEvent.exitedWater.emit()
          }
        }
    }
  }
}
