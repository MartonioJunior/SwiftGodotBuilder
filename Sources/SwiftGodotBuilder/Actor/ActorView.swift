import Foundation
import SwiftGodot

// MARK: - Collision Layers Config

/// Configuration for all physics collision layers used by ActorView
public struct ActorCollisionLayers: Sendable {
  public let player: Physics2DLayer
  public let enemyHurtbox: Physics2DLayer
  public let playerHurtbox: Physics2DLayer
  public let enemyAttack: Physics2DLayer
  public let playerAttack: Physics2DLayer
  public let terrain: Physics2DLayer
  public let collectible: Physics2DLayer
  public let interaction: Physics2DLayer

  public init(
    player: Physics2DLayer,
    enemyHurtbox: Physics2DLayer,
    playerHurtbox: Physics2DLayer,
    enemyAttack: Physics2DLayer,
    playerAttack: Physics2DLayer,
    terrain: Physics2DLayer,
    collectible: Physics2DLayer,
    interaction: Physics2DLayer
  ) {
    self.player = player
    self.enemyHurtbox = enemyHurtbox
    self.playerHurtbox = playerHurtbox
    self.enemyAttack = enemyAttack
    self.playerAttack = playerAttack
    self.terrain = terrain
    self.collectible = collectible
    self.interaction = interaction
  }
}

// MARK: - View State

/// Mutable state for ActorView (avoids reactive overhead)
final class ActorViewState {
  var deathHandled = false
}

/// Composable actor view - player uses controller, AI uses behaviors
public struct ActorView<Content: GView>: GView {
  @ObservableState public var state: ActorState
  @ObservableState public var weaponState: ActorWeaponState
  public let controller: ActorController?
  public let behaviors: [ActorBehavior]
  public let behaviorState: ActorBehaviorState
  public let levelBounds: Vector2?
  public let currentLevelIid: String
  public let resolveDoorTarget: ((String) -> Vector2?)?
  public let children: Content

  // Callbacks for external systems (provide object references)
  public var onActorReady: ((ActorState) -> Void)?
  public var onWeaponStateReady: ((ActorWeaponState) -> Void)?

  // Health bar configuration (nil = no health bar)
  public let healthBar: HealthBarConfig?

  // Physics layers for collision (required - no defaults)
  public let collisionLayers: ActorCollisionLayers

  // Convenience accessors
  private var playerLayer: Physics2DLayer { collisionLayers.player }
  private var enemyHurtboxLayer: Physics2DLayer { collisionLayers.enemyHurtbox }
  private var playerHurtboxLayer: Physics2DLayer { collisionLayers.playerHurtbox }
  private var enemyAttackLayer: Physics2DLayer { collisionLayers.enemyAttack }
  private var playerAttackLayer: Physics2DLayer { collisionLayers.playerAttack }
  private var terrainLayer: Physics2DLayer { collisionLayers.terrain }
  private var collectibleLayer: Physics2DLayer { collisionLayers.collectible }
  private var interactionLayer: Physics2DLayer { collisionLayers.interaction }

  // Internal state
  private let viewState = ActorViewState()

  // World physics (passed from level/project state)
  public let worldGravity: Float

  public init(
    entity: LDEntity,
    spriteAsset: String,
    animations: ActorAnimations,
    collisionLayers: ActorCollisionLayers,
    healthBar: HealthBarConfig? = nil,
    controller: ActorController? = nil,
    behaviors: [ActorBehavior] = [],
    physics: ActorPhysics = ActorPhysics(),
    combat: ActorCombat = ActorCombat(),
    capabilities: ActorCapabilities = .enemy,
    collisionConfig: ActorCollisionConfig = ActorCollisionConfig(),
    startingItems: [String] = [],
    startingWeapons: [ActorWeapon] = [],
    worldGravity: Float = 400,
    levelBounds: Vector2? = nil,
    currentLevelIid: String = "",
    resolveDoorTarget: ((String) -> Vector2?)? = nil,
    npcTypeId: String? = nil,
    displayName: String? = nil,
    @GViewBuilder content: () -> Content
  ) {
    let actorState = ActorState(
      entity: entity,
      spriteAsset: spriteAsset,
      animations: animations,
      physics: physics,
      combat: combat,
      capabilities: capabilities,
      collisionConfig: collisionConfig,
      startingItems: startingItems,
      npcTypeId: npcTypeId,
      displayName: displayName
    )
    _state = ObservableState(wrappedValue: actorState)
    _weaponState = ObservableState(wrappedValue: ActorWeaponState(weapons: startingWeapons))
    self.collisionLayers = collisionLayers
    self.healthBar = healthBar
    self.controller = controller
    self.behaviors = behaviors
    behaviorState = ActorBehaviorState()
    self.worldGravity = worldGravity
    self.levelBounds = levelBounds
    self.currentLevelIid = currentLevelIid
    self.resolveDoorTarget = resolveDoorTarget
    children = content()
  }

