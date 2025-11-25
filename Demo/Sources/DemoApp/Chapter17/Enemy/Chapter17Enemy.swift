import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter17 {
  struct Enemy: GView {
    let type: EnemyType
    let spawnPoint: Vector2
    let patrolLeft: Float
    let patrolRight: Float
    let gravity: Float
    let state: ObservableState<GameViewState>

    // Enemy-specific constants
    let size: Float = 16
    let speed: Float = 40
    let maxHealth: Int = 2
    let touchDamage: Int = 1
    let deathFadeDuration: Double = 0.5
    let knockbackForce: Float = 150
    let knockbackDuration: Double = 0.2
    let shootInterval: Double = 2.5 // For flying enemies
    let healthDropChance: Float = 0.25 // 25% chance

    @State var position: Vector2 = .zero
    @State var direction: Float = 1
    @State var health = 2
    @State var isDying = false
    @State var deathTimer = 0.0
    @State var knockbackVelocity: Vector2 = .zero
    @State var knockbackTimer = 0.0
    @State var sineTimer = 0.0 // For flying sine wave movement
    @State var shootTimer = 0.0 // For flying enemy shooting

    let palette = Palette()

    init(
      type: EnemyType = .patrol,
      spawnPoint: Vector2,
      patrolLeft: Float,
      patrolRight: Float,
      gravity: Float,
      state: ObservableState<GameViewState>
    ) {
      self.type = type
      self.spawnPoint = spawnPoint
      self.patrolLeft = patrolLeft
      self.patrolRight = patrolRight
      self.gravity = gravity
      self.state = state
      position = spawnPoint
      health = maxHealth
      shootTimer = shootInterval
    }

    var body: some GView {
      Node2D$ {
        ColorBox$()
          .size([size, size])
          .bind(\.color, to: $health, $isDying, $deathTimer) { h, dying, timer in
            if dying {
              // Fading death color based on type
              let alpha = Float(timer / deathFadeDuration)
              if type == .flyer {
                let c = palette.enemyPurple
                return Color(r: c.red, g: c.green, b: c.blue, a: alpha)
              } else {
                let c = palette.enemyRed
                return Color(r: c.red, g: c.green, b: c.blue, a: alpha)
              }
            }
            // Flying enemies are purple, patrol enemies are red
            if type == .flyer {
              let healthPercent = Float(h) / Float(maxHealth)
              return healthPercent > 0.5 ? palette.enemyPurple : palette.enemyPurpleDark
            } else {
              let healthPercent = Float(h) / Float(maxHealth)
              return healthPercent > 0.5 ? palette.enemyRed : palette.enemyRedDark
            }
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
        .collisionLayer(.delta) // Enemy damage area
        .collisionMask([.beta, .delta]) // Detects player body and player attacks
        .onSignal(\.bodyEntered) { _, body in
          // Colliding with player's CharacterBody2D
          if !isDying, body is CharacterBody2D {
            Event.playerHit(damage: touchDamage, position: position).emit()
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
      .onEvent(Event.self) { _, event in
        if case .gameReset = event {
          respawn()
        }
      }
      .onProcess { node, delta in
        guard state.wrappedValue.isPlaying else {
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
        // Type-specific movement
        if type == .flyer {
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
          shootTimer -= delta
          if shootTimer <= 0 {
            shootTimer = shootInterval
            // Fire projectile toward player (simplified: just fire left/right based on direction)
            let projectileDirection: Vector2 = [direction > 0 ? 1 : -1, 0]
            Event.enemyProjectileFired(
              position: position + [size / 2, size / 2],
              direction: projectileDirection
            ).emit()
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
        Event.enemyKilled(position: deathPos).emit()

        // 25% chance to drop health
        if Float.random(in: 0 ... 1) < healthDropChance {
          Event.healthDropSpawned(position: deathPos).emit()
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
