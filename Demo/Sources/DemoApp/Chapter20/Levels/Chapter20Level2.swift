import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  struct Level2: GView {
    let state: ObservableState<GameViewState>
    let screenWidth: Float = 800
    let screenHeight: Float = 180
    let platformHeight: Float = 8
    let gravity: Float = 400

    let palette = Palette()

    var body: some GView {
      Node2D$ {
        // NPC - Merchant near start
        NPC(id: "merchant", name: "Merchant", position: [100, 165], color: palette.npcBlue)

        Platform(x: 0, y: 165, width: 200, height: platformHeight, color: .gray)
        Platform(x: 600, y: 165, width: 200, height: platformHeight, color: .gray)

        Platform(x: 80, y: 130, width: 80, height: platformHeight, color: .gray)
        Platform(x: 140, y: 100, width: 80, height: platformHeight, color: .gray)
        Platform(x: 80, y: 70, width: 80, height: platformHeight, color: .gray)
        Platform(x: 140, y: 40, width: 80, height: platformHeight, color: .gray)

        Platform(x: 300, y: 90, width: 100, height: platformHeight, color: .gray)
        Platform(x: 450, y: 60, width: 100, height: platformHeight, color: .gray)
        Platform(x: 600, y: 100, width: 100, height: platformHeight, color: .gray)

        Coin(position: [120, 110])
        Coin(position: [180, 80])
        Coin(position: [120, 50])
        Coin(position: [180, 20])
        Coin(position: [350, 70])
        Coin(position: [500, 40])
        Coin(position: [650, 80])
        Coin(position: [700, 145])

        // Key is now given by the Merchant via dialog

        Ammo(position: [100, 145])
        Ammo(position: [350, 70])
        Ammo(position: [650, 80])

        Enemy(
          type: .flyer,
          spawnPoint: [350, 50],
          patrolLeft: 250,
          patrolRight: 450,
          gravity: gravity,
          state: state
        )

        EnemySpawner(
          enemyType: .flyer,
          position: [500, 30],
          patrolLeft: 450,
          patrolRight: 600,
          gravity: gravity,
          state: state
        )

        Door(position: [760, 83], state: state)
      }
    }
  }
}
