export default `import SwiftGodot
import SwiftGodotBuilder

struct PlayerView: GView {
  // Movement constants
  let gravity: Float = 980.0
  let speed: Float = 200.0
  let maxFallSpeed: Float = 500.0
  let jumpForce: Float = -400.0

  let terrainLayer: UInt32

  // Combat
  let isAttacking: State<Bool>

  // NEW: Reactive state properties
  @State var playerPos: Vector2 = [100, 100]
  @State var playerVel: Vector2 = [0, 0]
  @State var player: CharacterBody2D?

  init(from entity: LDEntity, in level: LDLevel, _ project: LDProject, isAttacking: State<Bool>) {
    self.isAttacking = isAttacking
    self.terrainLayer = project.collisionLayer(for: "Collisions", in: level)
    // NEW: Initialize position from entity
    self._playerPos = State(initialValue: entity.positionCenter)
  }

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
    .collisionMask(terrainLayer)
    .collisionLayer(1)  // Player layer
    .position($playerPos)
    .velocity($playerVel)
    .ref($player)
    .onProcess { _, delta in
      updatePlayer(delta)
    }
  }

  func updatePlayer(_ delta: Double) {
    guard let player else { return }

    var vel = playerVel

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

    // Move the player
    player.velocity = vel
    player.moveAndSlide()

    // NEW: Update reactive state from node
    playerVel = player.velocity
    playerPos = player.position
  }
}`;
