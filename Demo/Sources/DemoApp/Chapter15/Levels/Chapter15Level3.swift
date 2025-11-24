import SwiftGodot
import SwiftGodotBuilder

struct Chapter15Level3: GView {
  let state: ObservableState<Chapter15GameViewState>
  let screenWidth: Float = 800
  let screenHeight: Float = 180
  let platformHeight: Float = 8
  let gravity: Float = 400

  var body: some GView {
    Node2D$ {
      // Final challenge - complex layout with many enemies
      Chapter15Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)

      // Platform gauntlet
      Chapter15Platform(x: 100, y: 130, width: 70, height: platformHeight, color: .gray)
      Chapter15Platform(x: 200, y: 100, width: 70, height: platformHeight, color: .gray)
      Chapter15Platform(x: 300, y: 130, width: 70, height: platformHeight, color: .gray)
      Chapter15Platform(x: 400, y: 90, width: 70, height: platformHeight, color: .gray)
      Chapter15Platform(x: 500, y: 120, width: 70, height: platformHeight, color: .gray)
      Chapter15Platform(x: 600, y: 80, width: 70, height: platformHeight, color: .gray)

      // Upper platforms
      Chapter15Platform(x: 150, y: 60, width: 100, height: platformHeight, color: .gray)
      Chapter15Platform(x: 400, y: 50, width: 100, height: platformHeight, color: .gray)
      Chapter15Platform(x: 650, y: 40, width: 100, height: platformHeight, color: .gray)

      // Coins (10 total) - scattered throughout
      Chapter15Coin(position: [135, 110])
      Chapter15Coin(position: [235, 80])
      Chapter15Coin(position: [335, 110])
      Chapter15Coin(position: [435, 70])
      Chapter15Coin(position: [535, 100])
      Chapter15Coin(position: [635, 60])
      Chapter15Coin(position: [200, 40])
      Chapter15Coin(position: [450, 30])
      Chapter15Coin(position: [700, 20])
      Chapter15Coin(position: [750, 145])

      // Key on upper platform
      Chapter15Key(position: [700, 24])

      // Ammo (more needed for this level)
      Chapter15Ammo(position: [50, 145])
      Chapter15Ammo(position: [250, 80])
      Chapter15Ammo(position: [450, 70])
      Chapter15Ammo(position: [550, 100])

      // Many enemies - ground patrol
      Chapter15Enemy(
        type: .patrol,
        spawnPoint: [150, 149],
        patrolLeft: 100,
        patrolRight: 250,
        gravity: gravity,
        state: state
      )

      Chapter15EnemySpawner(
        enemyType: .patrol,
        position: [400, 114],
        patrolLeft: 350,
        patrolRight: 500,
        gravity: gravity,
        state: state
      )

      // Flying enemies
      Chapter15Enemy(
        type: .flyer,
        spawnPoint: [300, 80],
        patrolLeft: 200,
        patrolRight: 400,
        gravity: gravity,
        state: state
      )

      Chapter15EnemySpawner(
        enemyType: .flyer,
        position: [550, 40],
        patrolLeft: 450,
        patrolRight: 650,
        gravity: gravity,
        state: state
      )

      Chapter15Enemy(
        type: .flyer,
        spawnPoint: [650, 25],
        patrolLeft: 600,
        patrolRight: 750,
        gravity: gravity,
        state: state
      )

      // Door
      Chapter15Door(position: [760, 23], state: state)
    }
  }
}
