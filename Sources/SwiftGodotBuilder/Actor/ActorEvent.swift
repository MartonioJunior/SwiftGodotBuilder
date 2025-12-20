import Foundation
import SwiftGodot

public enum ActorEvent: EmittableEvent {
  // Lifecycle
  case spawned(actorId: Int)
  case died(actorId: Int)
  case reset(actorId: Int)

  // Combat
  case tookDamage(actorId: Int, damage: Int)
  case meleeHitTarget(actorId: Int, targetId: Int, damage: Int, knockback: Float, position: Vector2, direction: Vector2)
  case phaseChanged(actorId: Int, phase: Int)

  // Attack
  case attackStarted(actorId: Int, position: Vector2, facing: Facing)
  case attackActive(actorId: Int, position: Vector2, facing: Facing)
  case attackEnded(actorId: Int)

  // Projectiles
  case projectileFired(actorId: Int, position: Vector2, direction: Vector2, config: RangedWeaponConfig, isPlayerOwned: Bool)
  case projectileHitTarget(actorId: Int, targetId: Int, position: Vector2, damage: Int, knockback: Float, direction: Vector2)
  case projectileHitWall(actorId: Int, position: Vector2)

  // Movement
  case jumped(actorId: Int, position: Vector2)
  case landed(actorId: Int, position: Vector2, impact: Float)
  case dashed(actorId: Int, position: Vector2, direction: Vector2)
  case wallSlideStarted(actorId: Int, position: Vector2)

  // Zones
  case enteredZone(bodyInstanceId: Int, zone: String)
  case exitedZone(bodyInstanceId: Int, zone: String)

  // Interactions
  case collected(actorId: Int, itemId: String, position: Vector2)
  case enteredDoor(actorId: Int, targetLevelIid: String, targetEntityIid: String)
  case interactorEntered(actorId: Int, interactorId: Int)
  case interactorExited(actorId: Int, interactorId: Int)
  case interacted(actorId: Int, interactorId: Int)
}
