export default `import SwiftGodot
import SwiftGodotBuilder

struct GameView: GView {
  let project: LDProject
  @State var inventory: [Item] = [.boots]
  @State var isAttacking = false

  var body: some GView {
    Node2D$ {
      // Load and render the LDtk level
      LDLevelView(project, level: "Your_typical_2D_platformer")
        .onSpawn("Player") { entity, level, project in
          let terrainLayer = project.collisionLayer(for: "walls", in: level)
          PlayerView(terrainLayer: terrainLayer, isAttacking: $isAttacking)
        }

      // Collectible item (will be spawned from level later)
      CollectibleView(position: [500, 480], itemType: .knife)

      // Enemy (will be spawned from level later)
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
