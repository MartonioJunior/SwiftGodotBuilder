import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct PlayerView: GView {
    let entity: LDEntity
    let level: LDLevel
    let state: ObservableState<GameViewState>
    let settings: ObservableState<GameSettings>
    let router: ObservableState<GameRouter>

    private var vm: GameViewState { state.wrappedValue }
    private var gs: GameSettings { settings.wrappedValue }

    let config = PlayerConfig()

    var spawnPoint: Vector2 { vm.playerSpawnPosition }
    var levelWidth: Float { Float(level.pxWid) }
    var levelHeight: Float { Float(level.pxHei) }
    var size: Vector2 { vm.playerSize }

    @State var position: Vector2 = .zero
    @State var velocity: Vector2 = [0, 0]
    @State var wasOnFloor = false

    // Core player state
    @State var action: ActionState = .idle
    @State var damage: DamageState = .normal
    @State var facing: Facing = .right
    @State var overlay: ActionOverlayState = []

    // Detection flags (from physics)
    @State var isOnWall = false
    @State var isInWater = false

    // Resources
    @State var hasDoubleJump = true

    // Attack state
    @State var attackPhase: AttackPhase = .idle
    @State var attackPhaseTimer = 0.0
    var weaponConfig: WeaponConfig { vm.currentMeleeWeapon.config }

    // Timers
    @State var invincibilityTimer = 0.0
    @State var hitTimer = 0.0
    @State var coyoteTimer = 0.0
    @State var jumpBufferTimer = 0.0
    @State var dashTimer = 0.0
    @State var dashCooldownTimer = 0.0
    @State var dashDirection: Vector2 = .zero

    // Visual feedback state
    @State var playerScale: Vector2 = [1, 1]
    @State var playerRotation: Float = 0
    @State var visualOffset: Vector2 = .zero

    // Player colors
    let playerBlue = Color(code: "#4D80E6")
    let playerWhiteFlash = Color(code: "#FFFFFF")
    let playerDash = Color(code: "#FFB34D")
    let playerDoubleJump = Color(code: "#4DE6FF")
    let playerDashTrail = Color(code: "#FFFFFFCC")

    var spriteModulate: GState<Color> {
      $overlay.computed(with: $invincibilityTimer, $action, $attackPhase) { overlay, timer, action, phase in
        if overlay.contains(.invincible) {
          // Flash white during invincibility
          let flash = sin(timer * 20) > 0
          return flash ? playerWhiteFlash : playerBlue
        } else if phase.isAttacking {
          // Different color per phase for visual feedback
          switch phase {
          case .startup: return playerBlue.lightened(amount: 0.2)
          case .active: return playerDash
          case .recovery: return playerBlue.darkened(amount: 0.1)
          default: return .white
          }
        } else if action == .dashing {
          return playerDoubleJump
        } else {
          return .white
        }
      }
    }

    var body: some GView {
      CharacterBody2D$ {
        PlayerCamera(
          facing: $facing,
          velocity: $velocity,
          overlay: $overlay,
          levelWidth: levelWidth,
          levelHeight: levelHeight,
          state: state,
          config: config.camera
        )

        ColorBox$()
          .size(size)
          .modulate(spriteModulate)
          .scale($playerScale)
          .rotation($playerRotation) { Double($0) }
          .watch($overlay) { node, overlay in
            let isCrouching = overlay.contains(.crouching)
            node.size = [size.x, isCrouching ? size.y / 2 : size.y]
            node.position = [0, isCrouching ? size.y / 2 : 0]
          }

        // Physics collision shape (smaller - for world, enemies, projectiles)
        CollisionShape2D$()
          .shape(RectangleShape2D(w: 5, h: 6))
          .position([3.5, 4.5])
          .watch($overlay) { node, overlay in
            let crouching = overlay.contains(.crouching)
            node.shape = RectangleShape2D(w: 5, h: crouching ? 4 : 6)
            node.position = [3.5, crouching ? 5.5 : 4.5]
          }

        // Interaction area (larger - for NPCs, chests, doors)
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(w: 10, h: 10))
            .position([4, 4])
        }
        .collisionLayer(.interaction)

        // Attack hitbox - uses weapon config for size/position
        AttackHitboxView(
          facing: $facing,
          attackPhase: $attackPhase,
          weaponConfig: weaponConfig,
          playerSize: size
        )
      }
      .collisionLayer(.player)
      .collisionMask(.terrain)
      .position($position)
      .velocity($velocity)
      .onReady { node in
        // Set initial spawn position from entity
        vm.playerSpawnPosition = entity.positionTopLeft
        position = vm.playerSpawnPosition
        node.position = vm.playerSpawnPosition

        // Process starting items from entity
        let startingItems: [Item] = entity.field("items")?.asEnumArray() ?? []
        for item in startingItems {
          switch item {
          case .coin: vm.coinsCollected += 1
          case .key: vm.hasKey = true
          case .ammo: vm.currentAmmo += 5
          case .health: break
          }
        }
      }
      .onEvent(GameEvent.self) { _, event in
        switch event {
        case .gameReset:
          respawn()
        case let .playerHit(damage, _):
          takeDamage(damage)
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
      .onProcess { player, delta in
        guard router.scene.isActive else { return }
        updatePlayer(player, delta)
        updateTimers(delta)
      }
    }

    func updatePlayer(_ player: CharacterBody2D, _ delta: Double) {
      let onFloor = player.isOnFloor()
      isOnWall = player.isOnWall()

      let vel = updateMovement(player, delta, onFloor)
      handleInput(onFloor)
      applyMovement(player, vel, delta, onFloor)
      updateVisualEffects(delta)
    }

    func updateMovement(_ player: CharacterBody2D, _ delta: Double, _ onFloor: Bool) -> Vector2 {
      var vel = velocity
      let isCrouching = overlay.contains(.crouching)

      // Dash - overrides normal movement (disabled in water)
      if action == .dashing, !isInWater {
        return dashDirection * config.movement.dashSpeed
      }

      if isInWater {
        return updateWaterMovement(delta)
      }

      // Apply gravity (reduced on walls for wall slide)
      if isOnWall, vel.y > 0 {
        vel.y += gs.gravity * Float(delta) * 0.3
      } else {
        vel.y += gs.gravity * Float(delta)
      }

      // Crouching
      let wantsToCrouch = Action("move_down").isPressed
      if wantsToCrouch, onFloor {
        overlay.insert(.crouching)
      } else if !wantsToCrouch, isCrouching, canStandUp(player) {
        overlay.remove(.crouching)
      }

      // Horizontal movement
      var input: Float = 0
      if Action("move_left").isPressed {
        input -= 1
        facing = .left
      }
      if Action("move_right").isPressed {
        input += 1
        facing = .right
      }
      let speed = isCrouching ? config.movement.speed * config.movement.crouchSpeedMultiplier : config.movement.speed
      vel.x = input * speed

      // Dash input
      if Action("dash").isJustPressed, dashCooldownTimer <= 0 {
        action = .dashing
        dashTimer = config.movement.dashDuration
        dashCooldownTimer = config.movement.dashCooldown
        dashDirection = [facing.sign, 0]
      }

      // Jump
      vel = handleJump(player, vel, onFloor, isCrouching, input)

      return vel
    }

    func updateWaterMovement(_ delta: Double) -> Vector2 {
      var vel = velocity
      action = .swimming

      vel.y += gs.gravity * Float(delta) * config.water.gravityMultiplier
      if vel.y > config.water.maxFallSpeed {
        vel.y = config.water.maxFallSpeed
      }

      if Action("jump").isPressed {
        vel.y = -config.water.swimSpeed
      }
      if Action("move_down").isPressed {
        vel.y = min(vel.y + gs.gravity * Float(delta), config.water.maxFallSpeed * 2)
      }

      var input: Float = 0
      if Action("move_left").isPressed {
        input -= 1
        facing = .left
      }
      if Action("move_right").isPressed {
        input += 1
        facing = .right
      }
      vel.x = input * config.movement.speed * config.water.moveSpeedMultiplier

      hasDoubleJump = true
      overlay.remove(.crouching)

      return vel
    }

    func handleJump(_ player: CharacterBody2D, _ vel: Vector2, _ onFloor: Bool, _ isCrouching: Bool, _ input: Float) -> Vector2 {
      var vel = vel

      // Jump buffering (skip if in doorway to allow door entry)
      if Action("jump").isJustPressed, vm.currentDoorTargetRef == nil {
        jumpBufferTimer = config.movement.jumpBufferTime
      }

      let canJump = !isCrouching && (onFloor || coyoteTimer > 0 || isOnWall || hasDoubleJump)

      if jumpBufferTimer > 0, canJump {
        if isOnWall {
          vel.y = -config.movement.wallJumpVerticalSpeed
          vel.x = player.getWallNormal().x * config.movement.wallJumpSpeed
          facing = vel.x > 0 ? .right : .left
        } else if hasDoubleJump, !onFloor {
          vel.y = -config.movement.jumpSpeed
          hasDoubleJump = false
        } else {
          vel.y = -config.movement.jumpSpeed
        }
        action = .jumping
        jumpBufferTimer = 0
        coyoteTimer = 0
        playerScale = [0.6, 1.4]
        GameEvent.jumped(position: position + [3, 8]).emit()
      }

      // Variable jump height
      if Action("jump").isJustReleased, action == .jumping, vel.y < 0 {
        vel.y = max(vel.y, -config.movement.minJumpSpeed)
      }

      // Update action state
      if action != .dashing {
        if isOnWall && !onFloor && vel.y > 0 {
          action = .wallSliding
        } else if !onFloor {
          action = vel.y < 0 ? .jumping : .falling
        } else if input != 0 {
          action = .walking
        } else {
          action = .idle
        }
      }

      return vel
    }

    func handleInput(_ onFloor: Bool) {
      // Door entry
      if Action("move_up").isJustPressed, let targetRef = vm.currentDoorTargetRef, onFloor {
        if targetRef.levelIid != vm.currentLevelIid {
          GameEvent.enterCrossLevelDoor(targetLevelIid: targetRef.levelIid, targetEntityIid: targetRef.entityIid).emit()
        } else {
          GameEvent.enterDoor(targetEntityIid: targetRef.entityIid).emit()
        }
      }

      // Weapon switching
      if Action("switch_weapon").isJustPressed {
        vm.currentWeapon = vm.currentWeapon == .melee ? .ranged : .melee
        GameEvent.weaponSwitched(weaponType: vm.currentWeapon).emit()
      }

      // Attack
      if Action("attack").isJustPressed, attackPhase == .idle {
        if vm.currentWeapon == .melee {
          startAttack()
        } else if vm.consumeAmmo() {
          let projectilePos = position + [6, 4]
          let direction: Vector2 = [facing.sign, 0]
          GameEvent.projectileFired(position: projectilePos, direction: direction).emit()
        }
      }
    }

    func startAttack() {
      attackPhase = .startup
      attackPhaseTimer = weaponConfig.startupTime
      overlay.insert(.attacking)
    }

    func advanceAttackPhase() {
      switch attackPhase {
      case .startup:
        attackPhase = .active
        attackPhaseTimer = weaponConfig.activeTime
        GameEvent.attacked(position: position, facing: facing).emit()
      case .active:
        attackPhase = .recovery
        attackPhaseTimer = weaponConfig.recoveryTime
      case .recovery:
        attackPhase = .idle
        attackPhaseTimer = 0
        overlay.remove(.attacking)
      case .idle:
        break
      }
    }

    func applyMovement(_ player: CharacterBody2D, _ vel: Vector2, _ delta: Double, _ onFloor: Bool) {
      let wasInAir = !wasOnFloor
      let fallingVelocity = vel.y

      player.velocity = vel
      player.moveAndSlide()

      velocity = player.velocity
      position = player.position

      // Coyote time
      if onFloor {
        coyoteTimer = config.movement.coyoteTime
        hasDoubleJump = true
        if action == .jumping || action == .falling {
          action = .idle
        }
      } else if coyoteTimer > 0 {
        coyoteTimer -= delta
      }

      // Landing impact
      if wasInAir, player.isOnFloor(), fallingVelocity > 100 {
        playerScale = [1.3, 0.8]
        visualOffset = [0, 8 * (1 - 0.8) / 2]
        GameEvent.landed(position: position + [3, 8], impact: Float(fallingVelocity)).emit()
      }
      wasOnFloor = player.isOnFloor()

      // Keep in bounds
      if position.x < 0 {
        position.x = 0
        player.position = position
      } else if position.x > levelWidth - 6 {
        position.x = levelWidth - 6
        player.position = position
      }

      // Fall off screen = die
      let viewportHeight = player.getViewportRect().size.y
      if position.y > viewportHeight + 100 {
        takeDamage(vm.playerHealth)
      }
    }

    func updateVisualEffects(_ delta: Double) {
      let normalScale: Vector2 = [1, 1]
      if playerScale != normalScale {
        playerScale = playerScale.lerp(to: normalScale, weight: 12.0 * delta)
        if abs(playerScale.x - 1.0) < 0.01 && abs(playerScale.y - 1.0) < 0.01 {
          playerScale = normalScale
        }
      }

      if visualOffset != .zero {
        visualOffset = visualOffset.lerp(to: .zero, weight: 12.0 * delta)
        if visualOffset.length() < 0.01 {
          visualOffset = .zero
        }
      }

      if playerRotation != 0 {
        playerRotation *= Float(1.0 - 8.0 * delta)
        if abs(playerRotation) < 0.01 {
          playerRotation = 0
        }
      }
    }

    func updateTimers(_ delta: Double) {
      // Invincibility timer
      if overlay.contains(.invincible) {
        invincibilityTimer -= delta
        if invincibilityTimer <= 0 {
          overlay.remove(.invincible)
          invincibilityTimer = 0
        }
      }

      // Attack phase timer
      if attackPhase != .idle {
        attackPhaseTimer -= delta
        if attackPhaseTimer <= 0 {
          advanceAttackPhase()
        }
      }

      // Hit animation timer (damage state)
      if damage == .hit {
        hitTimer -= delta
        if hitTimer <= 0 {
          damage = .normal
          hitTimer = 0
        }
      }

      // Jump buffer timer
      if jumpBufferTimer > 0 {
        jumpBufferTimer -= delta
      }

      // Dash timer
      if action == .dashing {
        dashTimer -= delta
        if dashTimer <= 0 {
          action = .idle
          dashTimer = 0
        }
      }

      // Dash cooldown timer
      if dashCooldownTimer > 0 {
        dashCooldownTimer -= delta
      }
    }

    func takeDamage(_ amount: Int) {
      guard !overlay.contains(.invincible) else { return }

      vm.playerHealth -= amount
      damage = .hit
      hitTimer = config.combat.hitAnimDuration

      if vm.playerHealth <= 0 {
        vm.playerHealth = 0
        damage = .dead

        // Spin rotation effect on death
        playerRotation = Float.pi * 4 // 2 full rotations

        GameEvent.playerDied(position: position + [3, 4.5]).emit()
      } else {
        overlay.insert(.invincible)
        invincibilityTimer = config.combat.invincibilityDuration

        // Quick rotation wobble on damage
        playerRotation = Float.pi / 8 // 22.5 degrees
      }
    }

    func respawn() {
      position = spawnPoint
      velocity = [0, 0]
      vm.playerHealth = config.combat.maxHealth

      // Reset state
      action = .idle
      damage = .normal
      facing = .right
      overlay = [.invincible]
      invincibilityTimer = config.combat.invincibilityDuration

      // Reset detection flags
      isOnWall = false
      isInWater = false

      // Reset resources
      hasDoubleJump = true

      // Reset attack state
      attackPhase = .idle
      attackPhaseTimer = 0

      // Reset timers
      hitTimer = 0
      coyoteTimer = 0
      jumpBufferTimer = 0
      dashTimer = 0
      dashCooldownTimer = 0
      dashDirection = .zero

      // Reset visual feedback
      playerScale = [1, 1]
      playerRotation = 0
      visualOffset = .zero
    }

    /// Teleport player to a specific position (used for doorway teleportation)
    func teleportTo(_ targetPosition: Vector2) {
      position = targetPosition
      velocity = [0, 0]
      vm.currentDoorIid = nil
      vm.currentDoorTargetRef = nil

      // Reset movement state
      action = .idle
      coyoteTimer = 0
      jumpBufferTimer = 0
    }

    /// Check if there's enough room above the player to stand up from crouching
    func canStandUp(_ player: CharacterBody2D) -> Bool {
      guard let spaceState = player.getWorld2d()?.directSpaceState else {
        return true // If we can't check, assume we can stand
      }

      // Check both left and right edges to handle partial overlap with platforms
      let crouchedHeight = size.y / 2
      let crouchedTop = size.y - crouchedHeight // Where crouched head is
      let standingTop: Float = 0 // Where standing head would be
      let margin = size.x * 0.25 // Inset from edges

      // Left edge ray
      let leftStart = position + [margin, crouchedTop]
      let leftEnd = position + [margin, standingTop]
      if spaceState.raycast(from: leftStart, to: leftEnd, mask: 1, excluding: player) != nil {
        return false
      }

      // Right edge ray
      let rightStart = position + [size.x - margin, crouchedTop]
      let rightEnd = position + [size.x - margin, standingTop]
      if spaceState.raycast(from: rightStart, to: rightEnd, mask: 1, excluding: player) != nil {
        return false
      }

      return true
    }
  }
}
