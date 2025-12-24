import SwiftGodot
import SwiftGodotBuilder

// MARK: - Mob Types

enum MobType: CaseIterable {
  case emberRed
  case emberOrange
  case emberYellow
  case snakeYellow
  case snakePurple
  case bugGray
  case bugYellow
  case skeleton1
  case skeleton2
  case mage
  // Hero-based mobs
  case heroSword
  case heroBow
  case heroAxe
  case heroWand

  var isHero: Bool {
    switch self {
    case .heroSword, .heroBow, .heroAxe, .heroWand: true
    default: false
    }
  }

  var spritePath: String {
    isHero ? "Hero" : "Mobs"
  }

  var layer: String? {
    switch self {
    case .heroSword: "Sword"
    case .heroBow: "Bow"
    case .heroAxe: "Axe"
    case .heroWand: "Wand"
    default: nil
    }
  }

  var animationName: String {
    switch self {
    case .emberRed: "EmberRedMove"
    case .emberOrange: "EmberOrangeMove"
    case .emberYellow: "EmberYellowMove"
    case .snakeYellow: "SnakeYellowMove"
    case .snakePurple: "SnakePurpleMove"
    case .bugGray: "BugGrayMove"
    case .bugYellow: "BugYellowMove"
    case .skeleton1: "Skeleton1Move"
    case .skeleton2: "Skeleton2Move"
    case .mage: "MageMove"
    case .heroSword, .heroBow, .heroAxe, .heroWand: "Walk"
    }
  }

  var hitAnimation: String {
    switch self {
    case .emberRed, .emberOrange, .emberYellow: "EmberHit"
    case .snakeYellow, .snakePurple: "SnakeHit"
    case .bugGray, .bugYellow: "BugHit"
    case .skeleton1: "Skeleton1Hit"
    case .skeleton2: "Skeleton2Hit"
    case .mage: "MageHit"
    case .heroSword, .heroBow, .heroAxe, .heroWand: "Hit"
    }
  }

  var color: Color {
    switch self {
    case .emberRed: .red
    case .emberOrange: .orange
    case .emberYellow: .yellow
    case .snakeYellow: .yellow
    case .snakePurple: .purple
    case .bugGray: .gray
    case .bugYellow: .yellow
    case .skeleton1: .white
    case .skeleton2: .lightGray
    case .mage: .purple
    case .heroSword: .steelBlue
    case .heroBow: .forestGreen
    case .heroAxe: .brown
    case .heroWand: .magenta
    }
  }

  var speed: Float {
    switch self {
    case .emberRed, .emberOrange, .emberYellow: 40
    case .snakeYellow, .snakePurple: 30
    case .bugGray, .bugYellow: 50
    case .skeleton1: 25
    case .skeleton2: 20
    case .mage: 15
    case .heroSword: 35
    case .heroBow: 25
    case .heroAxe: 20
    case .heroWand: 30
    }
  }

  var health: Int {
    switch self {
    case .emberRed, .emberOrange, .emberYellow: 2
    case .snakeYellow, .snakePurple: 3
    case .bugGray, .bugYellow: 10
    case .skeleton1: 4
    case .skeleton2: 5
    case .mage: 3
    case .heroSword: 5
    case .heroBow: 3
    case .heroAxe: 6
    case .heroWand: 4
    }
  }

  var damage: Int {
    switch self {
    case .emberRed, .emberOrange, .emberYellow: 1
    case .snakeYellow, .snakePurple: 2
    case .bugGray, .bugYellow: 1
    case .skeleton1: 2
    case .skeleton2: 1
    case .mage: 3
    case .heroSword: 2
    case .heroBow: 2
    case .heroAxe: 3
    case .heroWand: 2
    }
  }

  var isRanged: Bool {
    switch self {
    case .skeleton2, .mage, .heroBow, .heroWand: true
    default: false
    }
  }

  var team: Int {
    switch self {
    case .emberRed, .emberOrange, .emberYellow: 0
    case .snakeYellow, .snakePurple: 1
    case .bugGray, .bugYellow: 2
    case .skeleton1, .skeleton2, .mage: 3
    case .heroSword, .heroBow: 4
    case .heroAxe, .heroWand: 5
    }
  }
}

