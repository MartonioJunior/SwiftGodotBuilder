import Foundation
import SwiftGodot

// MARK: - Actor Controller Protocol

/// Protocol for controlling an actor (player input, AI, network, etc.)
public protocol ActorController: AnyObject {
  /// Called each frame to get movement input (-1 to 1)
  func getMovementInput() -> Float

  /// Called each frame to check if jump was requested (just pressed)
  func wantsToJump() -> Bool

  /// Called each frame to check if jump was released (for variable height)
  func jumpReleased() -> Bool

  /// Called each frame to check if crouch/down is held
  func wantsToCrouch() -> Bool

  /// Called each frame to check if dash was requested
  func wantsToDash() -> Bool

  /// Called each frame to check if attack was requested
  func wantsToAttack() -> Bool

  /// Called each frame to check if weapon switch was requested
  func wantsToSwitchWeapon() -> Bool

  /// Called each frame to check if interaction was requested
  func wantsToInteract() -> Bool

  /// Called each frame to update controller state (for AI)
  func update(actor: ActorState, delta: Double)

  /// AI: Get preferred weapon for current situation (nil = don't switch)
  func preferredWeapon(actor: ActorState, targetDistance: Float?) -> String?
}

// MARK: - Player Controller

/// Player controller - reads from input actions
public class PlayerActorController: ActorController {
  public init() {}

  public func getMovementInput() -> Float {
    var input: Float = 0
    if Action("move_left").isPressed { input -= 1 }
    if Action("move_right").isPressed { input += 1 }
    return input
  }

  public func wantsToJump() -> Bool { Action("jump").isJustPressed }
  public func jumpReleased() -> Bool { Action("jump").isJustReleased }
  public func wantsToCrouch() -> Bool { Action("move_down").isPressed }
  public func wantsToDash() -> Bool { Action("dash").isJustPressed }
  public func wantsToAttack() -> Bool { Action("attack").isJustPressed }
  public func wantsToSwitchWeapon() -> Bool { Action("switch_weapon").isJustPressed }
  public func wantsToInteract() -> Bool { Action("interact").isJustPressed }
  public func update(actor: ActorState, delta: Double) {}
  public func preferredWeapon(actor: ActorState, targetDistance: Float?) -> String? { nil }
}

// MARK: - Patrol Controller

/// Simple patrol AI controller
public class PatrolController: ActorController {
  public var direction: Float = 1
  public let patrolLeft: Float
  public let patrolRight: Float

  public init(patrolLeft: Float, patrolRight: Float) {
    self.patrolLeft = patrolLeft
    self.patrolRight = patrolRight
  }

  public func update(actor: ActorState, delta: Double) {
    if actor.position.x <= patrolLeft {
      direction = 1
    } else if actor.position.x >= patrolRight {
      direction = -1
    }
  }

  public func getMovementInput() -> Float { direction }
  public func wantsToJump() -> Bool { false }
  public func jumpReleased() -> Bool { false }
  public func wantsToCrouch() -> Bool { false }
  public func wantsToDash() -> Bool { false }
  public func wantsToAttack() -> Bool { false }
  public func wantsToSwitchWeapon() -> Bool { false }
  public func wantsToInteract() -> Bool { false }
  public func preferredWeapon(actor: ActorState, targetDistance: Float?) -> String? { nil }
}

// MARK: - Stationary Controller

/// Stationary controller - doesn't move
public class StationaryController: ActorController {
  public init() {}

  public func getMovementInput() -> Float { 0 }
  public func wantsToJump() -> Bool { false }
  public func jumpReleased() -> Bool { false }
  public func wantsToCrouch() -> Bool { false }
  public func wantsToDash() -> Bool { false }
  public func wantsToAttack() -> Bool { false }
  public func wantsToSwitchWeapon() -> Bool { false }
  public func wantsToInteract() -> Bool { false }
  public func update(actor: ActorState, delta: Double) {}
  public func preferredWeapon(actor: ActorState, targetDistance: Float?) -> String? { nil }
}

// MARK: - Combat AI Controller

/// AI controller that can attack and switch weapons based on target distance
public class CombatAIController: ActorController {
  public var direction: Float = 1
  public var targetPosition: Vector2?
  public var attackCooldown: Double = 0
  public var weaponSwitchCooldown: Double = 0

  public let patrolLeft: Float
  public let patrolRight: Float
  public let aggroRange: Float
  public let meleeRange: Float
  public let rangedRange: Float
  public let attackRate: Double
  public let meleeWeaponId: String?
  public let rangedWeaponId: String?

  private var wantsAttack = false
  private var wantsSwitch = false
  private var targetWeaponId: String?

  public init(
    patrolLeft: Float,
    patrolRight: Float,
    aggroRange: Float = 100,
    meleeRange: Float = 20,
    rangedRange: Float = 80,
    attackRate: Double = 1.0,
    meleeWeaponId: String? = nil,
    rangedWeaponId: String? = nil
  ) {
    self.patrolLeft = patrolLeft
    self.patrolRight = patrolRight
    self.aggroRange = aggroRange
    self.meleeRange = meleeRange
    self.rangedRange = rangedRange
    self.attackRate = attackRate
    self.meleeWeaponId = meleeWeaponId
    self.rangedWeaponId = rangedWeaponId
  }

  public func update(actor: ActorState, delta: Double) {
    wantsAttack = false
    wantsSwitch = false
    targetWeaponId = nil

    // Decrement cooldowns
    if attackCooldown > 0 { attackCooldown -= delta }
    if weaponSwitchCooldown > 0 { weaponSwitchCooldown -= delta }

    // Check for target
    if let target = targetPosition {
      let distance = Float(actor.position.distanceTo(target))

      if distance <= aggroRange {
        // Face target
        direction = target.x > actor.position.x ? 1 : -1

        // Decide weapon based on distance
        if distance <= meleeRange, let melee = meleeWeaponId {
          targetWeaponId = melee
          if attackCooldown <= 0 {
            wantsAttack = true
            attackCooldown = attackRate
          }
        } else if distance <= rangedRange, let ranged = rangedWeaponId {
          targetWeaponId = ranged
          if attackCooldown <= 0 {
            wantsAttack = true
            attackCooldown = attackRate
          }
        }

        // Stop moving when in attack range
        if distance <= meleeRange {
          direction = 0
        }
      } else {
        patrol(actor: actor)
      }
    } else {
      patrol(actor: actor)
    }
  }

  private func patrol(actor: ActorState) {
    if actor.position.x <= patrolLeft {
      direction = 1
    } else if actor.position.x >= patrolRight {
      direction = -1
    }
  }

  public func getMovementInput() -> Float { direction }
  public func wantsToJump() -> Bool { false }
  public func jumpReleased() -> Bool { false }
  public func wantsToCrouch() -> Bool { false }
  public func wantsToDash() -> Bool { false }
  public func wantsToAttack() -> Bool { wantsAttack }
  public func wantsToSwitchWeapon() -> Bool { wantsSwitch }
  public func wantsToInteract() -> Bool { false }

  public func preferredWeapon(actor: ActorState, targetDistance: Float?) -> String? {
    guard weaponSwitchCooldown <= 0 else { return nil }
    if let weaponId = targetWeaponId {
      weaponSwitchCooldown = 0.5
      return weaponId
    }
    return nil
  }

  /// Update target position (called from game layer)
  public func setTarget(_ position: Vector2?) {
    targetPosition = position
  }
}
