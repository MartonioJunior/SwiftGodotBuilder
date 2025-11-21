import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter2Player: GView {
  let spawnPoint: Vector2
  let screenWidth: Float
  let screenHeight: Float
  let gravity: Float
  let gameState: State<Chapter2GameState>

  // Player-specific constants
  let size: Float = 16
  let jumpSpeed: Float = 180
  let moveSpeed: Float = 100
  let maxHealth: Int = 3
  let invincibilityDuration: Double = 1.0
  let attackDuration: Double = 0.2
  let health: State<Int>

  @State var position: Vector2 = .zero
  @State var velocity: Vector2 = [0, 0]
  @State var isInvincible: Bool = false
  @State var invincibilityTimer: Double = 0
  @State var isAttacking: Bool = false
  @State var attackTimer: Double = 0
  @State var playerNode: CharacterBody2D?

  init(
    spawnPoint: Vector2,
    screenWidth: Float,
    screenHeight: Float,
    gravity: Float,
    gameState: State<Chapter2GameState>,
    health: State<Int>
  ) {
    self.spawnPoint = spawnPoint
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    self.gravity = gravity
    self.gameState = gameState
    self.health = health
    position = spawnPoint
  }

  var body: some GView {
    let playerColor = $isInvincible.computed(with: $invincibilityTimer, $isAttacking) { invincible, timer, attacking in
      if invincible {
        // Flash white during invincibility
        let flash = sin(timer * 20) > 0
        return flash ? Color(r: 1.0, g: 1.0, b: 1.0) : Color(r: 0.3, g: 0.5, b: 0.9)
      } else if attacking {
        return Color(r: 1.0, g: 0.7, b: 0.3)
      } else {
        return Color(r: 0.3, g: 0.5, b: 0.9)
      }
    }

    return CharacterBody2D$ {
      ColorBox$()
        .size([size, size])
        .color(playerColor)

      CollisionShape2D$()
        .shape(RectangleShape2D(w: size, h: size))
        .position([size / 2, size / 2])

      // Attack hitbox
      Area2D$ {
        ColorBox$()
          .size([12, 12])
          .color(Color(r: 1.0, g: 1.0, b: 0.5, a: 0.7))

        CollisionShape2D$()
          .shape(RectangleShape2D(w: 12, h: 12))
          .position([6, 6])
      }
      .position([8, 2])
      .collisionLayer(.delta) // Enemy cannot take damage without this
      .bind(\.processMode, to: $isAttacking) { attacking in
        attacking ? .inherit : .disabled
      }
      .visible($isAttacking)
    }
    .collisionLayer(.beta) // Enemy cannot damage player without this, goal cannot detect player without this
    .position($position)
    .velocity($velocity)
    .watch(gameState) { node, state in
      node.visible = state != .menu
    }
    .ref($playerNode)
    .onEvent(Chapter2Event.self) { _, event in
      switch event {
      case .resetGame:
        respawn()
      case let .playerHit(damage):
        takeDamage(damage)
      case .goalReached, .playerDied, .enemyKilled:
        break
      }
    }
    .onProcess { _, delta in
      guard gameState.wrappedValue == .playing else {
        return
      }

      guard let player = playerNode else {
        return
      }

      updatePlayer(player, delta)
      updateTimers(delta)
    }
  }

  func updatePlayer(_ player: CharacterBody2D, _ delta: Double) {
    var vel = velocity

    // Apply gravity
    vel.y += gravity * Float(delta)

    // Horizontal movement
    var input: Float = 0
    if Action("move_left").isPressed {
      input -= 1
    }
    if Action("move_right").isPressed {
      input += 1
    }
    vel.x = input * moveSpeed

    // Jump
    if Action("jump").isJustPressed, player.isOnFloor() {
      vel.y = -jumpSpeed
    }

    // Attack
    if Action("attack").isJustPressed, !isAttacking {
      isAttacking = true
      attackTimer = attackDuration
    }

    // Move the player
    player.velocity = vel
    player.moveAndSlide()

    // Update state
    velocity = player.velocity
    position = player.position

    // Keep player in bounds
    if position.x < 0 {
      position.x = 0
      player.position = position
    } else if position.x > screenWidth - size {
      position.x = screenWidth - size
      player.position = position
    }

    // Fall off screen = die
    if position.y > screenHeight + 100 {
      takeDamage(health.wrappedValue)
    }
  }

  func updateTimers(_ delta: Double) {
    // Invincibility timer
    if isInvincible {
      invincibilityTimer -= delta
      if invincibilityTimer <= 0 {
        isInvincible = false
        invincibilityTimer = 0
      }
    }

    // Attack timer
    if isAttacking {
      attackTimer -= delta
      if attackTimer <= 0 {
        isAttacking = false
        attackTimer = 0
      }
    }
  }

  func takeDamage(_ damage: Int) {
    guard !isInvincible else { return }

    health.wrappedValue -= damage
    if health.wrappedValue <= 0 {
      health.wrappedValue = 0
      Chapter2Event.playerDied.emit()
    } else {
      isInvincible = true
      invincibilityTimer = invincibilityDuration
    }
  }

  func respawn() {
    position = spawnPoint
    velocity = [0, 0]
    health.wrappedValue = maxHealth
    isInvincible = true
    invincibilityTimer = invincibilityDuration
    isAttacking = false
    attackTimer = 0
  }
}
