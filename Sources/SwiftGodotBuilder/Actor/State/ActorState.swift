import Foundation
import SwiftGodot

@Observable
public class ActorState: Equatable {
  // MARK: - Properties

  /// Unique actor ID
  public let id: Int

  /// Reference to the CharacterBody2D node (set after body is created)
  public internal(set) var node: CharacterBody2D?

  /// Whether this is the player (affects death handling)
  public var isPlayer = false

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

  /// Behavior machine for AI behaviors (type-erased)
  var behaviorMachine: AnyBehaviorMachine?

  // MARK: - Interaction Tracking

  /// Actor IDs currently in interaction range (populated via interactorEntered/Exited events)
  public var nearbyInteractorIds: [Int] = []

  /// Whether there's an interactable actor in range
  public var canInteract: Bool {
    !nearbyInteractorIds.isEmpty
  }

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
}
