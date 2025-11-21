import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Audio Manager

struct Chapter11AudioManager: GView {
  let state: ObservableState<Chapter11GameViewState>

  var body: some GView {
    Node2D$ {
      // Sound effects using BfxrSound (built-in polyphony)
      Chapter11SFXPlayer(state: state)
    }
  }
}

// MARK: - SFX Player

struct Chapter11SFXPlayer: GView {
  let state: ObservableState<Chapter11GameViewState>

  private var vm: Chapter11GameViewState { state.wrappedValue }

  var body: some GView {
    Node2D$ {
      // Jump sound
      BfxrSound$()
        .bfxrPath("sounds/Jump.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .jumped = event {
            sound.playSound()
          }
        }

      // Land sound
      BfxrSound$()
        .bfxrPath("sounds/Land.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .landed = event {
            sound.playSound()
          }
        }

      // Attack sound
      BfxrSound$()
        .bfxrPath("sounds/Attack.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .attacked = event {
            sound.playSound()
          }
        }

      // Hit sound
      BfxrSound$()
        .bfxrPath("sounds/Hit.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .playerHit = event {
            sound.playSound()
          }
        }

      // Death sound
      BfxrSound$()
        .bfxrPath("sounds/Death.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .playerDied = event {
            sound.playSound()
          }
        }

      // Victory sound (triggered by goalReached event)
      BfxrSound$()
        .bfxrPath("sounds/Victory.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .goalReached = event {
            sound.playSound()
          }
        }

      // Coin pickup sound
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .coinCollected = event {
            sound.playSound()
          }
        }

      // Key pickup sound (reuse coin sound)
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .keyCollected = event {
            sound.playSound()
          }
        }

      // Door unlock sound (reuse coin sound)
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .doorUnlocked = event {
            sound.playSound()
          }
        }

      // Projectile fire sound
      BfxrSound$()
        .bfxrPath("sounds/ProjectileFire.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .projectileFired = event {
            sound.playSound()
          }
        }

      // Projectile hit wall sound
      BfxrSound$()
        .bfxrPath("sounds/ProjectileImpactWall.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .projectileHitWall = event {
            sound.playSound()
          }
        }

      // Projectile hit enemy sound
      BfxrSound$()
        .bfxrPath("sounds/ProjectileImpactEnemy.bfxr")
        .onEvent(Chapter11Event.self) { sound, event in
          if case .projectileHitEnemy = event {
            sound.playSound()
          }
        }
    }
  }
}
