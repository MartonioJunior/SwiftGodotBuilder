import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  /// Item types that can be collected or dropped
  enum Item: String, LDExported {
    case coin = "Coin"
    case key = "Key"
    case ammo = "Ammo"
    case health = "Health"
  }

  /// Definition for a collectible item
  struct CollectibleDefinition {
    let size: Float
    let sprite: ItemSprite
    let animation: SpriteAnimation<ItemSprite>?
    let collectEvent: (Vector2) -> GameEvent

    init(size: Float, sprite: ItemSprite, animation: SpriteAnimation<ItemSprite>? = nil, collectEvent: @escaping (Vector2) -> GameEvent) {
      self.size = size
      self.sprite = sprite
      self.animation = animation
      self.collectEvent = collectEvent
    }
  }
}

// MARK: - Collectible Definitions

extension Chapter25.CollectibleDefinition {
  static var coin: Chapter25.CollectibleDefinition {
    Chapter25.CollectibleDefinition(
      size: 8,
      sprite: .coin1,
      animation: Chapter25.ItemSprite.coinSpin,
      collectEvent: { Chapter25.GameEvent.coinCollected(position: $0) }
    )
  }

  static var key: Chapter25.CollectibleDefinition {
    Chapter25.CollectibleDefinition(
      size: 8,
      sprite: .key,
      collectEvent: { Chapter25.GameEvent.keyCollected(position: $0) }
    )
  }

  static var ammo: Chapter25.CollectibleDefinition {
    Chapter25.CollectibleDefinition(
      size: 8,
      sprite: .emerald,
      collectEvent: { Chapter25.GameEvent.ammoCollected(position: $0) }
    )
  }

  static var health: Chapter25.CollectibleDefinition {
    Chapter25.CollectibleDefinition(
      size: 8,
      sprite: .heartFull,
      collectEvent: { Chapter25.GameEvent.healthCollected(position: $0) }
    )
  }
}
