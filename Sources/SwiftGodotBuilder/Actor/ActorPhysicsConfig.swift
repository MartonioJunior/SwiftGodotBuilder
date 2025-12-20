import SwiftGodot

/// Configuration for an actor's physical properties
public struct ActorPhysicsConfig: Sendable {
  // Basic movement
  public var speed: Float
  public var gravity: Float? // nil = use world gravity, 0 = no gravity (flying/NPC)
  public var knockbackStrength: Float
  public var knockbackRecoveryTime: Double

  // Jump
  public var jumpSpeed: Float
  public var minJumpSpeed: Float // For variable jump height
  public var coyoteTime: Double
  public var jumpBufferTime: Double

  // Wall movement
  public var wallSlideGravityMultiplier: Float
  public var wallJumpSpeed: Float
  public var wallJumpVerticalSpeed: Float

  // Dash
  public var dashSpeed: Float
  public var dashDuration: Double
  public var dashCooldown: Double

  // Crouch
  public var crouchSpeedMultiplier: Float

  // Swimming
  public var swimSpeed: Float
  public var waterGravityMultiplier: Float
  public var waterMaxFallSpeed: Float
  public var waterMoveSpeedMultiplier: Float

  public init(
    speed: Float = 60,
    gravity: Float? = nil,
    knockbackStrength: Float = 80,
    knockbackRecoveryTime: Double = 0.15,
    jumpSpeed: Float = 130,
    minJumpSpeed: Float = 60,
    coyoteTime: Double = 0.1,
    jumpBufferTime: Double = 0.1,
    wallSlideGravityMultiplier: Float = 0.3,
    wallJumpSpeed: Float = 80,
    wallJumpVerticalSpeed: Float = 130,
    dashSpeed: Float = 200,
    dashDuration: Double = 0.15,
    dashCooldown: Double = 0.5,
    crouchSpeedMultiplier: Float = 0.4,
    swimSpeed: Float = 80,
    waterGravityMultiplier: Float = 0.2,
    waterMaxFallSpeed: Float = 30,
    waterMoveSpeedMultiplier: Float = 0.7
  ) {
    self.speed = speed
    self.gravity = gravity
    self.knockbackStrength = knockbackStrength
    self.knockbackRecoveryTime = knockbackRecoveryTime
    self.jumpSpeed = jumpSpeed
    self.minJumpSpeed = minJumpSpeed
    self.coyoteTime = coyoteTime
    self.jumpBufferTime = jumpBufferTime
    self.wallSlideGravityMultiplier = wallSlideGravityMultiplier
    self.wallJumpSpeed = wallJumpSpeed
    self.wallJumpVerticalSpeed = wallJumpVerticalSpeed
    self.dashSpeed = dashSpeed
    self.dashDuration = dashDuration
    self.dashCooldown = dashCooldown
    self.crouchSpeedMultiplier = crouchSpeedMultiplier
    self.swimSpeed = swimSpeed
    self.waterGravityMultiplier = waterGravityMultiplier
    self.waterMaxFallSpeed = waterMaxFallSpeed
    self.waterMoveSpeedMultiplier = waterMoveSpeedMultiplier
  }
}
