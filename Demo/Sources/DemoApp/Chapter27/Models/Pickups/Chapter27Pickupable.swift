import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Protocol for anything that can be rendered as a ground pickup
  protocol Pickupable {
    var sprite: String { get }
    var animation: String { get }
    var size: Vector2 { get }
  }
}

// MARK: - Conformances

extension Chapter27.ConsumableDefinition: Chapter27.Pickupable {}

extension ActorWeapon: Chapter27.Pickupable {
  var sprite: String { pickupSprite ?? "Items" }
  var animation: String { pickupAnimation ?? id }
  var size: Vector2 { pickupSize }
}