  /// Alternative init for spawner-created actors (no LDEntity required)
  public init(
    spawnPosition: Vector2,
    size: Vector2,
    spriteAsset: String,
    animations: ActorAnimations,
    collisionLayers: ActorCollisionLayers,
    healthBar: HealthBarConfig? = nil,
    controller: ActorController? = nil,
    behaviors: [ActorBehavior] = [],
    physics: ActorPhysics = ActorPhysics(),
    combat: ActorCombat = ActorCombat(),
    capabilities: ActorCapabilities = .enemy,
    collisionConfig: ActorCollisionConfig = ActorCollisionConfig(),
    startingItems: [String] = [],
    startingWeapons: [ActorWeapon] = [],
    worldGravity: Float = 400,
    @GViewBuilder content: () -> Content
  ) {
    let actorState = ActorState(
      spawnPosition: spawnPosition,
      size: size,
      spriteAsset: spriteAsset,
      animations: animations,
      physics: physics,
      combat: combat,
      capabilities: capabilities,
      collisionConfig: collisionConfig,
      startingItems: startingItems
    )
    _state = ObservableState(wrappedValue: actorState)
    _weaponState = ObservableState(wrappedValue: ActorWeaponState(weapons: startingWeapons))
    self.collisionLayers = collisionLayers
    self.healthBar = healthBar
    self.controller = controller
    self.behaviors = behaviors
    behaviorState = ActorBehaviorState()
    self.worldGravity = worldGravity
    levelBounds = nil
    currentLevelIid = ""
    resolveDoorTarget = nil
    children = content()
  }

  private var actor: ActorState { state }
  private var weapons: ActorWeaponState { weaponState }

  // Collision size helpers
  private var terrainCollisionSize: Vector2 {
    actor.collisionConfig.size(for: actor.collisionSize, type: .terrain)
  }

  // Effective gravity (actor override or world default)
  private var effectiveGravity: Float {
    actor.physics.gravity ?? worldGravity
  }
}

// MARK: - Builder Methods

extension ActorView {
  public func onActorReady(_ handler: @escaping (ActorState) -> Void) -> Self {
    var copy = self
    copy.onActorReady = handler
    return copy
  }

  public func onWeaponStateReady(_ handler: @escaping (ActorWeaponState) -> Void) -> Self {
    var copy = self
    copy.onWeaponStateReady = handler
    return copy
  }

