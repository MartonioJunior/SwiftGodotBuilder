import SwiftGodot
import SwiftGodotBuilder

extension Chapter22 {
  // MARK: - Collectible Definition

  struct CollectibleDefinition {
    let size: Float
    let color: Color
    let shape: PackedVector2Array
    let collectEvent: (Vector2) -> Event
  }

  // MARK: - Generic Collectible

  struct Collectible: GView {
    let position: Vector2
    let size: Float
    let color: Color
    let shape: PackedVector2Array
    let collectEvent: (Vector2) -> Event

    init(position: Vector2, _ definition: CollectibleDefinition) {
      self.position = position
      size = definition.size
      color = definition.color
      shape = definition.shape
      collectEvent = definition.collectEvent
    }

    @State var collected = false

    var body: some GView {
      Area2D$ {
        Polygon2D$().polygon(shape).color(color)
        CollisionShape2D$().shape(RectangleShape2D(size: [size, size]))
      }
      .position(position)
      .collisionLayer(.gamma)
      .collisionMask(.beta)
      .bind(\.visible, to: $collected) { !$0 }
      .onSignal(\.bodyEntered) { [collectEvent, position] _, body in
        guard !collected, body is CharacterBody2D else { return }
        collected = true
        collectEvent(position).emit()
      }
      .onEvent(Event.self) { _, event in
        if case .gameReset = event { collected = false }
      }
    }
  }
}

// MARK: - Collectible Definitions

extension Chapter22.CollectibleDefinition {
  static func coin(_ palette: Chapter22.Palette) -> Chapter22.CollectibleDefinition {
    Chapter22.CollectibleDefinition(
      size: 8,
      color: palette.coin,
      shape: palette.octagonShape(radius: 4),
      collectEvent: { Chapter22.Event.coinCollected(position: $0) }
    )
  }

  static func key(_ palette: Chapter22.Palette) -> Chapter22.CollectibleDefinition {
    Chapter22.CollectibleDefinition(
      size: 12,
      color: palette.key,
      shape: palette.keyShape(),
      collectEvent: { Chapter22.Event.keyCollected(position: $0) }
    )
  }

  static func ammo(_ palette: Chapter22.Palette) -> Chapter22.CollectibleDefinition {
    Chapter22.CollectibleDefinition(
      size: 8,
      color: palette.ammo,
      shape: palette.arrowShape(),
      collectEvent: { Chapter22.Event.ammoCollected(position: $0) }
    )
  }

  static func health(_ palette: Chapter22.Palette) -> Chapter22.CollectibleDefinition {
    Chapter22.CollectibleDefinition(
      size: 12,
      color: palette.healthDrop,
      shape: palette.heartShape(size: 12),
      collectEvent: { Chapter22.Event.healthCollected(position: $0) }
    )
  }
}
