import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct CollectibleView: GView {
    let position: Vector2
    let size: Float
    let color: Color
    let shape: PackedVector2Array
    let collectEvent: (Vector2) -> GameEvent

    init(entity: LDEntity) {
      let itemType: Item = entity.field("type")?.asEnum() ?? .coin
      let definition: CollectibleDefinition
      switch itemType {
      case .coin: definition = .coin
      case .key: definition = .key
      case .ammo: definition = .ammo
      case .health: definition = .health
      }

      position = entity.positionTopLeft
      size = definition.size
      color = definition.color
      shape = definition.shape
      collectEvent = definition.collectEvent
    }

    init(position: Vector2, _ definition: CollectibleDefinition) {
      self.position = position
      size = definition.size
      color = definition.color
      shape = definition.shape
      collectEvent = definition.collectEvent
    }

    @State var collected = false

    var halfSize: Float { size / 2 }
    var collisionSize: Float { size + 1 }

    var body: some GView {
      Area2D$ {
        Polygon2D$()
          .polygon(shape)
          .color(color)
          .position([halfSize, halfSize])
        CollisionShape2D$()
          .shape(RectangleShape2D(size: [collisionSize, collisionSize]))
          .position([halfSize, halfSize])
      }
      .position(position)
      .collisionLayer(.collectible)
      .collisionMask(.interaction)
      .bind(\.visible, to: $collected) { !$0 }
      .onSignal(\.areaEntered) { _, _ in
        guard !collected else { return }
        collected = true
        collectEvent(position).emit()
      }
      .onEvent(GameEvent.self) { _, event in
        if case .gameReset = event { collected = false }
      }
    }
  }
}
