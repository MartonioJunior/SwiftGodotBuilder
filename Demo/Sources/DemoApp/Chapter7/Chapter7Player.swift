import Foundation
import SwiftGodot
import SwiftGodotBuilder

struct Chapter7Player: GView {
  let spawnPoint: Vector2
  let screenWidth: Float
  let screenHeight: Float
  let gravity: Float
  let state: ObservableState<Chapter7GameViewState>

  private var vm: Chapter7GameViewState { state.wrappedValue }

  // Player-specific constants
  let size: Float = 16
  let jumpSpeed: Float = 180
  let moveSpeed: Float = 100
  let maxHealth: Int = 3
  let invincibilityDuration: Double = 1.0
  let attackDuration: Double = 0.2

  @State var position: Vector2 = .zero
  @State var velocity: Vector2 = [0, 0]
  @State var isInvincible: Bool = false
  @State var invincibilityTimer: Double = 0
  @State var isAttacking: Bool = false
  @State var attackTimer: Double = 0
  @State var playerNode: CharacterBody2D?
  @State var wasOnFloor: Bool = false
  @State var movementTimer: Double = 0

  init(
    spawnPoint: Vector2,
    screenWidth: Float,
    screenHeight: Float,
    gravity: Float,
    state: ObservableState<Chapter7GameViewState>
  ) {
    self.spawnPoint = spawnPoint
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
    self.gravity = gravity
    self.state = state
    position = spawnPoint
  }

  var body: some GView {
    CharacterBody2D$ {
      // Camera following the player
      Camera2D$()
        .enabled(true)
        .positionSmoothingEnabled(true)
        .positionSmoothingSpeed(5.0)
        .watch(state, \.cameraOffset) { camera, offset in
          camera.offset = offset
        }
        .onReady { camera in
          camera.makeCurrent()
        }

      ColorBox$()
        .size([size, size])
        .bind(\.color, to: $isInvincible, $invincibilityTimer, $isAttacking) { invincible, timer, attacking in
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
      .collisionLayer(.delta)
      .bind(\.processMode, to: $isAttacking) { attacking in
        attacking ? .inherit : .disabled
      }
      .visible($isAttacking)
    }
    .collisionLayer(.beta)
    .position($position)
    .velocity($velocity)
    .watch(state, \.isMenu) { node, isMenu in
      node.visible = !isMenu
    }
    .ref($playerNode)
    .onEvent(Chapter7Event.self) { _, event in
      switch event {
      case .gameReset:
        respawn()
      case let .playerHit(damage, _):
        takeDamage(damage)
      default:
        break
      }
    }
    .onProcess { _, delta in
      guard vm.isPlaying else {
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
      Chapter7Event.jumped(position: position + Vector2(x: size / 2, y: size)).emit()
    }

    // Attack
    if Action("attack").isJustPressed, !isAttacking {
      isAttacking = true
      attackTimer = attackDuration
      Chapter7Event.attacked(position: position).emit()
    }

    // Check landing before moveAndSlide (velocity gets reset on collision)
    let wasInAir = !wasOnFloor
    let fallingVelocity = vel.y

    // Move the player
    player.velocity = vel
    player.moveAndSlide()

    // Update state
    velocity = player.velocity
    position = player.position

    // Landing impact - check velocity before it was reset by collision
    if wasInAir, player.isOnFloor(), fallingVelocity > 100 {
      Chapter7Event.landed(position: position + Vector2(x: size / 2, y: size), impact: Float(fallingVelocity)).emit()
    }
    wasOnFloor = player.isOnFloor()

    // Movement trail particles (keep this for now, no semantic event needed)
    if abs(velocity.x) > 50, player.isOnFloor() {
      movementTimer += delta
      if movementTimer > 0.1 {
        // TODO: Could be a 'moving' or 'running' event if needed
        movementTimer = 0
      }
    }

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
      takeDamage(vm.playerHealth)
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

    vm.playerHealth -= damage

    if vm.playerHealth <= 0 {
      vm.playerHealth = 0
      Chapter7Event.playerDied(position: position + Vector2(x: size / 2, y: size / 2)).emit()
    } else {
      Chapter7Event.playerHit(damage: damage, position: position).emit()
      isInvincible = true
      invincibilityTimer = invincibilityDuration
    }
  }

  func respawn() {
    position = spawnPoint
    velocity = [0, 0]
    vm.playerHealth = maxHealth
    isInvincible = true
    invincibilityTimer = invincibilityDuration
    isAttacking = false
    attackTimer = 0
  }
}
