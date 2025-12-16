import Foundation
import SwiftGodot

// MARK: - Facing Direction

/// Facing direction for actors
public enum Facing: Sendable {
  case left
  case right

  public var sign: Float {
    switch self {
    case .left: -1
    case .right: 1
    }
  }

  public var isRight: Bool { self == .right }
  public var isLeft: Bool { self == .left }
}

// MARK: - Actor Configuration

/// Configuration for actor animations - maps actions to animation names
public struct ActorAnimations: Sendable {
  /// Animation to play for all movement states (single-animation actors)
  /// If set, overrides all other animations
  public let all: String?

  /// Animation to play when idle
  public let idle: String

  /// Animation to play when walking/moving
  public let walk: String

  /// Animation to play when jumping/falling
  public let jump: String

  /// Animation to play when attacking (optional)
  public let attack: String?

  /// Animation to play when hit/hurt (optional)
  public let hit: String?

  /// Animation to play when dying (optional)
  public let death: String?

  /// Animation to play when wall sliding (optional - falls back to jump)
  public let wallSlide: String?

  /// Animation to play when crouching (optional - falls back to idle)
  public let crouch: String?

  /// Animation to play when swimming (optional - falls back to idle)
  public let swim: String?

  /// Whether to prefix animation names with weapon layer (e.g., "Sword_Idle")
  public let useWeaponPrefix: Bool

  /// Default layer when no weapon equipped (used when useWeaponPrefix is true)
  public let defaultLayer: String

  public init(
    all: String? = nil,
    idle: String,
    walk: String,
    jump: String,
    attack: String? = nil,
    hit: String? = nil,
    death: String? = nil,
    wallSlide: String? = nil,
    crouch: String? = nil,
    swim: String? = nil,
    useWeaponPrefix: Bool = false,
    defaultLayer: String = ""
  ) {
    self.all = all
    self.idle = idle
    self.walk = walk
    self.jump = jump
    self.attack = attack
    self.hit = hit
    self.death = death
    self.wallSlide = wallSlide
    self.crouch = crouch
    self.swim = swim
    self.useWeaponPrefix = useWeaponPrefix
    self.defaultLayer = defaultLayer
  }

  // MARK: - Convenience Initializers

  /// Create animations for single-animation actors (like Ember)
  public static func single(_ animation: String) -> ActorAnimations {
    ActorAnimations(
      all: animation,
      idle: animation,
      walk: animation,
      jump: animation,
      attack: animation,
      hit: animation,
      death: animation,
      wallSlide: animation,
      crouch: animation,
      swim: animation,
      useWeaponPrefix: false,
      defaultLayer: ""
    )
  }

  /// Create animations for per-action actors (like Skeleton)
  public static func perAction(
    idle: String,
    walk: String,
    jump: String? = nil,
    attack: String? = nil,
    hit: String? = nil,
    death: String? = nil
  ) -> ActorAnimations {
    ActorAnimations(
      all: nil,
      idle: idle,
      walk: walk,
      jump: jump ?? idle,
      attack: attack,
      hit: hit,
      death: death,
      wallSlide: nil,
      crouch: nil,
      swim: nil,
      useWeaponPrefix: false,
      defaultLayer: ""
    )
  }

  /// Create animations for weapon-layered actors (like Hero)
  public static func withWeaponPrefix(
    defaultLayer: String,
    idle: String = "Idle",
    walk: String = "Walk",
    jump: String = "Jump",
    attack: String = "Attack",
    hit: String = "Hit",
    death: String = "Death",
    wallSlide: String = "WallSlide",
    crouch: String = "Crouch"
  ) -> ActorAnimations {
    ActorAnimations(
      all: nil,
      idle: idle,
      walk: walk,
      jump: jump,
      attack: attack,
      hit: hit,
      death: death,
      wallSlide: wallSlide,
      crouch: crouch,
      swim: nil,
      useWeaponPrefix: true,
      defaultLayer: defaultLayer
    )
  }

  // MARK: - Animation Resolution

  /// Resolve the animation name for current state
  public func animation(
    action: ActorAction,
    isAttacking: Bool,
    isDying: Bool,
    isHit: Bool,
    isCrouching: Bool,
    weaponLayer: String?
  ) -> String {
    // Single animation mode - always return the same animation
    if let all {
      return all
    }

    // Determine base animation from state
    let baseAnim: String
    if isDying {
      baseAnim = death ?? idle
    } else if isHit, let hitAnim = hit {
      baseAnim = hitAnim
    } else if isAttacking {
      baseAnim = attack ?? idle
    } else if isCrouching {
      baseAnim = crouch ?? idle
    } else {
      switch action {
      case .idle: baseAnim = idle
      case .walking: baseAnim = walk
      case .jumping, .falling: baseAnim = jump
      case .wallSliding: baseAnim = wallSlide ?? jump
      case .dashing: baseAnim = walk
      case .swimming: baseAnim = swim ?? idle
      }
    }

    // Apply weapon prefix if enabled
    if useWeaponPrefix {
      let layer = weaponLayer ?? defaultLayer
      return "\(layer)_\(baseAnim)"
    }
    return baseAnim
  }
}

/// Configuration for an actor's physical properties
public struct ActorPhysics: Sendable {
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

  // MARK: - Presets

  /// Stationary NPC - no movement, uses world gravity
  public static var npc: ActorPhysics {
    ActorPhysics(speed: 0, gravity: nil, knockbackStrength: 0)
  }

