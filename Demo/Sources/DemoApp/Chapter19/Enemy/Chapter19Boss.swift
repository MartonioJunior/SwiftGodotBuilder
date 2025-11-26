import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter19 {
  struct Boss: GView {
    let spawnPoint: Vector2
    let arenaLeft: Float
    let arenaRight: Float
    let gravity: Float
    let state: ObservableState<GameViewState>

    // Boss-specific constants
    let size: Vector2 = [32, 40]
    let maxHealth: Int = 100
    let touchDamage: Int = 1

    // Movement speeds per phase
    let baseSpeed: Float = 30
    let phase2SpeedMultiplier: Float = 1.5
    let phase3SpeedMultiplier: Float = 2.0

    // Attack timings
    let shootCooldown: Double = 2.0
    let jumpCooldown: Double = 4.0
    let chargeCooldown: Double = 5.0
    let summonCooldown: Double = 8.0

    // Attack parameters
    let chargeSpeed: Float = 200
    let jumpForce: Float = 300
    let projectileSpeed: Float = 120

    // Visual
    let flashDuration: Double = 0.1
    let stunDuration: Double = 1.0

    @State var position: Vector2 = .zero
    @State var velocity: Vector2 = .zero
    @State var direction: Float = -1
    @State var health = 100
    @State var phase: BossPhase = .one
    @State var isOnGround = true

    // Attack state
    @State var currentAttack: BossAttackType? = nil
    @State var attackTimer = 0.0
    @State var shootTimer = 2.0
    @State var jumpTimer = 4.0
    @State var chargeTimer = 5.0
    @State var summonTimer = 8.0

    // Charge attack state
    @State var isCharging = false
    @State var chargeDirection: Float = 0

    // Visual state
    @State var flashTimer = 0.0
    @State var isFlashing = false
    @State var isStunned = false
    @State var stunTimer = 0.0

    // Defeat state
    @State var isDefeated = false
    @State var defeatTimer = 0.0
    let defeatDuration: Double = 2.0

    let palette = Palette()

    init(
      spawnPoint: Vector2,
      arenaLeft: Float,
      arenaRight: Float,
      gravity: Float,
      state: ObservableState<GameViewState>
    ) {
      self.spawnPoint = spawnPoint
      self.arenaLeft = arenaLeft
      self.arenaRight = arenaRight
      self.gravity = gravity
      self.state = state
      position = spawnPoint
      health = maxHealth
    }

    var body: some GView {
      Node2D$ {
        // Boss body visual
        ColorBox$()
          .size(size)
          .bind(\.color, to: $phase, $isFlashing, $isDefeated) { phase, flashing, defeated in
            if defeated {
              return palette.gray
            }
            if flashing {
              return palette.white
            }
            switch phase {
            case .one:
              return palette.bossRed
            case .two:
              return palette.bossOrange
            case .three:
              return palette.bossPurple
            case .defeated:
              return palette.gray
            }
          }

        // Eye indicators (show phase)
        ColorBox$()
          .size([4, 4])
          .position([8, 10])
          .bind(\.color, to: $phase) { phase in
            phase == .three ? palette.yellow : palette.white
          }

        ColorBox$()
          .size([4, 4])
          .position([20, 10])
          .bind(\.color, to: $phase) { phase in
            phase == .three ? palette.yellow : palette.white
          }

        // Collision area for detecting player and attacks
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(size: size))
            .position(size / 2)
            .watch($isDefeated) { cs, defeated in
              Engine.onNextFrame { cs.disabled = defeated }
            }
        }
        .collisionLayer(.delta) // Enemy layer
        .collisionMask([.beta, .delta]) // Player body and player attacks
        .onSignal(\.bodyEntered) { _, body in
          // Player touched boss
          if !isDefeated, !isStunned, body is CharacterBody2D {
            Event.playerHit(damage: touchDamage, position: position).emit()
          }
        }
        .onSignal(\.areaEntered) { _, _ in
          // Player attack hit boss
          if !isDefeated, !isStunned {
            takeDamage(1)
          }
        }
      }
      .position($position)
      .visible($isDefeated.computed { !$0 })
      .onReady { [state] _ in
        state.wrappedValue.startBossFight(maxHealth: maxHealth)
      }
      .onEvent(Event.self) { _, event in
        switch event {
        case .gameReset:
          respawn()
        case let .projectileHitEnemy(hitPos):
          // Check if projectile hit us (within our bounds)
          let bossCenter = position + size / 2
          let distance = hitPos.distanceTo(bossCenter)
          if distance < 30, !isDefeated, !isStunned {
            takeDamage(2) // Projectiles do more damage
          }
        default:
          break
        }
      }
      .onProcess { _, delta in
        guard state.wrappedValue.isPlaying, !isDefeated else {
          if isDefeated {
            updateDefeat(delta)
          }
          return
        }

        updateBoss(delta)
      }
    }

    func updateBoss(_ delta: Double) {
      // Update flash effect
      if isFlashing {
        flashTimer -= delta
        if flashTimer <= 0 {
          isFlashing = false
        }
      }

      // Update stun
      if isStunned {
        stunTimer -= delta
        if stunTimer <= 0 {
          isStunned = false
          state.wrappedValue.bossStunned = false
        }
        return
      }

      // Apply gravity
      if !isOnGround {
        velocity.y += gravity * Float(delta)
      }

      // Handle current attack
      if isCharging {
        updateCharge(delta)
      } else {
        // Normal movement - patrol toward player direction
        let speed = currentSpeed
        position.x += direction * speed * Float(delta)

        // Reverse at arena bounds
        if position.x <= arenaLeft {
          position.x = arenaLeft
          direction = 1
        } else if position.x + size.x >= arenaRight {
          position.x = arenaRight - size.x
          direction = -1
        }
      }

      // Apply velocity
      position += velocity * Float(delta)

      // Ground check (simplified - assume ground at spawn y)
      if position.y >= spawnPoint.y {
        position.y = spawnPoint.y
        if velocity.y > 0 {
          velocity.y = 0
          isOnGround = true
        }
      }

      // Update attack cooldowns and choose attacks
      updateAttacks(delta)
    }

    var currentSpeed: Float {
      switch phase {
      case .one:
        return baseSpeed
      case .two:
        return baseSpeed * phase2SpeedMultiplier
      case .three:
        return baseSpeed * phase3SpeedMultiplier
      case .defeated:
        return 0
      }
    }

    func updateAttacks(_ delta: Double) {
      // Decrement timers
      shootTimer -= delta
      jumpTimer -= delta
      chargeTimer -= delta
      if phase == .three {
        summonTimer -= delta
      }

      // Choose attack based on phase and cooldowns
      switch phase {
      case .one:
        // Phase 1: Only shoots
        if shootTimer <= 0 {
          performShoot()
          shootTimer = shootCooldown
        }

      case .two:
        // Phase 2: Shoots and jumps
        if jumpTimer <= 0 {
          performJump()
          jumpTimer = jumpCooldown
        } else if shootTimer <= 0 {
          performShoot()
          shootTimer = shootCooldown * 0.8 // Faster shooting
        }

      case .three:
        // Phase 3: All attacks + summons
        if summonTimer <= 0 {
          performSummon()
          summonTimer = summonCooldown
        } else if chargeTimer <= 0 {
          performCharge()
          chargeTimer = chargeCooldown
        } else if jumpTimer <= 0 {
          performJump()
          jumpTimer = jumpCooldown * 0.7
        } else if shootTimer <= 0 {
          performShoot()
          shootTimer = shootCooldown * 0.6
        }

      case .defeated:
        break
      }
    }

    func performShoot() {
      currentAttack = .shoot
      let projectilePos = position + [size.x / 2, size.y / 2]
      let projectileDir: Vector2 = [direction, 0]
      Event.bossAttack(attackType: .shoot, position: projectilePos).emit()
      Event.enemyProjectileFired(position: projectilePos, direction: projectileDir).emit()
    }

    func performJump() {
      currentAttack = .jump
      velocity.y = -jumpForce
      isOnGround = false
      Event.bossAttack(attackType: .jump, position: position).emit()
    }

    func performCharge() {
      currentAttack = .charge
      isCharging = true
      chargeDirection = direction
      Event.bossAttack(attackType: .charge, position: position).emit()
    }

    func performSummon() {
      currentAttack = .summon
      // Emit event for spawner to create minions
      Event.bossAttack(attackType: .summon, position: position).emit()
    }

    func updateCharge(_ delta: Double) {
      position.x += chargeDirection * chargeSpeed * Float(delta)

      // Stop charging at walls
      if position.x <= arenaLeft || position.x + size.x >= arenaRight {
        isCharging = false
        // Brief stun after hitting wall
        isStunned = true
        stunTimer = stunDuration * 0.5
        state.wrappedValue.bossStunned = true
        direction = -chargeDirection
      }
    }

    func takeDamage(_ damage: Int) {
      health -= damage

      // Flash effect
      isFlashing = true
      flashTimer = flashDuration

      // Update state
      state.wrappedValue.handleBossHit(damage: damage)
      Event.bossHit(damage: damage, position: position + size / 2).emit()

      // Check phase transition
      let healthPercent = Float(health) / Float(maxHealth)
      let newPhase: BossPhase
      if healthPercent <= 0 {
        newPhase = .defeated
      } else if healthPercent <= 0.33 {
        newPhase = .three
      } else if healthPercent <= 0.66 {
        newPhase = .two
      } else {
        newPhase = .one
      }

      if newPhase != phase {
        phase = newPhase
        // Stun on phase transition
        isStunned = true
        stunTimer = stunDuration
        state.wrappedValue.bossStunned = true
      }

      if health <= 0 {
        defeat()
      }
    }

    func defeat() {
      isDefeated = true
      defeatTimer = defeatDuration
      Event.bossDefeated(position: position + size / 2).emit()
    }

    func updateDefeat(_ delta: Double) {
      defeatTimer -= delta
      if defeatTimer <= 0 {
        // Trigger goal reached / level complete
        Event.goalReached.emit()
      }
    }

    func respawn() {
      position = spawnPoint
      velocity = .zero
      direction = -1
      health = maxHealth
      phase = .one
      isOnGround = true
      currentAttack = nil
      shootTimer = shootCooldown
      jumpTimer = jumpCooldown
      chargeTimer = chargeCooldown
      summonTimer = summonCooldown
      isCharging = false
      isFlashing = false
      isStunned = false
      isDefeated = false
      defeatTimer = 0

      // Re-initialize boss fight state (delay to ensure watchers see the change)
      Engine.onNextFrame { [state, maxHealth] in
        state.wrappedValue.startBossFight(maxHealth: maxHealth)
      }
    }
  }
}
