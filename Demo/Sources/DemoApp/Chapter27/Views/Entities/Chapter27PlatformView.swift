import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Unified platform with composable behavior via LDtk fields
  struct PlatformView: GView {
    // Core properties
    let startPosition: Vector2
    let size: Vector2
    let platformColor: Color
    let gridSize: Int

    // Sprite (optional)
    let spriteTile: LDTilesetRect?
    let project: LDProject

    // Movement (optional - set endPoint to enable)
    let endPoint: Vector2?
    let speed: Float
    let pauseDuration: Double

    // Falling (optional - set falls=true to enable)
    let falls: Bool
    let shakeDelay: Double
    let fallDelay: Double
    let respawnDelay: Double
    let fallSpeed: Float = 200

    // Computed properties
    var moves: Bool { endPoint != nil }
    var crumbles: Bool { falls && respawnDelay <= 0 }

    private final class ViewModel {
      var position: Vector2 = .zero
      var shakeOffset: Vector2 = .zero
      var movingToEnd = true
      var pauseTimer = 0.0
      var shakeTimer = 0.0
      var fallTimer = 0.0
      var respawnTimer = 0.0
      var isVisible = true
      var triggered = false
      var isFalling = false
    }

    private let vm = ViewModel()

    init(entity: LDEntity, level: LDLevel, project: LDProject) {
      gridSize = level.entityLayers.first?.gridSize ?? 8

      startPosition = entity.positionTopLeft
      size = entity.size
      platformColor = entity.field("color")?.asColor() ?? Color(code: "#668844")

      // Sprite
      spriteTile = entity.field("sprite")?.asTile()
      self.project = project

      // Movement
      endPoint = entity.field("endPoint")?.asVector2(gridSize: gridSize)
      let rawSpeed = entity.field("speed")?.asFloat() ?? 0
      speed = rawSpeed > 0 ? rawSpeed : 50
      pauseDuration = entity.field("pauseDuration")?.asDouble() ?? 0.5

      // Falling
      falls = entity.field("falls")?.asBool() ?? false
      shakeDelay = entity.field("shakeDelay")?.asDouble() ?? 0.3
      fallDelay = entity.field("fallDelay")?.asDouble() ?? 0.8
      respawnDelay = entity.field("respawnDelay")?.asDouble() ?? 3.0
    }

    var body: some GView {
      let tileCount = Int(size.x) / gridSize

      return AnimatableBody2D$ {
        // Visual - sprites from tileset
        if let tile = spriteTile {
          LDTileFieldView(tile: tile, project: project, gridSize: gridSize, tileCountX: tileCount, tileCountY: 1)
        }

        CollisionShape2D$()
          .shape(RectangleShape2D(size: size))
          .position(size / 2)

        // Detection area for falling platforms (detects player standing on top)
        if falls {
          Area2D$ {
            CollisionShape2D$()
              .shape(RectangleShape2D(w: size.x - 4, h: 4))
              .position([size.x / 2, -2])
          }
          .collisionMask(.player)
          .onSignal(\.bodyEntered) { _, body in
            if body is CharacterBody2D, !vm.triggered, !vm.isFalling {
              vm.triggered = true
              vm.shakeTimer = shakeDelay
              vm.fallTimer = fallDelay
            }
          }
        }
      }
      .collisionLayer(.terrain)
      .syncToPhysics(moves)
      .onReady { body in
        vm.position = startPosition
        body.position = startPosition
      }
      .onPhysicsProcess { body, delta in
        updatePhysics(body: body, delta: delta)
      }
      .onEvent(GameEvent.self) { _, event in
        if case .gameReset = event {
          respawn()
        }
      }
    }

    // MARK: - Update

    private func respawn() {
      vm.position = startPosition
      vm.shakeOffset = .zero
      vm.movingToEnd = true
      vm.pauseTimer = 0
      vm.shakeTimer = 0
      vm.fallTimer = 0
      vm.triggered = false
      vm.isFalling = false
      vm.isVisible = true
    }

    private func updatePhysics(body: AnimatableBody2D, delta: Double) {
      // Sync visibility
      body.visible = vm.isVisible
      body.collisionLayer = vm.isVisible ? Physics2DLayer.terrain.rawValue : 0

      if !vm.isVisible {
        updateRespawn(delta)
        return
      }

      if falls {
        let stillFalling = updateFalling(body: body, delta)
        if stillFalling { return }
      }

      updateMovement(body: body, delta: delta)
    }

    private func updateRespawn(_ delta: Double) {
      if crumbles { return }
      vm.respawnTimer -= delta
      if vm.respawnTimer <= 0 {
        respawn()
      }
    }

    private func updateFalling(body: AnimatableBody2D, _ delta: Double) -> Bool {
      // Shaking phase
      if vm.triggered, !vm.isFalling {
        if vm.shakeTimer > 0 {
          vm.shakeTimer -= delta
        } else {
          vm.shakeOffset = [
            Float.random(in: -2 ... 2),
            Float.random(in: -1 ... 1),
          ]
        }

        vm.fallTimer -= delta
        if vm.fallTimer <= 0 {
          vm.isFalling = true
          vm.shakeOffset = .zero
        }

        // Update position with shake offset during shake phase
        body.position = vm.position + vm.shakeOffset
        return true
      }

      // Falling phase
      if vm.isFalling {
        vm.position.y += fallSpeed * Float(delta)
        body.position = vm.position

        if vm.position.y > startPosition.y + 200 {
          vm.isVisible = false
          vm.respawnTimer = respawnDelay
        }
        return true
      }

      return false
    }

    private func updateMovement(body: AnimatableBody2D, delta: Double) {
      guard moves, let target = vm.movingToEnd ? endPoint : startPosition else { return }

      if vm.pauseTimer > 0 {
        vm.pauseTimer -= delta
        return
      }

      let direction = (target - vm.position).normalized()
      let distance = vm.position.distanceTo(target)

      if Float(distance) < speed * Float(delta) {
        vm.position = target
        vm.movingToEnd.toggle()
        vm.pauseTimer = pauseDuration
      } else {
        let newPos = direction * speed * Float(delta)
        vm.position.x += newPos.x.rounded()
        vm.position.y += newPos.y.rounded()
      }

      body.position = vm.position + vm.shakeOffset
    }
  }
}
