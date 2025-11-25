import SwiftGodot
import SwiftGodotBuilder

extension Chapter17 {
  struct Level1: GView {
    let state: ObservableState<GameViewState>
    let screenWidth: Float = 800
    let screenHeight: Float = 180
    let platformHeight: Float = 8
    let gravity: Float = 400

    var body: some GView {
      Node2D$ {
        // Hazard tutorial level

        // Ground with gaps
        Platform(x: 0, y: 165, width: 150, height: platformHeight, color: .gray)
        Platform(x: 200, y: 165, width: 100, height: platformHeight, color: .gray)
        Platform(x: 350, y: 165, width: 150, height: platformHeight, color: .gray)
        Platform(x: 550, y: 165, width: 250, height: platformHeight, color: .gray)

        // Spikes in the first gap (instant death)
        Spikes(position: [150, 165], width: 48, direction: .up)

        // Lava in the second gap
        LavaZone(position: [300, 165], width: 48, height: 20, instantKill: true)

        // Moving platform over lava gap
        MovingPlatform(
          startPosition: [310, 140],
          endPosition: [310, 100],
          width: 40,
          speed: 40,
          pauseDuration: 1.0
        )

        // Platform section with crusher
        Platform(x: 550, y: 120, width: 64, height: platformHeight, color: .gray)

        // Crusher overhead
        Crusher(
          position: [560, 50],
          width: 40,
          height: 20,
          crushDistance: 40,
          crushSpeed: 200,
          retractSpeed: 40,
          pauseAtTop: 1.5,
          pauseAtBottom: 0.3
        )

        // Falling platforms section
        FallingPlatform(position: [630, 100], width: 40)
        FallingPlatform(position: [680, 80], width: 40)

        // Water pool - safe to swim through
        WaterZone(position: [200, 140], width: 100, height: 25)

        // High platform to crouch under (low ceiling)
        Platform(x: 350, y: 130, width: 80, height: platformHeight, color: .gray)
        // Low ceiling above - player needs to crouch to pass
        Platform(x: 380, y: 145, width: 40, height: platformHeight, color: .gray)

        // Coins (5 total)
        Coin(position: [75, 145])
        Coin(position: [250, 145])
        Coin(position: [320, 90])
        Coin(position: [650, 80])
        Coin(position: [750, 145])

        // Ammo pickups
        Ammo(position: [100, 145])

        // Goal at end
        Door(position: [760, 148], state: state, requiresKey: false)
      }
    }
  }
}
