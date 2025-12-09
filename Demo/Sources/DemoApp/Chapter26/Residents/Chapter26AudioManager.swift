import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct SFXPlayer: GView {
    var body: some GView {
      Node2D$ {
        BfxrSound$().bfxrPath("sounds/Jump.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .jumped = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/Land.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .landed = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/Attack.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .attacked = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/Hit.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .playerHit = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/Death.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .playerDied = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/Victory.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .goalReached = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/Coin.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .collected(.coin, _) = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/Key.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .collected(.key, _) = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/Door.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .doorUnlocked = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/ProjectileFire.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .projectileFired = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/ProjectileImpactWall.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .projectileHitWall = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/ProjectileImpactEnemy.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .projectileHitEnemy = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/TerrainBreak.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .terrainDestroyed = event { sound.playSound() }
          }
      }
    }
  }
}
