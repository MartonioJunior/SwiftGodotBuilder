import SwiftGodot
import SwiftGodotBuilder

// MARK: - Door Entity

extension Chapter22 {
  struct Door: GView {
    let position: Vector2
    let width: Float = 16
    let height: Float = 32
    let state: ObservableState<GameViewState>
    let requiresKey: Bool // If false, door is an open portal

    @State var unlocked = false
    @State var enteredDoor = false

    let palette = Palette.shared

    init(position: Vector2, state: ObservableState<GameViewState>, requiresKey: Bool = true) {
      self.position = position
      self.state = state
      self.requiresKey = requiresKey
      unlocked = !requiresKey // If no key required, start unlocked
    }

    var doorColor: GState<Color> {
      $unlocked.computed { $0 ? palette.doorUnlocked : palette.doorLocked }
    }

    var body: some GView {
      StaticBody2D$ {
        // Visual representation
        ColorBox$()
          .size([width, height])
          .position([-width / 2, -height / 2])
          .color(doorColor)

        // Lock indicator (disappears when unlocked)
        ColorBox$()
          .size([6, 6])
          .position([-3, -3])
          .color(palette.keyLock)
          .bind(\.visible, to: $unlocked) { !$0 }

        // Collision shape
        CollisionShape2D$()
          .shape(RectangleShape2D(size: [width, height]))
          .watch($unlocked) { shape, isUnlocked in
            Engine.onNextFrame {
              shape.disabled = isUnlocked
            }
          }

        // Interaction area to detect player proximity
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(size: [width + 4, height + 4]))
        }
        .collisionLayer(0) // No layer
        .collisionMask(.beta) // Player layer only
        .onSignal(\.bodyEntered) { _, body in
          guard body is CharacterBody2D else { return }

          if !unlocked && state.wrappedValue.hasKey {
            // Player has key, unlock the door
            unlocked = true
            Event.doorUnlocked(position: position).emit()
          } else if unlocked && !enteredDoor {
            // Door is unlocked, trigger level completion
            enteredDoor = true
            Event.goalReached.emit()
          }
        }
      }
      .position(position)
      .collisionLayer(.alpha) // Environment layer
      .collisionMask(.beta) // Player layer
      .onEvent(Event.self) { _, event in
        if case .gameReset = event {
          unlocked = !requiresKey // Reset to initial state
          enteredDoor = false
        }
      }
    }
  }
}