  public var body: some GView {
    CharacterBody2D$ {
      // Sprite with attack phase colors
      ActorSprite(state: $state, weaponState: $weaponState)

      // Physics collision shape (with terrain adjustment)
      CollisionShape2D$()
        .shape(RectangleShape2D(size: terrainCollisionSize))
        .position(actor.collisionOffset)

      // Combat components (conditional based on capabilities)
      if actor.combat.canReceiveDamage {
        ActorHurtBox(
          state: $state,
          collisionLayer: actor.capabilities.contains(.canCollectItems) ? playerHurtboxLayer : enemyHurtboxLayer
        )
      }

      if actor.combat.canDealTouchDamage {
        ActorTouchDamage(
          state: $state,
          collisionLayer: enemyAttackLayer,
          collisionMask: playerHurtboxLayer
        )
      }

      // Item collector
      if actor.capabilities.contains(.canCollectItems) {
        ActorCollector(state: $state, weaponState: $weaponState, collectibleMask: collectibleLayer)
      }

      // Door interaction
      if actor.capabilities.contains(.canUseDoors) {
        ActorDoorInteraction(
          state: $state,
          currentLevelIid: currentLevelIid,
          resolveDoorTarget: resolveDoorTarget
        )
      }

      // Melee attack hitbox (always created if actor can attack - handles no weapon gracefully)
      if actor.capabilities.contains(.canAttack) {
        ActorWeaponHitbox(
          actorState: $state,
          weaponState: $weaponState,
          attackLayer: actor.capabilities.contains(.canCollectItems) ? playerAttackLayer : enemyAttackLayer,
          targetMask: actor.capabilities.contains(.canCollectItems) ? enemyHurtboxLayer : playerHurtboxLayer
        )
      }

      // Interaction area (makes actor detectable by interactables)
      if actor.capabilities.contains(.canInteract) {
        ActorInteractionArea(state: $state, interactionLayer: interactionLayer)
      }

      // Interactable zone (makes this actor interactable by others)
      if actor.capabilities.contains(.canBeInteracted) {
        ActorInteractableZone(state: $state, interactionLayer: interactionLayer)
        ActorNameLabel(state: $state)
      }

      // Health bar (optional)
      if let config = healthBar {
        ActorHealthBar(state: $state, config: config)
      }

      // User-provided children (e.g., camera)
      children
    }
    .collisionLayer(actor.capabilities.contains(.canCollectItems) ? playerLayer : enemyHurtboxLayer)
    .collisionMask(terrainLayer)
    .floorSnapLength(4)
    .onReady { node in
      node.position = actor.position
      actor.bodyInstanceId = Int(node.getInstanceId())
      onActorReady?(actor)
      onWeaponStateReady?(weaponState)
    }
    .onEvent(ActorEvent.self) { _, event in
      handleActorEvent(event)
    }
    .onProcess { body, delta in
      updateActor(body: body, delta: delta)
    }
  }

  // MARK: - Update Loop

  private func updateActor(body: CharacterBody2D, delta: Double) {
    // Handle pending teleport - sync body position from actor state
    if actor.pendingTeleport {
      body.position = actor.position
      body.velocity = .zero
      actor.pendingTeleport = false
    }

    // Skip processing when dying
    if actor.isDying {
      viewState.deathHandled = true
      return
    }

    // Update controller (for player) or behaviors (for AI)
    if let ctrl = controller {
      ctrl.update(actor: actor, delta: delta)
    }
    updateBehaviors(body: body, delta: delta)

    // Update timers
    actor.updateTimers(delta)
    actor.updateVisuals(delta)
    updateWeaponTimer(delta)

    // Get input from controller or behaviors
    let movementInput = controller?.getMovementInput() ?? actor.movementInput

    // Handle crouch (before physics, affects speed)
    handleCrouch(body: body)

    // Handle dash (overrides normal movement)
    if handleDash() {
      applyDashMovement(body: body)
    } else if actor.isInWater {
      applyWaterMovement(body: body, input: movementInput, delta: delta)
    } else {
      applyNormalMovement(body: body, input: movementInput, delta: delta)
    }

    // Handle jump input (buffering)
    handleJumpInput()

    // Try to execute buffered jump
    tryJump(body: body)

    // Variable jump height
    handleVariableJump()

    // Handle attack
    handleAttack(body: body)

    // Handle weapon switching
    handleWeaponSwitch()

    // Update facing direction based on movement (not during attack)
    if movementInput != 0, !weapons.phase.isAttacking {
      actor.facing = movementInput > 0 ? .right : .left
    }

    // Post-physics updates
    applyPhysicsResult(body: body, delta: delta)

    // Update animation
    updateAnimation()

    // Sync position
    actor.position = body.position
  }

  // MARK: - Behavior Processing

