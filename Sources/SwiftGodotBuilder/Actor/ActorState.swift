import Foundation
import SwiftGodot

// MARK: - Actor Events

/// Events that actors emit
public enum ActorEvent: EmittableEvent {
  // Lifecycle
  case spawned(actorId: Int)
  case died(actorId: Int, position: Vector2)
  case reset(actorId: Int)

  // Combat
  case tookDamage(actorId: Int, damage: Int, position: Vector2)
  case dealtDamage(actorId: Int, targetId: Int, damage: Int, position: Vector2, direction: Vector2)
  case meleeAttacked(actorId: Int, position: Vector2, facing: Facing)
  case meleeHit(actorId: Int, targetId: Int, position: Vector2, damage: Int, knockback: Float, direction: Vector2)
  case phaseChanged(actorId: Int, phase: Int)

  // Projectiles
  case projectileFired(actorId: Int, position: Vector2, direction: Vector2, config: ActorRangedConfig)
  case projectileHitWall(actorId: Int, position: Vector2)
  case projectileHitTarget(actorId: Int, targetId: Int, position: Vector2, damage: Int, direction: Vector2)

  // Movement
  case jumped(actorId: Int, position: Vector2)
  case landed(actorId: Int, position: Vector2, impact: Float)

  // Interactions
  case collected(actorId: Int, itemId: String, position: Vector2)
  case enteredDoor(actorId: Int, targetLevelIid: String, targetEntityIid: String)
  case enteredZone(bodyInstanceId: Int, zone: String)
  case exitedZone(bodyInstanceId: Int, zone: String)

  // Actor-to-Actor interaction
  case interactorEntered(actorId: Int, interactorId: Int)
  case interactorExited(actorId: Int, interactorId: Int)
  case interacted(actorId: Int, interactorId: Int)
}

// MARK: - Actor State

/// Observable state for any actor
@Observable
public class ActorState {
  // Identity
  public let id: Int
  public let entity: LDEntity?
  public var bodyInstanceId: Int = 0 // Set when body is ready

  // Physics - basic
  public var position: Vector2
  public var pendingTeleport = false
  public var velocity: Vector2 = .zero
  public var facing: Facing = .right
  public var action: ActorAction = .idle
  public var isOnFloor = false
  public var isOnWall = false
  public var wasOnFloor = false
  public var knockbackVelocity: Vector2 = .zero
  public var knockbackTimer: Double = 0

  // Physics - jump
  public var coyoteTimer: Double = 0
  public var jumpBufferTimer: Double = 0
  public var hasDoubleJump = true

  // Physics - dash
  public var dashTimer: Double = 0
  public var dashCooldownTimer: Double = 0
  public var dashDirection: Vector2 = .zero

  // Physics - environment
  public var isInWater = false
  public var isCrouching = false

  // Behavior-driven input (set by behaviors, read by physics)
  public var movementInput: Float = 0
  public var wantsJump = false

  // Combat
  public var health: Int
  public var maxHealth: Int
  public var isDying = false
  public var isInvincible = false
  public var invincibilityTimer: Double = 0
  public var isHit = false
  public var hitTimer: Double = 0

  // Stun (boss mechanic)
  public var isStunned = false
  public var stunTimer: Double = 0

  // Phase system (for bosses/multi-phase enemies)
  // Phase changes emit ActorEvent.phaseChanged
  public var phase: Int = 1

  // Inventory
  public var inventory: [String] = [] // Item IDs

  // Interaction (for NPCs and other interactables)
  public var npcTypeId: String? // If set, this actor can provide dialog
  public var displayName: String? // Name shown when in interaction range
  public var interactorsInRange: Set<Int> = [] // Actor IDs currently in range

  // Visual
  public var animationName = ""
  public var sprite: AseSprite?
  public var scale: Vector2 = .one
  public var rotation: Float = 0

  // Config
  public let physics: ActorPhysics
  public let combat: ActorCombat
  public let capabilities: ActorCapabilities
  public let animations: ActorAnimations
  public let spriteAsset: String
  public let collisionSize: Vector2
  public let collisionConfig: ActorCollisionConfig
  public let pivot: Vector2
  public var spawnPosition: Vector2

