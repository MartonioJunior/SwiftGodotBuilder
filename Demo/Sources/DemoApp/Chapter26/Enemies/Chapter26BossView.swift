import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct BossView: GView {
    let spawnPoint: Vector2
    let arenaLeft: Float
    let arenaRight: Float
    let state: ObservableState<GameViewState>
    let router: ObservableState<GameRouter>

    let wc = WorldConfig()

    // Boss-specific constants
    let size: Vector2 = [16, 20]
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

    // Boss colors
    let bossRed = Color(code: "#CC2222")
    let bossOrange = Color(code: "#FF6600")
    let bossPurple = Color(code: "#9933FF")
    let bossColor: GState<Color>

    var vm: GameViewState { state.wrappedValue }

    init(
      entity: LDEntity,
      level: LDLevel,
      state: ObservableState<GameViewState>,
      router: ObservableState<GameRouter>
    ) {
      spawnPoint = entity.positionTopLeft
      let arenaPadding: Float = 10
      arenaLeft = arenaPadding
      arenaRight = Float(level.pxWid) - arenaPadding
      self.state = state
      self.router = router
      position = spawnPoint
      health = maxHealth

      bossColor = _phase.computed(with: _isFlashing, _isDefeated) { [bossRed, bossOrange, bossPurple] phase, flashing, defeated in
        if defeated { return .gray }
        if flashing { return .white }
        switch phase {
        case .one: return bossRed
        case .two: return bossOrange
        case .three: return bossPurple
        case .defeated: return .gray
        }
      }
    }

    var body: some GView {
      Node2D$ {
        // Boss body visual
        ColorBox$()
          .size(size)
          .color(bossColor)

        // Collision area for detecting player and attacks
        // Only MASK for combat - don't BE on combat layer (to avoid detecting other enemies)
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(size: size))
            .position(size / 2)
            .watch($isDefeated) { cs, defeated in
              Engine.onNextFrame { cs.disabled = defeated }
            }
        }
        .collisionLayer(0)
        .collisionMask([.player, .combat])
        .onSignal(\.bodyEntered) { _, body in
          // Player touched boss
          if !isDefeated, !isStunned, body is CharacterBody2D {
            GameEvent.playerHit(damage: touchDamage, position: position).emit()
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
      .onReady { _ in
        vm.startBossFight(maxHealth: maxHealth)
      }
      .onEvent(GameEvent.self) { _, event in
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
        guard router.scene.isActive, !isDefeated else {
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
          vm.bossStunned = false
        }
        return
      }

      // Apply gravity
      if !isOnGround {
        velocity.y += wc.gravity * Float(delta)
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
      GameEvent.enemyProjectileFired(position: projectilePos, direction: projectileDir).emit()
    }

    func performJump() {
      currentAttack = .jump
      velocity.y = -jumpForce
      isOnGround = false
    }

    func performCharge() {
      currentAttack = .charge
      isCharging = true
      chargeDirection = direction
    }

    func performSummon() {
      currentAttack = .summon
    }

    func updateCharge(_ delta: Double) {
      position.x += chargeDirection * chargeSpeed * Float(delta)

      // Stop charging at walls
      if position.x <= arenaLeft || position.x + size.x >= arenaRight {
        isCharging = false
        // Brief stun after hitting wall
        isStunned = true
        stunTimer = stunDuration * 0.5
        vm.bossStunned = true
        direction = -chargeDirection
      }
    }

    func takeDamage(_ damage: Int) {
      health -= damage

      // Flash effect
      isFlashing = true
      flashTimer = flashDuration

      // Emit damage for floating numbers
      let damagePos = position + [size.x / 2, 0]
      GameEvent.damageDealt(amount: damage, position: damagePos).emit()

      // Update state
      vm.handleBossHit(damage: damage)
      GameEvent.bossHit(damage: damage, position: position + size / 2).emit()

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
        vm.bossStunned = true
      }

      if health <= 0 {
        defeat()
      }
    }

    func defeat() {
      isDefeated = true
      defeatTimer = defeatDuration
      GameEvent.bossDefeated(position: position + size / 2).emit()
    }

    func updateDefeat(_ delta: Double) {
      defeatTimer -= delta
      if defeatTimer <= 0 {
        // Trigger goal reached / level complete
        GameEvent.goalReached.emit()
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

      Engine.onNextFrame {
        vm.startBossFight(maxHealth: maxHealth)
      }
    }
  }
}
