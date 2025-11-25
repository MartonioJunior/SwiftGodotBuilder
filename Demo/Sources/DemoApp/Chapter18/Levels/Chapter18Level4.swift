import SwiftGodot
import SwiftGodotBuilder

extension Chapter18 {
  struct Level4: GView {
    let state: ObservableState<GameViewState>
    let screenWidth: Float = 800
    let screenHeight: Float = 180
    let platformHeight: Float = 8
    let gravity: Float = 400

    // Boss arena bounds
    let arenaLeft: Float = 50
    let arenaRight: Float = 750

    var body: some GView {
      Node2D$ {
        Platform(x: 0, y: 165, width: screenWidth, height: platformHeight, color: .gray)
        Platform(x: 0, y: 0, width: 20, height: 165, color: Color(code: "#333333"))
        Platform(x: 780, y: 0, width: 20, height: 165, color: Color(code: "#333333"))

        Platform(x: 100, y: 120, width: 80, height: platformHeight, color: .gray)
        Platform(x: 350, y: 90, width: 100, height: platformHeight, color: .gray)
        Platform(x: 620, y: 120, width: 80, height: platformHeight, color: .gray)
        Platform(x: 200, y: 60, width: 60, height: platformHeight, color: .gray)
        Platform(x: 540, y: 60, width: 60, height: platformHeight, color: .gray)

        Ammo(position: [140, 100])
        Ammo(position: [400, 70])
        Ammo(position: [660, 100])
        Ammo(position: [230, 40])
        Ammo(position: [570, 40])

        HealthDrop(spawnPosition: [400, 145])

        Boss(
          spawnPoint: [600, 125],
          arenaLeft: arenaLeft,
          arenaRight: arenaRight,
          gravity: gravity,
          state: state
        )
      }
    }
  }
}
