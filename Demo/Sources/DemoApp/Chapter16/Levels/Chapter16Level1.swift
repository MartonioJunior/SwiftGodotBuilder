import SwiftGodot
import SwiftGodotBuilder

extension Chapter16 {
  struct Level1: GView {
    let state: ObservableState<GameViewState>
    let screenWidth: Float = 800
    let screenHeight: Float = 180
    let platformHeight: Float = 8
    let gravity: Float = 400

    var body: some GView {
      Node2D$ {
        // Simple tutorial level - ground and a few platforms
        Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

        // Starting platforms
        Platform(x: 50, y: 130, width: 100, height: platformHeight, color: .gray)
        Platform(x: 200, y: 100, width: 100, height: platformHeight, color: .gray)
        Platform(x: 350, y: 130, width: 100, height: platformHeight, color: .gray)

        // Coins (5 total)
        Coin(position: [100, 110])
        Coin(position: [250, 80])
        Coin(position: [400, 110])
        Coin(position: [550, 145])
        Coin(position: [700, 145])

        // Ammo pickups
        Ammo(position: [150, 145])
        Ammo(position: [300, 80])

        // One easy enemy
        Enemy(
          type: .patrol,
          spawnPoint: [500, 149],
          patrolLeft: 450,
          patrolRight: 600,
          gravity: gravity,
          state: state
        )

        // Goal door at end (open portal, no key required)
        Door(position: [760, 148], state: state, requiresKey: false)
      }
    }
  }
}
