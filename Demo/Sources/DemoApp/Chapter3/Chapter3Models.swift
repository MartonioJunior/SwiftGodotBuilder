import Foundation
import SwiftGodot
import SwiftGodotBuilder

enum Chapter3GameState {
  case menu
  case playing
  case victory
  case gameOver
}

enum Chapter3Event: EmittableEvent {
  case goalReached
  case playerDied
  case playerHit(damage: Int)
  case enemyKilled
  case resetGame
}