// MARK: - Events

enum StressTestEvent: EmittableEvent {
  case mobSpawned(position: Vector2, type: MobType)
  case mobDied(position: Vector2, type: MobType)
  case mobHit(position: Vector2, damage: Int)
  case spawnParticles(type: StressTestParticleType, position: Vector2)
}

enum StressTestParticleType: CaseIterable {
  case hit
  case death
  case spawn
  case blood

  var config: ParticleConfig {
    switch self {
    case .hit:
      ParticleConfig(
        amount: 3, lifetime: 0.2, explosiveness: 1.0,
        direction: [0, -1], spread: 45,
        initialVelocityMin: 30, initialVelocityMax: 60,
        gravity: [0, 100], color: .white
      )
    case .death:
      ParticleConfig(
        amount: 10, lifetime: 0.5, explosiveness: 1.0,
        direction: [0, -1], spread: 90,
        initialVelocityMin: 50, initialVelocityMax: 120,
        gravity: [0, 200], color: .red
      )
    case .spawn:
      ParticleConfig(
        amount: 5, lifetime: 0.3, explosiveness: 1.0,
        direction: [0, 1], spread: 200,
        initialVelocityMin: 20, initialVelocityMax: 40,
        gravity: [0, -50], color: .cyan
      )
    case .blood:
      ParticleConfig(
        amount: 2, lifetime: 0.3, explosiveness: 1.0,
        direction: [0, -1], spread: 30,
        initialVelocityMin: 40, initialVelocityMax: 80,
        gravity: [0, 300], color: .darkRed
      )
    }
  }

  func makeNode() -> CPUParticles2D {
    let c = config
    return CPUParticles2D$()
      .oneShot(true)
      .emitting(false)
      .amount(c.amount)
      .lifetime(c.lifetime)
      .explosiveness(c.explosiveness)
      .direction(c.direction)
      .spread(c.spread)
      .initialVelocityMin(c.initialVelocityMin)
      .initialVelocityMax(c.initialVelocityMax)
      .gravity(c.gravity)
      .color(c.color)
      .toNode() as! CPUParticles2D
  }
}

// MARK: - Stress Test View

struct StressTestView: GView {
  @State var mobCount = 0
  @State var killCount = 0
  @State var spawnTimer = 0.0

  let arenaWidth: Float = 320
  let arenaHeight: Float = 180
  let maxMobs = 1000
  let spawnInterval = 0.007

  var body: some GView {
    Node2D$ {
      // Camera centered on arena
      Camera2D$()
        .position([arenaWidth / 2, arenaHeight / 2])
        .enabled(true)

      // UI
      CanvasLayer$ {
        VBoxContainer$ {
          Label$()
            .text($mobCount) { "Mobs: \($0)" }
          Label$()
            .text($killCount) { "Kills: \($0)" }
        }
        .offset(top: 8, right: 0, bottom: 0, left: 8)
      }

      ArenaBounds(width: arenaWidth, height: arenaHeight)

      PooledMobSpawner()

      StressTestParticleSpawner(arenaWidth: arenaWidth, arenaHeight: arenaHeight)

      ActorProjectileSpawner()
    }
    .onProcess { _, delta in
      spawnTimer += delta
      if spawnTimer >= spawnInterval && mobCount < maxMobs {
        spawnTimer = 0
        spawnRandomMob()
      }
    }
    .onEvent(StressTestEvent.self) { _, event in
      switch event {
      case .mobSpawned:
        mobCount += 1
      case .mobDied:
        mobCount -= 1
        killCount += 1
      default:
        break
      }
    }
  }

  func spawnRandomMob() {
    let mobType = MobType.allCases.randomElement()!
    let margin: Float = 16
    let x = Float.random(in: margin ... arenaWidth - margin)
    let y = Float.random(in: margin ... arenaHeight - 40)
    let position: Vector2 = [x, y]

    StressTestEvent.mobSpawned(position: position, type: mobType).emit()
    StressTestEvent.spawnParticles(type: .spawn, position: position).emit()
  }
}