  /// Offset for centered collision shapes (RectangleShape2D is centered by default)
  public var collisionOffset: Vector2 {
    Vector2(
      x: (0.5 - pivot.x) * collisionSize.x,
      y: (0.5 - pivot.y) * collisionSize.y
    )
  }

  /// Offset for non-centered sprite (draws from top-left)
  public var spriteOffset: Vector2 {
    Vector2(
      x: -pivot.x * collisionSize.x,
      y: -pivot.y * collisionSize.y
    )
  }

  public init(
    entity: LDEntity,
    spriteAsset: String,
    animations: ActorAnimations,
    physics: ActorPhysics = ActorPhysics(),
    combat: ActorCombat = ActorCombat(),
    capabilities: ActorCapabilities = .enemy,
    collisionConfig: ActorCollisionConfig = ActorCollisionConfig(),
    startingItems: [String] = [],
    npcTypeId: String? = nil,
    displayName: String? = nil
  ) {
    id = Int.random(in: 1 ... Int.max)
    self.entity = entity
    position = entity.positionPivot
    spawnPosition = entity.positionPivot
    self.spriteAsset = spriteAsset
    self.animations = animations
    // Compute initial animation
    animationName = animations.animation(
      action: .idle,
      isAttacking: false,
      isDying: false,
      isHit: false,
      isCrouching: false,
      weaponLayer: nil
    )
    self.physics = physics
    self.combat = combat
    self.capabilities = capabilities
    self.collisionConfig = collisionConfig
    health = combat.maxHealth
    maxHealth = combat.maxHealth
    collisionSize = entity.size
    pivot = entity.pivotVector
    inventory = startingItems
    self.npcTypeId = npcTypeId
    self.displayName = displayName
  }

  /// Alternative init for spawner-created actors (no LDEntity)
  public init(
    spawnPosition: Vector2,
    size: Vector2,
    spriteAsset: String,
    animations: ActorAnimations,
    physics: ActorPhysics = ActorPhysics(),
    combat: ActorCombat = ActorCombat(),
    capabilities: ActorCapabilities = .enemy,
    collisionConfig: ActorCollisionConfig = ActorCollisionConfig(),
    startingItems: [String] = []
  ) {
    id = Int.random(in: 1 ... Int.max)
    entity = nil
    position = spawnPosition
    self.spawnPosition = spawnPosition
    self.spriteAsset = spriteAsset
    self.animations = animations
    animationName = animations.animation(
      action: .idle,
      isAttacking: false,
      isDying: false,
      isHit: false,
      isCrouching: false,
      weaponLayer: nil
    )
    self.physics = physics
    self.combat = combat
    self.capabilities = capabilities
    self.collisionConfig = collisionConfig
    health = combat.maxHealth
    maxHealth = combat.maxHealth
    collisionSize = size
    pivot = [0.5, 1.0] // Default to bottom-center
    inventory = startingItems
    npcTypeId = nil
    displayName = nil
  }

  // MARK: - Inventory

  /// Add an item to inventory
  public func addItem(_ itemId: String) {
    if !inventory.contains(itemId) {
      inventory.append(itemId)
      ActorEvent.collected(actorId: id, itemId: itemId, position: position).emit()
    }
  }

  /// Remove an item from inventory
  public func removeItem(_ itemId: String) {
    if let index = inventory.firstIndex(of: itemId) {
      inventory.remove(at: index)
    }
  }

  /// Check if actor has a specific item
  public func hasItem(_ itemId: String) -> Bool {
    inventory.contains(itemId)
  }

  /// Count of a specific item type
  public func itemCount(_ itemId: String) -> Int {
    inventory.filter { $0 == itemId }.count
  }

  // MARK: - Combat

