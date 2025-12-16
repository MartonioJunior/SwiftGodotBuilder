import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// LDtk-exportable enum for consumable types
  enum ConsumableType: String, LDExported {
    case coin = "Coin"
    case health = "Health"
    case key = "Key"

    // This pattern is needed because LDtk enums can't store associated values
    // so we map to definitions here
    var definition: ConsumableDefinition {
      switch self {
      case .coin: .coin
      case .health: .health
      case .key: .key
      }
    }
  }

  /// Rich definition for consumables with all pickup/effect data
  struct ConsumableDefinition: Equatable {
    let id: String
    let sprite: String
    let animation: String
    let size: Vector2
    let effect: ConsumableEffect

    init(
      id: String,
      sprite: String = "Items",
      animation: String,
      size: Vector2 = [8, 8],
      effect: ConsumableEffect
    ) {
      self.id = id
      self.sprite = sprite
      self.animation = animation
      self.size = size
      self.effect = effect
    }

    static let coin = ConsumableDefinition(
      id: "coin",
      animation: "coinGold",
      effect: .addScore(5)
    )

    static let health = ConsumableDefinition(
      id: "health",
      animation: "heart",
      effect: .heal(1)
    )

    static let key = ConsumableDefinition(
      id: "key",
      animation: "key",
      effect: .giveKey
    )
  }

  enum ConsumableEffect: Equatable {
    case addScore(Int)
    case heal(Int)
    case giveKey
  }

  /// Types of items that can be dropped by enemies or spawned dynamically
  enum DropType {
    case consumable(ConsumableDefinition)
    case weapon(ActorWeapon)
    case ammo(weapon: ActorWeapon, amount: Int)
  }
}
