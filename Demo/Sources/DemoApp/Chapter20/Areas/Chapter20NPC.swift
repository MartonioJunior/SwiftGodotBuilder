import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  struct NPC: GView {
    let id: String
    let name: String
    let position: Vector2
    let color: Color
    let size: Vector2

    let palette = Palette()

    @State var playerInRange = false

    var labelOffsetY: Double { Double(-size.y - 12) }

    init(
      id: String,
      name: String,
      position: Vector2,
      color: Color = Color(code: "#8844FF"),
      size: Vector2 = [12, 16]
    ) {
      self.id = id
      self.name = name
      self.position = position
      self.color = color
      self.size = size
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
      .onProcess { _, _ in
        guard playerInRange else { return }
        if Action("interact").isJustPressed {
          DialogEvent.started(npcId: id).emit()
        }
      }
    }
  }
}
