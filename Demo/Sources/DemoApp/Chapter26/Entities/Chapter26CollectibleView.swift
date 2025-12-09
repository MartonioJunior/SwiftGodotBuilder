import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct CollectibleView: GView {
    let position: Vector2
    let item: Item

    init(entity: LDEntity) {
      item = entity.field("type")?.asEnum() ?? .coin
      position = entity.positionTopLeft
    }

    init(position: Vector2, _ item: Item) {
      self.position = position
      self.item = item
    }

    @State var collected = false

    var size: Vector2 { AseSprite.frameSize(path: "Items", tag: item.animation) }

    var body: some GView {
      Area2D$ {
        AseSprite$(path: "Items")
          .autoplay(item.animation)
          .centered(false)

        CollisionShape2D$()
          .shape(RectangleShape2D(size: size + [1, 1]))
          .position(size / 2)
      }
      .position(position)
      .collisionLayer(.collectible)
      .collisionMask(.interaction)
      .bind(\.visible, to: $collected) { !$0 }
      .onSignal(\.areaEntered) { _, _ in
        guard !collected else { return }
        collected = true
        GameEvent.collected(item, position: position).emit()
      }
      .onEvent(GameEvent.self) { _, event in
        if case .gameReset = event { collected = false }
      }
    }
  }
}
