import SwiftGodot
import SwiftGodotBuilder

extension Chapter22 {
  struct Level1: GView {
    let state: ObservableState<GameViewState>
    let screenWidth: Float = 800
    let screenHeight: Float = 180
    let platformHeight: Float = 8
    let gravity: Float = 400

    let palette = Palette.shared

    var body: some GView {
      Node2D$ {
        NPC(.oldMan, at: [80, 166])

        Platform(x: 0, y: 165, width: 150, height: platformHeight, color: .gray)
        Platform(x: 200, y: 165, width: 100, height: platformHeight, color: .gray)
        Platform(x: 350, y: 165, width: 150, height: platformHeight, color: .gray)
        Platform(x: 550, y: 165, width: 250, height: platformHeight, color: .gray)

        Spikes(position: [150, 165], width: 48, direction: .up)

        HazardZone(
          position: [300, 165],
          size: [50, 20],
          effect: .instantKill,
          color: palette.lava,
          highlightColor: palette.lavaGlow
        )

        MovingPlatform(
          startPosition: [310, 140],
          endPosition: [310, 100],
          width: 40,
          speed: 40,
          pauseDuration: 1.0
        )

        Platform(x: 550, y: 120, width: 64, height: platformHeight, color: .gray)
        Checkpoint(id: 2, x: 570, y: 165, state: state)

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

        FallingPlatform(position: [630, 100], width: 40)
        FallingPlatform(position: [680, 80], width: 40)

        HazardZone(
          position: [200, 140],
          size: [100, 25],
          effect: .water,
          color: palette.water.withAlpha(0.6),
          highlightColor: palette.waterSurface.withAlpha(0.8),
          highlightHeight: 3,
          collisionLayer: .eta
        )
        Checkpoint(id: 1, x: 220, y: 165, state: state)

        Platform(x: 350, y: 130, width: 80, height: platformHeight, color: .gray)
        Platform(x: 380, y: 145, width: 40, height: platformHeight, color: .gray) // Low ceiling - crouch to pass

        Collectible(position: [250, 145], .coin(palette))
        Collectible(position: [320, 90], .coin(palette))
        Collectible(position: [650, 80], .coin(palette))

        Door(position: [760, 150], state: state, requiresKey: false)
      }
    }
  }
}
