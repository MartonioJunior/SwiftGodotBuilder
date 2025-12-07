import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct NPCView: GView {
    let id: String
    let name: String
    let color: Color
    let size: Vector2
    let position: Vector2
    let makeDialog: (DialogState, GameViewState, GameProgress) -> DialogDefinition?

    let palette = Palette.shared

    @State var playerInRange = false

    var labelOffsetY: Double { Double(-size.y - 12) }

    init(entity: LDEntity) {
      let npcType: NPCType = entity.field("npcType")?.asEnum() ?? .oldMan
      let definition: NPCDefinition
      switch npcType {
      case .oldMan: definition = .oldMan
      case .merchant: definition = .merchant
      case .guardNPC: definition = .guard
      case .advisors: definition = .advisors
      }

      id = definition.id
      name = definition.name
      color = definition.color
      size = definition.size
      makeDialog = definition.makeDialog
      position = entity.positionTopLeft
    }

    var halfSize: Vector2 { size / 2 }
    // Widened collision area for easier interaction
    var collisionSize: Vector2 { [(size.x * 4) + 1, size.y + 1] }

    var body: some GView {
      Node2D$ {
        // NPC body
        ColorBox$()
          .size(size)
          .color(color)

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
            .shape(RectangleShape2D(size: collisionSize))
            .position(halfSize)
        }
        .collisionLayer(.collectible)
        .collisionMask(.interaction)
        .monitorable(true)
        .monitoring(true)
        .onSignal(\.areaEntered) { _, _ in
          playerInRange = true
        }
        .onSignal(\.areaExited) { _, _ in
          playerInRange = false
        }
      }
      .position(position)
      .onProcess { _, _ in
        guard playerInRange else { return }
        if Action("interact").isJustPressed {
          DialogEvent.started(npcId: id, makeDialog: makeDialog).emit()
        }
      }
    }
  }
}
