import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  struct Checkpoint: GView {
    let id: Int
    let x: Float
    let y: Float
    let state: ObservableState<GameViewState>

    private var vm: GameViewState { state.wrappedValue }

    let width: Float = 8
    let height: Float = 24

    @State var isActivated = false

    var body: some GView {
      Area2D$ {
        // Simple flag pole visual
        ColorBox$()
          .size([width, height])
          .position([-width / 2, -height])
          .bind(\.color, to: $isActivated) { activated in
            activated ? Palette.shared.checkpointActive : Palette.shared.checkpointInactive
          }

        // Detection area
        CollisionShape2D$()
          .shape(RectangleShape2D(w: 16, h: 24))
          .position([0, -12])
      }
      .position([x, y])
      .collisionLayer(.epsilon) // Checkpoint layer - not in projectile mask
      .collisionMask(.beta) // Only detect player
      .onSignal(\.bodyEntered) { _, _ in
        guard !isActivated else { return }
        activate()
      }
      .watch(state, \.activatedCheckpointIds) { _, activatedIds in
        isActivated = activatedIds.contains(id)
      }
    }

    func activate() {
      isActivated = true
      // Respawn position is above ground level (player is 16 pixels tall)
      let respawnPosition: Vector2 = [x - 8, y - 20]
      Event.checkpointActivated(id: id, position: respawnPosition).emit()
    }
  }
}
