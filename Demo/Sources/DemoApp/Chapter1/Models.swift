import Foundation
import SwiftGodot
import SwiftGodotBuilder

enum Chapter1GameState {
  case menu
  case playing
  case victory
}

enum Chapter1Event: EmittableEvent {
  case goalReached
  case playerHit
  case resetPlayer
}
