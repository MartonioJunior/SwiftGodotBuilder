import Foundation
import SwiftGodot

/// Physics capability state for actors with movement physics
@Observable
public class ActorPhysicsState {
  // MARK: - Config

  public let config: ActorPhysicsConfig

  // MARK: - Floor/Wall Detection

  public var isOnFloor = false
  public var wasOnFloor = false
  public var isOnWall = false
  public var isInWater = false
  public var isCrouching = false

  // MARK: - Knockback

  public var knockbackVelocity: Vector2 = .zero
  public var knockbackTimer: Double = 0

  // MARK: - Jump

  public var coyoteTimer: Double = 0
  public var jumpBufferTimer: Double = 0
  public var hasDoubleJump = true

  // MARK: - Dash

  public var dashTimer: Double = 0
  public var dashCooldownTimer: Double = 0
  public var dashDirection: Vector2 = .zero

  // MARK: - Input State

  public var inputDirection: Float = 0
  public var jumpRequested = false
  public var jumpHeld = false
  public var dashRequested = false
  public var crouchHeld = false

  // MARK: - Initialization

  public init(config: ActorPhysicsConfig) {
    self.config = config
  }

  // MARK: - Timer Updates

  public func updateTimers(_ delta: Double) {
    // Knockback decay
    if knockbackTimer > 0 {
      knockbackTimer -= delta
      knockbackVelocity = knockbackVelocity.lerp(to: .zero, weight: Float(10.0 * delta))
      if knockbackTimer <= 0 {
        knockbackVelocity = .zero
      }
    }

    // Coyote time
    if coyoteTimer > 0 {
      coyoteTimer -= delta
    }

    // Jump buffer
    if jumpBufferTimer > 0 {
      jumpBufferTimer -= delta
      if jumpBufferTimer <= 0 {
        jumpRequested = false
      }
    }

    // Dash timer
    if dashTimer > 0 {
      dashTimer -= delta
    }

    // Dash cooldown
    if dashCooldownTimer > 0 {
      dashCooldownTimer -= delta
    }
  }

  // MARK: - Physics Processing

  public func process(body: CharacterBody2D, delta: Double, coreState: ActorState) {
    updateWallDetection(body: body)
    updateCoyoteTime()
    processJumpBuffer()

    // Dash overrides normal movement
    if processDash(body: body, coreState: coreState) {
      return
    }

    applyGravity(body: body, delta: delta)
    processJump(body: body, coreState: coreState)
    applyVariableJumpHeight(body: body)
    applyHorizontalMovement(body: body)
    applyKnockback(body: body)

    let preMoveVelocityY = body.velocity.y
    moveAndSlide(body: body)
    updateFloorState(body: body, coreState: coreState, preMoveVelocityY: preMoveVelocityY)
    updateActionState(body: body, coreState: coreState)
    updateFacing(coreState: coreState)
  }

  // MARK: - Wall Detection

  private func updateWallDetection(body: CharacterBody2D) {
    isOnWall = body.isOnWall()
  }

  // MARK: - Coyote Time

  private func updateCoyoteTime() {
    if wasOnFloor, !isOnFloor {
      coyoteTimer = config.coyoteTime
    }
  }

  // MARK: - Jump Buffer

  private func processJumpBuffer() {
    if jumpRequested {
      jumpBufferTimer = config.jumpBufferTime
      jumpRequested = false
    }
  }

  // MARK: - Dash

  /// Returns true if dash is active (caller should skip normal movement)
  private func processDash(body: CharacterBody2D, coreState: ActorState) -> Bool {
    // Active dash
    if dashTimer > 0 {
      body.velocity = dashDirection * config.dashSpeed
      body.velocity = body.velocity
      body.moveAndSlide()
      coreState.moveStatus = .dashing
      return true
    }

    // Start new dash
    if dashRequested, dashCooldownTimer <= 0 {
      dashTimer = config.dashDuration
      dashCooldownTimer = config.dashCooldown
      dashDirection = Vector2(x: coreState.facing.sign, y: 0)
      dashRequested = false
      ActorEvent.dashed(actorId: coreState.id, position: body.position, direction: dashDirection).emit()
      return true
    }

    dashRequested = false
    return false
  }

