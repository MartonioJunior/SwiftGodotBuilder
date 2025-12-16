import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Enemy using the ActorView system
  struct EnemyActorView: GView {
    let entity: LDEntity?
    let definition: EnemyDefinition
    let patrolLeft: Float
    let patrolRight: Float
    let behaviors: [ActorBehavior]
    let spawnPoint: Vector2?
    let worldGravity: Float

    let healthBar = HealthBarConfig(
      name: nil,
      showWhenFull: false,
      barWidth: 24,
      barHeight: 3,
      fillColor: .red,
      backgroundColor: Color(r: 0.1, g: 0.1, b: 0.1, a: 0.8),
      borderColor: .white
    )

    private final class ViewModel {
      var actor: ActorState?
      var deathTimer: Double = 0
      var isDying = false
      var hitTimer: Double = 0
      var actorId: Int = 0
    }

    private let vm = ViewModel()

    /// Initialize from LDtk entity
    init(entity: LDEntity, worldGravity: Float) {
      self.entity = entity
      spawnPoint = nil
      self.worldGravity = worldGravity
      let enemyType: EnemyType = entity.field("enemyType")?.asEnum() ?? .patrol
      definition = enemyType.definition

      let pos = entity.positionTopLeft
      let patrolBounds = entity.field("patrol_bounds")?.asFloatArray() ?? []
      patrolLeft = patrolBounds.count > 0 ? patrolBounds[0] : pos.x - 32
      patrolRight = patrolBounds.count > 1 ? patrolBounds[1] : pos.x + 32

      // Build behaviors based on enemy definition
      var behaviorList: [ActorBehavior] = [
        .pathPatrol(.fromBounds(patrolLeft, patrolRight, speed: definition.speed)),
      ]
      if definition.flies {
        behaviorList.append(.sineWave(ActorSineWave(amplitude: 30, frequency: 2.0, baseY: pos.y)))
      }
      if let interval = definition.shootInterval {
        behaviorList.append(.shoot(ActorShoot(interval: interval)))
      }
      behaviors = behaviorList
    }

    /// Initialize with explicit definition (for boss spawners with entity)
    init(
      entity: LDEntity,
      definition: EnemyDefinition,
      patrolLeft: Float,
      patrolRight: Float,
      worldGravity: Float
    ) {
      self.entity = entity
      spawnPoint = nil
      self.definition = definition
      self.patrolLeft = patrolLeft
      self.patrolRight = patrolRight
      self.worldGravity = worldGravity

      var behaviorList: [ActorBehavior] = [
        .pathPatrol(.fromBounds(patrolLeft, patrolRight, speed: definition.speed)),
      ]
      if definition.flies {
        behaviorList.append(.sineWave(ActorSineWave(amplitude: 30, frequency: 2.0, baseY: entity.positionTopLeft.y)))
      }
      if let interval = definition.shootInterval {
        behaviorList.append(.shoot(ActorShoot(interval: interval)))
      }
      behaviors = behaviorList
    }

    /// Initialize without LDEntity (for spawner-created enemies)
    init(
      definition: EnemyDefinition,
      spawnPoint: Vector2,
      patrolLeft: Float,
      patrolRight: Float,
      worldGravity: Float
    ) {
      entity = nil
      self.spawnPoint = spawnPoint
      self.definition = definition
      self.patrolLeft = patrolLeft
      self.patrolRight = patrolRight
      self.worldGravity = worldGravity

      var behaviorList: [ActorBehavior] = [
        .pathPatrol(.fromBounds(patrolLeft, patrolRight, speed: definition.speed)),
      ]
      if definition.flies {
        behaviorList.append(.sineWave(ActorSineWave(amplitude: 30, frequency: 2.0, baseY: spawnPoint.y)))
      }
      if let interval = definition.shootInterval {
        behaviorList.append(.shoot(ActorShoot(interval: interval)))
      }
      behaviors = behaviorList
    }

    private var physics: ActorPhysics {
      ActorPhysics(
        speed: definition.speed,
        gravity: definition.flies ? 0 : nil, // Flying = no gravity, grounded = world gravity
        knockbackStrength: definition.knockbackForce
      )
    }

    private var combat: ActorCombat {
      ActorCombat(
        maxHealth: definition.maxHealth,
        touchDamage: definition.touchDamage,
        invincibilityDuration: 0.2,
        canDealTouchDamage: true,
        canReceiveDamage: true
      )
    }

    private var startingWeapons: [ActorWeapon] {
      definition.startingWeapons
    }

    private var actorView: ActorView<EmptyGView> {
      if let entity {
        ActorView(
          entity: entity,
          spriteAsset: "Mobs",
          animations: definition.animations,
          collisionLayers: Chapter27.actorCollisionLayers,
          healthBar: healthBar,
          behaviors: behaviors,
          physics: physics,
          combat: combat,
          capabilities: .enemy,
          startingItems: [],
          startingWeapons: startingWeapons,
          worldGravity: worldGravity
        )
      } else {
        ActorView(
          spawnPosition: spawnPoint ?? .zero,
          size: [definition.size, definition.size],
          spriteAsset: "Mobs",
          animations: definition.animations,
          collisionLayers: Chapter27.actorCollisionLayers,
          healthBar: healthBar,
          behaviors: behaviors,
          physics: physics,
          combat: combat,
          capabilities: .enemy,
          startingItems: [],
          startingWeapons: startingWeapons,
          worldGravity: worldGravity
        )
      }
    }

    var body: some GView {
      Node2D$ {
        actorView
          .onActorReady { actor in
            vm.actorId = actor.id
            vm.actor = actor
          }
      }
      .onProcess { node, delta in
        // Death fade
        if vm.isDying {
          vm.deathTimer -= delta
          if vm.deathTimer <= 0 {
            node.queueFree()
          } else {
            let alpha = Float(vm.deathTimer / definition.deathFadeDuration)
            node.modulate = Color(r: 1, g: 1, b: 1, a: alpha)
          }
          return
        }

        // Hit animation timer
        if vm.hitTimer > 0 {
          vm.hitTimer -= delta
        }
      }
      .onEvent(GameEvent.self) { node, event in
        switch event {
        case .gameReset:
          vm.isDying = false
          vm.deathTimer = 0
          node.modulate = Color.white
        default:
          break
        }
      }
      .onEvent(ActorEvent.self) { _, event in
        switch event {
        case let .meleeHit(attackerId, _, hitPos, damage) where attackerId == vm.actorId:
          GameEvent.playerTookDamage(damage: damage, position: hitPos).emit()
        case let .died(id, position) where id == vm.actorId:
          vm.isDying = true
          vm.deathTimer = definition.deathFadeDuration
          GameEvent.enemyKilled(position: position).emit()
          // Random health drop via DropSpawner
          if Float.random(in: 0 ... 1) < definition.healthDropChance {
            let dropPos = position + [definition.size / 2, definition.size / 2]
            GameEvent.itemDropped(.consumable(.health), position: dropPos).emit()
          }
        case let .tookDamage(id, damage, position) where id == vm.actorId:
          // Show hit animation briefly (0.15s like old EnemyState)
          if let actor = vm.actor {
            actor.isHit = true
            actor.hitTimer = 0.15
          }
          GameEvent.enemyTookDamage(amount: damage, position: position).emit()
        case let .projectileFired(id, position, direction, _) where id == vm.actorId:
          GameEvent.enemyFiredProjectile(position: position, direction: direction).emit()
        default:
          break
        }
      }
    }
  }
}
