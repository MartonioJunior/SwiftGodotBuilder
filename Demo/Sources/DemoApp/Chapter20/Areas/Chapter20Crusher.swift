import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  /// A crusher that moves down and up, killing the player on contact
  struct Crusher: GView {
    let startPosition: Vector2
    let width: Float
    let height: Float
    let crushDistance: Float // How far down it moves
    let crushSpeed: Float // Speed when crushing down
    let retractSpeed: Float // Speed when moving back up
    let pauseAtTop: Double // Time to wait at top
    let pauseAtBottom: Double // Time to wait at bottom (crushed position)

    @State var position: Vector2
    @State var isCrushing = true // Start crushing after initial pause
    @State var pauseTimer = 0.0

    let palette = Palette()

    init(
      position: Vector2,
      width: Float = 48,
      height: Float = 24,
      crushDistance: Float = 48,
      crushSpeed: Float = 300,
      retractSpeed: Float = 50,
      pauseAtTop: Double = 2.0,
      pauseAtBottom: Double = 0.5
    ) {
      startPosition = position
      self.width = width
      self.height = height
      self.crushDistance = crushDistance
      self.crushSpeed = crushSpeed
      self.retractSpeed = retractSpeed
      self.pauseAtTop = pauseAtTop
      self.pauseAtBottom = pauseAtBottom
      self.position = position
      pauseTimer = pauseAtTop
    }

    var body: some GView {
      AnimatableBody2D$ {
        // Main crusher body
        ColorBox$()
          .size([width, height])
          .color(palette.crusher)

        // Bottom edge
        ColorBox$()
          .size([width, 4])
          .position([0, height])
          .color(palette.crusherDark)

        // Top mounting bracket
        ColorBox$()
          .size([width + 8, 4])
          .position([-4, -4])
          .color(palette.crusherDark)

        CollisionShape2D$()
          .shape(RectangleShape2D(w: width, h: height + 4))
          .position([width / 2, height / 2 + 2])

        // Kill zone at bottom
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(w: width - 4, h: 8))
            .position([width / 2, height + 4])
        }
        .collisionLayer(.zeta) // Hazard layer
        .collisionMask(.beta) // Player layer
        .onSignal(\.bodyEntered) { _, body in
          if body is CharacterBody2D {
            Event.playerHit(damage: 999, position: position).emit()
          }
        }
      }
      .position($position)
      .collisionLayer(.alpha) // Terrain layer
      .syncToPhysics(true)
      .onPhysicsProcess { body, delta in
        // Handle pause timers
        if pauseTimer > 0 {
          pauseTimer -= delta
          return
        }

        if isCrushing {
          // Move down fast
          let targetY = startPosition.y + crushDistance
          if position.y < targetY {
            position.y += crushSpeed * Float(delta)
            if position.y >= targetY {
              position.y = targetY
              isCrushing = false
              pauseTimer = pauseAtBottom
            }
          }
        } else {
          // Move up slow
          if position.y > startPosition.y {
            position.y -= retractSpeed * Float(delta)
            if position.y <= startPosition.y {
              position.y = startPosition.y
              isCrushing = true
              pauseTimer = pauseAtTop
            }
          }
        }

        body.position = position
      }
      .onEvent(Event.self) { _, event in
        if case .gameReset = event {
          position = startPosition
          isCrushing = true
          pauseTimer = pauseAtTop
        }
      }
    }
  }
}
