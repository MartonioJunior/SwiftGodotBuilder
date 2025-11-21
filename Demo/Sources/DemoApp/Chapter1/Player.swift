import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter1Player: GView {
  let spawnPoint: Vector2
  let screenWidth: Float
  let screenHeight: Float
  let gravity: Float
  let gameState: State<Chapter1GameState>

  // Player-specific constants
  let size: Float = 16
  let jumpSpeed: Float = 180
  let moveSpeed: Float = 100

  @State var position: Vector2 = .zero
  @State var velocity: Vector2 = [0, 0]
  @State var playerNode: CharacterBody2D?

  init(
    spawnPoint: Vector2,
    screenWidth: Float,
    screenHeight: Float,
    gravity: Float,
    gameState: State<Chapter1GameState>
  ) {
    self.spawnPoint = spawnPoint
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    self.gravity = gravity
    self.gameState = gameState
    position = spawnPoint
  }

  var body: some GView {
    CharacterBody2D$ {
      ColorBox$()
        .size([size, size])
        .color(Color(r: 0.3, g: 0.5, b: 0.9))

      CollisionShape2D$()
        .shape(RectangleShape2D(w: size, h: size))
        .position([size / 2, size / 2])
    }
    .position($position)
    .velocity($velocity)
    .bind(\.visible, to: gameState) { $0 != .menu }
    .ref($playerNode)
    .onEvent(Chapter1Event.self) { _, event in
      switch event {
      case .playerHit, .resetPlayer:
        respawn()
      case .goalReached:
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

    // Fall off screen = respawn
    if position.y > screenHeight + 100 {
      respawn()
    }
  }

  func respawn() {
    position = spawnPoint
    velocity = [0, 0]
  }
}
