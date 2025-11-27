import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  struct Level2: GView {
    let state: ObservableState<GameViewState>
    let screenWidth: Float = 800
    let screenHeight: Float = 180
    let platformHeight: Float = 8
    let gravity: Float = 400

    let palette = Palette.shared

    var body: some GView {
      Node2D$ {
        NPC(.merchant, at: [100, 165])

        Platform(x: 0, y: 165, width: 200, height: platformHeight, color: .gray)
        Platform(x: 600, y: 165, width: 200, height: platformHeight, color: .gray)

        Platform(x: 80, y: 130, width: 80, height: platformHeight, color: .gray)
        Platform(x: 140, y: 100, width: 80, height: platformHeight, color: .gray)
        Platform(x: 80, y: 70, width: 80, height: platformHeight, color: .gray)
        Platform(x: 140, y: 40, width: 80, height: platformHeight, color: .gray)

        Platform(x: 300, y: 90, width: 100, height: platformHeight, color: .gray)
        Platform(x: 450, y: 60, width: 100, height: platformHeight, color: .gray)
        Platform(x: 600, y: 100, width: 100, height: platformHeight, color: .gray)

        Collectible(position: [120, 110], .coin(palette))
        Collectible(position: [180, 80], .coin(palette))
        Collectible(position: [120, 50], .coin(palette))
        Collectible(position: [180, 20], .coin(palette))
        Collectible(position: [350, 70], .coin(palette))
        Collectible(position: [500, 40], .coin(palette))
        Collectible(position: [650, 80], .coin(palette))
        Collectible(position: [700, 145], .coin(palette))

        // Key is given by the Merchant via dialog

        Collectible(position: [100, 145], .ammo(palette))
        Collectible(position: [350, 70], .ammo(palette))
        Collectible(position: [650, 80], .ammo(palette))

        Enemy(
          .flyer,
          spawnPoint: [350, 50],
          patrolLeft: 250,
          patrolRight: 450,
          gravity: gravity,
          state: state
        )

        EnemySpawner(
          .flyer,
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