  private func updateBehaviors(body: CharacterBody2D, delta: Double) {
    guard !behaviors.isEmpty else { return }

    // Always reset behavior-driven inputs
    actor.movementInput = 0
    actor.wantsJump = false

    // Don't process behaviors when stunned or dying
    guard !actor.isStunned, !actor.isDying else { return }

    for behavior in behaviors {
      switch behavior {
      case let .pathPatrol(config):
        updatePathPatrol(config: config)

      case let .arenaPatrol(config):
        updateArenaPatrol(config: config, body: body)

      case let .sineWave(config):
        updateSineWave(config: config, body: body, delta: delta)

      case let .charge(config):
        updateCharge(config: config, body: body)

      case let .attackPatterns(config):
        updateAttackPatterns(config: config, delta: delta)

      case let .shoot(config):
        updateShoot(config: config, delta: delta)
      }
    }

    // Apply jump from behaviors
    if actor.wantsJump {
      actor.jumpBufferTimer = actor.physics.jumpBufferTime
    }
  }

  private func updatePathPatrol(config: ActorPathPatrol) {
    let halfWidth = actor.collisionSize.x / 2
    if actor.position.x - halfWidth <= config.leftBound {
      behaviorState.patrolDirection = 1
    } else if actor.position.x + halfWidth >= config.rightBound {
      behaviorState.patrolDirection = -1
    }
    actor.movementInput = behaviorState.patrolDirection
  }

  private func updateArenaPatrol(config: ActorArenaPatrol, body _: CharacterBody2D) {
    if behaviorState.isCharging { return }

    let halfWidth = actor.collisionSize.x / 2
    if actor.position.x - halfWidth <= config.leftBound {
      actor.position.x = config.leftBound + halfWidth
      behaviorState.arenaDirection = 1
    } else if actor.position.x + halfWidth >= config.rightBound {
      actor.position.x = config.rightBound - halfWidth
      behaviorState.arenaDirection = -1
    }

    let phaseSpeed = config.speed(forPhase: actor.phase)
    if actor.physics.speed > 0 {
      actor.movementInput = behaviorState.arenaDirection * (phaseSpeed / actor.physics.speed)
    } else {
      actor.movementInput = behaviorState.arenaDirection
    }
  }

  private func updateSineWave(config: ActorSineWave, body: CharacterBody2D, delta: Double) {
    behaviorState.sineTimer += delta
    let baseY = config.baseY ?? actor.spawnPosition.y
    body.position.y = baseY + sin(Float(behaviorState.sineTimer * config.frequency)) * config.amplitude
  }

  private func updateCharge(config: ActorCharge, body _: CharacterBody2D) {
    guard behaviorState.isCharging else { return }
    guard actor.physics.speed > 0 else {
      behaviorState.isCharging = false
      return
    }

    actor.movementInput = behaviorState.chargeDirection * (config.speed / actor.physics.speed)

    var hitWall = false
    var hitLeft = false
    let halfWidth = actor.collisionSize.x / 2

    // Check arena patrol bounds
    for behavior in behaviors {
      if case let .arenaPatrol(arenaConfig) = behavior {
        hitLeft = actor.position.x - halfWidth <= arenaConfig.leftBound
        let hitRight = actor.position.x + halfWidth >= arenaConfig.rightBound
        hitWall = hitLeft || hitRight
        if hitWall {
          behaviorState.arenaDirection = hitLeft ? 1 : -1
        }
        break
      }
    }

    // Fall back to path patrol bounds
    if !hitWall {
      for behavior in behaviors {
        if case let .pathPatrol(patrolConfig) = behavior {
          hitLeft = actor.position.x - halfWidth <= patrolConfig.leftBound
          let hitRight = actor.position.x + halfWidth >= patrolConfig.rightBound
          hitWall = hitLeft || hitRight
          if hitWall {
            behaviorState.patrolDirection = hitLeft ? 1 : -1
          }
          break
        }
      }
    }

    // Fall back to physics wall detection
    if !hitWall, actor.isOnWall {
      hitWall = true
      hitLeft = behaviorState.chargeDirection < 0
    }

    if hitWall {
      behaviorState.isCharging = false
      if config.stunOnWallHit {
        actor.stun(config.wallStunDuration)
      }
    }
  }

  private func updateAttackPatterns(config: ActorAttackPatterns, delta: Double) {
    if behaviorState.attackTimers.count != config.patterns.count {
      behaviorState.attackTimers = config.patterns.map { $0.baseCooldown }
    }

    for i in behaviorState.attackTimers.indices {
      behaviorState.attackTimers[i] -= delta
    }

    for (i, pattern) in config.patterns.enumerated() {
      guard behaviorState.attackTimers[i] <= 0, actor.phase >= pattern.minPhase else { continue }

      executeAttack(pattern.type)
      behaviorState.attackTimers[i] = pattern.cooldown(forPhase: actor.phase)
      break
    }
  }

