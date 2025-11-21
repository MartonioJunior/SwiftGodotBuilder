import Foundation
import SwiftGodot
import SwiftGodotBuilder

// MARK: - Audio Manager

struct Chapter8AudioManager: GView {
  let state: ObservableState<Chapter8GameViewState>

  var body: some GView {
    Node2D$ {
      // Sound effects using BfxrSound (built-in polyphony)
      Chapter8SFXPlayer(state: state)
    }
  }
}

// MARK: - SFX Player

struct Chapter8SFXPlayer: GView {
  let state: ObservableState<Chapter8GameViewState>

  private var vm: Chapter8GameViewState { state.wrappedValue }

  var body: some GView {
    Node2D$ {
      // Jump sound
      BfxrSound$()
        .bfxrPath("sounds/Jump.bfxr")
        .onEvent(Chapter8Event.self) { sound, event in
          if case .jumped = event {
            sound.playSound()
          }
        }

      // Land sound
      BfxrSound$()
        .bfxrPath("sounds/Land.bfxr")
        .onEvent(Chapter8Event.self) { sound, event in
          if case .landed = event {
            sound.playSound()
          }
        }

      // Attack sound
      BfxrSound$()
        .bfxrPath("sounds/Attack.bfxr")
        .onEvent(Chapter8Event.self) { sound, event in
          if case .attacked = event {
            sound.playSound()
          }
        }

      // Hit sound
      BfxrSound$()
        .bfxrPath("sounds/Hit.bfxr")
        .onEvent(Chapter8Event.self) { sound, event in
          if case .playerHit = event {
            sound.playSound()
          }
        }

      // Death sound
      BfxrSound$()
        .bfxrPath("sounds/Death.bfxr")
        .onEvent(Chapter8Event.self) { sound, event in
          if case .playerDied = event {
            sound.playSound()
          }
        }

      // Victory sound (triggered by goalReached event)
      BfxrSound$()
        .bfxrPath("sounds/Victory.bfxr")
        .onEvent(Chapter8Event.self) { sound, event in
          if case .goalReached = event {
            sound.playSound()
          }
        }

      // Coin pickup sound
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter8Event.self) { sound, event in
          if case .coinCollected = event {
            sound.playSound()
          }
        }

      // Key pickup sound (reuse coin sound)
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter8Event.self) { sound, event in
          if case .keyCollected = event {
            sound.playSound()
          }
        }

      // Door unlock sound (reuse coin sound)
      BfxrSound$()
        .bfxrPath("sounds/Coin.bfxr")
        .onEvent(Chapter8Event.self) { sound, event in
          if case .doorUnlocked = event {
            sound.playSound()
          }
        }
    }
  }
}
