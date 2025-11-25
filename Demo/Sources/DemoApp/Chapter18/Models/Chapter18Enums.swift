import SwiftGodot
import SwiftGodotBuilder

enum Chapter18 {
  enum GameState {
    case levelSelect
    case playing
    case paused
    case settings
    case levelComplete
    case gameOver
  }

  enum Event: EmittableEvent {
    case goalReached
    case gameReset

    case jumped(position: Vector2)
    case landed(position: Vector2, impact: Float)
    case attacked(position: Vector2)

    case playerDied(position: Vector2)
    case playerHit(damage: Int, position: Vector2)

    case enemyKilled(position: Vector2)
    case enemyProjectileFired(position: Vector2, direction: Vector2)
    case healthDropSpawned(position: Vector2)

    case bossHit(damage: Int, position: Vector2)
    case bossPhaseChanged(phase: BossPhase)
    case bossDefeated(position: Vector2)
    case bossAttack(attackType: BossAttackType, position: Vector2)

    case healthCollected(position: Vector2)
    case coinCollected(position: Vector2)
    case keyCollected(position: Vector2)
    case doorUnlocked(position: Vector2)
    case ammoCollected(position: Vector2)

    case projectileFired(position: Vector2, direction: Vector2)
    case projectileHitWall(position: Vector2)
    case projectileHitEnemy(position: Vector2)
    case weaponSwitched(weaponType: WeaponType)

    case enteredWater
    case exitedWater

    case checkpointActivated(id: Int, position: Vector2)
  }

  enum BossPhase: Int {
    case one = 1
    case two = 2
    case three = 3
    case defeated = 0
  }

  enum BossAttackType {
    case shoot
    case jump
    case charge
    case summon
  }

  enum ParticleType {
    case jumpDust
    case landingImpact
    case movementTrail
    case deathExplosion
    case enemyHit
    case coinSparkle
    case projectileTrail
  }

  enum WeaponType {
    case melee
    case ranged
  }

  enum EnemyType {
    case patrol
    case flyer
  }
}
