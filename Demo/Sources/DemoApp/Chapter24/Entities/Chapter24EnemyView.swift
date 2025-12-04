import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct EnemyView: GView {
    let spawnPoint: Vector2
    let patrolLeft: Float
    let patrolRight: Float
    let state: ObservableState<GameViewState>
    let router: ObservableState<GameRouter>

    // From EnemyDefinition
    let size: Float
    let speed: Float
    let maxHealth: Int
    let touchDamage: Int
    let deathFadeDuration: Double
    let knockbackForce: Float
    let knockbackDuration: Double
    let shootInterval: Double?
    let healthDropChance: Float
    let colorHex: String
    let damagedColorHex: String
    let flies: Bool

    @State var position: Vector2 = .zero
    @State var direction: Float = 1
    @State var health = 2
    @State var isDying = false
    @State var deathTimer = 0.0
    @State var knockbackVelocity: Vector2 = .zero
    @State var knockbackTimer = 0.0
    @State var sineTimer = 0.0
    @State var shootTimer = 0.0

    init(
      entity: LDEntity,
      state: ObservableState<GameViewState>,
      router: ObservableState<GameRouter>
    ) {
      let enemyType: EnemyType = entity.field("enemyType")?.asEnum() ?? .patrol
      let definition: EnemyDefinition
      switch enemyType {
      case .patrol: definition = .patrol
      case .flyer: definition = .flyer
      }

      size = definition.size
      speed = definition.speed
      maxHealth = definition.maxHealth
      touchDamage = definition.touchDamage
      deathFadeDuration = definition.deathFadeDuration
      knockbackForce = definition.knockbackForce
      knockbackDuration = definition.knockbackDuration
      shootInterval = definition.shootInterval
      healthDropChance = definition.healthDropChance
      colorHex = definition.colorHex
      damagedColorHex = definition.damagedColorHex
      flies = definition.flies

      spawnPoint = entity.positionTopLeft
      patrolLeft = entity.field("patrolLeft")?.asFloat() ?? (entity.positionCenter.x - 50)
      patrolRight = entity.field("patrolRight")?.asFloat() ?? (entity.positionCenter.x + 50)
      self.state = state
      self.router = router
      position = spawnPoint
      health = maxHealth
      shootTimer = shootInterval ?? 0
    }

    init(
      _ definition: EnemyDefinition,
      spawnPoint: Vector2,
      patrolLeft: Float,
      patrolRight: Float,
      state: ObservableState<GameViewState>,
      router: ObservableState<GameRouter>
    ) {
      size = definition.size
      speed = definition.speed
      maxHealth = definition.maxHealth
      touchDamage = definition.touchDamage
      deathFadeDuration = definition.deathFadeDuration
      knockbackForce = definition.knockbackForce
      knockbackDuration = definition.knockbackDuration
      shootInterval = definition.shootInterval
      healthDropChance = definition.healthDropChance
      colorHex = definition.colorHex
      damagedColorHex = definition.damagedColorHex
      flies = definition.flies

      self.spawnPoint = spawnPoint
      self.patrolLeft = patrolLeft
      self.patrolRight = patrolRight
      self.state = state
      self.router = router
      position = spawnPoint
      health = maxHealth
      shootTimer = shootInterval ?? 0
    }

    var body: some GView {
      let color = Color(code: colorHex)
      let damagedColor = Color(code: damagedColorHex)

      return Node2D$ {
        ColorBox$()
          .size([size, size])
          .bind(\.color, to: $health, $isDying, $deathTimer) { h, dying, timer in
            if dying {
              let alpha = Float(timer / deathFadeDuration)
              return Color(r: color.red, g: color.green, b: color.blue, a: alpha)
            }
            let healthPercent = Float(h) / Float(maxHealth)
            return healthPercent > 0.5 ? color : damagedColor
          }

        // Enemy damage area - detects player body and player attacks
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(w: size, h: size))
            .position([size / 2, size / 2])
            .watch($isDying) { cs, isDying in
              Engine.onNextFrame { cs.disabled = isDying }
            }
        }
        .collisionLayer(.combat)
        .collisionMask([.player, .combat])
        .onSignal(\.bodyEntered) { _, body in
          // Colliding with player's CharacterBody2D
          if !isDying, body is CharacterBody2D {
            GameEvent.playerHit(damage: touchDamage, position: position).emit()
          }
        }
        .onSignal(\.areaEntered) { _, _ in
          // Colliding with player's attack hitbox
          if !isDying {
            takeDamage(1)
          }
        }
      }
      .position($position)
      .onEvent(GameEvent.self) { _, event in
        if case .gameReset = event {
          respawn()
        }
      }
      .onProcess { node, delta in
        guard router.scene.isActive else {
          return
        }

        if isDying {
          deathTimer -= delta
          if deathTimer <= 0 {
            node.queueFree()
          }
          return
        }

        updateEnemy(delta)
      }
    }

    func updateEnemy(_ delta: Double) {
      // Update knockback
      if knockbackTimer > 0 {
        knockbackTimer -= delta
        position += knockbackVelocity * Float(delta)

        // Decay knockback velocity
        knockbackVelocity = knockbackVelocity.lerp(to: .zero, weight: 10.0 * delta)

        if knockbackTimer <= 0 {
          knockbackVelocity = .zero
        }
      } else {
        if flies {
          // Flying enemy: horizontal patrol + sine wave vertical movement
          sineTimer += delta
          position.x += direction * speed * Float(delta)

          // Sine wave vertical offset (30 pixel amplitude)
          let sineOffset = sin(Float(sineTimer * 2)) * 30
          position.y = spawnPoint.y + sineOffset

          // Check patrol bounds and reverse direction
          if position.x <= patrolLeft {
            position.x = patrolLeft
            direction = 1
          } else if position.x >= patrolRight {
            position.x = patrolRight
            direction = -1
          }

          // Shooting logic for flying enemies
          if let interval = shootInterval {
            shootTimer -= delta
            if shootTimer <= 0 {
              shootTimer = interval
              let projectileDirection: Vector2 = [direction > 0 ? 1 : -1, 0]
              GameEvent.enemyProjectileFired(
                position: position + [size / 2, size / 2],
                direction: projectileDirection
              ).emit()
            }
          }
        } else {
          // Ground patrol enemy: normal horizontal movement
          position.x += direction * speed * Float(delta)

          // Check patrol bounds and reverse direction
          if position.x <= patrolLeft {
            position.x = patrolLeft
            direction = 1
          } else if position.x >= patrolRight {
            position.x = patrolRight
            direction = -1
          }
        }
      }
    }

    func takeDamage(_ damage: Int, from sourcePosition: Vector2 = .zero) {
      health -= damage

      // Apply horizontal knockback if not dying
      if health > 0 {
        let horizontalDirection = position.x - sourcePosition.x
        let knockbackDir: Float = horizontalDirection >= 0 ? 1.0 : -1.0
        knockbackVelocity = [knockbackDir * knockbackForce, 0]
        knockbackTimer = knockbackDuration
      }

      if health <= 0 {
        health = 0
        isDying = true
        deathTimer = deathFadeDuration
        let deathPos = position + [size / 2, size / 2]
        GameEvent.enemyKilled(position: deathPos).emit()

        // 25% chance to drop health
        if Float.random(in: 0 ... 1) < healthDropChance {
          GameEvent.healthDropSpawned(position: deathPos).emit()
        }
      }
    }

    func respawn() {
      position = spawnPoint
      direction = 1
      health = maxHealth
      isDying = false
      deathTimer = 0
      knockbackVelocity = .zero
      knockbackTimer = 0
    }
  }
}
