import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  /// A doorway that teleports the player to another location within the same level.
  /// Player presses "up" while standing in the doorway to teleport.
  struct DoorwayView: GView {
    let position: Vector2
    let size: Vector2
    let entityIid: String
    let targetEntityRef: LDEntityRef?

    let state: ObservableState<GameViewState>
    private var vm: GameViewState { state.wrappedValue }

    let palette = Palette.shared

    @State var isPlayerInside = false

    init(entity: LDEntity, state: ObservableState<GameViewState>) {
      position = entity.positionTopLeft
      size = entity.size
      self.state = state

      entityIid = entity.iid
      targetEntityRef = entity.field("targetDoor")?.asEntityRef()
    }

    var body: some GView {
      Area2D$ {
        // Visual marker for the doorway
        ColorBox$()
          .size(size)
          .modulate(palette.cyan)

        CollisionShape2D$()
          .shape(RectangleShape2D(size: size))
          .position(size / 2)
      }
      .position(position)
      .collisionLayer(.interaction)
      .collisionMask(.player)
      .onSignal(\.bodyEntered) { _, body in
        guard body is CharacterBody2D else { return }
        isPlayerInside = true
        vm.currentDoorIid = entityIid
        vm.currentDoorTargetRef = targetEntityRef
      }
      .onSignal(\.bodyExited) { _, body in
        guard body is CharacterBody2D else { return }
        isPlayerInside = false
        if vm.currentDoorIid == entityIid {
          vm.currentDoorIid = nil
          vm.currentDoorTargetRef = nil
        }
      }
      .onReady { _ in
        // Register this door's position for teleportation (keyed by IID)
        vm.doorPositions[entityIid] = Vector2(x: position.x, y: position.y + size.y)
      }
      .onEvent(GameEvent.self) { _, event in
        if case .gameReset = event {
          isPlayerInside = false
          // Re-register door position (cleared during reset)
          vm.doorPositions[entityIid] = Vector2(x: position.x, y: position.y + size.y)
        }
      }
    }
  }
}
