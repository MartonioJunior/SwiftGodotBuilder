import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct PlayerActorView: GView {
    let entity: LDEntity
    let level: LDLevel
    let state: ObservableState<ProjectState>
    let player: ObservableState<PlayerGameState>
    let boss: ObservableState<BossState>
    let dialog: ObservableState<DialogGameState>
    let router: ObservableState<GameRouter>
    let progress: ObservableState<GameProgress>
    let particlePool: ParticlePool

    private let playerController = PlayerActorController()

    private final class ViewModel {
      var actor: ActorState?
      var weapons: ActorWeaponState?
      var actorId: Int = 0
    }

    private let vm = ViewModel()

    // MARK: - Computed Properties

    var ps: ProjectState { state.wrappedValue }
    var pgs: PlayerGameState { player.wrappedValue }
    var bs: BossState { boss.wrappedValue }
    var ds: DialogGameState { dialog.wrappedValue }
    var gp: GameProgress { progress.wrappedValue }

    var levelWidth: Float { Float(level.pxWid) }
    var levelHeight: Float { Float(level.pxHei) }

    // Player starting weapons from LDtk entity (weapon IDs)
    var startingWeaponIds: [String] {
      entity.field("weapons")?.asStringArray() ?? []
    }

    var playerStartingWeapons: [ActorWeapon] {
      startingWeaponIds.compactMap { WeaponRegistry.weapon(forId: $0) }
    }

    // Starting consumables (like key) from LDtk entity
    var startingConsumables: [ConsumableDefinition] {
      let types: [ConsumableType] = entity.field("consumables")?.asEnumArray() ?? []
      return types.map(\.definition)
    }

    var body: some GView {
      // Wrap in Node2D for event handling
      Node2D$ {
        ActorView(
          entity: entity,
          spriteAsset: "Hero",
          animations: .withWeaponPrefix(defaultLayer: "Unarmed"),
          collisionLayers: Chapter27.actorCollisionLayers,
          controller: playerController,
          physics: playerPhysics,
          combat: playerCombat,
          capabilities: .player,
          collisionConfig: playerCollisionConfig,
          startingItems: [],
          startingWeapons: playerStartingWeapons,
          worldGravity: ps.gravity,
          levelBounds: [levelWidth, levelHeight],
          currentLevelIid: level.iid,
          resolveDoorTarget: { entityIid in
            level.entity(iid: entityIid)?.positionTopLeft
          }
        ) {
          PlayerActorCamera(
            boss: boss,
            levelWidth: levelWidth,
            levelHeight: levelHeight
          )
        }
        .onActorReady { actor in
          vm.actorId = actor.id
          vm.actor = actor
        }
        .onWeaponStateReady { weaponState in
          vm.weapons = weaponState
          // Sync initial weapon to HUD
          if let weapon = weaponState.currentWeapon {
            pgs.syncWeapon(type: weapon.type == .melee ? .melee : .ranged, ammo: weaponState.currentAmmo)
          }
        }
      }
      .onReady { _ in
        GD.print("[PlayerActorView] Node2D ready")
        initializeSpawn(from: entity, levelIid: level.iid)
      }
      .onEvent(DialogEvent.self) { _, event in
        switch event {
        case let .npcInteracted(npcType):
          handleNPCInteracted(npcType: npcType)
        default:
          break
        }
      }
      .onEvent(GameEvent.self) { _, event in
        handleEvent(event, vm: vm)
      }
      .onEvent(ActorEvent.self) { _, event in
        switch event {
        case let .meleeHit(attackerId, targetId, hitPos, _, _, _) where attackerId == vm.actorId:
          applyHitstop()
          GameEvent.enemyHitByMelee(targetId: targetId, position: hitPos).emit()
        case let .died(id, _) where id == vm.actorId:
          if let actor = vm.actor {
            handlePlayerDeath(actor: actor)
          }
        case let .jumped(id, position) where id == vm.actorId:
          vm.actor?.scale = [0.6, 1.4]
          GameEvent.playerJumped(position: position).emit()
        case let .landed(id, position, impact) where id == vm.actorId:
          vm.actor?.scale = [1.3, 0.8]
          GameEvent.playerLanded(position: position, impact: impact).emit()
        case let .projectileFired(id, position, direction, _) where id == vm.actorId:
          GameEvent.projectileFired(position: position, direction: direction).emit()
        case let .tookDamage(id, damage, position) where id == vm.actorId:
          if let actor = vm.actor {
            actor.rotation = Float.pi / 8
            bs.shakeIntensity = 0.5
            pgs.syncHealth(actor.health)
            GameEvent.playerTookDamage(damage: damage, position: position).emit()
          }
        default:
          break
        }
      }
      .onEvent(ActorWeaponEvent.self) { _, event in
        switch event {
        case let .weaponSwitched(id, weapon) where id == vm.actorId:
          pgs.syncWeapon(type: weapon.type == .melee ? .melee : .ranged, ammo: 0)
        default:
          break
        }
      }
      .onEvent(ActorDoorEvent.self) { _, event in
        switch event {
        case let .actorEnteredDoor(id, targetLevelIid, targetEntityIid, isCrossLevel) where id == vm.actorId && isCrossLevel:
          handleCrossLevelDoor(targetLevelIid: targetLevelIid, targetEntityIid: targetEntityIid)
        default:
          break
        }
      }
    }

    // MARK: - Physics Config

    private var playerPhysics: ActorPhysics {
      let config = pgs.config
      return ActorPhysics(
        speed: config.movement.speed,
        gravity: nil, // Use world gravity
        knockbackStrength: 80,
        jumpSpeed: config.movement.jumpSpeed,
        minJumpSpeed: config.movement.minJumpSpeed,
        coyoteTime: config.movement.coyoteTime,
        jumpBufferTime: config.movement.jumpBufferTime,
        wallSlideGravityMultiplier: 0.3,
        wallJumpSpeed: config.movement.wallJumpSpeed,
        wallJumpVerticalSpeed: config.movement.wallJumpVerticalSpeed,
        dashSpeed: config.movement.dashSpeed,
        dashDuration: config.movement.dashDuration,
        dashCooldown: config.movement.dashCooldown,
        crouchSpeedMultiplier: config.movement.crouchSpeedMultiplier,
        swimSpeed: config.water.swimSpeed,
        waterGravityMultiplier: config.water.gravityMultiplier,
        waterMaxFallSpeed: config.water.maxFallSpeed,
        waterMoveSpeedMultiplier: config.water.moveSpeedMultiplier
      )
    }

    private var playerCombat: ActorCombat {
      ActorCombat(
        maxHealth: 3,
        touchDamage: 0,
        invincibilityDuration: 1.0,
        canDealTouchDamage: false,
        canReceiveDamage: true
      )
    }

    private var playerCollisionConfig: ActorCollisionConfig {
      ActorCollisionConfig(
        terrain: [-2, 0], // Slightly narrower for tight gaps
        hurtbox: [-2, -2] // Smaller = more forgiving hits
        // collector and interaction use defaults (+8, +8)
      )
    }

    // MARK: - Effects

    private func applyHitstop() {
      Engine.timeScale = 0.0
      Engine.onNextFrame {
        Engine.timeScale = 1.0
      }
    }

    // MARK: - Event Handling

    private func handlePlayerDeath(actor: ActorState) {
      actor.rotation = Float.pi * 4

      guard router.scene == .playing else { return }
      let targetScene = pgs.handlePlayerDied()

      if targetScene == .death {
        router.scene = .death
      } else {
        router.navigate(to: .gameOver, transition: .fade(duration: 0.8))
      }
    }

    private func handleNPCInteracted(npcType: NPCType) {
      let def = npcType.definition
      let visitCount = ds.beginDialogVisit(npcId: def.id)
      let dialogState = DialogState(visitCount: visitCount)

      guard let dialogDef = def.makeDialog(dialogState, ps, pgs, gp) else { return }

      if ds.prepareDialog(npcId: def.id, dialog: dialogDef, branchId: nil, currentScene: router.scene) {
        router.scene = .dialog
      }
    }

    // MARK: - Navigation

    private func handleCrossLevelDoor(targetLevelIid: String, targetEntityIid: String) {
      guard let targetLevel = ps.project.level(iid: targetLevelIid) else {
        GD.printErr("Target level with IID '\(targetLevelIid)' not found")
        return
      }

      guard let targetDoor = targetLevel.entity(iid: targetEntityIid) else { return }
      let targetDoorPosition = targetDoor.positionTopLeft
      let doorSize = targetDoor.size

      router.navigate(to: .playing, transition: .iris(duration: 1.0)) {
        ps.prepareLevel(targetLevel.identifier)

        let doorCenterX = targetDoorPosition.x + doorSize.x / 2
        let spawnPos: Vector2 = [doorCenterX - entity.size.x / 2, targetDoorPosition.y + doorSize.y - entity.size.y]
        ps.spawnPosition = spawnPos
      }
    }

    private func handleEvent(_ event: GameEvent, vm: ViewModel) {
      switch event {
      case .enemyKilled:
        pgs.handleEnemyKilled()
      case let .checkpointActivated(id, position):
        ps.handleCheckpointActivated(id: id, position: position)
      case .gameReset:
        pgs.fullReset()
        if vm.actorId != 0 {
          ActorEvent.reset(actorId: vm.actorId).emit()
        }
        // Sync weapon state to HUD after reset
        if let weapons = vm.weapons, let weapon = weapons.currentWeapon {
          pgs.syncWeapon(type: weapon.type == .melee ? .melee : .ranged, ammo: weapons.currentAmmo)
        }
      case let .consumableCollected(consumable, _):
        // Handle health healing (score handled by GameView)
        if case let .heal(amount) = consumable.effect {
          if let actor = vm.actor {
            actor.heal(amount)
            pgs.syncHealth(actor.health)
          }
        }
      case let .weaponCollected(weapon, _):
        guard let weaponState = vm.weapons else { return }
        if weaponState.weapons.contains(weapon) {
          // Already have weapon - refill ammo
          weaponState.refillAmmo(for: weapon.id)
        } else {
          // New weapon - add it and sync to HUD
          weaponState.addWeapon(weapon)
          pgs.syncWeapon(type: weapon.type == .melee ? .melee : .ranged, ammo: weapon.maxAmmo)
        }
      case let .ammoCollected(weapon, amount, _):
        guard let weaponState = vm.weapons else { return }
        if weaponState.weapons.contains(weapon) {
          weaponState.addAmmo(for: weapon.id, amount: amount)
        }
      default:
        break
      }
    }

    // MARK: - Initialization

    private func initializeSpawn(from entity: LDEntity, levelIid: String) {
      ps.spawnPosition = entity.positionTopLeft
      ps.currentLevelIid = levelIid

      // Process starting consumables via events
      for consumable in startingConsumables {
        GameEvent.consumableCollected(consumable, position: ps.spawnPosition).emit()
      }
    }
  }

  // MARK: - Player Actor Camera

  struct PlayerActorCamera: GView {
    let boss: ObservableState<BossState>
    let levelWidth: Float
    let levelHeight: Float

    var body: some GView {
      Camera2D$()
        .enabled(true)
        .dragHorizontalEnabled(true)
        .dragVerticalEnabled(true)
        .dragLeftMargin(0.2)
        .dragRightMargin(0.2)
        .dragTopMargin(0.1)
        .dragBottomMargin(0.3)
        .limitLeft(0)
        .limitTop(0)
        .limitRight(Int32(levelWidth))
        .limitBottom(Int32(levelHeight))
        .watch(boss, \.shakeIntensity) { camera, intensity in
          if intensity > 0 {
            let offsetX = Float.random(in: -intensity ... intensity) * 4
            let offsetY = Float.random(in: -intensity ... intensity) * 4
            camera.offset = [offsetX, offsetY]
          } else {
            camera.offset = .zero
          }
        }
    }
  }
}
