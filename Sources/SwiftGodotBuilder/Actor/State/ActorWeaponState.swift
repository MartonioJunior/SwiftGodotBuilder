import Foundation
import SwiftGodot

/// Weapon capability state for actors with weapons
public class ActorWeaponState {
  // MARK: - Weapons

  public let weapons: [ActorWeaponConfig]
  public var currentIndex: Int = 0

  // MARK: - Attack State

  public var attackPhase: AttackPhase = .idle
  public var attackTimer: Double = 0
  public var attackRequested = false

  // MARK: - Computed Properties

  /// Current weapon config
  public var current: ActorWeaponConfig? {
    guard !weapons.isEmpty, currentIndex < weapons.count else { return nil }
    return weapons[currentIndex]
  }

  /// Whether the hitbox should be active
  public var hitboxActive: Bool {
    guard let weapon = current, let melee = weapon.melee else { return false }
    // For alwaysActive melee weapons (touch damage), always active
    if melee.alwaysActive { return true }
    // Otherwise, only active during attack active phase
    return attackPhase == .active
  }

  /// Current melee config if current weapon has melee
  public var currentMelee: MeleeWeaponConfig? {
    current?.melee
  }

  /// Current ranged config if current weapon has ranged
  public var currentRanged: RangedWeaponConfig? {
    current?.ranged
  }

  // MARK: - Initialization

  public init(weapons: [ActorWeaponConfig] = []) {
    self.weapons = weapons
  }

  // MARK: - Weapon Switching

  public func switchTo(index: Int) {
    guard index >= 0, index < weapons.count else { return }
    currentIndex = index
  }

  public func switchToNext() {
    guard !weapons.isEmpty else { return }
    currentIndex = (currentIndex + 1) % weapons.count
  }

  public func switchToPrevious() {
    guard !weapons.isEmpty else { return }
    currentIndex = currentIndex > 0 ? currentIndex - 1 : weapons.count - 1
  }

  // MARK: - Attack

  public func tryAttack() {
    attackRequested = true
  }

  // MARK: - Processing

  public func process(body: CharacterBody2D, delta: Double, coreState: ActorState) {
    guard let weapon = current else {
      attackRequested = false
      return
    }

    // AlwaysActive melee weapons don't use attack phases
    if let melee = weapon.melee, melee.alwaysActive {
      // Still fire ranged immediately if requested and not recovering
      if attackRequested, let ranged = weapon.ranged, attackPhase == .idle {
        // Check onBeforeAttack callback
        let shouldFire = coreState.onBeforeAttack?(coreState, currentIndex) ?? true
        if shouldFire {
          coreState.onAttack?(coreState, currentIndex)
          fireProjectile(body: body, coreState: coreState, config: ranged)
        }
      }
      attackRequested = false
      return
    }

    // Start attack if requested and idle
    if attackRequested, attackPhase == .idle {
      // Check onBeforeAttack callback - if it returns false, cancel attack
      if let onBeforeAttack = coreState.onBeforeAttack {
        guard onBeforeAttack(coreState, currentIndex) else {
          attackRequested = false
          return
        }
      }
      startAttack(body: body, coreState: coreState, weapon: weapon)
      attackRequested = false
      return
    }
    attackRequested = false

    // Process ongoing attack
    guard attackPhase != .idle else { return }

    attackTimer -= delta
    if attackTimer <= 0 {
      advancePhase(body: body, coreState: coreState, weapon: weapon)
    }
  }

  // MARK: - Attack Phase State Machine

  private func startAttack(body: CharacterBody2D, coreState: ActorState, weapon: ActorWeaponConfig) {
    attackPhase = .startup
    attackTimer = weapon.startupDuration
    ActorEvent.attackStarted(actorId: coreState.id, position: body.position, facing: coreState.facing).emit()
  }

  private func advancePhase(body: CharacterBody2D, coreState: ActorState, weapon: ActorWeaponConfig) {
    switch attackPhase {
    case .idle:
      break

    case .startup:
      attackPhase = .active
      attackTimer = weapon.activeDuration
      ActorEvent.attackActive(actorId: coreState.id, position: body.position, facing: coreState.facing).emit()

      // Call onAttack callback
      coreState.onAttack?(coreState, currentIndex)

      // Fire projectile at start of active phase
      if let ranged = weapon.ranged {
        fireProjectile(body: body, coreState: coreState, config: ranged)
      }

    case .active:
      attackPhase = .recovery
      attackTimer = weapon.recoveryDuration

    case .recovery:
      attackPhase = .idle
      attackTimer = 0
      ActorEvent.attackEnded(actorId: coreState.id).emit()
    }
  }

  private func fireProjectile(body: CharacterBody2D, coreState: ActorState, config: RangedWeaponConfig) {
    let direction = Vector2(x: coreState.facing.sign, y: 0)
    let spawnPos = body.position + Vector2(
      x: config.spawnOffset.x * coreState.facing.sign,
      y: config.spawnOffset.y
    )

    ActorEvent.projectileFired(
      actorId: coreState.id,
      position: spawnPos,
      direction: direction,
      config: config,
      isPlayerOwned: coreState.isPlayer
    ).emit()
  }

  // MARK: - Reset (for pooling)

  /// Resets state to initial values for reuse from pool
  public func reset() {
    currentIndex = 0
    attackPhase = .idle
    attackTimer = 0
    attackRequested = false
  }
}
