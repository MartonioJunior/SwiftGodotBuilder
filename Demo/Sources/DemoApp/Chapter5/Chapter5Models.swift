import Foundation
import SwiftGodot
import SwiftGodotBuilder

enum Chapter5GameState {
  case menu
  case playing
  case victory
  case gameOver
}

enum Chapter5Event: EmittableEvent {
  case goalReached
  case playerDied
  case playerHit(damage: Int)
  case enemyKilled
  case resetGame
  case screenShake(intensity: Float)
  case screenFlash
  case spawnParticles(type: Chapter5ParticleType, position: Vector2)
}

enum Chapter5ParticleType {
  case jumpDust
  case landingImpact
  case movementTrail
  case deathExplosion
  case enemyHit
  case coinSparkle
}
