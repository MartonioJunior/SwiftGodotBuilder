import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Builds Area2D zones from an IntGrid layer for hazards and environment effects.
  /// Zones emit ActorEvent.enteredZone/exitedZone when bodies enter/exit.
  /// Supports value identifiers: "damage", "kill", "water"
  struct IntGridZonesView: GView {
    let layer: LDLayer
    let project: LDProject

    var body: some GView {
      LDIntGridZonesView(layer: layer, project: project)
        .collisionLayer(Physics2DLayer.hazard.rawValue)
        .collisionMask(Physics2DLayer.player.rawValue)
    }
  }
}