  private func executeAttack(_ type: ActorAttackType) {
    switch type {
    case .shoot:
      let pos = actor.position + [actor.collisionSize.x / 2, -actor.collisionSize.y / 2]
      let dir: Vector2 = [actor.facing.sign, 0]
      ActorBehaviorEvent.shoot(actorId: actor.id, position: pos, direction: dir).emit()

    case .jump:
      actor.wantsJump = true

    case .charge:
      behaviorState.isCharging = true
      behaviorState.chargeDirection = actor.facing.sign

    case .summon:
      ActorBehaviorEvent.summon(actorId: actor.id, position: actor.position).emit()
    }
  }

  private func updateShoot(config: ActorShoot, delta: Double) {
    if behaviorState.shootTimer == 0 {
      behaviorState.shootTimer = config.interval
    }
    behaviorState.shootTimer -= delta
    if behaviorState.shootTimer <= 0 {
      behaviorState.shootTimer = config.interval

      if let rangedWeapon = weapons.weapons.first(where: { $0.type == .ranged }),
         let rangedConfig = rangedWeapon.ranged
      {
        let pos = actor.position + config.projectileOffset + [actor.collisionSize.x / 2, -actor.collisionSize.y / 2]
        let dir: Vector2 = [actor.facing.sign, 0]
        ActorEvent.projectileFired(
          actorId: actor.id,
          position: pos,
          direction: dir,
          config: rangedConfig
        ).emit()
      }
    }
  }

  // MARK: - Weapons

  private func updateWeaponTimer(_ delta: Double) {
    guard actor.capabilities.contains(.canAttack), weapons.hasWeapon else { return }

    if let newPhase = weapons.updateTimer(delta) {
      if newPhase == .active {
        let hitboxCenter = actor.position + [0, -actor.collisionSize.y / 2]
        ActorAttackEvent.attackStarted(
          actorId: actor.id,
          position: actor.position,
          facing: actor.facing
        ).emit()
        ActorEvent.meleeAttacked(actorId: actor.id, position: hitboxCenter, facing: actor.facing).emit()
      } else if newPhase == .idle {
        ActorAttackEvent.attackEnded(actorId: actor.id).emit()
      }
    }
  }

  private func handleWeaponSwitch() {
    guard actor.capabilities.contains(.canAttack), weapons.weapons.count > 1 else { return }

    if controller?.wantsToSwitchWeapon() == true {
      weapons.switchToNext()
      if let weapon = weapons.currentWeapon {
        ActorWeaponEvent.weaponSwitched(actorId: actor.id, weapon: weapon).emit()
      }
      return
    }

    if let ctrl = controller, let preferredId = ctrl.preferredWeapon(actor: actor, targetDistance: nil) {
      if weapons.currentWeapon?.id != preferredId, weapons.switchTo(weaponId: preferredId) {
        if let weapon = weapons.currentWeapon {
          ActorWeaponEvent.weaponSwitched(actorId: actor.id, weapon: weapon).emit()
        }
      }
    }
  }

  private func handleAttack(body: CharacterBody2D) {
    guard actor.capabilities.contains(.canAttack), weapons.hasWeapon else { return }
    guard controller?.wantsToAttack() == true, weapons.phase == .idle else { return }
    guard let weapon = weapons.currentWeapon else { return }

    switch weapon.type {
    case .melee:
      weapons.startMeleeAttack()

    case .ranged:
      if let rangedConfig = weapon.ranged, weapons.consumeAmmo() {
        fireProjectile(body: body, config: rangedConfig)

        ActorWeaponEvent.ammoChanged(
          actorId: actor.id,
          weaponId: weapon.id,
          current: weapons.currentAmmo,
          max: weapons.currentMaxAmmo
        ).emit()

        if weapons.currentAmmo == 0, !weapon.infiniteAmmo {
          ActorWeaponEvent.ammoEmpty(actorId: actor.id, weaponId: weapon.id).emit()
        }
      }

    case .unarmed:
      break
    }
  }

