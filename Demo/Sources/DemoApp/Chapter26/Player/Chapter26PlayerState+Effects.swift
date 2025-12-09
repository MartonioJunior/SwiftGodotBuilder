import SwiftGodot

extension Chapter26.PlayerState {
  // MARK: - Timers

  /// Update all gameplay timers (invincibility, hit animation, dash, attack phase)
  /// - Parameter delta: Frame delta time
  func updateTimers(_ delta: Double) {
    // Invincibility timer
    if invincibilityTimer > 0 {
      invincibilityTimer -= delta
      if invincibilityTimer <= 0 {
        invincibilityTimer = 0
        overlay.remove(.invincible)
      }
    }

    // Hit animation timer
    if hitTimer > 0 {
      hitTimer -= delta
      if hitTimer <= 0 {
        hitTimer = 0
        if damage == .hit { damage = .normal }
      }
    }

    // Jump buffer timer
    if jumpBufferTimer > 0 { jumpBufferTimer -= delta }

    // Dash timer
    if dashTimer > 0 {
      dashTimer -= delta
      if dashTimer <= 0 {
        dashTimer = 0
        if action == .dashing { action = .idle }
      }
    }

    // Dash cooldown timer
    if dashCooldownTimer > 0 { dashCooldownTimer -= delta }

    // Attack phase timer
    if attackPhase != .idle, attackPhaseTimer > 0 {
      attackPhaseTimer -= delta
      if attackPhaseTimer <= 0 {
        attackPhaseTimer = 0
        advanceAttackPhase()
      }
    }
  }

  // MARK: - Visual Effects

  /// Update visual feedback (scale squash/stretch, rotation wobble)
  /// - Parameter delta: Frame delta time
  func updateVisualEffects(_ delta: Double) {
    // Scale lerp back to normal
    if playerScale != [1, 1] {
      playerScale = playerScale.lerp(to: [1, 1], weight: 12.0 * delta)
      if abs(playerScale.x - 1) < 0.01 && abs(playerScale.y - 1) < 0.01 {
        playerScale = [1, 1]
      }
    }

    // Rotation decay
    if playerRotation != 0 {
      playerRotation *= Float(1.0 - 8.0 * delta)
      if abs(playerRotation) < 0.01 { playerRotation = 0 }
    }
  }

  // MARK: - Teleportation

  /// Instantly move player to target position (used for doorway teleportation)
  /// - Parameter targetPosition: Destination position
  func teleportTo(_ targetPosition: Vector2) {
    position = targetPosition
    velocity = [0, 0]
    currentDoorIid = nil
    currentDoorTargetRef = nil
    action = .idle
    coyoteTimer = 0
    jumpBufferTimer = 0
  }
}
