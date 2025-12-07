import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct AudioManager: GView {
    let state: ObservableState<GameViewState>
    let settings: ObservableState<GameSettings>

    private var gs: GameSettings { settings.wrappedValue }

    var body: some GView {
      Node2D$ {
        SFXPlayer()
      }
      .onReady { _ in
        applyVolumeSettings()
      }
      .watch(settings, \.masterVolume) { _, _ in
        applyVolumeSettings()
      }
      .watch(settings, \.sfxVolume) { _, _ in
        applyVolumeSettings()
      }
    }

    func applyVolumeSettings() {
      let masterDb = linearToDb(gs.masterVolume * gs.sfxVolume)
      AudioServer.setBusVolumeDb(busIdx: 0, volumeDb: Double(masterDb))
    }

    func linearToDb(_ linear: Double) -> Float {
      if linear <= 0 { return -80.0 }
      return Float(20.0 * log10(linear))
    }
  }

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
            if case .coinCollected = event { sound.playSound() }
          }

        BfxrSound$().bfxrPath("sounds/Key.bfxr")
          .onEvent(GameEvent.self) { sound, event in
            if case .keyCollected = event { sound.playSound() }
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
