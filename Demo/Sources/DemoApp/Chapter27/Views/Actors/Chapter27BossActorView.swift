import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Boss using the ActorView system - minimal configuration wrapper
  struct BossActorView: GView {
    let entity: LDEntity
    let level: LDLevel
    let boss: ObservableState<BossState>
    let router: ObservableState<GameRouter>
    let worldGravity: Float

    // Configuration
    let bossName: String
    let spriteAsset: String
    let animations: ActorAnimations
    let combat: ActorCombat
    let phaseColors: [Color]

    // Composable behaviors
    let behaviors: [ActorBehavior]

    var healthBar: HealthBarConfig {
      HealthBarConfig(
        name: bossName,
        showWhenFull: true,
        barWidth: 48,
        barHeight: 6,
        fillColor: .red,
        backgroundColor: Color(r: 0.1, g: 0.1, b: 0.1, a: 0.8),
        borderColor: .white
      )
    }

    private final class ViewModel {
      var actor: ActorState?
      var actorId: Int = 0
      var phaseColor: Color = .init(code: "#CC2222")
      var isDefeated = false
      var rootNode: Node2D?
    }

    private let vm = ViewModel()

    var bs: BossState { boss.wrappedValue }

    init(
      entity: LDEntity,
      level: LDLevel,
      boss: ObservableState<BossState>,
      router: ObservableState<GameRouter>,
      worldGravity: Float,
      bossName: String = "THE GUARDIAN",
      spriteAsset: String = "Bosses",
      animations: ActorAnimations = .perAction(
        idle: "Red_Idle",
        walk: "Red_Idle",
        jump: "Red_Jump",
        hit: "Red_Hit",
        death: "Red_Death"
      ),
      combat: ActorCombat = ActorCombat(
        maxHealth: 100,
        touchDamage: 1,
        invincibilityDuration: 0.1,
        canDealTouchDamage: true,
        canReceiveDamage: true,
        phaseThresholds: [0.66, 0.33],
        stunOnPhaseChange: true,
        phaseStunDuration: 1.0
      ),
      phaseColors: [Color] = [
        Color(code: "#CC2222"), // Phase 1
        Color(code: "#FF6600"), // Phase 2
        Color(code: "#9933FF"), // Phase 3
      ]
    ) {
      self.entity = entity
      self.level = level
      self.boss = boss
      self.router = router
      self.worldGravity = worldGravity
      self.bossName = bossName
      self.spriteAsset = spriteAsset
      self.animations = animations
      self.combat = combat
      self.phaseColors = phaseColors

      // Create behaviors for boss
      let levelWidth = Float(level.pxWid)
      behaviors = [
        .arenaPatrol(.boss(levelWidth: levelWidth)),
        .charge(ActorCharge(speed: 200, stunOnWallHit: true, wallStunDuration: 0.5)),
        .attackPatterns(ActorAttackPatterns([
          ActorAttackPattern(type: .shoot, cooldown: 2.0, minPhase: 1, cooldownMultiplier: [2: 0.8, 3: 0.6]),
          ActorAttackPattern(type: .jump, cooldown: 4.0, minPhase: 2, cooldownMultiplier: [3: 0.7]),
          ActorAttackPattern(type: .charge, cooldown: 5.0, minPhase: 3),
          ActorAttackPattern(type: .summon, cooldown: 8.0, minPhase: 3),
        ])),
      ]
    }

    private var physics: ActorPhysics {
      ActorPhysics(
        speed: 30,
        gravity: nil, // Use world gravity
        knockbackStrength: 0,
        jumpSpeed: 300
      )
    }

    var body: some GView {
      Node2D$ {
        ActorView(
          entity: entity,
          spriteAsset: spriteAsset,
          animations: animations,
          collisionLayers: Chapter27.actorCollisionLayers,
          healthBar: healthBar,
          behaviors: behaviors,
          physics: physics,
          combat: combat,
          capabilities: .enemy,
          worldGravity: worldGravity
        )
        .onActorReady { actor in
          vm.actorId = actor.id
          vm.actor = actor
        }
      }
      .onReady { node in
        vm.rootNode = node
        node.modulate = vm.phaseColor
        bs.startBossFight(maxHealth: combat.maxHealth)
      }
      .onProcess { _, _ in
        guard router.scene.isActive, vm.isDefeated else { return }
        GameEvent.goalReached.emit()
      }
      .onEvent(ActorEvent.self) { _, event in
        switch event {
        case let .phaseChanged(id, phase) where id == vm.actorId:
          handlePhaseChange(phase, vm: vm)
        case let .tookDamage(id, damage, position) where id == vm.actorId:
          bs.handleBossHit(damage: damage)
          bs.shakeIntensity = 0.3
          GameEvent.enemyTookDamage(amount: damage, position: position).emit()
        case let .died(id, position) where id == vm.actorId:
          vm.isDefeated = true
          vm.rootNode?.visible = false
          bs.shakeIntensity = 1.5
          GameEvent.bossDefeated(position: position).emit()
        default:
          break
        }
      }
      .onEvent(GameEvent.self) { _, event in
        if case .gameReset = event {
          reset(vm: vm)
        }
      }
      .onEvent(ActorBehaviorEvent.self) { _, event in
        switch event {
        case let .shoot(id, position, direction) where id == vm.actorId:
          GameEvent.enemyFiredProjectile(position: position, direction: direction).emit()
        case let .summon(id, _) where id == vm.actorId:
          GameEvent.bossSummonedMinions.emit()
        default:
          break
        }
      }
    }

    private func handlePhaseChange(_ phase: Int, vm: ViewModel) {
      bs.bossPhase = BossPhase(rawValue: phase) ?? .one
      bs.shakeIntensity = 1.0
      GameEvent.bossPhaseChanged(phase: bs.bossPhase).emit()

      // Update color (phase is 1-based, array is 0-based)
      let colorIndex = min(phase - 1, phaseColors.count - 1)
      vm.phaseColor = phaseColors[max(0, colorIndex)]
      vm.rootNode?.modulate = vm.phaseColor
    }

    private func reset(vm: ViewModel) {
      vm.isDefeated = false
      vm.phaseColor = phaseColors.first ?? .white
      vm.rootNode?.visible = true
      vm.rootNode?.modulate = vm.phaseColor
      Engine.onNextFrame { bs.startBossFight(maxHealth: combat.maxHealth) }
    }
  }
}
