import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Door Entity

struct Chapter9Door: GView {
  let position: Vector2
  let width: Float = 16
  let height: Float = 32
  let state: ObservableState<Chapter9GameViewState>

  @State var unlocked: Bool = false

  var body: some GView {
    StaticBody2D$ {
      // Visual representation
      ColorBox$()
        .size([width, height])
        .position([-width / 2, -height / 2])
        .watch($unlocked) { colorBox, isUnlocked in
          colorBox.color = isUnlocked
            ? Color(r: 0.3, g: 0.8, b: 0.3, a: 0.5) // Green when unlocked
            : Color(r: 0.6, g: 0.3, b: 0.1) // Brown when locked
        }

      // Lock indicator (disappears when unlocked)
      ColorBox$()
        .size([6, 6])
        .position([-3, -3])
        .color(Color(r: 0.9, g: 0.8, b: 0.2))
        .watch($unlocked) { node, isUnlocked in
          node.visible = !isUnlocked
        }

      // Collision shape
      CollisionShape2D$()
        .shape(RectangleShape2D(size: [width, height]))

      // Interaction area to detect player proximity
      Area2D$ {
        CollisionShape2D$()
          .shape(RectangleShape2D(size: [width + 4, height + 4]))
      }
      .collisionLayer(0) // No layer
      .collisionMask(.beta) // Player layer only
      .onSignal(\.bodyEntered) { _, body in
        guard !unlocked, body is CharacterBody2D, state.wrappedValue.hasKey else { return }

        // Player has key, unlock the door and trigger victory
        unlocked = true
        Chapter9Event.doorUnlocked(position: position).emit()
        Chapter9Event.goalReached.emit()
      }
    }
    .position(position)
    .collisionLayer(.alpha) // Environment layer
    .collisionMask(.beta) // Player layer
    .watch($unlocked) { node, isUnlocked in
      // Disable collision when unlocked to allow passage
      if let shape = node.getNode(path: NodePath("CollisionShape2D")) as? CollisionShape2D {
        shape.disabled = isUnlocked
      }
    }
    .onEvent(Chapter9Event.self) { _, event in
      if case .gameReset = event {
        unlocked = false
      }
    }
  }
}
