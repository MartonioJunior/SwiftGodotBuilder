import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  enum GameEvent: EmittableEvent {
    // Game flow
    case checkpointActivated(id: Int, position: Vector2)
    case goalReached
    case gameReset

    // Player
    case playerJumped(position: Vector2)
    case playerLanded(position: Vector2, impact: Float)
    case playerAttacked(position: Vector2, facing: Facing)
    case playerDied(position: Vector2)
    case playerTookDamage(damage: Int, position: Vector2)

    // Enemies
    case enemyKilled(position: Vector2)
    case enemyHitByMelee(targetId: Int, position: Vector2)
    case enemyTookDamage(amount: Int, position: Vector2)
    case enemyFiredProjectile(position: Vector2, direction: Vector2)
    case bossPhaseChanged(phase: BossPhase)
    case bossDefeated(position: Vector2)
    case bossSummonedMinions

    // Pickups
    case consumableCollected(ConsumableDefinition, position: Vector2)
    case weaponCollected(ActorWeapon, position: Vector2)
    case ammoCollected(weapon: ActorWeapon, amount: Int, position: Vector2)
    case itemDropped(DropType, position: Vector2)

    // Projectiles
    case projectileFired(position: Vector2, direction: Vector2)
    case projectileHitWall(position: Vector2)
    case enemyHitByProjectile(targetId: Int, position: Vector2)

    // Level
    case terrainDestroyed(position: Vector2)
  }
}
