
import Foundation
import SwiftGodot

// Public actions used to control ActorState externally

public extension ActorState {
  // MARK: - Movement Input

  /// Set movement input (-1 to 1)
  func move(_ direction: Double) {
    physics?.inputDirection = Float(direction)
  }

  func move(_ direction: Float) {
    physics?.inputDirection = direction
  }

  /// Request a jump (will be buffered)
  func tryJump() {
    physics?.jumpRequested = true
  }

  /// Set whether jump button is held (for variable jump height)
  func setJumpHeld(_ held: Bool) {
    physics?.jumpHeld = held
  }

  /// Request a dash
  func tryDash() {
    physics?.dashRequested = true
  }

  /// Set crouch state
  func setCrouching(_ crouching: Bool) {
    physics?.crouchHeld = crouching
  }

  // MARK: - Attack

  /// Request an attack with current weapon
  func tryAttack() {
    weapon?.tryAttack()
  }

  // MARK: - Weapon Switching

  /// Switch to the next weapon
  func switchWeapon() {
    weapon?.switchToNext()
  }

  /// Switch to a specific weapon index
  func switchWeapon(to index: Int) {
    weapon?.switchTo(index: index)
  }

  // MARK: - Combat

  /// Apply damage to actor
  func takeDamage(_ amount: Int, knockback: Vector2? = nil) {
    defense?.takeDamage(amount, knockback: knockback, coreState: self, physicsState: physics)
  }

  /// Heal actor
  func heal(_ amount: Int) {
    defense?.heal(amount)
  }

  // MARK: - Interaction

  /// Try to interact with the closest nearby actor
  /// Emits interacted event if there's an actor in range
  func tryInteract() {
    guard let targetId = nearbyInteractorIds.first else { return }
    ActorEvent.interacted(actorId: targetId, interactorId: id).emit()
  }

  // MARK: - Dialog

  /// Try to trigger dialog (if actor has dialog capability)
  func tryTriggerDialog() {
    dialog?.tryTriggerDialog(actorState: self)
  }
}
