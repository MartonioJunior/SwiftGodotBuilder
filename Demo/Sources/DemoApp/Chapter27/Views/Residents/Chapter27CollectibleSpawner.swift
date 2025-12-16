import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Spawns pickups dynamically from game events (enemy drops, chests, etc.)
  struct DropSpawner: GView {
    var body: some GView {
      NodeSpawner(GameEvent.self) { event in
        if case let .itemDropped(dropType, position) = event {
          return createPickup(dropType, at: position)
        }
        return nil
      } resetWhen: { event in
        if case .gameReset = event { return true }
        return false
      }
    }

    private func createPickup(_ dropType: DropType, at position: Vector2) -> Node2D? {
      switch dropType {
      case let .consumable(consumable):
        return ConsumablePickupView(position: position, consumable: consumable).toNode() as? Node2D
      case let .weapon(weapon):
        return WeaponPickupView(position: position, weapon: weapon).toNode() as? Node2D
      case let .ammo(weapon, amount):
        return AmmoPickupView(position: position, weapon: weapon, amount: amount).toNode() as? Node2D
      }
    }
  }
}
