export default `import SwiftGodot
import SwiftGodotBuilder

struct PlayerView: GView {
  // Movement constants
  let gravity: Float = 980.0
  let speed: Float = 200.0
  let maxFallSpeed: Float = 500.0
  let jumpForce: Float = -400.0
  let coyoteTime: Float = 0.15      // 150ms grace period
  let jumpBufferTime: Float = 0.1   // 100ms input buffer

  var body: some GView {
    CharacterBody2D$ {
      // Visual representation (simple colored square for now)
      ColorBox$()
        .color(.darkGray)
        .size([32, 32])
        .position([-16, -16]) // Center the box

      // Collision shape
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 32, h: 32))
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

      // Track time since leaving ground (coyote time)
      let coyoteTimer = player.get("coyoteTimer") as? Float ?? 0
      if player.isOnFloor() {
        player.set("coyoteTimer", coyoteTime)
      } else {
        player.set("coyoteTimer", max(0, coyoteTimer - Float(delta)))
      }

      // Track jump input buffer
      let jumpBufferTimer = player.get("jumpBufferTimer") as? Float ?? 0
      if Action("jump").isJustPressed {
        player.set("jumpBufferTimer", jumpBufferTime)
      } else {
        player.set("jumpBufferTimer", max(0, jumpBufferTimer - Float(delta)))
      }

      // Execute jump if buffered input and coyote time available
      let updatedCoyoteTimer = player.get("coyoteTimer") as? Float ?? 0
      let updatedJumpBufferTimer = player.get("jumpBufferTimer") as? Float ?? 0
      if updatedJumpBufferTimer > 0 && updatedCoyoteTimer > 0 {
        vel.y = jumpForce
        player.set("jumpBufferTimer", 0)
        player.set("coyoteTimer", 0)
      }

      // Apply velocity and handle collisions
      player.velocity = vel
      player.moveAndSlide()
    }
  }
}`;
