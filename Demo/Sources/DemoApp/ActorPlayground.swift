import SwiftGodot
import SwiftGodotBuilder

enum PickupItem {
  case coin(value: Int)
  case health(amount: Int)
  case ammo(amount: Int)
}

struct ActorPlaygroundView: GView {
  let playerActor = ActorState()
  let skullNPC = ActorState()
  @State var ammo = 10
  @State var healthDisplay = "Health: 0"

  let pickupSize: Vector2 = [8, 8]

  var body: some GView {
    Node2D$ {
      CanvasLayer$ {
        VBoxContainer$ {
          Label$()
            .text($healthDisplay)
          Label$()
            .text($ammo) { "Ammo: \($0)" }
        }
      }
      .onProcess { _, _ in
        healthDisplay = "Health: \(playerActor.currentHealth)"
      }

      PlayerActor(actor: playerActor, ammo: $ammo)
        .as(CharacterBody2D.self)
        .position([0, 40])

      EnemyPatroller()
        .as(CharacterBody2D.self)
        .position([20, 40])

      EnemyFlyer()

      SkullNPC(actor: skullNPC)
        .as(CharacterBody2D.self)
        .position([60, 40])

      Platform(size: [400, 4])
        .as(StaticBody2D.self)
        .position([-200, 40])

      Pickup(.health(amount: 10)) {
        ColorBox$().color(.red).size(pickupSize)
        CollisionShape2D$()
          .shape(CircleShape2D(radius: Int(pickupSize.x / 2) + 1))
          .position(pickupSize / 2)
          .debugBorder()
      } onCollected: { (item: PickupItem, _) in
        if case let .health(amount) = item {
          playerActor.heal(amount)
        }
      }
      .as(Area2D.self)
      .position([-50, 32])

      Pickup(.ammo(amount: 5)) {
        ColorBox$().color(.yellow).size(pickupSize)
        CollisionShape2D$()
          .shape(CircleShape2D(radius: Int(pickupSize.x / 2) + 1))
          .position(pickupSize / 2)
          .debugBorder()
      } onCollected: { (item: PickupItem, _) in
        if case let .ammo(amount) = item {
          ammo += amount
        }
      }
      .as(Area2D.self)
      .position([-80, 32])

      ActorParticleSpawner()
      ActorProjectileSpawner()
      DialogManager()

      InputHandler(player: playerActor)
    }
  }
}

struct InputHandler: GView {
  let player: ActorState

  let actions = Actions {
    ActionRecipes.axisLR(
      namePrefix: "move",
      device: 0,
      axis: .leftX,
      dz: 0.2,
      keyLeft: .a,
      keyRight: .d
    )

    ActionRecipes.axisUD(
      namePrefix: "move",
      device: 0,
      axis: .leftY,
      dz: 0.2,
      keyDown: .s,
      keyUp: .w
    )

    Action("jump") {
      Key(.w)
      JoyButton(.a, device: 0)
    }

    Action("attack") {
      Key(.space)
      JoyButton(.x, device: 0)
    }

    Action("dash") {
      Key(.shift)
      JoyButton(.rightShoulder, device: 0)
      JoyButton(.leftShoulder, device: 0)
    }

    Action("switch_weapon") {
      Key(.tab)
      JoyButton(.y, device: 0)
    }

    Action("interact") {
      Key(.e)
      JoyButton(.a, device: 0)
    }

    Action("ui_accept") {
      Key(.space)
      Key(.enter)
      JoyButton(.a, device: 0)
    }
  }

  var body: some GView {
    Node2D$()
      .onReady { _ in
        actions.install()
      }
      .onProcess { _, _ in
        // Movement
        let moveDir = Action("move_right").strength - Action("move_left").strength
        player.move(moveDir)

        // Jump
        if Action("jump").isJustPressed {
          player.tryJump()
        }
        player.setJumpHeld(Action("jump").isPressed)

        // Dash
        if Action("dash").isJustPressed {
          player.tryDash()
        }

        // Attack
        if Action("attack").isJustPressed {
          player.tryAttack()
        }

        // Weapon switch
        if Action("switch_weapon").isJustPressed {
          player.switchWeapon()
        }

        // Interact
        if Action("interact").isJustPressed {
          player.tryInteract()
        }
      }
  }
}

struct Platform: GView {
  let size: Vector2

  var body: some GView {
    StaticBody2D$ {
      ColorBox$().color(.gray).size(size)
      CollisionShape2D$()
        .shape(RectangleShape2D(size: size))
        .position([size.x / 2, size.y / 2])
    }
    .collisionLayer(.alpha) // Terrain
  }
}

struct EnemyFlyer: GView {
  let actor: ActorState = .init()

  var body: some GView {
    Actor(actor) { state in
      AseSprite$(path: "Mobs").autoplay("BugYellowMove").scale(state.facingScale)
    }
    .physics(.init(speed: 30, gravity: 0))
    .attacks([
      .init(
        melee: .init(size: [8, 8], offset: 0, damage: 1, knockback: 0, alwaysActive: true),
        ranged: .init(damage: 1, speed: 200, size: [4, 2], lifetime: 2.0)
      ),
    ])
    .behavior(initial: "hover") {
      During("hover") {
        SineWave(amplitudeX: 30, amplitudeY: 15)
        Shoot(cooldown: 1.0)
      }
    }
  }
}

struct EnemyPatroller: GView {
  let actor: ActorState = .init()

