import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  /// A doorway that teleports the player to another location within the same level.
  /// Player presses "up" while standing in the doorway to teleport.
  struct DoorwayView: GView {
    let position: Vector2
    let size: Vector2
    let entityIid: String
    let targetEntityRef: LDEntityRef?
    let spriteTile: LDTilesetRect?
    let project: LDProject

    let state: ObservableState<GameViewState>
    let player: ObservableState<PlayerState>
    var vm: GameViewState { state.wrappedValue }
    var ps: PlayerState { player.wrappedValue }

    let palette = Palette.shared

    @State var isPlayerInside = false

    init(entity: LDEntity, state: ObservableState<GameViewState>, player: ObservableState<PlayerState>, project: LDProject) {
      position = entity.positionTopLeft
      size = entity.size
      self.state = state
      self.player = player
      self.project = project

      entityIid = entity.iid
      targetEntityRef = entity.field("targetDoor")?.asEntityRef()
      spriteTile = entity.field("sprite")?.asTile()
    }

    var body: some GView {
      Area2D$ {
        // Visual - sprite from tileset
        if let tile = spriteTile,
           let tilesetDef = project.defs.tileset(uid: tile.tilesetUid),
           let texture = ResourceLoader.load(path: tilesetDef.resourcePath(relativeTo: project.projectPath ?? "")) as? Texture2D
        {
          Sprite2D$()
            .texture(texture)
            .regionEnabled(true)
            .regionRect(tile.rect)
            .centered(false)
        }

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
        ps.currentDoorIid = entityIid
        ps.currentDoorTargetRef = targetEntityRef
      }
      .onSignal(\.bodyExited) { _, body in
        guard body is CharacterBody2D else { return }
        isPlayerInside = false
        if ps.currentDoorIid == entityIid {
          ps.currentDoorIid = nil
          ps.currentDoorTargetRef = nil
        }
      }
      .onReady { _ in
        // Register this door's position for teleportation (keyed by IID)
        vm.doorPositions[entityIid] = Vector2(x: position.x + size.x / 2, y: position.y + size.y)
      }
      .onEvent(GameEvent.self) { _, event in
        if case .gameReset = event {
          isPlayerInside = false
          // Re-register door position (cleared during reset)
          vm.doorPositions[entityIid] = Vector2(x: position.x + size.x / 2, y: position.y + size.y)
        }
      }
    }
  }
}
