import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  struct Level3: GView {
    let state: ObservableState<GameViewState>
    let router: ObservableState<GameRouter>
    let screenWidth: Float = 800
    let screenHeight: Float = 180
    let platformHeight: Float = 8
    let gravity: Float = 400

    let palette = Palette.shared

    var body: some GView {
      Node2D$ {
        NPC(.guard, at: [80, 165])

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

        Collectible(position: [135, 110], .coin(palette))
        Collectible(position: [235, 80], .coin(palette))
        Collectible(position: [335, 110], .coin(palette))
        Collectible(position: [435, 70], .coin(palette))
        Collectible(position: [535, 100], .coin(palette))
        Collectible(position: [635, 60], .coin(palette))
        Collectible(position: [200, 40], .coin(palette))
        Collectible(position: [450, 30], .coin(palette))
        Collectible(position: [700, 20], .coin(palette))
        Collectible(position: [750, 145], .coin(palette))

        Collectible(position: [700, 24], .key(palette))

        Collectible(position: [50, 145], .ammo(palette))
        Collectible(position: [250, 80], .ammo(palette))
        Collectible(position: [450, 70], .ammo(palette))
        Collectible(position: [550, 100], .ammo(palette))

        Enemy(
          .patrol,
          spawnPoint: [150, 149],
          patrolLeft: 100,
          patrolRight: 250,
          gravity: gravity,
          state: state,
          router: router
        )

        EnemySpawner(
          .patrol,
          position: [400, 114],
          patrolLeft: 350,
          patrolRight: 500,
          gravity: gravity,
          state: state,
          router: router
        )

        Enemy(
          .flyer,
          spawnPoint: [300, 80],
          patrolLeft: 200,
          patrolRight: 400,
          gravity: gravity,
          state: state,
          router: router
        )

        EnemySpawner(
          .flyer,
          position: [550, 40],
          patrolLeft: 450,
          patrolRight: 650,
          gravity: gravity,
          state: state,
          router: router
        )

        Enemy(
          .flyer,
          spawnPoint: [650, 25],
          patrolLeft: 600,
          patrolRight: 750,
          gravity: gravity,
          state: state,
          router: router
        )

        Door(position: [760, 23], state: state)
      }
    }
  }
}
