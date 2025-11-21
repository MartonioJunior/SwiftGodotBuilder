import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter9Player: GView {
  let spawnPoint: Vector2
  let screenWidth: Float
  let screenHeight: Float
  let gravity: Float
  let state: ObservableState<Chapter9GameViewState>

  private var vm: Chapter9GameViewState { state.wrappedValue }

  // Player-specific constants
  let size: Float = 16
  let jumpSpeed: Float = 180
  let moveSpeed: Float = 100
  let maxHealth: Int = 3
  let invincibilityDuration: Double = 1.0
  let attackDuration: Double = 0.2

  // Advanced movement constants
  let coyoteTime: Double = 0.15 // Time after leaving platform to still jump
  let jumpBufferTime: Double = 0.1 // Time to buffer jump input before landing
  let minJumpSpeed: Float = 100 // Minimum jump when releasing jump button early
  let wallJumpSpeed: Float = 200 // Horizontal speed from wall jump
  let wallJumpVerticalSpeed: Float = 180 // Vertical speed from wall jump
  let dashSpeed: Float = 300 // Dash speed
  let dashDuration: Double = 0.2 // How long dash lasts
  let dashCooldown: Double = 1.0 // Cooldown between dashes

  @State var position: Vector2 = .zero
  @State var velocity: Vector2 = [0, 0]
  @State var isInvincible: Bool = false
  @State var invincibilityTimer: Double = 0
  @State var isAttacking: Bool = false
  @State var attackTimer: Double = 0
  @State var playerNode: CharacterBody2D?
  @State var wasOnFloor: Bool = false
  @State var movementTimer: Double = 0

  // Advanced movement state
  @State var facingRight: Bool = true
  @State var coyoteTimer: Double = 0
  @State var jumpBufferTimer: Double = 0
  @State var isJumping: Bool = false
  @State var hasDoubleJump: Bool = false
  @State var isDashing: Bool = false
  @State var dashTimer: Double = 0
  @State var dashCooldownTimer: Double = 0
  @State var dashDirection: Vector2 = .zero
  @State var isOnWall: Bool = false

  init(
    spawnPoint: Vector2,
    screenWidth: Float,
    screenHeight: Float,
    gravity: Float,
    state: ObservableState<Chapter9GameViewState>
  ) {
    self.spawnPoint = spawnPoint
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    self.gravity = gravity
    self.state = state
    position = spawnPoint
  }

  var body: some GView {
    CharacterBody2D$ {
      // Camera following the player
      Camera2D$()
        .enabled(true)
        .positionSmoothingEnabled(true)
        .positionSmoothingSpeed(5.0)
        .watch(state, \.cameraOffset) { camera, offset in
          camera.offset = offset
        }
        .onReady { camera in
          camera.makeCurrent()
        }

      ColorBox$()
        .size([size, size])
        .bind(\.color, to: $isInvincible, $invincibilityTimer, $isAttacking) { invincible, timer, attacking in
          if invincible {
            // Flash white during invincibility
            let flash = sin(timer * 20) > 0
            return flash ? Color(r: 1.0, g: 1.0, b: 1.0) : Color(r: 0.3, g: 0.5, b: 0.9)
          } else if attacking {
            return Color(r: 1.0, g: 0.7, b: 0.3)
          } else {
            return Color(r: 0.3, g: 0.5, b: 0.9)
          }
        }

      CollisionShape2D$()
        .shape(RectangleShape2D(w: size, h: size))
        .position([size / 2, size / 2])

      // Attack hitbox
      Area2D$ {
        ColorBox$()
          .size([12, 12])
          .color(Color(r: 1.0, g: 1.0, b: 0.5, a: 0.7))

        CollisionShape2D$()
          .shape(RectangleShape2D(w: 12, h: 12))
          .position([6, 6])
      }
      .bind(\.position, to: $facingRight) { facing in
        facing ? Vector2(x: 8, y: 2) : Vector2(x: -4, y: 2)
      }
      .collisionLayer(.delta)
      .bind(\.processMode, to: $isAttacking) { attacking in
        attacking ? .inherit : .disabled
      }
      .visible($isAttacking)
    }
    .collisionLayer(.beta)
    .position($position)
    .velocity($velocity)
    .watch(state, \.isMenu) { node, isMenu in
      node.visible = !isMenu
    }
    .ref($playerNode)
    .onEvent(Chapter9Event.self) { _, event in
      switch event {
      case .gameReset:
        respawn()
      case let .playerHit(damage, _):
        takeDamage(damage)
      default:
        break
      }
    }
    .onProcess { _, delta in
      guard vm.isPlaying else {
        return
      }

      guard let player = playerNode else {
        return
      }

      updatePlayer(player, delta)
      updateTimers(delta)
    }
  }

  func updatePlayer(_ player: CharacterBody2D, _ delta: Double) {
    var vel = velocity
    let onFloor = player.isOnFloor()
    isOnWall = player.isOnWall()

    // Dash logic - overrides normal movement
    if isDashing {
      vel = dashDirection * dashSpeed
    } else {
      // Apply gravity (reduced on walls for wall slide)
      if isOnWall, vel.y > 0 {
        vel.y += gravity * Float(delta) * 0.3 // Wall slide slower
      } else {
        vel.y += gravity * Float(delta)
      }

      // Horizontal movement
      var input: Float = 0
      if Action("move_left").isPressed {
        input -= 1
        facingRight = false
      }
      if Action("move_right").isPressed {
        input += 1
        facingRight = true
      }
      vel.x = input * moveSpeed

      // Dash input
      if Action("dash").isJustPressed, dashCooldownTimer <= 0 {
        isDashing = true
        dashTimer = dashDuration
        dashCooldownTimer = dashCooldown
        dashDirection = Vector2(x: facingRight ? 1 : -1, y: 0)
      }

      // Jump buffering - store jump input
      if Action("jump").isJustPressed {
        jumpBufferTimer = jumpBufferTime
      }

      // Check if we can jump (ground, coyote time, or wall)
      let canJump = onFloor || coyoteTimer > 0 || isOnWall || hasDoubleJump

      // Jump logic with buffering
      if jumpBufferTimer > 0, canJump {
        if isOnWall {
          // Wall jump - push away from wall
          vel.y = -wallJumpVerticalSpeed
          vel.x = player.getWallNormal().x * wallJumpSpeed
          facingRight = vel.x > 0
        } else if hasDoubleJump, !onFloor {
          // Double jump
          vel.y = -jumpSpeed
          hasDoubleJump = false
        } else {
          // Normal jump
          vel.y = -jumpSpeed
        }
        isJumping = true
        jumpBufferTimer = 0
        coyoteTimer = 0
        Chapter9Event.jumped(position: position + Vector2(x: size / 2, y: size)).emit()
      }

      // Variable jump height - release jump button for lower jump
      if Action("jump").isJustReleased, isJumping, vel.y < 0 {
        vel.y = max(vel.y, -minJumpSpeed)
        isJumping = false
      }
    }

    // Attack
    if Action("attack").isJustPressed, !isAttacking {
      isAttacking = true
      attackTimer = attackDuration
      Chapter9Event.attacked(position: position).emit()
    }

    // Check landing before moveAndSlide (velocity gets reset on collision)
    let wasInAir = !wasOnFloor
    let fallingVelocity = vel.y

    // Move the player
    player.velocity = vel
    player.moveAndSlide()

    // Update state
    velocity = player.velocity
    position = player.position

    // Update coyote time
    if onFloor {
      coyoteTimer = coyoteTime
      hasDoubleJump = true // Reset double jump on landing
      isJumping = false
    } else if coyoteTimer > 0 {
      coyoteTimer -= delta
    }

    // Landing impact - check velocity before it was reset by collision
    if wasInAir, player.isOnFloor(), fallingVelocity > 100 {
      Chapter9Event.landed(position: position + Vector2(x: size / 2, y: size), impact: Float(fallingVelocity)).emit()
    }
    wasOnFloor = player.isOnFloor()

    // Keep player in bounds
    if position.x < 0 {
      position.x = 0
      player.position = position
    } else if position.x > screenWidth - size {
      position.x = screenWidth - size
      player.position = position
    }

    // Fall off screen = die
    if position.y > screenHeight + 100 {
      takeDamage(vm.playerHealth)
    }
  }

  func updateTimers(_ delta: Double) {
    // Invincibility timer
    if isInvincible {
      invincibilityTimer -= delta
      if invincibilityTimer <= 0 {
        isInvincible = false
        invincibilityTimer = 0
      }
    }

    // Attack timer
    if isAttacking {
      attackTimer -= delta
      if attackTimer <= 0 {
        isAttacking = false
        attackTimer = 0
      }
    }

    // Jump buffer timer
    if jumpBufferTimer > 0 {
      jumpBufferTimer -= delta
    }

    // Dash timer
    if isDashing {
      dashTimer -= delta
      if dashTimer <= 0 {
        isDashing = false
        dashTimer = 0
      }
    }

    // Dash cooldown timer
    if dashCooldownTimer > 0 {
      dashCooldownTimer -= delta
    }
  }

  func takeDamage(_ damage: Int) {
    guard !isInvincible else { return }

    vm.playerHealth -= damage

    if vm.playerHealth <= 0 {
      vm.playerHealth = 0
      Chapter9Event.playerDied(position: position + Vector2(x: size / 2, y: size / 2)).emit()
    } else {
      isInvincible = true
      invincibilityTimer = invincibilityDuration
    }
  }

  func respawn() {
    position = spawnPoint
    velocity = [0, 0]
    vm.playerHealth = maxHealth
    isInvincible = true
    invincibilityTimer = invincibilityDuration
    isAttacking = false
    attackTimer = 0

    // Reset advanced movement state
    facingRight = true
    coyoteTimer = 0
    jumpBufferTimer = 0
    isJumping = false
    hasDoubleJump = false
    isDashing = false
    dashTimer = 0
    dashCooldownTimer = 0
    isOnWall = false
  }
}
