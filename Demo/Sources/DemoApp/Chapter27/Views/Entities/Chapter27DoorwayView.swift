import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// A doorway that teleports the player to another location.
  /// Player presses interact while overlapping the doorway to teleport.
  struct DoorwayView: GView {
    let position: Vector2
    let size: Vector2
    let gridSize: Int
    let targetLevelIid: String
    let targetEntityIid: String
    let spriteTile: LDTilesetRect?
    let project: LDProject

    private final class ViewModel {
      var playerInRange = false
    }

    private let vm = ViewModel()

    init(entity: LDEntity, level: LDLevel, project: LDProject) {
      position = entity.positionTopLeft
      size = entity.size
      gridSize = level.entityLayers.first?.gridSize ?? 8
      self.project = project
      let ref = entity.field("targetDoor")?.asEntityRef()
      targetLevelIid = ref?.levelIid ?? ""
      targetEntityIid = ref?.entityIid ?? ""
      spriteTile = entity.field("sprite")?.asTile()
    }

    var body: some GView {
      Area2D$ {
        // Visual - sprite from tileset
        if let tile = spriteTile {
          LDTileFieldView(tile: tile, project: project, gridSize: gridSize, width: Float(tile.w), height: Float(tile.h))
        }

        CollisionShape2D$()
          .shape(RectangleShape2D(size: size))
          .position(size / 2)
      }
      .position(position)
      .collisionLayer(.interaction)
      .collisionMask(.interaction)
      .monitorable(true)
      .monitoring(true)
      .onSignal(\.areaEntered) { [vm] _, _ in
        vm.playerInRange = true
      }
      .onSignal(\.areaExited) { [vm] _, _ in
        vm.playerInRange = false
      }
      .onProcess { [vm, targetLevelIid, targetEntityIid] _, _ in
        guard vm.playerInRange else { return }
        if Action("interact").isJustPressed {
          DoorwayEvent.entered(levelIid: targetLevelIid, entityIid: targetEntityIid).emit()
        }
      }
    }
  }
}
