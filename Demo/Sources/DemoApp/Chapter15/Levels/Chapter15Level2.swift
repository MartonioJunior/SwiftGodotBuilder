import SwiftGodot
import SwiftGodotBuilder

struct Chapter15Level2: GView {
  let state: ObservableState<Chapter15GameViewState>
  let screenWidth: Float = 800
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  var body: some GView {
    Node2D$ {
      // Sky-themed level with more vertical platforming
      Chapter15Platform(x: 0, y: 165, width: 200, height: platformHeight, color: .gray)
      Chapter15Platform(x: 600, y: 165, width: 200, height: platformHeight, color: .gray)

      // Vertical tower of platforms
      Chapter15Platform(x: 80, y: 130, width: 80, height: platformHeight, color: .gray)
      Chapter15Platform(x: 140, y: 100, width: 80, height: platformHeight, color: .gray)
      Chapter15Platform(x: 80, y: 70, width: 80, height: platformHeight, color: .gray)
      Chapter15Platform(x: 140, y: 40, width: 80, height: platformHeight, color: .gray)

      // Mid-air platforms
      Chapter15Platform(x: 300, y: 90, width: 100, height: platformHeight, color: .gray)
      Chapter15Platform(x: 450, y: 60, width: 100, height: platformHeight, color: .gray)
      Chapter15Platform(x: 600, y: 100, width: 100, height: platformHeight, color: .gray)

      // Coins (8 total)
      Chapter15Coin(position: [120, 110])
      Chapter15Coin(position: [180, 80])
      Chapter15Coin(position: [120, 50])
      Chapter15Coin(position: [180, 20])
      Chapter15Coin(position: [350, 70])
      Chapter15Coin(position: [500, 40])
      Chapter15Coin(position: [650, 80])
      Chapter15Coin(position: [700, 145])

      // Key on high platform
      Chapter15Key(position: [180, 24])

      // Ammo
      Chapter15Ammo(position: [100, 145])
      Chapter15Ammo(position: [350, 70])
      Chapter15Ammo(position: [650, 80])

      // Flying enemies
      Chapter15Enemy(
        type: .flyer,
        spawnPoint: [350, 50],
        patrolLeft: 250,
        patrolRight: 450,
        gravity: gravity,
        state: state
      )

      Chapter15EnemySpawner(
        enemyType: .flyer,
        position: [500, 30],
        patrolLeft: 450,
        patrolRight: 600,
        gravity: gravity,
        state: state
      )

      // Door
      Chapter15Door(position: [760, 83], state: state)
    }
  }
}
