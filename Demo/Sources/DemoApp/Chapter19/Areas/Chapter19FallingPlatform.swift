import SwiftGodot
import SwiftGodotBuilder

extension Chapter19 {
  /// A platform that falls after the player stands on it
  struct FallingPlatform: GView {
    let startPosition: Vector2
    let width: Float
    let height: Float = 8
    let shakeDelay: Double // Time before shaking starts
    let fallDelay: Double // Time before falling after player steps on
    let respawnDelay: Double // Time before platform respawns
    let fallSpeed: Float = 200

    @State var position: Vector2
    @State var triggered = false
    @State var falling = false
    @State var shakeTimer = 0.0
    @State var fallTimer = 0.0
    @State var respawnTimer = 0.0
    @State var shakeOffset: Vector2 = .zero
    @State var isVisible = true

    let palette = Palette()

    init(
      position: Vector2,
      width: Float = 48,
      shakeDelay: Double = 0.3,
      fallDelay: Double = 0.8,
      respawnDelay: Double = 3.0
    ) {
      startPosition = position
      self.width = width
      self.shakeDelay = shakeDelay
      self.fallDelay = fallDelay
      self.respawnDelay = respawnDelay
      self.position = position
    }

    var platformColor: GState<Color> {
      $triggered.computed(with: $falling) { triggered, falling in
        if falling {
          return palette.fallingPlatformWarning
        } else if triggered {
          return palette.fallingPlatformWarning.lerp(to: palette.fallingPlatform, weight: 0.5)
        } else {
          return palette.fallingPlatform
        }
      }
    }

    var body: some GView {
      StaticBody2D$ {
        // Visual platform
        ColorBox$()
          .size([width, height])
          .color(platformColor)

        CollisionShape2D$()
          .shape(RectangleShape2D(w: width, h: height))
          .position([width / 2, height / 2])

        // Detection area for player
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(w: width - 4, h: 4))
            .position([width / 2, -2])
        }
        .collisionMask(.beta) // Player layer
        .onSignal(\.bodyEntered) { _, body in
          if body is CharacterBody2D, !triggered, !falling {
            triggered = true
            shakeTimer = shakeDelay
            fallTimer = fallDelay
          }
        }
      }
      .bind(\.position, to: $position, $shakeOffset) { pos, shake in
        pos + shake
      }
      .collisionLayer(.alpha) // Terrain layer
      .visible($isVisible)
      .onProcess { _, delta in
        // Respawn logic
        if !isVisible {
          respawnTimer -= delta
          if respawnTimer <= 0 {
            respawn()
          }
          return
        }

        // Shaking logic
        if triggered, !falling {
          if shakeTimer > 0 {
            shakeTimer -= delta
          } else {
            // Shake effect
            shakeOffset = Vector2(
              x: Float.random(in: -2 ... 2),
              y: Float.random(in: -1 ... 1)
            )
          }

          fallTimer -= delta
          if fallTimer <= 0 {
            falling = true
            shakeOffset = .zero
          }
        }

        // Falling logic
        if falling {
          position.y += fallSpeed * Float(delta)

          // Disappear after falling far enough
          if position.y > startPosition.y + 200 {
            isVisible = false
            respawnTimer = respawnDelay
          }
        }
      }
      .onEvent(Event.self) { _, event in
        if case .gameReset = event {
          respawn()
        }
      }
    }

    func respawn() {
      position = startPosition
      triggered = false
      falling = false
      shakeTimer = 0
      fallTimer = 0
      shakeOffset = .zero
      isVisible = true
    }
  }
}
