import Foundation
import SwiftGodot

public class ActorState: Equatable {
  // MARK: - Properties

  /// Unique actor ID (regenerated on pool reset)
  public private(set) var id: Int

  /// Reference to the CharacterBody2D node (set after body is created)
  /// Weak to avoid retain cycles with ActorPool
  public internal(set) weak var node: CharacterBody2D?

  /// Whether this is the player (affects death handling)
  public var isPlayer = false

  /// Whether this actor is managed by an ActorPool
  public var isPooled = false

  // MARK: - Core Movement

  /// Direction actor is facing
  public var facing: Facing = .right

  /// Current move status (idle, walk, jump, fall, etc.)
  public var moveStatus: ActorMoveStatus = .idle

  // MARK: - Optional Capabilities

  /// Physics capability (movement, jumping, dashing, etc.)
  public var physics: ActorPhysicsState?

  /// Defense capability (health, invincibility, death)
  public var defense: ActorDefenseState?

  /// Weapon capability (melee/ranged weapons, attack phases)
  public var weapon: ActorWeaponState?

  /// Targeting capability (tracking targets)
  public var targeting: ActorTargetingState?

  /// Dialog capability (provides dialog when interacted)
  public var dialog: ActorDialogState?

  /// Selection capability (can be selected by player)
  public var selection: ActorSelectionState?

  /// Behavior machine for AI behaviors (type-erased)
  var behaviorMachine: AnyBehaviorMachine?

  // MARK: - Interaction Tracking

  /// Actor IDs currently in interaction range (populated via interactorEntered/Exited events)
  public var nearbyInteractorIds: [Int] = []

  /// Whether there's an interactable actor in range
  public var canInteract: Bool {
    !nearbyInteractorIds.isEmpty
  }

  // MARK: - Callbacks
  //
  // IMPORTANT: Callbacks can create retain cycles if you capture `self` strongly.
  // Always use `[weak self]` in callback closures to avoid memory leaks:
  //
  // ```swift
  // // GOOD - uses weak self
  // state.onDeath = { [weak self] actor in
  //   self?.handleDeath(actor)
  // }
  //
  // // BAD - creates retain cycle
  // state.onDeath = { actor in
  //   self.handleDeath(actor)  // 'self' captured strongly!
  // }
  // ```

  /// Called when this actor takes damage. Receives (actor, damage, knockback).
  /// If set, replaces default damage handling - call `takeDamage` manually if needed.
  ///
  /// - Warning: Use `[weak self]` to avoid retain cycles.
  public var onHurt: ((ActorState, Int, Vector2) -> Void)?

  /// Called when this actor hits a target. Receives (actor, targetId, damage).
  ///
  /// - Warning: Use `[weak self]` to avoid retain cycles.
  public var onHit: ((ActorState, Int, Int) -> Void)?

  /// Called when this actor dies.
  ///
  /// - Warning: Use `[weak self]` to avoid retain cycles.
  public var onDeath: ((ActorState) -> Void)?

  /// Called when targeting acquires a new target.
  ///
  /// - Warning: Use `[weak self]` to avoid retain cycles.
  public var onAcquiredTarget: ((ActorState, Area2D) -> Void)?

  /// Called when targeting loses all targets.
  ///
  /// - Warning: Use `[weak self]` to avoid retain cycles.
  public var onLostAllTargets: ((ActorState) -> Void)?

  /// Called before an attack starts. Receives (actor, weaponIndex). Return false to cancel.
  ///
  /// - Warning: Use `[weak self]` to avoid retain cycles.
  public var onBeforeAttack: ((ActorState, Int) -> Bool)?

  /// Called after an attack fires (for ranged) or activates (for melee).
  ///
  /// - Warning: Use `[weak self]` to avoid retain cycles.
  public var onAttack: ((ActorState, Int) -> Void)?

  // MARK: - Computed Properties

  /// Scale vector based on facing direction
  public var facingScale: Vector2 {
    facing == .left ? [-1, 1] : [1, 1]
  }

  /// Current health (0 if no defense capability)
  public var currentHealth: Int {
    defense?.health ?? 5
  }

  /// Whether actor has a target in range
  public var hasTarget: Bool {
    targeting?.closestTarget != nil
  }

  /// Distance to closest target (returns .infinity if no target)
  public var distanceToTarget: Float {
    targeting?.distanceTo(node) ?? .infinity
  }

  /// Current position (from node, or zero)
  public var position: Vector2 {
    node?.position ?? .zero
  }

  /// Whether actor is on the floor
  public var isOnFloor: Bool {
    physics?.isOnFloor ?? false
  }

  /// Whether actor is on a wall
  public var isOnWall: Bool {
    physics?.isOnWall ?? false
  }

  /// Whether actor is dying
  public var isDying: Bool {
    defense?.isDying ?? false
  }

  /// Whether actor is invincible
  public var isInvincible: Bool {
    defense?.isInvincible ?? false
  }

  /// Whether actor is currently selected
  public var isSelected: Bool {
    selection?.isSelected ?? false
  }

  // MARK: - Initialization

  public init() {
    id = Int.random(in: 1 ... Int.max)
  }

  // MARK: - Equatable

  public static func == (lhs: ActorState, rhs: ActorState) -> Bool {
    lhs === rhs
  }

  // MARK: - Internal Update Methods

  /// Update timers (called by Actor each frame)
  func updateTimers(_ delta: Double) {
    physics?.updateTimers(delta)
    defense?.updateTimers(delta)
  }

  /// Process behavior machine (called by Actor each physics frame)
  func processBehaviorMachine(_ delta: Double) {
    behaviorMachine?.process(actor: self, delta: delta)
  }

  // MARK: - Reset (for pooling)

  /// Resets state for reuse from pool. Generates a fresh ID.
  /// - Parameters:
  ///   - facing: Initial facing direction
  /// Note: behaviorMachine must be set separately after reset.
  /// Note: Callbacks are cleared separately via clearCallbacks() on pool release.
  public func reset(facing: Facing = .right) {
    // Generate fresh ID
    id = Int.random(in: 1 ... Int.max)

    // Reset core state
    self.facing = facing
    moveStatus = .idle
    nearbyInteractorIds = []

    // Reset capabilities
    physics?.reset()
    defense?.reset()
    weapon?.reset()
    targeting?.reset()
    selection?.isSelected = false

    // Clear behavior machine (must be recreated by consumer)
    behaviorMachine = nil
  }

  /// Clears all callbacks to release captured references.
  /// Called automatically by ActorPool on release to prevent retain cycles.
  public func clearCallbacks() {
    onHurt = nil
    onHit = nil
    onDeath = nil
    onAcquiredTarget = nil
    onLostAllTargets = nil
    onBeforeAttack = nil
    onAttack = nil
  }
}
