import SwiftGodot
import SwiftGodotBuilder

extension Chapter22 {
  struct NPC: GView {
    let id: String
    let name: String
    let color: Color
    let size: Vector2
    let position: Vector2
    let makeDialog: (DialogState, GameViewState, GameProgress) -> DialogDefinition?

    let palette = Palette.shared

    @State var playerInRange = false

    var labelOffsetY: Double { Double(-size.y - 12) }

    init(_ definition: NPCDefinition, at position: Vector2) {
      id = definition.id
      name = definition.name
      color = definition.color
      size = definition.size
      makeDialog = definition.makeDialog
      self.position = position
    }

    var body: some GView {
      Node2D$ {
        // NPC body
        ColorBox$()
          .size(size)
          .color(color)
          .position([-size.x / 2, -size.y])

        // Eyes
        ColorBox$()
          .size([2, 2])
          .color(palette.white)
          .position([-size.x / 2 + 2, -size.y + 3])
        ColorBox$()
          .size([2, 2])
          .color(palette.white)
          .position([size.x / 2 - 4, -size.y + 3])

        // Name label
        Label$()
          .text(name)
          .visible($playerInRange)
          .horizontalAlignment(.center)
          .growHorizontal(.both)
          .theme(["fontColor": palette.white])
          .offset(top: labelOffsetY, right: 0, bottom: 0, left: 0)

        // Detection area
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(size: [size.x + 24, size.y + 16]))
            .position([0, -size.y / 2])
        }
        .collisionLayer(.gamma)
        .collisionMask(.beta)
        .monitorable(true)
        .monitoring(true)
        .onSignal(\.bodyEntered) { _, body in
          guard body is CharacterBody2D else { return }
          playerInRange = true
        }
        .onSignal(\.bodyExited) { _, body in
          guard body is CharacterBody2D else { return }
          playerInRange = false
        }
      }
      .position(position)
      .onProcess { [id, makeDialog] _, _ in
        guard playerInRange else { return }
        if Action("interact").isJustPressed {
          DialogEvent.started(npcId: id, makeDialog: makeDialog).emit()
        }
      }
    }
  }
}