  private func fireProjectile(body: CharacterBody2D, config: ActorRangedConfig) {
    let xOffset: Float = actor.facing == .right ? actor.collisionSize.x / 2 : -actor.collisionSize.x / 2
    let yOffset: Float = -actor.collisionSize.y / 2
    let projectilePos = body.position + [xOffset, yOffset]
    let direction: Vector2 = [actor.facing.sign, 0]

    ActorEvent.projectileFired(
      actorId: actor.id,
      position: projectilePos,
      direction: direction,
      config: config
    ).emit()
  }

  // MARK: - Dash

  private func handleDash() -> Bool {
    guard actor.capabilities.contains(.canDash) else { return false }

    if controller?.wantsToDash() == true, actor.dashCooldownTimer <= 0, !actor.isInWater {
      actor.action = .dashing
      actor.dashTimer = actor.physics.dashDuration
      actor.dashCooldownTimer = actor.physics.dashCooldown
      actor.dashDirection = [actor.facing.sign, 0]
    }

    return actor.action == .dashing
  }

  private func applyDashMovement(body: CharacterBody2D) {
    body.velocity = actor.dashDirection * actor.physics.dashSpeed
    body.moveAndSlide()
    actor.velocity = body.velocity
  }

  // MARK: - Water Movement

  private func applyWaterMovement(body: CharacterBody2D, input: Float, delta: Double) {
    var vel = actor.velocity
    actor.action = .swimming

    vel.y += effectiveGravity * Float(delta) * actor.physics.waterGravityMultiplier
    vel.y = min(vel.y, actor.physics.waterMaxFallSpeed)

    if controller?.wantsToJump() == true || actor.wantsJump {
      vel.y = -actor.physics.swimSpeed
    }

    if controller?.wantsToCrouch() == true {
      vel.y = min(vel.y + effectiveGravity * Float(delta), actor.physics.waterMaxFallSpeed * 2)
    }

    vel.x = input * actor.physics.speed * actor.physics.waterMoveSpeedMultiplier

    actor.hasDoubleJump = true
    actor.isCrouching = false

    body.velocity = vel
    body.moveAndSlide()
    actor.velocity = body.velocity
    actor.isOnFloor = body.isOnFloor()
    actor.isOnWall = body.isOnWall()
  }

  // MARK: - Normal Movement

  private func applyNormalMovement(body: CharacterBody2D, input: Float, delta: Double) {
    let onWall = body.isOnWall()
    var vel = actor.velocity

    if onWall, vel.y > 0, actor.capabilities.contains(.canWallJump) {
      vel.y += effectiveGravity * Float(delta) * actor.physics.wallSlideGravityMultiplier
    } else {
      vel.y += effectiveGravity * Float(delta)
    }

    if actor.capabilities.contains(.canMove) {
      let speed = actor.isCrouching
        ? actor.physics.speed * actor.physics.crouchSpeedMultiplier
        : actor.physics.speed
      vel.x = input * speed
    }

    body.velocity = vel
    body.moveAndSlide()
    actor.velocity = body.velocity
    actor.isOnFloor = body.isOnFloor()
    actor.isOnWall = body.isOnWall()
  }

  // MARK: - Crouch

  private func handleCrouch(body: CharacterBody2D) {
    guard actor.capabilities.contains(.canCrouch) else { return }

    let onFloor = body.isOnFloor()
    let wantsToCrouch = controller?.wantsToCrouch() == true

    if wantsToCrouch, onFloor {
      actor.isCrouching = true
    } else if !wantsToCrouch, actor.isCrouching, canStandUp(body: body) {
      actor.isCrouching = false
    }
  }

  private func canStandUp(body: CharacterBody2D) -> Bool {
    guard actor.isCrouching else { return true }

    let space = body.getWorld2d()?.directSpaceState
    let standingHeight = actor.collisionSize.y
    let crouchedHeight = standingHeight * 0.5
    let standingTop = -standingHeight
    let crouchedTop = -crouchedHeight

    for xOffset: Float in [-actor.collisionSize.x / 2 + 1, 0, actor.collisionSize.x / 2 - 1] {
      let start = body.position + [xOffset, crouchedTop]
      let end = body.position + [xOffset, standingTop]
      let query = PhysicsRayQueryParameters2D.create(from: start, to: end)
      query?.collisionMask = UInt32(terrainLayer.rawValue)
      if let result = space?.intersectRay(parameters: query!), result.collider != nil {
        return false
      }
    }
    return true
  }

