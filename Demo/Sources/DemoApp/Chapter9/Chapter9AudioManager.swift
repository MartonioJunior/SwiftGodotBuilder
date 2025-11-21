import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Audio Manager

struct Chapter9AudioManager: GView {
  let state: ObservableState<Chapter9GameViewState>

  var body: some GView {
    Node2D$ {
      // Sound effects using BfxrSound (built-in polyphony)
      Chapter9SFXPlayer(state: state)
    }
  }
}

// MARK: - SFX Player

struct Chapter9SFXPlayer: GView {
  let state: ObservableState<Chapter9GameViewState>

  private var vm: Chapter9GameViewState { state.wrappedValue }

  var body: some GView {
    Node2D$ {
      // Jump sound
      BfxrSound$()
        .bfxrPath("sounds/Jump.bfxr")
        .onEvent(Chapter9Event.self) { sound, event in
          if case .jumped = event {
            sound.playSound()
          }
        }

      // Land sound
      BfxrSound$()
        .bfxrPath("sounds/Land.bfxr")
        .onEvent(Chapter9Event.self) { sound, event in
          if case .landed = event {
            sound.playSound()
          }
        }

      // Attack sound
      BfxrSound$()
        .bfxrPath("sounds/Attack.bfxr")
        .onEvent(Chapter9Event.self) { sound, event in
          if case .attacked = event {
            sound.playSound()
          }
        }

      // Hit sound
      BfxrSound$()
        .bfxrPath("sounds/Hit.bfxr")
        .onEvent(Chapter9Event.self) { sound, event in
          if case .playerHit = event {
            sound.playSound()
          }
        }

      // Death sound
      BfxrSound$()
        .bfxrPath("sounds/Death.bfxr")
        .onEvent(Chapter9Event.self) { sound, event in
          if case .playerDied = event {
            sound.playSound()
          }
        }

      // Victory sound (triggered by goalReached event)
      BfxrSound$()
        .bfxrPath("sounds/Victory.bfxr")
        .onEvent(Chapter9Event.self) { sound, event in
          if case .goalReached = event {
            sound.playSound()
          }
        }

      // Coin pickup sound
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter9Event.self) { sound, event in
          if case .coinCollected = event {
            sound.playSound()
          }
        }

      // Key pickup sound (reuse coin sound)
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter9Event.self) { sound, event in
          if case .keyCollected = event {
            sound.playSound()
          }
        }

      // Door unlock sound (reuse coin sound)
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter9Event.self) { sound, event in
          if case .doorUnlocked = event {
            sound.playSound()
          }
        }
    }
  }
}
