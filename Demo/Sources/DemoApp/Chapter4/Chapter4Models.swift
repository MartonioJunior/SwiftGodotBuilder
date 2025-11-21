import Foundation
import SwiftGodot
import SwiftGodotBuilder

enum Chapter4GameState {
  case menu
  case playing
  case victory
  case gameOver
}

enum Chapter4Event: EmittableEvent {
  case goalReached
  case playerDied
  case playerHit(damage: Int)
  case enemyKilled
  case resetGame
  case screenShake(intensity: Float)
  case screenFlash
}
