import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  struct Level3: GView {
    let state: ObservableState<GameViewState>
    let screenWidth: Float = 800
    let screenHeight: Float = 180
    let platformHeight: Float = 8
    let gravity: Float = 400

    let palette = Palette()

    var body: some GView {
      Node2D$ {
        // NPC - Guard near start
        NPC(id: "guard", name: "Guard", position: [80, 165], color: palette.npcPurple)

        Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

        Platform(x: 100, y: 130, width: 70, height: platformHeight, color: .gray)
        Platform(x: 200, y: 100, width: 70, height: platformHeight, color: .gray)
        Platform(x: 300, y: 130, width: 70, height: platformHeight, color: .gray)
        Platform(x: 400, y: 90, width: 70, height: platformHeight, color: .gray)
        Platform(x: 500, y: 120, width: 70, height: platformHeight, color: .gray)
        Platform(x: 600, y: 80, width: 70, height: platformHeight, color: .gray)

        Platform(x: 150, y: 60, width: 100, height: platformHeight, color: .gray)
        Platform(x: 400, y: 50, width: 100, height: platformHeight, color: .gray)
        Platform(x: 650, y: 40, width: 100, height: platformHeight, color: .gray)

        Coin(position: [135, 110])
        Coin(position: [235, 80])
        Coin(position: [335, 110])
        Coin(position: [435, 70])
        Coin(position: [535, 100])
        Coin(position: [635, 60])
        Coin(position: [200, 40])
        Coin(position: [450, 30])
        Coin(position: [700, 20])
        Coin(position: [750, 145])

        KeyPickup(position: [700, 24])

        Ammo(position: [50, 145])
        Ammo(position: [250, 80])
        Ammo(position: [450, 70])
        Ammo(position: [550, 100])

        Enemy(
          type: .patrol,
          spawnPoint: [150, 149],
          patrolLeft: 100,
          patrolRight: 250,
          gravity: gravity,
          state: state
        )

        EnemySpawner(
          enemyType: .patrol,
          position: [400, 114],
          patrolLeft: 350,
          patrolRight: 500,
          gravity: gravity,
          state: state
        )

        Enemy(
          type: .flyer,
          spawnPoint: [300, 80],
          patrolLeft: 200,
          patrolRight: 400,
          gravity: gravity,
          state: state
        )

        EnemySpawner(
          enemyType: .flyer,
          position: [550, 40],
          patrolLeft: 450,
          patrolRight: 650,
          gravity: gravity,
          state: state
        )

        Enemy(
          type: .flyer,
          spawnPoint: [650, 25],
          patrolLeft: 600,
          patrolRight: 750,
          gravity: gravity,
          state: state
        )

        Door(position: [760, 23], state: state)
      }
    }
  }
}
