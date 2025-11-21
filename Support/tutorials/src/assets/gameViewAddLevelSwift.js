export default `import SwiftGodot
import SwiftGodotBuilder

struct GameView: GView {
  let project: LDProject
  @State var inventory: [Item] = [.boots]
  @State var isAttacking = false

  var body: some GView {
    Node2D$ {
      // LDtk level
      LDLevelView(project, level: "Your_typical_2D_platformer")

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
