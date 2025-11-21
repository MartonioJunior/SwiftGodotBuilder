import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter1Enemy: GView {
  let spawnPoint: Vector2
  let patrolLeft: Float
  let patrolRight: Float
  let gravity: Float
  let gameState: State<Chapter1GameState>

  // Enemy-specific constants
  let size: Float = 16
  let speed: Float = 40

  @State var position: Vector2 = .zero
  @State var direction: Float = 1 // 1 = right, -1 = left
  @State var enemyNode: CharacterBody2D?

  init(
    spawnPoint: Vector2,
    patrolLeft: Float,
    patrolRight: Float,
    gravity: Float,
    gameState: State<Chapter1GameState>
  ) {
    self.spawnPoint = spawnPoint
    self.patrolLeft = patrolLeft
    self.patrolRight = patrolRight
    self.gravity = gravity
    self.gameState = gameState
    position = spawnPoint
  }

  var body: some GView {
    CharacterBody2D$ {
      ColorBox$()
        .size([size, size])
        .color(Color(r: 0.9, g: 0.3, b: 0.3))

      CollisionShape2D$()
        .shape(RectangleShape2D(w: size, h: size))
        .position([size / 2, size / 2])

      // Enemy collision detection area
      Area2D$ {
        CollisionShape2D$()
          .shape(RectangleShape2D(w: size, h: size))
          .position([size / 2, size / 2])
      }
      .onSignal(\.bodyEntered) { _, body in
        if gameState.wrappedValue == .playing, body is CharacterBody2D {
          Chapter1Event.playerHit.emit()
        }
      }
    }
    .position($position)
    .bind(\.visible, to: gameState) { $0 != .menu }
    .ref($enemyNode)
    .onEvent(Chapter1Event.self) { _, event in
      if case .resetPlayer = event {
        respawn()
      }
    }
    .onProcess { _, delta in
      guard gameState.wrappedValue == .playing else {
        return
      }

      guard let enemy = enemyNode else {
        return
      }

      updateEnemy(enemy, delta)
    }
  }

  func updateEnemy(_ enemy: CharacterBody2D, _ delta: Double) {
    // Simple patrol movement
    position.x += direction * speed * Float(delta)

    // Check patrol bounds and reverse direction
    if position.x <= patrolLeft {
      position.x = patrolLeft
      direction = 1
    } else if position.x >= patrolRight {
      position.x = patrolRight
      direction = -1
    }

    // Apply gravity to enemy
    let enemyVelocity = Vector2(x: 0, y: gravity * Float(delta))
    enemy.velocity = enemyVelocity
    enemy.moveAndSlide()

    // Update position from physics
    position = enemy.position
  }

  func respawn() {
    position = spawnPoint
    direction = 1
  }
}
