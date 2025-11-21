import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter10Enemy: GView {
  let spawnPoint: Vector2
  let patrolLeft: Float
  let patrolRight: Float
  let gravity: Float
  let state: ObservableState<Chapter10GameViewState>

  // Enemy-specific constants
  let size: Float = 16
  let speed: Float = 40
  let maxHealth: Int = 2
  let touchDamage: Int = 1
  let deathFadeDuration: Double = 0.5

  @State var position: Vector2 = .zero
  @State var direction: Float = 1
  @State var health: Int = 2
  @State var isDying: Bool = false
  @State var deathTimer: Double = 0

  init(
    spawnPoint: Vector2,
    patrolLeft: Float,
    patrolRight: Float,
    gravity: Float,
    state: ObservableState<Chapter10GameViewState>
  ) {
    self.spawnPoint = spawnPoint
    self.patrolLeft = patrolLeft
    self.patrolRight = patrolRight
    self.gravity = gravity
    self.state = state
    position = spawnPoint
    health = maxHealth
  }

  var body: some GView {
    Node2D$ {
      ColorBox$()
        .size([size, size])
        .bind(\.color, to: $health, $isDying) { h, dying in
          if dying {
            return Color(r: 0.9, g: 0.3, b: 0.3, a: deathAlpha)
          }
          let healthPercent = Float(h) / Float(maxHealth)
          return healthPercent > 0.5 ? Color(r: 0.9, g: 0.3, b: 0.3) : Color(r: 0.6, g: 0.2, b: 0.2)
        }

      // Enemy damage area - detects player body and player attacks
      Area2D$ {
        CollisionShape2D$()
          .shape(RectangleShape2D(w: size, h: size))
          .position([size / 2, size / 2])
          .watch($isDying) { cs, isDying in
            Engine.onNextFrame { cs.disabled = isDying }
          }
      }
      .collisionLayer(.delta) // Enemy damage area
      .collisionMask([.beta, .delta]) // Detects player body and player attacks
      .onSignal(\.bodyEntered) { _, body in
        // Colliding with player's CharacterBody2D
        if !isDying, body is CharacterBody2D {
          Chapter10Event.playerHit(damage: touchDamage, position: position).emit()
        }
      }
      .onSignal(\.areaEntered) { _, _ in
        // Colliding with player's attack hitbox
        if !isDying {
          takeDamage(1)
        }
      }
    }
    .position($position)
    .watch(state, \.isMenu) { node, isMenu in
      if !isDying {
        node.visible = !isMenu
      }
    }
    .onEvent(Chapter10Event.self) { _, event in
      if case .gameReset = event {
        respawn()
      }
    }
    .onProcess { node, delta in
      guard state.wrappedValue.isPlaying else {
        return
      }

      if isDying {
        deathTimer -= delta
        if deathTimer <= 0 {
          node.visible = false
        }
        return
      }

      updateEnemy(delta)
    }
  }

  var deathAlpha: Float {
    Float(deathTimer / deathFadeDuration)
  }

  func updateEnemy(_ delta: Double) {
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
  }

  func takeDamage(_ damage: Int) {
    health -= damage

    if health <= 0 {
      health = 0
      isDying = true
      deathTimer = deathFadeDuration
      Chapter10Event.enemyKilled(position: position + Vector2(x: size / 2, y: size / 2)).emit()
    }
  }

  func respawn() {
    position = spawnPoint
    direction = 1
    health = maxHealth
    isDying = false
    deathTimer = 0
  }
}
