import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter22 {
  struct Player: GView {
    let spawnPoint: Vector2
    let screenWidth: Float
    let screenHeight: Float
    let gravity: Float
    let state: ObservableState<GameViewState>

    private var vm: GameViewState { state.wrappedValue }

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

    // Crouching constants
    let crouchHeight: Float = 8 // Height when crouching (half normal)
    let crouchSpeedMultiplier: Float = 0.5 // Move slower when crouching

    // Water physics constants
    let waterGravityMultiplier: Float = 0.25 // Much less gravity in water
    let waterMoveSpeedMultiplier: Float = 0.6 // Slower horizontal movement
    let waterMaxFallSpeed: Float = 50 // Terminal velocity in water
    let swimSpeed: Float = 120 // Upward swim speed when pressing jump

    @State var position: Vector2 = .zero
    @State var velocity: Vector2 = [0, 0]
    @State var isInvincible = false
    @State var invincibilityTimer = 0.0
    @State var isAttacking = false
    @State var attackTimer = 0.0
    @State var playerNode: CharacterBody2D?
    @State var collisionShape: CollisionShape2D?
    @State var wasOnFloor = false
    @State var movementTimer = 0.0

    // Advanced movement state
    @State var facingRight = true
    @State var coyoteTimer = 0.0
    @State var jumpBufferTimer = 0.0
    @State var isJumping = false
    @State var hasDoubleJump = false
    @State var isDashing = false
    @State var dashTimer = 0.0
    @State var dashCooldownTimer = 0.0
    @State var dashDirection: Vector2 = .zero
    @State var isOnWall = false
    @State var isCrouching = false
    @State var isInWater = false

    // Visual feedback state
    @State var playerScale: Vector2 = [1, 1]
    @State var playerRotation: Float = 0
    @State var visualOffset: Vector2 = .zero

    let palette = Palette.shared

    init(
      spawnPoint: Vector2,
      screenWidth: Float,
      screenHeight: Float,
      gravity: Float,
      state: ObservableState<GameViewState>
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
            .bind(\.size, to: $isCrouching) { crouching in
              crouching ? [size, crouchHeight] : [size, size]
            }
            .bind(\.position, to: $isCrouching) { crouching in
              crouching ? [-size / 2, -crouchHeight / 2] : [-size / 2, -size / 2]
            }
            .bind(\.color, to: $isInvincible, $invincibilityTimer, $isAttacking, $isDashing) { invincible, timer, attacking, dashing in
              if invincible {
                // Flash white during invincibility
                let flash = sin(timer * 20) > 0
                return flash ? palette.playerWhiteFlash : palette.playerBlue
              } else if attacking {
                // Orange when attacking
                return palette.playerDash
              } else if dashing {
                // Cyan when dashing
                return palette.playerDoubleJump
              } else {
                // Default blue color
                return palette.playerBlue
              }
            }
            .watch($isInWater) { node, inWater in
              // Modulate color when in water (unless invincible/attacking/dashing)
              if inWater {
                node.modulate = Color(r: 0.7, g: 0.9, b: 1.0, a: 1.0)
              } else {
                node.modulate = Color(r: 1, g: 1, b: 1, a: 1)
              }
            }
        }
        .bind(\.position, to: $visualOffset, $isCrouching) { offset, crouching in
          // Keep feet on ground - visual center moves down when crouching
          let yCenter = crouching ? size - crouchHeight / 2 : size / 2
          return [size / 2, yCenter] + offset
        }
        .scale($playerScale)
        .watch($playerRotation) { node, rotation in
          node.rotation = Double(rotation)
        }

        CollisionShape2D$()
          .shape(RectangleShape2D(w: size, h: size))
          .bind(\.position, to: $isCrouching) { crouching in
            // Keep feet on ground - collision shape bottom stays at y = size
            let height = crouching ? crouchHeight : size
            return [size / 2, size - height / 2]
          }
          .ref($collisionShape)
          .debugColor(Color(r: 0, g: 0, b: 0, a: 0))
          .watch($isCrouching) { shape, crouching in
            let height = crouching ? crouchHeight : size
            shape.shape = RectangleShape2D(w: size, h: height)
          }

        // Attack hitbox
        Area2D$ {
          ColorBox$()
            .size([12, 12])
            .color(palette.playerDashTrail)

          CollisionShape2D$()
            .shape(RectangleShape2D(w: 12, h: 12))
            .position([6, 6])
        }
        .bind(\.position, to: $facingRight) { facing in
          facing ? [14, 2] : [-10, 2]
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
      .onEvent(Event.self) { _, event in
        switch event {
        case .gameReset:
          respawn()
        case let .playerHit(damage, _):
          takeDamage(damage)
        case .enteredWater:
          isInWater = true
        case .exitedWater:
          isInWater = false
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

      // Dash logic - overrides normal movement (disabled in water)
      if isDashing, !isInWater {
        vel = dashDirection * dashSpeed
      } else if isInWater {
        // Water physics - Mario Bros style swimming

        // Reduced gravity in water
        vel.y += gravity * Float(delta) * waterGravityMultiplier

        // Cap fall speed in water (buoyancy)
        if vel.y > waterMaxFallSpeed {
          vel.y = waterMaxFallSpeed
        }

        // Swimming - press jump to swim upward
        if Action("jump").isPressed {
          vel.y = -swimSpeed
        }

        // Sink faster when pressing down
        if Action("move_down").isPressed {
          vel.y = min(vel.y + gravity * Float(delta), waterMaxFallSpeed * 2)
        }

        // Horizontal movement (slower in water)
        var input: Float = 0
        if Action("move_left").isPressed {
          input -= 1
          facingRight = false
        }
        if Action("move_right").isPressed {
          input += 1
          facingRight = true
        }
        vel.x = input * moveSpeed * waterMoveSpeedMultiplier

        // Reset double jump while in water
        hasDoubleJump = true
        isCrouching = false
      } else {
        // Normal land physics

        // Apply gravity (reduced on walls for wall slide)
        if isOnWall, vel.y > 0 {
          vel.y += gravity * Float(delta) * 0.3 // Wall slide slower
        } else {
          vel.y += gravity * Float(delta)
        }

        // Crouching - only on ground, stay crouched if holding down
        let wantsToCrouch = Action("move_down").isPressed
        if wantsToCrouch, onFloor {
          isCrouching = true
        } else if !wantsToCrouch, isCrouching {
          // Only stop crouching if there's room to stand up
          if canStandUp(player) {
            isCrouching = false
          }
        }
        // Note: if player walks off edge while crouching, they stay crouched until releasing down

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
        let speed = isCrouching ? moveSpeed * crouchSpeedMultiplier : moveSpeed
        vel.x = input * speed

        // Dash input
        if Action("dash").isJustPressed, dashCooldownTimer <= 0 {
          isDashing = true
          dashTimer = dashDuration
          dashCooldownTimer = dashCooldown
          dashDirection = [facingRight ? 1 : -1, 0]
        }

        // Jump buffering - store jump input
        if Action("jump").isJustPressed {
          jumpBufferTimer = jumpBufferTime
        }

        // Check if we can jump (ground, coyote time, or wall) - can't jump while crouching
        let canJump = !isCrouching && (onFloor || coyoteTimer > 0 || isOnWall || hasDoubleJump)

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
          playerScale = [0.6, 1.4]

          Event.jumped(position: position + [size / 2, size]).emit()
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
        Event.weaponSwitched(weaponType: vm.currentWeapon).emit()
      }

      // Attack
      if Action("attack").isJustPressed, !isAttacking {
        if vm.currentWeapon == .melee {
          // Melee attack
          isAttacking = true
          attackTimer = attackDuration
          Event.attacked(position: position).emit()
        } else {
          // Ranged attack - fire projectile if we have ammo
          if vm.consumeAmmo() {
            let projectilePos = position + [size / 2, size / 2]
            let direction: Vector2 = [facingRight ? 1 : -1, 0]
            Event.projectileFired(position: projectilePos, direction: direction).emit()
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
        playerScale = [1.3, 0.8]
        visualOffset = [0, size * (1 - 0.8) / 2]

        Event.landed(position: position + [size / 2, size], impact: Float(fallingVelocity)).emit()
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
      let normalScale: Vector2 = [1, 1]
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

        Event.playerDied(position: position + [size / 2, size / 2]).emit()
      } else {
        isInvincible = true
        invincibilityTimer = invincibilityDuration

        // Quick rotation wobble on damage
        playerRotation = Float.pi / 8 // 22.5 degrees
      }
    }

    func respawn() {
      // Respawn at last checkpoint if available, otherwise at level spawn point
      let levelSpawn = Chapter22.getLevelData(vm.currentLevelId)?.playerSpawnPoint ?? spawnPoint
      position = vm.lastCheckpointPosition ?? levelSpawn
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
      isCrouching = false
      isInWater = false

      // Reset visual feedback
      playerScale = [1, 1]
      playerRotation = 0
      visualOffset = .zero
    }

    /// Check if there's enough room above the player to stand up from crouching
    func canStandUp(_ player: CharacterBody2D) -> Bool {
      guard let spaceState = player.getWorld2d()?.directSpaceState else {
        return true // If we can't check, assume we can stand
      }

      // Check both left and right edges to handle partial overlap with platforms
      let crouchedTop = size - crouchHeight
      let margin: Float = 2 // Small inset from edges

      // Left edge ray
      let leftStart = position + [margin, crouchedTop]
      let leftEnd = position + [margin, 0]
      if spaceState.raycast(from: leftStart, to: leftEnd, mask: 1, excluding: player) != nil {
        return false
      }

      // Right edge ray
      let rightStart = position + [size - margin, crouchedTop]
      let rightEnd = position + [size - margin, 0]
      if spaceState.raycast(from: rightStart, to: rightEnd, mask: 1, excluding: player) != nil {
        return false
      }

      return true
    }
  }
}
