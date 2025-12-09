import SwiftGodot
import SwiftGodotBuilder

extension Chapter26.PlayerState {
  // MARK: - Physics Queries

  /// Check if player has room to stand up from crouching position
  /// - Parameters:
  ///   - body: Player's CharacterBody2D for physics queries
  ///   - collisionSize: Player collision box size
  /// - Returns: `true` if no obstacles above, `false` if blocked
  func canStandUp(body: CharacterBody2D, collisionSize: Vector2) -> Bool {
    guard let spaceState = body.getWorld2d()?.directSpaceState else { return true }

    let crouchedTop = -collisionSize.y / 2
    let standingTop = -collisionSize.y
    let margin = collisionSize.x * 0.25

    for xOffset in [-margin, margin] {
      let start = position + [xOffset, crouchedTop]
      let end = position + [xOffset, standingTop]
      if spaceState.raycast(from: start, to: end, mask: 1, excluding: body) != nil {
        return false
      }
    }
    return true
  }

  // MARK: - Movement

  /// Main physics update loop - call from View's onProcess
  /// - Parameters:
  ///   - body: Player's CharacterBody2D
  ///   - gravity: World gravity value
  ///   - collisionSize: Player collision box size
  ///   - levelWidth: Level width for bounds clamping
  ///   - delta: Frame delta time
  func update(
    body: CharacterBody2D,
    gravity: Float,
    collisionSize: Vector2,
    levelWidth: Float,
    delta: Double
  ) {
    isOnWall = body.isOnWall()

    // Compute velocity
    let canStandUp = self.canStandUp(body: body, collisionSize: collisionSize)
    let vel = computeMovement(body: body, gravity: gravity, canStandUp: canStandUp, delta: delta)

    // Handle discrete inputs
    handleInput(body: body, collisionSize: collisionSize)

    // Apply physics
    let fallingVelocity = vel.y
    body.velocity = vel
    body.moveAndSlide()

    // Post-physics updates
    applyPhysicsResult(
      body: body,
      fallingVelocity: fallingVelocity,
      levelWidth: levelWidth,
      collisionHalfWidth: collisionSize.x / 2,
      delta: delta
    )
  }

  /// Compute player velocity based on input and physics state
  /// - Parameters:
  ///   - body: Player's CharacterBody2D
  ///   - gravity: World gravity value
  ///   - canStandUp: Whether there's room to stand from crouch
  ///   - delta: Frame delta time
  /// - Returns: Computed velocity vector
  func computeMovement(
    body: CharacterBody2D,
    gravity: Float,
    canStandUp: Bool,
    delta: Double
  ) -> Vector2 {
    let onFloor = body.isOnFloor()
    let onWall = body.isOnWall()

    // Dash overrides normal movement (disabled in water)
    if action == .dashing, !isInWater {
      return dashDirection * config.movement.dashSpeed
    }

    if isInWater {
      return computeWaterMovement(gravity: gravity, delta: delta)
    }

    var vel = velocity

    // Apply gravity (reduced on walls for wall slide)
    if onWall, vel.y > 0 {
      vel.y += gravity * Float(delta) * 0.3
    } else {
      vel.y += gravity * Float(delta)
    }

    // Crouching
    let isCrouching = overlay.contains(.crouching)
    let wantsToCrouch = Action("move_down").isPressed
    if wantsToCrouch, onFloor {
      overlay.insert(.crouching)
    } else if !wantsToCrouch, isCrouching, canStandUp {
      overlay.remove(.crouching)
    }

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
    let speed = overlay.contains(.crouching)
      ? config.movement.speed * config.movement.crouchSpeedMultiplier
      : config.movement.speed
    vel.x = input * speed

    // Dash input
    if Action("dash").isJustPressed, dashCooldownTimer <= 0 {
      action = .dashing
      dashTimer = config.movement.dashDuration
      dashCooldownTimer = config.movement.dashCooldown
      dashDirection = [facing.sign, 0]
    }

    // Jump
    vel = computeJump(body: body, vel: vel, isCrouching: overlay.contains(.crouching), input: input)

    return vel
  }

  /// Compute velocity while swimming in water (reduced gravity, swim controls)
  /// - Parameters:
  ///   - gravity: World gravity value
  ///   - delta: Frame delta time
  /// - Returns: Computed velocity vector for water movement
  func computeWaterMovement(gravity: Float, delta: Double) -> Vector2 {
    var vel = velocity
    action = .swimming

    vel.y += gravity * Float(delta) * config.water.gravityMultiplier
    if vel.y > config.water.maxFallSpeed {
      vel.y = config.water.maxFallSpeed
    }

    if Action("jump").isPressed {
      vel.y = -config.water.swimSpeed
    }
    if Action("move_down").isPressed {
      vel.y = min(vel.y + gravity * Float(delta), config.water.maxFallSpeed * 2)
    }

    var input: Float = 0
    if Action("move_left").isPressed {
      input -= 1
      facing = .left
    }
    if Action("move_right").isPressed {
      input += 1
      facing = .right
    }
    vel.x = input * config.movement.speed * config.water.moveSpeedMultiplier

    hasDoubleJump = true
    overlay.remove(.crouching)

    return vel
  }

