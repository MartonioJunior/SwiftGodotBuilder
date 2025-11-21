import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter12Player: GView {
  let spawnPoint: Vector2
  let screenWidth: Float
  let screenHeight: Float
  let gravity: Float
  let state: ObservableState<Chapter12GameViewState>

  private var vm: Chapter12GameViewState { state.wrappedValue }

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

  // Visual feedback state
  @State var playerScale: Vector2 = .init(x: 1, y: 1)
  @State var playerRotation: Float = 0
  @State var visualOffset: Vector2 = .zero

  init(
    spawnPoint: Vector2,
    screenWidth: Float,
    screenHeight: Float,
    gravity: Float,
    state: ObservableState<Chapter12GameViewState>
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
        .positionSmoothingEnabled(false) // Disabled for pixel-perfect rendering
        .watch(state, \.cameraOffset) { camera, offset in
          // Round offset to prevent sub-pixel jitter
          camera.offset = Vector2(
            x: round(offset.x),
            y: round(offset.y)
          )
        }
        .onReady { camera in
          camera.makeCurrent()
        }

      // Visual representation wrapped in Node2D for centered scaling and rotation
      Node2D$ {
        ColorBox$()
          .size([size, size])
          .position([-size / 2, -size / 2])
          .bind(\.color, to: $isInvincible, $invincibilityTimer, $isAttacking, $isDashing) { invincible, timer, attacking, dashing in
            if invincible {
              // Flash white during invincibility
              let flash = sin(timer * 20) > 0
              return flash ? Color(r: 1.0, g: 1.0, b: 1.0) : Color(r: 0.3, g: 0.5, b: 0.9)
            } else if attacking {
              // Orange when attacking
              return Color(r: 1.0, g: 0.7, b: 0.3)
            } else if dashing {
              // Cyan when dashing
              return Color(r: 0.3, g: 0.9, b: 1.0)
            } else {
              // Default blue color
              return Color(r: 0.3, g: 0.5, b: 0.9)
            }
          }
      }
      .bind(\.position, to: $visualOffset) { offset in
        Vector2(x: size / 2, y: size / 2) + offset
      }
      .watch($playerScale) { node, scale in
        node.scale = scale
      }
      .watch($playerRotation) { node, rotation in
        node.rotation = Double(rotation)
      }

      CollisionShape2D$()
        .shape(RectangleShape2D(w: size, h: size))
        .position([size / 2, size / 2])

      // Attack hitbox
      Area2D$ {
        ColorBox$()
          .size([12, 12])
          .color(Color(r: 1.0, g: 1.0, b: 1.0, a: 0.8))

        CollisionShape2D$()
          .shape(RectangleShape2D(w: 12, h: 12))
          .position([6, 6])
      }
      .bind(\.position, to: $facingRight) { facing in
        facing ? Vector2(x: 14, y: 2) : Vector2(x: -10, y: 2)
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
    .ref($playerNode)
    .onEvent(Chapter12Event.self) { _, event in
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

        // Stretch effect on jump (skinny, tall)
        playerScale = Vector2(x: 0.6, y: 1.4)

        Chapter12Event.jumped(position: position + Vector2(x: size / 2, y: size)).emit()
      }

      // Variable jump height - release jump button for lower jump
      if Action("jump").isJustReleased, isJumping, vel.y < 0 {
        vel.y = max(vel.y, -minJumpSpeed)
        isJumping = false
      }
    }

    // Weapon switching
    if Action("switch_weapon").isJustPressed {
      vm.currentWeapon = vm.currentWeapon == .melee ? .ranged : .melee
      Chapter12Event.weaponSwitched(weaponType: vm.currentWeapon).emit()
    }

    // Attack
    if Action("attack").isJustPressed, !isAttacking {
      if vm.currentWeapon == .melee {
        // Melee attack
        isAttacking = true
        attackTimer = attackDuration
        Chapter12Event.attacked(position: position).emit()
      } else {
        // Ranged attack - fire projectile if we have ammo
        if vm.consumeAmmo() {
          let projectilePos = position + Vector2(x: size / 2, y: size / 2)
          let direction = Vector2(x: facingRight ? 1 : -1, y: 0)
          Chapter12Event.projectileFired(position: projectilePos, direction: direction).emit()
        }
      }
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
      // Squash effect on land (wider, shorter) - pinned to bottom
      playerScale = Vector2(x: 1.3, y: 0.8)
      visualOffset = Vector2(x: 0, y: size * (1 - 0.8) / 2)

      Chapter12Event.landed(position: position + Vector2(x: size / 2, y: size), impact: Float(fallingVelocity)).emit()
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

    // Smoothly lerp scale back to normal
    let normalScale = Vector2(x: 1, y: 1)
    if playerScale != normalScale {
      playerScale = playerScale.lerp(to: normalScale, weight: 12.0 * delta)
      // Snap to normal when very close
      if abs(playerScale.x - 1.0) < 0.01 && abs(playerScale.y - 1.0) < 0.01 {
        playerScale = normalScale
      }
    }

    // Smoothly lerp visual offset back to zero
    if visualOffset != .zero {
      visualOffset = visualOffset.lerp(to: .zero, weight: 12.0 * delta)
      // Snap to zero when very close
      if visualOffset.length() < 0.01 {
        visualOffset = .zero
      }
    }

    // Smoothly decay rotation back to 0
    if playerRotation != 0 {
      playerRotation *= Float(1.0 - 8.0 * delta)
      // Snap to 0 when very close
      if abs(playerRotation) < 0.01 {
        playerRotation = 0
      }
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

      // Spin rotation effect on death
      playerRotation = Float.pi * 4 // 2 full rotations

      Chapter12Event.playerDied(position: position + Vector2(x: size / 2, y: size / 2)).emit()
    } else {
      isInvincible = true
      invincibilityTimer = invincibilityDuration

      // Quick rotation wobble on damage
      playerRotation = Float.pi / 8 // 22.5 degrees
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

    // Reset visual feedback
    playerScale = Vector2(x: 1, y: 1)
    playerRotation = 0
    visualOffset = .zero
  }
}