  var body: some GView {
    Actor(actor) { state in
      AseSprite$(path: "Mobs").autoplay("EmberRedMove").scale(state.facingScale)
    }
    .collision { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 6, h: 6)).position([1, 1])
    }
    .hurtbox { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 8, h: 8))
    }
    .hitbox { _, _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 8, h: 8))
    }
    .targetbox { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 80, h: 40))
    }
    .attacks([
      .init(
        melee: .init(size: [8, 8], offset: 0, damage: 1, knockback: 0, alwaysActive: true),
        ranged: .init(damage: 1, speed: 200, size: [4, 2], lifetime: 2.0)
      ),
    ])
    .physics(.init(speed: 30, gravity: 800))
    .defense(.init(maxHealth: 3))
    .behavior(
      BehaviorMachine(initial: "patrol") {
        During("patrol") {
          Patrol(left: 50, right: 50)
          Shoot(cooldown: 2.0)
        }
        .transition(to: "chase") { $0.hasTarget }

        During("chase") {
          Chase()
          FaceTarget()
        }
        .transition(to: "patrol") { !$0.hasTarget }
      }
    )
  }
}

struct PlayerActor: GView {
  let actor: ActorState
  let ammo: State<Int>

  var body: some GView {
    Actor(actor) { state in
      AseSprite$(path: "Hero").autoplay("Sword_Idle").scale(state.facingScale)
      Camera2D$()
    }
    .collision { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 8, h: 8))
    }
    .hurtbox { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 8, h: 8))
    }
    .hitbox { state, _ in
      if let melee = state.weapon?.currentMelee {
        CollisionShape2D$()
          .shape(RectangleShape2D(size: melee.size))
          .position([melee.offset, 0])
      }
    }
    .interaction { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 16, h: 16))
    }
    .collector { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 12, h: 12)).debugBorder()
    }
    .attacks([
      .init(melee: .init(size: [12, 8], offset: 10, damage: 1, knockback: 100)),
      .init(ranged: .init(damage: 1, speed: 200, size: [4, 2], lifetime: 2.0)),
    ])
    .physics(.init(speed: 80, gravity: 800, jumpSpeed: 150))
    .defense(.init(maxHealth: 50))
    .isPlayer()
    .onBeforeAttack { _, weaponIndex in
      // Weapon 0 = melee (no ammo), Weapon 1 = ranged (uses ammo)
      if weaponIndex == 1 {
        return ammo.wrappedValue > 0
      }
      return true
    }
    .onAttack { _, weaponIndex in
      // Decrement ammo for ranged weapon
      if weaponIndex == 1 {
        ammo.wrappedValue -= 1
      }
    }
  }
}

struct SkullNPC: GView {
  let actor: ActorState
  let Skull = Speaker("Skull")

  var body: some GView {
    Actor(actor) { _ in
      AseSprite$(path: "Mobs").autoplay("Skull")
    }
    .collision { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 8, h: 8))
    }
    .interaction { _ in
      CollisionShape2D$().shape(RectangleShape2D(w: 20, h: 20))
    }
    .physics(.init(speed: 0, gravity: 800))
    .dialog { _, dialogState in
      Dialog(id: "skull_npc") {
        Branch("main") {
          if dialogState.isFirstVisit {
            Skull ~ "Greetings, traveler..."
            Skull ~ "I am but a humble skull."
          } else {
            Skull ~ "You again? Still alive, I see."
          }
        }
      }
    }
  }
}

enum ParticleType: CaseIterable {
  case jumpDust
  case landingImpact
  case projectileTrail

  var config: ParticleConfig {
    switch self {
    case .jumpDust:
      ParticleConfig(
        amount: 8, lifetime: 0.3, explosiveness: 1.0,
        direction: [0, -1], spread: 45,
        initialVelocityMin: 20, initialVelocityMax: 50,
        gravity: [0, 100], color: .gray
      )
    case .landingImpact:
      ParticleConfig(
        amount: 12, lifetime: 0.4, explosiveness: 1.0,
        direction: [0, -1], spread: 60,
        initialVelocityMin: 30, initialVelocityMax: 80,
        gravity: [0, 150], color: .darkGray
      )
    case .projectileTrail:
      ParticleConfig(
        amount: 8, lifetime: 0.3, explosiveness: 1.0,
        direction: [0, 0], spread: 180,
        initialVelocityMin: 10, initialVelocityMax: 30,
        gravity: [0, 0], color: .yellow
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

struct ActorParticleSpawner: GView {
  let pool = TypedParticlePool<ParticleType, CPUParticles2D>(
    keys: ParticleType.allCases,
    config: .init(prewarmPerType: 15, defaultLifetime: 1.0),
    factory: { $0.makeNode() }
  )

  var body: some GView {
    Node2D$()
      .onReady { node in
        pool.setup(parent: node)
      }
      .onEvent(ActorEvent.self) { _, event in
        switch event {
        case let .jumped(_, position):
          pool.spawn(type: .jumpDust, at: position)

        case let .landed(_, position, _):
          pool.spawn(type: .landingImpact, at: position)

        case let .projectileHitWall(_, position):
          pool.spawn(type: .projectileTrail, at: position)

        case let .projectileHitTarget(_, _, position, _, _, _):
          pool.spawn(type: .projectileTrail, at: position)

        default:
          break
        }
      }
  }
}

@Godot
final class ActorPlayground: Node2D {
  override func _ready() {
    ReactiveDebug.isEnabled = true
    NodeDebug.isEnabled = true
    ProcessDebug.isEnabled = true

    ServiceLocator.resolve(ActorEvent.self).tapLog()

    let rootNode = ActorPlaygroundView().toNode()
    addChild(node: rootNode)
  }
}
