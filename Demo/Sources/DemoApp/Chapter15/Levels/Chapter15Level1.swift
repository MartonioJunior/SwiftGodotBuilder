import SwiftGodot
import SwiftGodotBuilder

struct Chapter15Level1: GView {
  let state: ObservableState<Chapter15GameViewState>
  let screenWidth: Float = 800
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  var body: some GView {
    Node2D$ {
      // Simple tutorial level - ground and a few platforms
      Chapter15Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Starting platforms
      Chapter15Platform(x: 50, y: 130, width: 100, height: platformHeight, color: .gray)
      Chapter15Platform(x: 200, y: 100, width: 100, height: platformHeight, color: .gray)
      Chapter15Platform(x: 350, y: 130, width: 100, height: platformHeight, color: .gray)

      // Coins (5 total)
      Chapter15Coin(position: [100, 110])
      Chapter15Coin(position: [250, 80])
      Chapter15Coin(position: [400, 110])
      Chapter15Coin(position: [550, 145])
      Chapter15Coin(position: [700, 145])

      // Ammo pickups
      Chapter15Ammo(position: [150, 145])
      Chapter15Ammo(position: [300, 80])

      // One easy enemy
      Chapter15Enemy(
        type: .patrol,
        spawnPoint: [500, 149],
        patrolLeft: 450,
        patrolRight: 600,
        gravity: gravity,
        state: state
      )

      // Goal door at end (open portal, no key required)
      Chapter15Door(position: [760, 148], state: state, requiresKey: false)
    }
  }
}