  public func takeDamage(
    _ amount: Int,
    from sourcePosition: Vector2,
    knockback: Float? = nil,
    direction attackDirection: Vector2? = nil
  ) {
    guard !isDying, !isInvincible, combat.canReceiveDamage else { return }

    health -= amount
    isInvincible = true
    invincibilityTimer = combat.invincibilityDuration

    if health <= 0 {
      isDying = true
      ActorEvent.died(actorId: id, position: position).emit()
    } else {
      ActorEvent.tookDamage(actorId: id, damage: amount, position: position).emit()
      checkPhaseChange()
    }

    // Apply knockback (use provided value or fall back to actor's physics config)
    let knockbackStrength = knockback ?? physics.knockbackStrength
    let horizontalDir: Float
    if let attackDirection, abs(attackDirection.x) > 0.01 {
      horizontalDir = attackDirection.x
    } else {
      horizontalDir = position.x - sourcePosition.x
    }
    let knockbackDir: Float = horizontalDir >= 0 ? 1 : -1
    knockbackVelocity = [knockbackDir * knockbackStrength, 0]
    knockbackTimer = physics.knockbackRecoveryTime
    velocity.x = knockbackVelocity.x
  }

  /// Check if health crossed a phase threshold
  private func checkPhaseChange() {
    guard combat.phaseThresholds != nil else { return }

    let healthPercent = Float(health) / Float(maxHealth)
    let newPhase = combat.phase(forHealthPercent: healthPercent)

    if newPhase != phase {
      phase = newPhase

      if combat.stunOnPhaseChange {
        stun(combat.phaseStunDuration)
      }

      ActorEvent.phaseChanged(actorId: id, phase: newPhase).emit()
    }
  }

  public func heal(_ amount: Int) {
    health = min(health + amount, maxHealth)
  }

  public func stun(_ duration: Double) {
    isStunned = true
    stunTimer = duration
  }

  // MARK: - Timers

  public func updateTimers(_ delta: Double) {
    // Invincibility
    if invincibilityTimer > 0 {
      invincibilityTimer -= delta
      if invincibilityTimer <= 0 {
        isInvincible = false
      }
    }

    // Hit animation (brief)
    if hitTimer > 0 {
      hitTimer -= delta
      if hitTimer <= 0 {
        isHit = false
      }
    }

    // Knockback decay
    if knockbackTimer > 0 {
      knockbackTimer -= delta
      knockbackVelocity = knockbackVelocity.lerp(to: .zero, weight: Float(10.0 * delta))
      if knockbackTimer <= 0 {
        knockbackVelocity = .zero
        knockbackTimer = 0
      }
    }

    // Dash
    if dashTimer > 0 {
      dashTimer -= delta
      if dashTimer <= 0 {
        action = .idle
      }
    }
    if dashCooldownTimer > 0 {
      dashCooldownTimer -= delta
    }

    // Jump buffer
    if jumpBufferTimer > 0 {
      jumpBufferTimer -= delta
    }

    // Stun
    if stunTimer > 0 {
      stunTimer -= delta
      if stunTimer <= 0 {
        isStunned = false
      }
    }
  }

  // MARK: - Visual feedback

  public func updateVisuals(_ delta: Double) {
    scale = scale.lerp(to: .one, weight: Float(delta) * 10)
    rotation = rotation * (1 - Float(delta) * 10)
  }

  public func applyJumpSquash() {
    scale = [0.6, 1.4]
  }

  public func applyLandSquash() {
    scale = [1.3, 0.8]
  }

  // MARK: - Movement

  public func teleportTo(_ newPosition: Vector2) {
    position = newPosition
    pendingTeleport = true
    velocity = .zero
    coyoteTimer = 0
    jumpBufferTimer = 0
    action = .idle
  }

  // MARK: - Reset

  /// Reset state without emitting event (called when handling ActorEvent.reset)
  public func resetState() {
    position = spawnPosition
    pendingTeleport = true
    velocity = .zero
    facing = .right
    action = .idle
    isOnFloor = false
    isOnWall = false
    wasOnFloor = false
    coyoteTimer = 0
    jumpBufferTimer = 0
    hasDoubleJump = true
    dashTimer = 0
    dashCooldownTimer = 0
    isInWater = false
    isCrouching = false
    movementInput = 0
    wantsJump = false
    health = combat.maxHealth
    isDying = false
    isInvincible = false
    invincibilityTimer = 0
    isHit = false
    hitTimer = 0
    knockbackVelocity = .zero
    knockbackTimer = 0
    isStunned = false
    stunTimer = 0
    phase = 1
    scale = .one
    rotation = 0
  }

  /// Reset and emit event (for initiating a reset)
  public func reset() {
    resetState()
    ActorEvent.reset(actorId: id).emit()
  }
}
