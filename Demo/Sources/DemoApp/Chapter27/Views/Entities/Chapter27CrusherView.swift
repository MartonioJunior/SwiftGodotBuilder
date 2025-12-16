import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// A crusher that moves to endPoint and back, killing the player on contact
  struct CrusherView: GView {
    let startPosition: Vector2
    let endPosition: Vector2
    let width: Float
    let height: Float
    let gridSize: Int
    let crushDirection: Vector2
    let crushDistance: Float
    let crushSpeed: Float
    let retractSpeed: Float
    let pauseAtTop: Double
    let pauseAtBottom: Double
    let damageAmount: Int

    // Sprite (optional)
    let spriteTile: LDTilesetRect?
    let project: LDProject

    // Non-reactive state (position set directly on node)
    private class CrusherState {
      var position: Vector2 = .zero
      var isCrushing = true
      var pauseTimer = 0.0
    }

    private let vm = CrusherState()

    init(entity: LDEntity, level: LDLevel, project: LDProject) {
      gridSize = level.gridSize(for: entity) ?? 8

      startPosition = entity.positionTopLeft
      width = entity.size.x
      height = entity.size.y

      // Sprite
      spriteTile = entity.field("sprite")?.asTile()
      self.project = project

      // Get endPoint and calculate direction/distance
      let rawEndPoint = entity.field("endPoint")?.asVector2(gridSize: gridSize)
      endPosition = rawEndPoint ?? (startPosition + [0, 48])
      let delta = endPosition - startPosition
      crushDistance = Float(delta.length())
      crushDirection = crushDistance > 0 ? delta.normalized() : [0, 1]

      crushSpeed = entity.field("crushSpeed")?.asFloat() ?? 300
      retractSpeed = entity.field("retractSpeed")?.asFloat() ?? 50
      pauseAtTop = entity.field("pauseAtTop")?.asDouble() ?? 2.0
      pauseAtBottom = entity.field("pauseAtBottom")?.asDouble() ?? 0.5
      damageAmount = entity.field("damageAmount")?.asInt() ?? 1

      vm.position = startPosition
      vm.pauseTimer = pauseAtTop
    }

    var body: some GView {
      let tileCountX = Int(width) / gridSize
      let tileCountY = Int(height) / gridSize

      return AnimatableBody2D$ {
        // Visual - sprites from tileset
        if let tile = spriteTile {
          LDTileFieldView(tile: tile, project: project, gridSize: gridSize, tileCountX: tileCountX, tileCountY: tileCountY)
        }

        CollisionShape2D$()
          .shape(RectangleShape2D(w: width, h: height))
          .position([width / 2, height / 2])

        // Hazard area - damages player on contact
        Area2D$ {
          CollisionShape2D$()
            .shape(RectangleShape2D(w: width - 2, h: height - 2))
            .position([width / 2, height / 2])
        }
        .collisionLayer(.hazard)
        .collisionMask(.player)
        .onSignal(\.bodyEntered) { _, body in
          if body is CharacterBody2D {
            GameEvent.playerTookDamage(damage: damageAmount, position: vm.position).emit()
          }
        }
      }
      .position(startPosition)
      .collisionLayer(.terrain)
      .syncToPhysics(true)
      .onPhysicsProcess { body, delta in
        // Handle pause timers
        if vm.pauseTimer > 0 {
          vm.pauseTimer -= delta
          return
        }

        if vm.isCrushing {
          // Move toward endPosition
          let distanceToEnd = Float((endPosition - vm.position).length())
          let moveAmount = crushSpeed * Float(delta)

          if moveAmount >= distanceToEnd {
            vm.position = endPosition
            vm.isCrushing = false
            vm.pauseTimer = pauseAtBottom
          } else {
            vm.position += crushDirection * moveAmount
          }
        } else {
          // Move back toward startPosition
          let distanceToStart = Float((startPosition - vm.position).length())
          let moveAmount = retractSpeed * Float(delta)

          if moveAmount >= distanceToStart {
            vm.position = startPosition
            vm.isCrushing = true
            vm.pauseTimer = pauseAtTop
          } else {
            vm.position -= crushDirection * moveAmount
          }
        }

        body.position = vm.position
      }
      .onEvent(GameEvent.self) { body, event in
        if case .gameReset = event {
          vm.position = startPosition
          vm.isCrushing = true
          vm.pauseTimer = pauseAtTop
          body.position = vm.position
        }
      }
    }
  }
}
