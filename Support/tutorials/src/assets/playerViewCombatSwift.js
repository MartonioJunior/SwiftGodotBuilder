export default `import SwiftGodot
import SwiftGodotBuilder

struct PlayerView: GView {
  // Movement constants
  let gravity: Float = 980.0
  let speed: Float = 200.0
  let maxFallSpeed: Float = 500.0
  let jumpForce: Float = -400.0

  // Combat
  let isAttacking: State<Bool>

  var body: some GView {
    CharacterBody2D$ {
      // Visual representation (simple colored square for now)
      ColorBox$()
        .size([32, 32])
        .position([-16, -16])
        .bind(\\.color, to: isAttacking) { $0 ? .orange : .darkGray }

      // Collision shape
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 32, h: 32))

      // Camera that follows the player
      Camera2D$()
        .enabled(true)
    }
    .position([400, 200])
    .onProcess { player, delta in
      var vel = player.velocity

      // Apply gravity
      vel.y += gravity * Float(delta)

      // Cap fall speed
      if vel.y > maxFallSpeed {
        vel.y = maxFallSpeed
      }

      // Get horizontal input
      var inputX: Float = 0
      if Action("move_left").isPressed {
        inputX -= 1
      }
      if Action("move_right").isPressed {
        inputX += 1
      }

      // Apply horizontal movement
      vel.x = inputX * speed

      // Jumping
      if Action("jump").isJustPressed && player.isOnFloor() {
        vel.y = jumpForce
      }

      // Apply velocity and handle collisions
      player.velocity = vel
      player.moveAndSlide()
    }
  }
}`;
