import SwiftGodot

extension Chapter26 {
  struct WorldConfig {
    let gravity: Float = 400
  }

  struct PlayerConfig {
    let movement = Movement()
    let water = Water()
    let combat = Combat()
    let camera = Camera()

    struct Movement {
      // 240px wide / 70 = ~3.4 sec to cross screen
      let speed: Float = 70
      let jumpSpeed: Float = 130
      let minJumpSpeed: Float = 60
      let coyoteTime: Double = 0.1
      let jumpBufferTime: Double = 0.1
      let wallJumpSpeed: Float = 130
      let wallJumpVerticalSpeed: Float = 130
      let dashSpeed: Float = 180
      let dashDuration: Double = 0.15
      let dashCooldown: Double = 0.6
      let crouchSpeedMultiplier: Float = 0.5
    }

    struct Water {
      let gravityMultiplier: Float = 0.3
      let moveSpeedMultiplier: Float = 0.6
      let maxFallSpeed: Float = 40
      let swimSpeed: Float = 80
    }

    struct Combat {
      let maxHealth: Int = 3
      let invincibilityDuration: Double = 1.0
      let attackDuration: Double = 0.15
      let hitAnimDuration: Double = 0.2
    }

    struct Camera {
      // 240x135 viewport - keep lookahead subtle
      let lookahead: Float = 16
      let lookaheadSpeed: Float = 5.0
      let lookaheadThreshold: Float = 16

      let crouchLookDelay: Double = 0.8
      let dragMarginH: Double = 0.2

      // Slight upward bias to see more ground ahead
      let verticalBiasNormal: Float = -4
      let verticalBiasCrouch: Float = 20
      let dragMarginTop: Double = 0.25
      let dragMarginBottom: Double = 0.15
    }
  }
}