  // MARK: - Gravity

  private func applyGravity(body: CharacterBody2D, delta: Double) {
    let gravity = config.gravity ?? 0
    guard gravity != 0 else { return }

    let isWallSliding = isOnWall && body.velocity.y > 0
    let gravityMult: Float = isWallSliding ? config.wallSlideGravityMultiplier : 1.0
    body.velocity.y += gravity * gravityMult * Float(delta)
  }

  // MARK: - Jump

  private func processJump(body: CharacterBody2D, coreState: ActorState) {
    guard jumpBufferTimer > 0 else { return }

    // Ground jump (with coyote time)
    let canGroundJump = isOnFloor || coyoteTimer > 0
    if canGroundJump {
      body.velocity.y = -config.jumpSpeed
      coyoteTimer = 0
      jumpBufferTimer = 0
      ActorEvent.jumped(actorId: coreState.id, position: body.position).emit()
      return
    }

    // Wall jump
    if isOnWall {
      let wallNormal = coreState.node?.getWallNormal() ?? Vector2.zero
      body.velocity.x = wallNormal.x * config.wallJumpSpeed
      body.velocity.y = -config.wallJumpVerticalSpeed
      jumpBufferTimer = 0
      ActorEvent.jumped(actorId: coreState.id, position: body.position).emit()
      return
    }

    // Double jump
    if !isOnFloor, hasDoubleJump {
      body.velocity.y = -config.jumpSpeed
      hasDoubleJump = false
      jumpBufferTimer = 0
      ActorEvent.jumped(actorId: coreState.id, position: body.position).emit()
    }
  }

  // MARK: - Variable Jump Height

  private func applyVariableJumpHeight(body: CharacterBody2D) {
    if !jumpHeld, body.velocity.y < -config.minJumpSpeed {
      body.velocity.y = -config.minJumpSpeed
    }
  }

  // MARK: - Horizontal Movement

  private func applyHorizontalMovement(body: CharacterBody2D) {
    let speed = isCrouching ? config.speed * config.crouchSpeedMultiplier : config.speed
    body.velocity.x = inputDirection * speed
  }

  // MARK: - Knockback

  private func applyKnockback(body: CharacterBody2D) {
    if knockbackTimer > 0 {
      body.velocity += knockbackVelocity
    }
  }

  // MARK: - Move and Slide

  private func moveAndSlide(body: CharacterBody2D) {
    body.velocity = body.velocity
    body.moveAndSlide()
    // Sync velocity back - moveAndSlide modifies it based on collisions
    body.velocity = body.velocity
  }

  // MARK: - Floor State

  private func updateFloorState(body: CharacterBody2D, coreState: ActorState, preMoveVelocityY: Float) {
    wasOnFloor = isOnFloor
    isOnFloor = body.isOnFloor()

    // Reset double jump and emit landed event
    if isOnFloor, !wasOnFloor {
      hasDoubleJump = true
      // Use pre-move velocity since moveAndSlide zeroes it on landing
      let impact = abs(preMoveVelocityY)
      if impact > 50 {
        ActorEvent.landed(actorId: coreState.id, position: body.position, impact: impact).emit()
      }
    }
  }

  // MARK: - Action State

  private func updateActionState(body: CharacterBody2D, coreState: ActorState) {
    let prevAction = coreState.moveStatus

    if isOnWall, !isOnFloor, body.velocity.y > 0 {
      coreState.moveStatus = .wallSliding
      if prevAction != .wallSliding {
        ActorEvent.wallSlideStarted(actorId: coreState.id, position: body.position).emit()
      }
    } else if !isOnFloor {
      coreState.moveStatus = body.velocity.y < 0 ? .jumping : .falling
    } else if abs(body.velocity.x) > 1 {
      coreState.moveStatus = .walking
    } else {
      coreState.moveStatus = .idle
    }
  }

  // MARK: - Facing

  private func updateFacing(coreState: ActorState) {
    if inputDirection > 0.1 {
      coreState.facing = .right
    } else if inputDirection < -0.1 {
      coreState.facing = .left
    }
  }
}
