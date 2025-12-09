import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  enum GameEvent: EmittableEvent {
    case goalReached
    case gameReset

    case jumped(position: Vector2)
    case landed(position: Vector2, impact: Float)
    case attacked(position: Vector2, facing: Facing)

    case playerDied(position: Vector2)
    case playerHit(damage: Int, position: Vector2)

    case enemyKilled(position: Vector2)
    case meleeHitEnemy(position: Vector2)
    case damageDealt(amount: Int, position: Vector2)
    case terrainDestroyed(position: Vector2)
    case enemyProjectileFired(position: Vector2, direction: Vector2)
    case collectibleSpawned(Item, position: Vector2)

    case bossHit(damage: Int, position: Vector2)
    case bossPhaseChanged(phase: BossPhase)
    case bossDefeated(position: Vector2)

    case collected(Item, position: Vector2)
    case doorUnlocked(position: Vector2)

    case projectileFired(position: Vector2, direction: Vector2)
    case projectileHitWall(position: Vector2)
    case projectileHitEnemy(position: Vector2)
    case weaponSwitched(weaponType: WeaponType)

    case enteredWater
    case exitedWater

    case checkpointActivated(id: Int, position: Vector2)

    // Doorway events (intra-level teleportation)
    case enterDoor(targetEntityIid: String)
    case doorTeleportComplete(position: Vector2)

    // Cross-level doorway (inter-level transitions via entity ref)
    case enterCrossLevelDoor(targetLevelIid: String, targetEntityIid: String)

    var projectileFired: (position: Vector2, direction: Vector2)? {
      if case let .projectileFired(pos, dir) = self { return (pos, dir) }
      return nil
    }

    var enemyProjectileFired: (position: Vector2, direction: Vector2)? {
      if case let .enemyProjectileFired(pos, dir) = self { return (pos, dir) }
      return nil
    }
  }
}