// MARK: - Arena Bounds

struct ArenaBounds: GView {
  let width: Float
  let height: Float

  var body: some GView {
    StaticBody2D$ {
      // Floor (bottom)
      ColorBox$().color(.darkGray).size([width, 4]).position([0, height - 4])
      CollisionShape2D$()
        .shape(RectangleShape2D(w: Int(width), h: 4))
        .position([width / 2, height - 2])

      // Left wall
      ColorBox$().color(.darkGray).size([4, height]).position([0, 0])
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 4, h: Int(height)))
        .position([2, height / 2])

      // Right wall
      ColorBox$().color(.darkGray).size([4, height]).position([width - 4, 0])
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 4, h: Int(height)))
        .position([width - 2, height / 2])

      // Bottom left platform
      ColorBox$().color(.gray).size([80, 4]).position([20, 140])
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 80, h: 4))
        .position([60, 142])

      // Bottom right platform
      ColorBox$().color(.gray).size([80, 4]).position([220, 140])
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 80, h: 4))
        .position([260, 142])

      // Middle left platform
      ColorBox$().color(.gray).size([72, 4]).position([40, 100])
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 72, h: 4))
        .position([76, 102])

      // Middle right platform
      ColorBox$().color(.gray).size([72, 4]).position([208, 100])
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 72, h: 4))
        .position([244, 102])

      // Middle center platform
      ColorBox$().color(.gray).size([64, 4]).position([128, 120])
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 64, h: 4))
        .position([160, 122])

      // Upper left platform
      ColorBox$().color(.gray).size([64, 4]).position([24, 60])
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 64, h: 4))
        .position([56, 62])

      // Upper right platform
      ColorBox$().color(.gray).size([64, 4]).position([232, 60])
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 64, h: 4))
        .position([264, 62])

      // Top center platform
      ColorBox$().color(.gray).size([80, 4]).position([120, 40])
      CollisionShape2D$()
        .shape(RectangleShape2D(w: 80, h: 4))
        .position([160, 42])
    }
    .collisionLayer(.alpha)
  }
}

// MARK: - Mob Actor

struct MobActor: GView {
  let mobType: MobType
  let spawnPosition: Vector2
  let actor: ActorState

  @State var facingScale: Vector2 = [1, 1]

  init(mobType: MobType, spawnPosition: Vector2, actor: ActorState? = nil) {
    self.mobType = mobType
    self.spawnPosition = spawnPosition
    self.actor = actor ?? ActorState()
  }

  var body: some GView {
    Actor(actor) { _ in
      AseSprite$(path: mobType.spritePath, currentLayer: mobType.layer ?? "")
        .autoplay(mobType.animationName)
        .scale($facingScale)
    }
    .collision { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 6, h: 6)).position([1, 1])
    }
    .hurtbox { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 8, h: 8))
    }
    .hitbox { _, _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 10, h: 8)).position([4, 0])
    }
    .targetbox { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 60, h: 30))
    }
    .attacks(mobAttacks)
    .physics(.init(speed: mobType.speed, gravity: 600, jumpSpeed: 120))
    .defense(.init(maxHealth: mobType.health, invincibilityDuration: 0.3))
    .behavior(
      BehaviorMachine(initial: "wander") {
        During("wander") {
          Patrol(left: 40, right: 40)
          if mobType.isRanged {
            Shoot(cooldown: 1.5)
          }
        }
        .transition(to: "fight") { $0.hasTarget }

        During("fight") {
          Chase(stopDistance: mobType.isRanged ? 30 : 12)
          FaceTarget()
          Shoot(cooldown: mobType.isRanged ? 1.0 : 0.8)
        }
        .transition(to: "wander") { !$0.hasTarget }
      }
    )
    .onHurt { actor, damage, _ in
      actor.takeDamage(damage, knockback: .zero)
      if let node = actor.node {
        StressTestEvent.spawnParticles(type: .hit, position: node.position).emit()
        StressTestEvent.spawnParticles(type: .blood, position: node.position).emit()
      }
    }
    .onDeath { actor in
      if let node = actor.node {
        StressTestEvent.mobDied(position: node.position, type: mobType).emit()
        StressTestEvent.spawnParticles(type: .death, position: node.position).emit()
      }
    }
    .as(CharacterBody2D.self)
    .position(spawnPosition)
  }

  var mobAttacks: [ActorWeaponConfig] {
    if mobType.isRanged {
      [.init(ranged: .init(damage: mobType.damage, speed: 150, size: [2, 2], lifetime: 2.0))]
    } else {
      [.init(melee: .init(size: [10, 8], offset: 4, damage: mobType.damage, knockback: 50, alwaysActive: true))]
    }
  }
}

