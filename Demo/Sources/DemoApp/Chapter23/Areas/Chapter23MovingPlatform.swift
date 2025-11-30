import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  /// A platform that moves between two points
  struct MovingPlatform: GView {
    let startPosition: Vector2
    let endPosition: Vector2
    let width: Float
    let height: Float = 8
    let speed: Float
    let pauseDuration: Double

    @State var position: Vector2
    @State var velocity: Vector2 = .zero
    @State var movingToEnd = true
    @State var pauseTimer = 0.0

    init(
      startPosition: Vector2,
      endPosition: Vector2,
      width: Float = 64,
      speed: Float = 50,
      pauseDuration: Double = 0.5
    ) {
      self.startPosition = startPosition
      self.endPosition = endPosition
      self.width = width
      self.speed = speed
      self.pauseDuration = pauseDuration
      position = startPosition
    }

    var body: some GView {
      AnimatableBody2D$ {
        // Visual platform
        ColorBox$()
          .size([width, height])
          .color(Palette.shared.movingPlatform)

        // Top edge highlight
        ColorBox$()
          .size([width, 2])
          .color(Palette.shared.movingPlatform.lightened(amount: 0.2))

        CollisionShape2D$()
          .shape(RectangleShape2D(w: width, h: height))
          .position([width / 2, height / 2])
      }
      .position($position)
      .collisionLayer(.alpha) // Terrain layer
      .syncToPhysics(true)
      .onPhysicsProcess { body, delta in
        // Handle pause at endpoints
        if pauseTimer > 0 {
          pauseTimer -= delta
          velocity = .zero
          return
        }

        // Calculate target and direction
        let target = movingToEnd ? endPosition : startPosition
        let direction = (target - position).normalized()
        let distance = position.distanceTo(target)

        // Check if reached target
        if Float(distance) < speed * Float(delta) {
          position = target
          movingToEnd.toggle()
          pauseTimer = pauseDuration
          velocity = .zero
        } else {
          velocity = direction * speed
          position += velocity * Float(delta)
        }

        // Update body position for physics sync
        body.position = position
      }
    }
  }
}
