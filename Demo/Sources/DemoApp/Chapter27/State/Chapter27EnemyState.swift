import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  @Observable
  class EnemyState {
    // Config from EnemyDefinition
    let size: Float
    let speed: Float
    let maxHealth: Int
    let touchDamage: Int
    let deathFadeDuration: Double
    let knockbackForce: Float
    let knockbackDuration: Double
    let shootInterval: Double?
    let healthDropChance: Float
    let flies: Bool
    let moveAnimation: String
    let hitAnimation: String
    let deathAnimation: String

    // Spawn/patrol config
    let spawnPoint: Vector2
    let patrolLeft: Float
    let patrolRight: Float

    // Dynamic state
    var position: Vector2 = .zero
    var direction: Float = 1
    var health = 0
    var isDying = false
    var deathTimer = 0.0
    var knockbackVelocity: Vector2 = .zero
    var knockbackTimer = 0.0
    var sineTimer = 0.0
    var shootTimer = 0.0
    var hitTimer = 0.0
    var animationName = ""

    init(definition: EnemyDefinition, spawnPoint: Vector2, patrolLeft: Float, patrolRight: Float) {
      size = definition.size
      speed = definition.speed
      maxHealth = definition.maxHealth
      touchDamage = definition.touchDamage
      deathFadeDuration = definition.deathFadeDuration
      knockbackForce = definition.knockbackForce
      knockbackDuration = definition.knockbackDuration
      shootInterval = definition.shootInterval
      healthDropChance = definition.healthDropChance
      flies = definition.flies
      moveAnimation = definition.moveAnimation
      hitAnimation = definition.hitAnimation
      deathAnimation = definition.deathAnimation

      self.spawnPoint = spawnPoint
      self.patrolLeft = patrolLeft
      self.patrolRight = patrolRight

      position = spawnPoint
      health = maxHealth
      shootTimer = shootInterval ?? 0
      animationName = moveAnimation
    }

    convenience init(entity: LDEntity) {
      let enemyType: EnemyType = entity.field("enemyType")?.asEnum() ?? .patrol
      let definition: EnemyDefinition = enemyType == .flyer ? .flyer : .patrol

      let spawnPoint = entity.positionTopLeft
      let patrolLeft = entity.field("patrolLeft")?.asFloat() ?? (entity.positionCenter.x - 50)
      let patrolRight = entity.field("patrolRight")?.asFloat() ?? (entity.positionCenter.x + 50)

      self.init(definition: definition, spawnPoint: spawnPoint, patrolLeft: patrolLeft, patrolRight: patrolRight)
    }

    /// Update enemy movement, shooting, and timers each frame.
    func update(delta: Double) {
      // Update hit animation timer
      if hitTimer > 0 {
        hitTimer -= delta
        if hitTimer <= 0 { animationName = moveAnimation }
      }

      // Knockback interrupts other movement
      if knockbackTimer > 0 {
        knockbackTimer -= delta
        position += knockbackVelocity * delta
        knockbackVelocity = knockbackVelocity.lerp(to: .zero, weight: 10.0 * delta)
        if knockbackTimer <= 0 { knockbackVelocity = .zero }
        return
      }

      if flies {
        // Flying movement with sine wave
        sineTimer += delta
        position.x += direction * speed * Float(delta)
        position.y = spawnPoint.y + sin(Float(sineTimer * 2)) * 30

        // Shooting logic for flying enemies
        if let interval = shootInterval {
          shootTimer -= delta
          if shootTimer <= 0 {
            shootTimer = interval
            let projectileDir: Vector2 = [direction > 0 ? 1 : -1, 0]
            GameEvent.enemyFiredProjectile(
              position: position + [size / 2, size / 2],
              direction: projectileDir
            ).emit()
          }
        }
      } else {
        // Ground patrol movement
        position.x += direction * speed * Float(delta)
      }

      // Patrol bounds check
      if position.x <= patrolLeft {
        position.x = patrolLeft
        direction = 1
      } else if position.x >= patrolRight {
        position.x = patrolRight
        direction = -1
      }
    }

    /// Apply damage to enemy. Handles knockback, death, and health drop spawning.
    func takeDamage(_ damage: Int, from sourcePosition: Vector2 = .zero) {
      health -= damage

      // Emit damage dealt event for floating numbers
      let damagePos = position + [size / 2, 0]
      GameEvent.enemyTookDamage(amount: damage, position: damagePos).emit()

      // Show hit animation
      hitTimer = 0.15
      animationName = hitAnimation

      // Apply horizontal knockback if not dying
      if health > 0 {
        let knockbackDir: Float = (position.x - sourcePosition.x) >= 0 ? 1.0 : -1.0
        knockbackVelocity = [knockbackDir * knockbackForce, 0]
        knockbackTimer = knockbackDuration
      }

      if health <= 0 {
        health = 0
        isDying = true
        deathTimer = deathFadeDuration
        animationName = deathAnimation

        let deathPos = position + [size / 2, size / 2]
        GameEvent.enemyKilled(position: deathPos).emit()

        // Random health drop - spawned via DropSpawner
        if Float.random(in: 0 ... 1) < healthDropChance {
          let dropItem = ConsumableDefinition.health
          let dropSize = AseSprite.frameSize(path: "Items", tag: dropItem.animation)
          let dropPos = position + [size / 2, size / 2] - dropSize / 2
          GameEvent.itemDropped(.consumable(dropItem), position: dropPos).emit()
        }
      }
    }

    /// Reset enemy to spawn state.
    func respawn() {
      position = spawnPoint
      direction = 1
      health = maxHealth
      isDying = false
      deathTimer = 0
      knockbackVelocity = .zero
      knockbackTimer = 0
      hitTimer = 0
      animationName = moveAnimation
    }

    /// Update death fade timer. Returns true if enemy should be freed.
    func updateDeath(delta: Double) -> Bool {
      deathTimer -= delta
      return deathTimer <= 0
    }
  }
}