  // MARK: - Jump

  private func handleJumpInput() {
    guard actor.capabilities.contains(.canJump) else { return }

    if controller?.wantsToJump() == true {
      actor.jumpBufferTimer = actor.physics.jumpBufferTime
    }
  }

  private func tryJump(body: CharacterBody2D) {
    guard actor.capabilities.contains(.canJump) else { return }
    guard actor.jumpBufferTimer > 0 else { return }
    guard !actor.isCrouching else { return }

    let onFloor = actor.isOnFloor
    let onWall = actor.isOnWall
    let canCoyoteJump = actor.coyoteTimer > 0
    let canWallJump = onWall && actor.capabilities.contains(.canWallJump)
    let canDoubleJump = actor.hasDoubleJump && actor.capabilities.contains(.canDoubleJump) && !onFloor

    guard onFloor || canCoyoteJump || canWallJump || canDoubleJump else { return }

    var vel = actor.velocity

    if canWallJump, !onFloor {
      vel.y = -actor.physics.wallJumpVerticalSpeed
      vel.x = body.getWallNormal().x * actor.physics.wallJumpSpeed
      actor.facing = vel.x > 0 ? .right : .left
    } else if canDoubleJump, !onFloor, !canCoyoteJump {
      vel.y = -actor.physics.jumpSpeed
      actor.hasDoubleJump = false
    } else {
      vel.y = -actor.physics.jumpSpeed
    }

    body.velocity = vel
    actor.velocity = vel
    actor.action = .jumping
    actor.jumpBufferTimer = 0
    actor.coyoteTimer = 0
    actor.applyJumpSquash()
    ActorEvent.jumped(actorId: actor.id, position: body.position).emit()
  }

  private func handleVariableJump() {
    guard actor.capabilities.contains(.canJump) else { return }

    if controller?.jumpReleased() == true, actor.action == .jumping, actor.velocity.y < 0 {
      actor.velocity.y = max(actor.velocity.y, -actor.physics.minJumpSpeed)
    }
  }

  // MARK: - Post-Physics

  private func applyPhysicsResult(body: CharacterBody2D, delta: Double) {
    let onFloor = actor.isOnFloor
    let fallingVelocity = actor.velocity.y

    if onFloor {
      actor.coyoteTimer = actor.physics.coyoteTime
      actor.hasDoubleJump = true
      if actor.action == .jumping || actor.action == .falling {
        actor.action = .idle
      }
    } else if actor.coyoteTimer > 0 {
      actor.coyoteTimer -= delta
    }

    let justLanded = !actor.wasOnFloor && onFloor && fallingVelocity > 100
    if justLanded {
      actor.applyLandSquash()
      ActorEvent.landed(actorId: actor.id, position: body.position, impact: fallingVelocity).emit()
    }
    actor.wasOnFloor = onFloor

    if let bounds = levelBounds {
      let halfWidth = actor.collisionSize.x / 2
      if body.position.x < halfWidth {
        body.position.x = halfWidth
      } else if body.position.x > bounds.x - halfWidth {
        body.position.x = bounds.x - halfWidth
      }
    }

    if let bounds = levelBounds, body.position.y > bounds.y + 50 {
      actor.takeDamage(actor.health, from: body.position)
    }

    if actor.action != .dashing, actor.action != .swimming {
      let onWall = actor.isOnWall
      if onWall, !onFloor, actor.velocity.y > 0, actor.capabilities.contains(.canWallJump) {
        actor.action = .wallSliding
      } else if !onFloor {
        actor.action = actor.velocity.y < 0 ? .jumping : .falling
      } else if abs(actor.velocity.x) > 0.1 {
        actor.action = .walking
      } else {
        actor.action = .idle
      }
    }
  }

  // MARK: - Animation

