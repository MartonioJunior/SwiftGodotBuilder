import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  /// Checkpoint trigger - invisible zone that sets player respawn point
  struct TriggerView: GView {
    let position: Vector2
    let size: Vector2
    let id: Int

    @State var isActivated = false

    let player: ObservableState<PlayerState>

    init(entity: LDEntity, player: ObservableState<PlayerState>) {
      position = entity.positionTopLeft
      size = entity.size
      self.player = player
      id = entity.field("id")?.asInt() ?? 0
    }

    var body: some GView {
      Area2D$ {
        CollisionShape2D$()
          .shape(RectangleShape2D(size: size))
          .position(size / 2)
      }
      .position(position)
      .collisionLayer(0)
      .collisionMask(.interaction)
      .onSignal(\.areaEntered) { _, _ in
        guard !isActivated else { return }
        Engine.onNextFrame {
          isActivated = true
        }
        let respawnPosition: Vector2 = [position.x + size.x / 2, position.y - 4]
        GameEvent.checkpointActivated(id: id, position: respawnPosition).emit()
      }
      .watch(player, \.activatedCheckpointIds) { _, activatedIds in
        isActivated = activatedIds.contains(id)
      }
      .onEvent(GameEvent.self) { _, event in
        if case .gameReset = event {
          isActivated = false
        }
      }
    }
  }
}