// MARK: - Mob Behavior Factory

func makeMobBehavior(for mobType: MobType) -> AnyBehaviorMachine {
  AnyBehaviorMachine(BehaviorMachine(initial: "wander") {
    During("wander") {
      Patrol(left: 40, right: 40)
      if mobType.isRanged {
        Shoot(cooldown: 1.5)
      }
    }
    .transition(to: "fight") { $0.hasTarget }

    During("fight") {
      Chase(stopDistance: mobType.isRanged ? 30 : 12)
      FaceTarget()
      Shoot(cooldown: mobType.isRanged ? 1.0 : 0.8)
    }
    .transition(to: "wander") { !$0.hasTarget }
  })
}

// MARK: - Pooled Mob Spawner

struct PooledMobSpawner: GView {
  // One pool per mob type
  let pools: [MobType: ActorPool]

  init() {
    var dict: [MobType: ActorPool] = [:]
    for type in MobType.allCases {
      dict[type] = ActorPool(
        prewarm: 50,
        max: 200,
        make: {
          let state = ActorState()
          let mob = MobActor(mobType: type, spawnPosition: .zero, actor: state)
          let node = mob.toNode() as! CharacterBody2D
          // let node2 = CharacterBody2D()
          return (node, state)
        },
        makeBehavior: { makeMobBehavior(for: type) }
      )
    }
    pools = dict
  }

  var body: some GView {
    Node2D$()
      .onReady { node in
        for pool in pools.values {
          pool.setup(parent: node)
        }
      }
      .onEvent(StressTestEvent.self) { _, event in
        if case let .mobSpawned(position, type) = event {
          pools[type]?.spawn(at: position)
        }
      }
      .onEvent(ActorEvent.self) { _, event in
        if case let .died(actorId) = event {
          // Try to release from any pool (only one will have it)
          for pool in pools.values {
            if pool.release(actorId: actorId) {
              break
            }
          }
        }
      }
  }
}

// MARK: - Particle Spawner

struct StressTestParticleSpawner: GView {
  let arenaWidth: Float
  let arenaHeight: Float

  let pool = TypedParticlePool<StressTestParticleType, CPUParticles2D>(
    keys: StressTestParticleType.allCases,
    config: .init(prewarmPerType: 30, defaultLifetime: 1.0),
    factory: { $0.makeNode() }
  )

  var body: some GView {
    Node2D$()
      .onReady { node in
        pool.setup(parent: node)
      }
      .onProcess { _, delta in
        pool.update(delta: delta)
      }
      .onEvent(StressTestEvent.self) { _, event in
        if case let .spawnParticles(type, position) = event {
          pool.spawn(type: type, at: position)
        }
      }
      .onEvent(ActorEvent.self) { _, event in
        switch event {
        case let .meleeHitTarget(_, _, _, _, position, _):
          pool.spawn(type: .hit, at: position)
        case let .projectileHitTarget(_, _, position, _, _, _):
          pool.spawn(type: .hit, at: position)
        case let .projectileHitWall(_, position):
          pool.spawn(type: .hit, at: position)
        default:
          break
        }
      }
  }
}

// MARK: - Main Entry Point

@Godot
final class StressTest: Node2D {
  override func _ready() {
    let rootNode = StressTestView().toNode()
    addChild(node: rootNode)
  }
}
