export default `import SwiftGodot
import SwiftGodotBuilder

struct GameView: GView {
  @State var inventory: [Item] = [.boots]
  @State var isAttacking = false

  var body: some GView {
    Node2D$ {
      // Ground platform
      StaticBody2D$ {
        ColorBox$()
          .color(.gray)
          .size([800, 50])
          .position([0, 500])

        CollisionShape2D$()
          .shape(RectangleShape2D(w: 800, h: 50))
          .position([400, 525])
      }

      // Player character
      PlayerView(isAttacking: $isAttacking)

      // Collectible item
      CollectibleView(position: [500, 480], itemType: .knife)

      // Enemy
      EnemyView(startPos: [700, 480])

      // HUD showing inventory
      InventoryHUD(items: $inventory)
    }
    .onProcess { _, delta in
      isAttacking = Action("attack").isPressed
    }
    .onEvent(GameEvent.self) { _, event in
      switch event {
      case .itemCollected(let item):
        inventory.append(item)

      case .enemyHit(let enemy):
        enemy.queueFree()
      }
    }
  }
}`;
