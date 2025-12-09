import Foundation
import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  @Observable
  class PlayerState {
    // MARK: - Constants

    let maxHealth = 3
    let maxLives = 3
    let config = PlayerConfig()

    // Player colors
    let playerBlue = Color(code: "#4D80E6")
    let playerWhiteFlash = Color(code: "#FFFFFF")
    let playerDash = Color(code: "#FFB34D")
    let playerDoubleJump = Color(code: "#4DE6FF")

    // MARK: - Resources & Combat

    var playerHealth = 3
    var playerLives = 3
    var currentAmmo = 10
    var maxAmmo = 20
    var currentWeapon: WeaponType = .melee
    var currentMeleeWeapon: MeleeWeapon = .sword
    var hasKey = false

    // MARK: - Spawn & Checkpoints

    var spawnPosition: Vector2 = .zero
    var activatedCheckpointIds: Set<Int> = []
    var currentLevelIid: String?
    var collisionHeight: Float = 8

    // MARK: - Door State

    var currentDoorIid: String?
    var currentDoorTargetRef: LDEntityRef?

    // MARK: - Physics State

    var position: Vector2 = .zero
    var velocity: Vector2 = [0, 0]
    var wasOnFloor = false

    // MARK: - Core State

    var action: ActionState = .idle
    var damage: DamageState = .normal
    var facing: Facing = .right
    var overlay: ActionOverlayState = []

    // MARK: - Detection Flags

    var isOnWall = false
    var isInWater = false
    var hasDoubleJump = true

    // MARK: - Attack State

    var attackPhase: AttackPhase = .idle
    var attackPhaseTimer = 0.0

    // MARK: - Timers

    var invincibilityTimer = 0.0
    var hitTimer = 0.0
    var coyoteTimer = 0.0
    var jumpBufferTimer = 0.0
    var dashTimer = 0.0
    var dashCooldownTimer = 0.0
    var dashDirection: Vector2 = .zero

    // MARK: - Visual Feedback

    var playerScale: Vector2 = [1, 1]
    var playerRotation: Float = 0

    // MARK: - Computed Properties

    var weaponConfig: WeaponConfig { currentMeleeWeapon.config }
    var isDead: Bool { damage == .dead }
    var isInvincible: Bool { overlay.contains(.invincible) }

    /// Animation name computed from current state
    var animationName: String {
      let layer = currentWeapon == .melee ? "Sword" : "Bow"
      let anim: String = switch damage {
      case .dead: "Death"
      case .hit: "Hit"
      case .normal:
        if attackPhase.isAttacking {
          "Attack"
        } else if overlay.contains(.crouching) {
          "Crouch"
        } else {
          switch action {
          case .idle: "Idle"
          case .walking: "Walk"
          case .jumping, .falling: "Jump"
          case .wallSliding: "WallSlide"
          case .dashing: "Walk"
          case .swimming: "Idle"
          }
        }
      }
      return "\(layer)_\(anim)"
    }

    /// Sprite modulation color based on state
    var spriteModulate: Color {
      if overlay.contains(.invincible) {
        let flash = sin(invincibilityTimer * 20) > 0
        return flash ? playerWhiteFlash : playerBlue
      } else if attackPhase.isAttacking {
        switch attackPhase {
        case .startup: return playerBlue.lightened(amount: 0.2)
        case .active: return playerDash
        case .recovery: return playerBlue.darkened(amount: 0.1)
        case .idle: return .white
        }
      } else if action == .dashing {
        return playerDoubleJump
      }
      return .white
    }

    // MARK: - Display Properties

    var ammoDisplay: String { currentWeapon == .ranged ? "\(currentAmmo)/\(maxAmmo)" : "" }
    var livesDisplay: String { "Lives: \(playerLives)" }
    var livesCountDisplay: String { "x\(playerLives)" }
    var livesRemainingText: String { playerLives == 1 ? "LAST LIFE!" : "\(playerLives) LIVES LEFT" }

    // MARK: - Resource Methods

    /// Consume one ammo if available
    /// - Returns: `true` if ammo was consumed, `false` if out of ammo
    func consumeAmmo() -> Bool {
      guard currentAmmo > 0 else { return false }
      currentAmmo -= 1
      return true
    }

    /// Handle checkpoint activation, updating spawn position
    /// - Parameters:
    ///   - id: Unique checkpoint identifier
    ///   - position: New spawn position
    /// - Returns: `true` if checkpoint was newly activated, `false` if already active
    func handleCheckpointActivated(id: Int, position: Vector2) -> Bool {
      guard !activatedCheckpointIds.contains(id) else { return false }
      activatedCheckpointIds.insert(id)
      spawnPosition = position
      return true
    }

    /// Restore one health point (clamped to max)
    func handleHealthCollected() {
      playerHealth = min(playerHealth + 1, maxHealth)
    }

    /// Add ammo (clamped to max)
    func handleAmmoCollected() {
      currentAmmo = min(currentAmmo + 5, maxAmmo)
    }

    // MARK: - State Reset

    /// Reset player state for respawn (keeps lives, checkpoints, level progress)
    func reset() {
      position = spawnPosition
      velocity = [0, 0]
      playerHealth = maxHealth

      action = .idle
      damage = .normal
      facing = .right
      overlay = [.invincible]
      invincibilityTimer = config.combat.invincibilityDuration

      isOnWall = false
      isInWater = false
      hasDoubleJump = true

      attackPhase = .idle
      attackPhaseTimer = 0
      hitTimer = 0
      coyoteTimer = 0
      jumpBufferTimer = 0
      dashTimer = 0
      dashCooldownTimer = 0
      dashDirection = .zero

      playerScale = [1, 1]
      playerRotation = 0
    }

    /// Full reset for new game/level (resets everything including lives and checkpoints)
    func fullReset() {
      reset()
      playerLives = maxLives
      currentAmmo = 10
      currentWeapon = .melee
      currentMeleeWeapon = .sword
      hasKey = false
      activatedCheckpointIds = []
      spawnPosition = .zero
      currentLevelIid = nil
      currentDoorIid = nil
      currentDoorTargetRef = nil
    }

    // MARK: - Initialization

    /// Initialize player spawn from entity data
    /// - Parameters:
    ///   - entity: LDtk entity containing spawn position and starting items
    ///   - levelIid: Current level identifier
    ///   - collisionHeight: Player collision box height (for damage calculations)
    func initializeSpawn(from entity: LDEntity, levelIid: String, collisionHeight: Float) {
      spawnPosition = entity.positionTopLeft
      position = spawnPosition
      currentLevelIid = levelIid
      self.collisionHeight = collisionHeight

      // Process starting items via events (handled by GameViewState)
      let startingItems: [Item] = entity.field("items")?.asEnumArray() ?? []
      for item in startingItems {
        GameEvent.collected(item, position: position).emit()
      }
    }

    // MARK: - Event Handling

    /// Handle game events relevant to player state
    /// - Parameter event: The game event to handle
    func handleEvent(_ event: GameEvent) {
      switch event {
      case .gameReset:
        reset()
      case let .playerHit(dmg, _):
        takeDamage(dmg, collisionHeight: collisionHeight)
      case .enteredWater:
        isInWater = true
      case .exitedWater:
        isInWater = false
      case let .doorTeleportComplete(targetPosition):
        teleportTo(targetPosition)
      default:
        break
      }
    }
  }
}