  /// Flying enemy - moves but no gravity
  public static func flying(speed: Float = 40) -> ActorPhysics {
    ActorPhysics(speed: speed, gravity: 0, knockbackStrength: 150)
  }

  /// Grounded actor - uses world gravity (nil)
  public static func grounded(speed: Float = 60) -> ActorPhysics {
    ActorPhysics(speed: speed, gravity: nil, knockbackStrength: 80)
  }
}

/// Configuration for an actor's combat properties
public struct ActorCombat: Sendable {
  public var maxHealth: Int
  public var touchDamage: Int
  public var invincibilityDuration: Double
  public var canDealTouchDamage: Bool
  public var canReceiveDamage: Bool

  // Phase system (optional) - thresholds are health percentages in descending order
  // e.g., [0.66, 0.33] = phase 1 at 100-67%, phase 2 at 66-34%, phase 3 at 33-0%
  public var phaseThresholds: [Float]?
  public var stunOnPhaseChange: Bool
  public var phaseStunDuration: Double

  public init(
    maxHealth: Int = 3,
    touchDamage: Int = 1,
    invincibilityDuration: Double = 1.0,
    canDealTouchDamage: Bool = true,
    canReceiveDamage: Bool = true,
    phaseThresholds: [Float]? = nil,
    stunOnPhaseChange: Bool = true,
    phaseStunDuration: Double = 1.0
  ) {
    self.maxHealth = maxHealth
    self.touchDamage = touchDamage
    self.invincibilityDuration = invincibilityDuration
    self.canDealTouchDamage = canDealTouchDamage
    self.canReceiveDamage = canReceiveDamage
    self.phaseThresholds = phaseThresholds
    self.stunOnPhaseChange = stunOnPhaseChange
    self.phaseStunDuration = phaseStunDuration
  }

  /// Calculate phase from health percentage (1-based)
  public func phase(forHealthPercent percent: Float) -> Int {
    guard let thresholds = phaseThresholds else { return 1 }
    for (index, threshold) in thresholds.enumerated() {
      if percent > threshold {
        return index + 1
      }
    }
    return thresholds.count + 1
  }
}

/// Configuration for collision shape size adjustments
/// Adjustments are added to base collisionSize (negative shrinks, positive grows)
public struct ActorCollisionConfig: Sendable {
  public var terrain: Vector2
  public var hurtbox: Vector2
  public var touchDamage: Vector2
  public var zone: Vector2
  public var collector: Vector2
  public var interaction: Vector2

  public init(
    terrain: Vector2 = .zero,
    hurtbox: Vector2 = .zero,
    touchDamage: Vector2 = .zero,
    zone: Vector2 = .zero,
    collector: Vector2 = [8, 8],
    interaction: Vector2 = [8, 8]
  ) {
    self.terrain = terrain
    self.hurtbox = hurtbox
    self.touchDamage = touchDamage
    self.zone = zone
    self.collector = collector
    self.interaction = interaction
  }

  /// Compute final size for a collision type
  public func size(for base: Vector2, type: CollisionType) -> Vector2 {
    let adjustment: Vector2
    switch type {
    case .terrain: adjustment = terrain
    case .hurtbox: adjustment = hurtbox
    case .touchDamage: adjustment = touchDamage
    case .zone: adjustment = zone
    case .collector: adjustment = collector
    case .interaction: adjustment = interaction
    }
    return base + adjustment
  }

  public enum CollisionType: Sendable {
    case terrain
    case hurtbox
    case touchDamage
    case zone
    case collector
    case interaction
  }
}

/// Configuration for what an actor can interact with
public struct ActorCapabilities: OptionSet, Sendable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  // Basic
  public static let canMove = ActorCapabilities(rawValue: 1 << 0)
  public static let canJump = ActorCapabilities(rawValue: 1 << 1)
  public static let canAttack = ActorCapabilities(rawValue: 1 << 2)

  // Advanced movement
  public static let canDash = ActorCapabilities(rawValue: 1 << 3)
  public static let canWallJump = ActorCapabilities(rawValue: 1 << 4)
  public static let canDoubleJump = ActorCapabilities(rawValue: 1 << 5)
  public static let canCrouch = ActorCapabilities(rawValue: 1 << 6)
  public static let canSwim = ActorCapabilities(rawValue: 1 << 7)

  // Interactions
  public static let canCollectItems = ActorCapabilities(rawValue: 1 << 8)
  public static let canUseDoors = ActorCapabilities(rawValue: 1 << 9)
  public static let affectedByZones = ActorCapabilities(rawValue: 1 << 10)
  public static let canInteract = ActorCapabilities(rawValue: 1 << 11)
  public static let canBeInteracted = ActorCapabilities(rawValue: 1 << 13)

  // Presets
  public static let player: ActorCapabilities = [
    .canMove, .canJump, .canAttack, .canDash, .canWallJump, .canDoubleJump, .canCrouch, .canSwim,
    .canCollectItems, .canUseDoors, .affectedByZones, .canInteract,
  ]
  public static let enemy: ActorCapabilities = [.canMove, .affectedByZones]
  public static let npc: ActorCapabilities = [.canBeInteracted]
}

/// Movement action state
public enum ActorAction: Sendable {
  case idle
  case walking
  case jumping
  case falling
  case wallSliding
  case dashing
  case swimming
}
