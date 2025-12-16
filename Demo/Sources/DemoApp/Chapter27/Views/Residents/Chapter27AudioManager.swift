import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct SFXPlayer: GView {
    var body: some GView {
      Node2D$ {
        // Jump sound - actor events + legacy game events
        BfxrSound$().bfxrPath("sounds/Jump.bfxr")
          .onEvent(ActorEvent.self) { sound, event in
            if case .jumped = event { sound.playSound() }
          }
          .onEvent(GameEvent.self) { sound, event in
            if case .playerJumped = event { sound.playSound() }
          }

        // Land sound
        BfxrSound$().bfxrPath("sounds/Land.bfxr")
          .onEvent(ActorEvent.self) { sound, event in
            if case .landed = event { sound.playSound() }
          }
          .onEvent(GameEvent.self) { sound, event in
            if case .playerLanded = event { sound.playSound() }
          }

        // Attack sound (melee)
        BfxrSound$().bfxrPath("sounds/Attack.bfxr")
          .onEvent(ActorEvent.self) { sound, event in
            if case .meleeAttacked = event { sound.playSound() }
          }
          .onEvent(GameEvent.self) { sound, event in
            if case .playerAttacked = event { sound.playSound() }
          }

        // Hit sound (player taking damage)
        BfxrSound$().bfxrPath("sounds/Hit.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .playerTookDamage = event { sound.playSound() }
          }

        // Death sound
        BfxrSound$().bfxrPath("sounds/Death.bfxr")
          .onEvent(ActorEvent.self) { sound, event in
            if case .died = event { sound.playSound() }
          }
          .onEvent(GameEvent.self) { sound, event in
            if case .playerDied = event { sound.playSound() }
          }

        // Victory sound
        BfxrSound$().bfxrPath("sounds/Victory.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .goalReached = event { sound.playSound() }
          }

        // Coin pickup
        BfxrSound$().bfxrPath("sounds/Coin.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case let .consumableCollected(c, _) = event, c == .coin { sound.playSound() }
          }

        // Key pickup
        BfxrSound$().bfxrPath("sounds/Key.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case let .consumableCollected(c, _) = event, c == .key { sound.playSound() }
          }

        // Projectile fire sound
        BfxrSound$().bfxrPath("sounds/ProjectileFire.bfxr")
          .onEvent(ActorEvent.self) { sound, event in
            if case .projectileFired = event { sound.playSound() }
          }
          .onEvent(GameEvent.self) { sound, event in
            if case .projectileFired = event { sound.playSound() }
          }

        // Projectile hit wall
        BfxrSound$().bfxrPath("sounds/ProjectileImpactWall.bfxr")
          .onEvent(ActorEvent.self) { sound, event in
            if case .projectileHitWall = event { sound.playSound() }
          }
          .onEvent(GameEvent.self) { sound, event in
            if case .projectileHitWall = event { sound.playSound() }
          }

        // Projectile hit enemy
        BfxrSound$().bfxrPath("sounds/ProjectileImpactEnemy.bfxr")
          .onEvent(ActorEvent.self) { sound, event in
            if case .projectileHitTarget = event { sound.playSound() }
          }
          .onEvent(GameEvent.self) { sound, event in
            if case .enemyHitByProjectile = event { sound.playSound() }
          }

        // Terrain break
        BfxrSound$().bfxrPath("sounds/TerrainBreak.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .terrainDestroyed = event { sound.playSound() }
          }
      }
    }
  }
}
