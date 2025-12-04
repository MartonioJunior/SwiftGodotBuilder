import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct PlayerView: GView {
    let state: ObservableState<GameViewState>
    let settings: ObservableState<GameSettings>
    let router: ObservableState<GameRouter>

    private var vm: GameViewState { state.wrappedValue }
    private var gs: GameSettings { settings.wrappedValue }

    var spawnPoint: Vector2 { vm.currentLevelData?.playerSpawnPoint ?? [40, 100] }
    var screenWidth: Float { vm.currentLevelData?.levelWidth ?? 800 }
    let jumpSpeed: Float = 180
    let moveSpeed: Float = 100
    let maxHealth: Int = 3
    let invincibilityDuration: Double = 1.0
    let attackDuration: Double = 0.2
    let hitAnimDuration: Double = 0.3

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
    let crouchSpeedMultiplier: Float = 0.5 // Move slower when crouching

    // Water physics constants
    let waterGravityMultiplier: Float = 0.25 // Much less gravity in water
    let waterMoveSpeedMultiplier: Float = 0.6 // Slower horizontal movement
    let waterMaxFallSpeed: Float = 50 // Terminal velocity in water
    let swimSpeed: Float = 120 // Upward swim speed when pressing jump

    @State var position: Vector2 = .zero
    @State var velocity: Vector2 = [0, 0]
    @State var playerNode: CharacterBody2D?
    @State var collisionShape: CollisionShape2D?
    @State var wasOnFloor = false

    // Core player state
    @State var action: ActionState = .idle
    @State var damage: DamageState = .normal
    @State var facing: Facing = .right
    @State var overlay: ActionOverlayState = []

    // Detection flags (from physics)
    @State var isOnWall = false
    @State var isInWater = false

    // Resources
    @State var hasDoubleJump = true

    // Timers
    @State var invincibilityTimer = 0.0
    @State var attackTimer = 0.0
    @State var hitTimer = 0.0
    @State var coyoteTimer = 0.0
    @State var jumpBufferTimer = 0.0
    @State var dashTimer = 0.0
    @State var dashCooldownTimer = 0.0
    @State var dashDirection: Vector2 = .zero

    // Visual feedback state
    @State var playerScale: Vector2 = [1, 1]
    @State var playerRotation: Float = 0
    @State var visualOffset: Vector2 = .zero

    // Player colors
    let playerBlue = Color(code: "#4D80E6")
    let playerWhiteFlash = Color(code: "#FFFFFF")
    let playerDash = Color(code: "#FFB34D")
    let playerDoubleJump = Color(code: "#4DE6FF")
    let playerDashTrail = Color(code: "#FFFFFFCC")

    var spriteModulate: GState<Color> {
      $overlay.computed(with: $invincibilityTimer, $action) { overlay, timer, action in
        if overlay.contains(.invincible) {
          // Flash white during invincibility
          let flash = sin(timer * 20) > 0
          return flash ? playerWhiteFlash : playerBlue
        } else if overlay.contains(.attacking) {
          return playerDash
        } else if action == .dashing {
          return playerDoubleJump
        } else {
          return .white
        }
      }
    }

    var body: some GView {
      CharacterBody2D$ {
        Camera2D$()
          .positionSmoothingEnabled(false)
          .watch(state, \.cameraOffset) { camera, offset in
            camera.offset = Vector2(
              x: round(offset.x),
              y: round(offset.y)
            )
          }

        ColorBox$()
          .size([8, 8])
          .modulate(spriteModulate)
          .scale($playerScale)
          .rotation($playerRotation) { Double($0) }
          .watch($overlay) { node, overlay in
            let isCrouching = overlay.contains(.crouching)
            node.size = [8, isCrouching ? 4 : 8]
            node.position = [0, isCrouching ? 4 : 0]
          }

        // Physics collision shape (smaller - for world, enemies, projectiles)
        CollisionShape2D$()
          .shape(RectangleShape2D(w: 5, h: 6))
          .position([3.5, 4.5])
          .ref($collisionShape)
          .watch($overlay) { node, overlay in
            let crouching = overlay.contains(.crouching)
            node.shape = RectangleShape2D(w: 5, h: crouching ? 4 : 6)
            node.position = [3.5, crouching ? 5.5 : 4.5]
          }

        // Interaction area (larger - for NPCs, chests, doors)
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(w: 10, h: 10))
            .position([4, 4])
        }
        .collisionLayer(.interaction)

        // Attack hitbox
        Area2D$ {
          ColorBox$()
            .size([6, 3])
            .color(playerDashTrail)

          CollisionShape2D$()
            .shape(RectangleShape2D(w: 6, h: 3))
            .position([3, 1.5])
        }
        .bind(\.position, to: $facing) { facing in
          facing.isRight ? [8, 3] : [-6, 3]
        }
        .collisionLayer(.combat)
        .bind(\.processMode, to: $overlay) { overlay in
          overlay.contains(.attacking) ? .inherit : .disabled
        }
        .bind(\.visible, to: $overlay) { $0.contains(.attacking) }
      }
      .collisionLayer(.player)
      .collisionMask(.terrain)
      .position($position)
      .velocity($velocity)
      .ref($playerNode)
      .onReady { node in
        position = spawnPoint
        node.position = spawnPoint
      }
      .onEvent(GameEvent.self) { _, event in
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
        guard router.scene.isActive else {
          return
        }

        guard let playerNode else { return }

        updatePlayer(playerNode, delta)
        updateTimers(delta)
      }
    }

    func updatePlayer(_ player: CharacterBody2D, _ delta: Double) {
      var vel = velocity
      let onFloor = player.isOnFloor()
      isOnWall = player.isOnWall()
      let isCrouching = overlay.contains(.crouching)

      // Dash logic - overrides normal movement (disabled in water)
      if action == .dashing, !isInWater {
        vel = dashDirection * dashSpeed
      } else if isInWater {
        // Water physics - Mario Bros style swimming
        action = .swimming

        // Reduced gravity in water
        vel.y += gs.gravity * Float(delta) * waterGravityMultiplier

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
          vel.y = min(vel.y + gs.gravity * Float(delta), waterMaxFallSpeed * 2)
        }

        // Horizontal movement (slower in water)
        var input: Float = 0
        if Action("move_left").isPressed {
          input -= 1
          facing = .left
        }
        if Action("move_right").isPressed {
          input += 1
          facing = .right
        }
        vel.x = input * moveSpeed * waterMoveSpeedMultiplier

        // Reset states while in water
        hasDoubleJump = true
        overlay.remove(.crouching)
      } else {
        // Normal land physics

        // Apply gravity (reduced on walls for wall slide)
        if isOnWall, vel.y > 0 {
          vel.y += gs.gravity * Float(delta) * 0.3 // Wall slide slower
        } else {
          vel.y += gs.gravity * Float(delta)
        }

        // Crouching - only on ground, stay crouched if holding down
        let wantsToCrouch = Action("move_down").isPressed
        if wantsToCrouch, onFloor {
          overlay.insert(.crouching)
        } else if !wantsToCrouch, isCrouching {
          // Only stop crouching if there's room to stand up
          if canStandUp(player) {
            overlay.remove(.crouching)
          }
        }
        // Note: if player walks off edge while crouching, they stay crouched until releasing down

        // Horizontal movement
        var input: Float = 0
        if Action("move_left").isPressed {
          input -= 1
          facing = .left
        }
        if Action("move_right").isPressed {
          input += 1
          facing = .right
        }
        let speed = isCrouching ? moveSpeed * crouchSpeedMultiplier : moveSpeed
        vel.x = input * speed

        // Dash input
        if Action("dash").isJustPressed, dashCooldownTimer <= 0 {
          action = .dashing
          dashTimer = dashDuration
          dashCooldownTimer = dashCooldown
          dashDirection = [facing.sign, 0]
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
            facing = vel.x > 0 ? .right : .left
          } else if hasDoubleJump, !onFloor {
            // Double jump
            vel.y = -jumpSpeed
            hasDoubleJump = false
          } else {
            // Normal jump
            vel.y = -jumpSpeed
          }
          action = .jumping
          jumpBufferTimer = 0
          coyoteTimer = 0

          // Stretch effect on jump (skinny, tall)
          playerScale = [0.6, 1.4]

          GameEvent.jumped(position: position + [3, 8]).emit()
        }

        // Variable jump height - release jump button for lower jump
        if Action("jump").isJustReleased, action == .jumping, vel.y < 0 {
          vel.y = max(vel.y, -minJumpSpeed)
        }

        // Update action state based on movement (if not dashing/jumping)
        if action != .dashing {
          if isOnWall && !onFloor && vel.y > 0 {
            action = .wallSliding
          } else if !onFloor {
            action = vel.y < 0 ? .jumping : .falling
          } else if input != 0 {
            action = .walking
          } else {
            action = .idle
          }
        }
      }

      // Weapon switching
      if Action("switch_weapon").isJustPressed {
        vm.currentWeapon = vm.currentWeapon == .melee ? .ranged : .melee
        GameEvent.weaponSwitched(weaponType: vm.currentWeapon).emit()
      }

      // Attack
      if Action("attack").isJustPressed, !overlay.contains(.attacking) {
        if vm.currentWeapon == .melee {
          // Melee attack
          overlay.insert(.attacking)
          attackTimer = attackDuration
          GameEvent.attacked(position: position).emit()
        } else {
          // Ranged attack - fire projectile if we have ammo
          if vm.consumeAmmo() {
            let projectilePos = position + [6, 4]
            let direction: Vector2 = [facing.sign, 0]
            GameEvent.projectileFired(position: projectilePos, direction: direction).emit()
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

      // Update coyote time and reset on landing
      if onFloor {
        coyoteTimer = coyoteTime
        hasDoubleJump = true
        if action == .jumping || action == .falling {
          action = .idle
        }
      } else if coyoteTimer > 0 {
        coyoteTimer -= delta
      }

      // Landing impact - check velocity before it was reset by collision
      if wasInAir, player.isOnFloor(), fallingVelocity > 100 {
        // Squash effect on land (wider, shorter) - pinned to bottom
        playerScale = [1.3, 0.8]
        visualOffset = [0, 8 * (1 - 0.8) / 2]

        GameEvent.landed(position: position + [3, 8], impact: Float(fallingVelocity)).emit()
      }
      wasOnFloor = player.isOnFloor()

      // Keep player in bounds
      if position.x < 0 {
        position.x = 0
        player.position = position
      } else if position.x > screenWidth - 6 {
        position.x = screenWidth - 6
        player.position = position
      }

      // Fall off screen = die
      let viewportHeight = player.getViewportRect().size.y
      if position.y > viewportHeight + 100 {
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
      if overlay.contains(.invincible) {
        invincibilityTimer -= delta
        if invincibilityTimer <= 0 {
          overlay.remove(.invincible)
          invincibilityTimer = 0
        }
      }

      // Attack timer
      if overlay.contains(.attacking) {
        attackTimer -= delta
        if attackTimer <= 0 {
          overlay.remove(.attacking)
          attackTimer = 0
        }
      }

      // Hit animation timer (damage state)
      if damage == .hit {
        hitTimer -= delta
        if hitTimer <= 0 {
          damage = .normal
          hitTimer = 0
        }
      }

      // Jump buffer timer
      if jumpBufferTimer > 0 {
        jumpBufferTimer -= delta
      }

      // Dash timer
      if action == .dashing {
        dashTimer -= delta
        if dashTimer <= 0 {
          action = .idle
          dashTimer = 0
        }
      }

      // Dash cooldown timer
      if dashCooldownTimer > 0 {
        dashCooldownTimer -= delta
      }
    }

    func takeDamage(_ amount: Int) {
      guard !overlay.contains(.invincible) else { return }

      vm.playerHealth -= amount
      damage = .hit
      hitTimer = hitAnimDuration

      if vm.playerHealth <= 0 {
        vm.playerHealth = 0
        damage = .dead

        // Spin rotation effect on death
        playerRotation = Float.pi * 4 // 2 full rotations

        GameEvent.playerDied(position: position + [3, 4.5]).emit()
      } else {
        overlay.insert(.invincible)
        invincibilityTimer = invincibilityDuration

        // Quick rotation wobble on damage
        playerRotation = Float.pi / 8 // 22.5 degrees
      }
    }

    func respawn() {
      // Respawn at last checkpoint if available, otherwise at level spawn point
      position = vm.lastCheckpointPosition ?? spawnPoint
      velocity = [0, 0]
      vm.playerHealth = maxHealth

      // Reset state
      action = .idle
      damage = .normal
      facing = .right
      overlay = [.invincible]
      invincibilityTimer = invincibilityDuration

      // Reset detection flags
      isOnWall = false
      isInWater = false

      // Reset resources
      hasDoubleJump = true

      // Reset timers
      attackTimer = 0
      hitTimer = 0
      coyoteTimer = 0
      jumpBufferTimer = 0
      dashTimer = 0
      dashCooldownTimer = 0
      dashDirection = .zero

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
      let standingTop: Float = 1 // visual top
      let crouchedTop: Float = 4 // 8 - 4 = 4
      let margin: Float = 2 // Small inset from edges

      // Left edge ray
      let leftStart = position + [margin, crouchedTop] // [2, 4]
      let leftEnd = position + [margin, standingTop] // [2, 1]
      if spaceState.raycast(from: leftStart, to: leftEnd, mask: 1, excluding: player) != nil {
        return false
      }

      // Right edge ray
      let rightStart = position + [6 - margin, crouchedTop]
      let rightEnd = position + [6 - margin, 0]
      if spaceState.raycast(from: rightStart, to: rightEnd, mask: 1, excluding: player) != nil {
        return false
      }

      return true
    }
  }
}