  /// Handle jump mechanics (ground jump, wall jump, double jump, variable height)
  /// - Parameters:
  ///   - body: Player's CharacterBody2D
  ///   - vel: Current velocity to modify
  ///   - isCrouching: Whether player is crouching (blocks jumping)
  ///   - input: Horizontal input (-1, 0, or 1)
  /// - Returns: Modified velocity with jump applied
  func computeJump(body: CharacterBody2D, vel: Vector2, isCrouching: Bool, input: Float) -> Vector2 {
    var vel = vel
    let onFloor = body.isOnFloor()
    let onWall = body.isOnWall()

    // Jump buffering (skip if in doorway to allow door entry)
    if Action("jump").isJustPressed, currentDoorTargetRef == nil {
      jumpBufferTimer = config.movement.jumpBufferTime
    }

    let canJump = !isCrouching && (onFloor || coyoteTimer > 0 || onWall || hasDoubleJump)

    if jumpBufferTimer > 0, canJump {
      if onWall {
        vel.y = -config.movement.wallJumpVerticalSpeed
        vel.x = body.getWallNormal().x * config.movement.wallJumpSpeed
        facing = vel.x > 0 ? .right : .left
      } else if hasDoubleJump, !onFloor {
        vel.y = -config.movement.jumpSpeed
        hasDoubleJump = false
      } else {
        vel.y = -config.movement.jumpSpeed
      }
      action = .jumping
      jumpBufferTimer = 0
      coyoteTimer = 0
      playerScale = [0.6, 1.4] // Jump stretch
      Chapter26.GameEvent.jumped(position: position).emit()
    }

    // Variable jump height
    if Action("jump").isJustReleased, action == .jumping, vel.y < 0 {
      vel.y = max(vel.y, -config.movement.minJumpSpeed)
    }

    // Update action state
    if action != .dashing {
      if onWall && !onFloor && vel.y > 0 {
        action = .wallSliding
      } else if !onFloor {
        action = vel.y < 0 ? .jumping : .falling
      } else if input != 0 {
        action = .walking
      } else {
        action = .idle
      }
    }

    return vel
  }

  // MARK: - Input Handling

  /// Handle discrete input actions (door entry, weapon switch, attack)
  /// - Parameters:
  ///   - body: Player's CharacterBody2D
  ///   - collisionSize: Player collision box size (for projectile positioning)
  func handleInput(body: CharacterBody2D, collisionSize: Vector2) {
    let onFloor = body.isOnFloor()

    // Door entry
    if Action("move_up").isJustPressed, let targetRef = currentDoorTargetRef, onFloor {
      if targetRef.levelIid != currentLevelIid {
        Chapter26.GameEvent.enterCrossLevelDoor(targetLevelIid: targetRef.levelIid, targetEntityIid: targetRef.entityIid).emit()
      } else {
        Chapter26.GameEvent.enterDoor(targetEntityIid: targetRef.entityIid).emit()
      }
    }

    // Weapon switching
    if Action("switch_weapon").isJustPressed {
      currentWeapon = currentWeapon == .melee ? .ranged : .melee
      Chapter26.GameEvent.weaponSwitched(weaponType: currentWeapon).emit()
    }

    // Attack
    if Action("attack").isJustPressed, attackPhase == .idle {
      if currentWeapon == .melee {
        startAttack()
      } else if consumeAmmo() {
        let xOffset: Float = facing == .right ? collisionSize.x / 2 : -collisionSize.x / 2
        let arrowHalfHeight: Float = 4
        let yOffset = -collisionSize.y / 2 - arrowHalfHeight
        let projectilePos = position + [xOffset, yOffset]
        let direction: Vector2 = [facing.sign, 0]
        Chapter26.GameEvent.projectileFired(position: projectilePos, direction: direction).emit()
      }
    }
  }

  // MARK: - Post-Physics Updates

  /// Apply results after physics step (coyote time, landing, bounds, death)
  /// - Parameters:
  ///   - body: Player's CharacterBody2D (updated by moveAndSlide)
  ///   - fallingVelocity: Velocity.y before physics (for landing impact)
  ///   - levelWidth: Level width for bounds clamping
  ///   - collisionHalfWidth: Half player width for bounds calculation
  ///   - delta: Frame delta time
  func applyPhysicsResult(
    body: CharacterBody2D,
    fallingVelocity: Float,
    levelWidth: Float,
    collisionHalfWidth: Float,
    delta: Double
  ) {
    let onFloor = body.isOnFloor()
    velocity = body.velocity
    position = body.position

    // Coyote time
    if onFloor {
      coyoteTimer = config.movement.coyoteTime
      hasDoubleJump = true
      if action == .jumping || action == .falling {
        action = .idle
      }
    } else if coyoteTimer > 0 {
      coyoteTimer -= delta
    }

    // Landing impact
    let justLanded = !wasOnFloor && onFloor && fallingVelocity > 100
    if justLanded {
      playerScale = [1.3, 0.8] // Land squash
      Chapter26.GameEvent.landed(position: position, impact: fallingVelocity).emit()
    }
    wasOnFloor = onFloor

    // Keep in bounds
    if position.x < collisionHalfWidth {
      position.x = collisionHalfWidth
      body.position = position
    } else if position.x > levelWidth - collisionHalfWidth {
      position.x = levelWidth - collisionHalfWidth
      body.position = position
    }

    // Fall off screen = die
    let viewportHeight = body.getViewportRect().size.y
    if position.y > viewportHeight + 100 {
      takeDamage(playerHealth, collisionHeight: collisionHalfWidth * 2)
    }
  }
}
