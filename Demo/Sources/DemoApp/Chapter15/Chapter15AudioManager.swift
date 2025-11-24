import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Audio Manager

struct Chapter15AudioManager: GView {
  let state: ObservableState<Chapter15GameViewState>
  let settings: ObservableState<Chapter15GameSettings>

  var body: some GView {
    Node2D$ {
      Chapter15SFXPlayer(state: state)
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
    // Master bus (index 0) controls overall volume
    let masterDb = linearToDb(settings.wrappedValue.masterVolume * settings.wrappedValue.sfxVolume)
    AudioServer.setBusVolumeDb(busIdx: 0, volumeDb: Double(masterDb))
  }

  // Convert linear volume (0-1) to decibels
  func linearToDb(_ linear: Double) -> Float {
    if linear <= 0 {
      return -80.0 // Essentially muted
    }
    return Float(20.0 * log10(linear))
  }
}

// MARK: - SFX Player

struct Chapter15SFXPlayer: GView {
  let state: ObservableState<Chapter15GameViewState>

  private var vm: Chapter15GameViewState { state.wrappedValue }

  var body: some GView {
    Node2D$ {
      // Jump sound
      BfxrSound$()
        .bfxrPath("sounds/Jump.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .jumped = event {
            sound.playSound()
          }
        }

      // Land sound
      BfxrSound$()
        .bfxrPath("sounds/Land.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .landed = event {
            sound.playSound()
          }
        }

      // Attack sound
      BfxrSound$()
        .bfxrPath("sounds/Attack.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .attacked = event {
            sound.playSound()
          }
        }

      // Hit sound
      BfxrSound$()
        .bfxrPath("sounds/Hit.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .playerHit = event {
            sound.playSound()
          }
        }

      // Death sound
      BfxrSound$()
        .bfxrPath("sounds/Death.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .playerDied = event {
            sound.playSound()
          }
        }

      // Victory sound (triggered by goalReached event)
      BfxrSound$()
        .bfxrPath("sounds/Victory.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .goalReached = event {
            sound.playSound()
          }
        }

      // Coin pickup sound
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .coinCollected = event {
            sound.playSound()
          }
        }

      // Key pickup sound (reuse coin sound)
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .keyCollected = event {
            sound.playSound()
          }
        }

      // Door unlock sound (reuse coin sound)
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .doorUnlocked = event {
            sound.playSound()
          }
        }

      // Projectile fire sound
      BfxrSound$()
        .bfxrPath("sounds/ProjectileFire.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .projectileFired = event {
            sound.playSound()
          }
        }

      // Projectile hit wall sound
      BfxrSound$()
        .bfxrPath("sounds/ProjectileImpactWall.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .projectileHitWall = event {
            sound.playSound()
          }
        }

      // Projectile hit enemy sound
      BfxrSound$()
        .bfxrPath("sounds/ProjectileImpactEnemy.bfxr")
        .onEvent(Chapter15Event.self) { sound, event in
          if case .projectileHitEnemy = event {
            sound.playSound()
          }
        }
    }
  }
}