  private func updateAnimation() {
    let newAnim = actor.animations.animation(
      action: actor.action,
      isAttacking: weapons.phase.isAttacking,
      isDying: actor.isDying,
      isHit: actor.isHit,
      isCrouching: actor.isCrouching,
      weaponLayer: weapons.currentWeapon?.spriteLayer
    )

    if newAnim != actor.animationName {
      actor.animationName = newAnim
    }
  }

  // MARK: - Event Handling

  private func handleActorEvent(_ event: ActorEvent) {
    switch event {
    case let .enteredZone(bodyInstanceId, zone) where bodyInstanceId == actor.bodyInstanceId:
      handleZoneEntered(zone)
    case let .exitedZone(bodyInstanceId, zone) where bodyInstanceId == actor.bodyInstanceId:
      handleZoneExited(zone)
    case let .reset(actorId) where actorId == actor.id:
      actor.resetState()
      weaponState.reset()
      behaviorState.reset()
      viewState.deathHandled = false
    default:
      break
    }
  }

  private func handleZoneEntered(_ zone: String) {
    switch zone {
    case "water":
      actor.isInWater = true
    case "damage":
      actor.takeDamage(1, from: actor.position)
    case "kill":
      actor.takeDamage(actor.combat.maxHealth, from: actor.position)
    default:
      break
    }
  }

  private func handleZoneExited(_ zone: String) {
    switch zone {
    case "water":
      actor.isInWater = false
    default:
      break
    }
  }
}

// MARK: - Convenience initializers for ActorView without children

public extension ActorView where Content == EmptyGView {
  init(
    entity: LDEntity,
    spriteAsset: String,
    animations: ActorAnimations,
    collisionLayers: ActorCollisionLayers,
    healthBar: HealthBarConfig? = nil,
    controller: ActorController? = nil,
    behaviors: [ActorBehavior] = [],
    physics: ActorPhysics = ActorPhysics(),
    combat: ActorCombat = ActorCombat(),
    capabilities: ActorCapabilities = .enemy,
    collisionConfig: ActorCollisionConfig = ActorCollisionConfig(),
    startingItems: [String] = [],
    startingWeapons: [ActorWeapon] = [],
    worldGravity: Float = 400,
    levelBounds: Vector2? = nil,
    currentLevelIid: String = "",
    resolveDoorTarget: ((String) -> Vector2?)? = nil,
    npcTypeId: String? = nil,
    displayName: String? = nil
  ) {
    self.init(
      entity: entity,
      spriteAsset: spriteAsset,
      animations: animations,
      collisionLayers: collisionLayers,
      healthBar: healthBar,
      controller: controller,
      behaviors: behaviors,
      physics: physics,
      combat: combat,
      capabilities: capabilities,
      collisionConfig: collisionConfig,
      startingItems: startingItems,
      startingWeapons: startingWeapons,
      worldGravity: worldGravity,
      levelBounds: levelBounds,
      currentLevelIid: currentLevelIid,
      resolveDoorTarget: resolveDoorTarget,
      npcTypeId: npcTypeId,
      displayName: displayName
    ) {
      EmptyGView()
    }
  }

  init(
    spawnPosition: Vector2,
    size: Vector2,
    spriteAsset: String,
    animations: ActorAnimations,
    collisionLayers: ActorCollisionLayers,
    healthBar: HealthBarConfig? = nil,
    controller: ActorController? = nil,
    behaviors: [ActorBehavior] = [],
    physics: ActorPhysics = ActorPhysics(),
    combat: ActorCombat = ActorCombat(),
    capabilities: ActorCapabilities = .enemy,
    collisionConfig: ActorCollisionConfig = ActorCollisionConfig(),
    startingItems: [String] = [],
    startingWeapons: [ActorWeapon] = [],
    worldGravity: Float = 400
  ) {
    self.init(
      spawnPosition: spawnPosition,
      size: size,
      spriteAsset: spriteAsset,
      animations: animations,
      collisionLayers: collisionLayers,
      healthBar: healthBar,
      controller: controller,
      behaviors: behaviors,
      physics: physics,
      combat: combat,
      capabilities: capabilities,
      collisionConfig: collisionConfig,
      startingItems: startingItems,
      startingWeapons: startingWeapons,
      worldGravity: worldGravity
    ) {
      EmptyGView()
    }
  }
}
