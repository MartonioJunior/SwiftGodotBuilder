import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
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

    // Movement state
    @State var position: Vector2 = .zero
    @State var movingToEnd = true
    @State var pauseTimer = 0.0

    // Falling state
    @State var triggered = false
    @State var isFalling = false
    @State var shakeTimer = 0.0
    @State var fallTimer = 0.0
    @State var respawnTimer = 0.0
    @State var shakeOffset: Vector2 = .zero
    @State var isVisible = true

    // Warning color for falling platforms
    let warningColor = Color(code: "#CC8844")
    let computedColor: GState<Color>

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

      position = startPosition

      computedColor = _triggered.computed(with: _isFalling) { [platformColor, warningColor] triggered, falling in
        if falling {
          return warningColor
        } else if triggered {
          return warningColor.lerp(to: platformColor, weight: 0.5)
        } else {
          return platformColor
        }
      }
    }

    var body: some GView {
      let tileCount = Int(size.x) / gridSize

      return AnimatableBody2D$ {
        // Visual - sprites from tileset
        if let tile = spriteTile,
           let tilesetDef = project.defs.tileset(uid: tile.tilesetUid),
           let texture = ResourceLoader.load(path: tilesetDef.resourcePath(relativeTo: project.projectPath ?? "")) as? Texture2D
        {
          // Handle multi-tile selections: tile.w may span multiple source tiles
          let sourceTileCount = tile.w / gridSize
          for i in 0 ..< tileCount {
            let sourceTileIndex = i % sourceTileCount
            let sourceX = tile.x + (sourceTileIndex * gridSize)
            Sprite2D$()
              .texture(texture)
              .regionEnabled(true)
              .regionRect(Rect2(x: Float(sourceX), y: Float(tile.y), width: Float(gridSize), height: Float(tile.h)))
              .centered(false)
              .position([Float(i * gridSize), 0])
          }
        }

        CollisionShape2D$()
          .shape(RectangleShape2D(size: size))
          .position(size / 2)
          .disabled($isVisible) { !$0 }

        // Detection area for falling platforms (detects player standing on top)
        if falls {
          Area2D$ {
            CollisionShape2D$()
              .shape(RectangleShape2D(w: size.x - 4, h: 4))
              .position([size.x / 2, -2])
          }
          .collisionMask(.player)
          .onSignal(\.bodyEntered) { _, body in
            if body is CharacterBody2D, !triggered, !isFalling {
              triggered = true
              shakeTimer = shakeDelay
              fallTimer = fallDelay
            }
          }
        }
      }
      .bind(\.position, to: $position, $shakeOffset) { pos, shake in
        pos + shake
      }
      .collisionLayer(.terrain)
      .syncToPhysics(moves)
      .visible($isVisible)
      .watch($isVisible) { body, visible in
        body.collisionLayer = visible ? Physics2DLayer.terrain.rawValue : 0
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

    func respawn() {
      position = startPosition
      movingToEnd = true
      pauseTimer = 0
      triggered = false
      isFalling = false
      shakeTimer = 0
      fallTimer = 0
      shakeOffset = .zero
      isVisible = true
    }

    func updatePhysics(body: AnimatableBody2D, delta: Double) {
      if !isVisible {
        updateRespawn(delta)
        return
      }

      if falls {
        let stillFalling = updateFalling(delta)
        if stillFalling { return }
      }

      updateMovement(body: body, delta: delta)
    }

    func updateRespawn(_ delta: Double) {
      if crumbles { return }
      respawnTimer -= delta
      if respawnTimer <= 0 {
        respawn()
      }
    }

    func updateFalling(_ delta: Double) -> Bool {
      // Shaking phase
      if triggered, !isFalling {
        if shakeTimer > 0 {
          shakeTimer -= delta
        } else {
          shakeOffset = Vector2(
            x: Float.random(in: -2 ... 2),
            y: Float.random(in: -1 ... 1)
          )
        }

        fallTimer -= delta
        if fallTimer <= 0 {
          isFalling = true
          shakeOffset = .zero
        }
      }

      // Falling phase
      if isFalling {
        position.y += fallSpeed * Float(delta)

        if position.y > startPosition.y + 200 {
          Engine.onNextFrame {
            isVisible = false
            respawnTimer = respawnDelay
          }
        }
        return true
      }

      return false
    }

    func updateMovement(body: AnimatableBody2D, delta: Double) {
      guard moves, let target = movingToEnd ? endPoint : startPosition else { return }

      if pauseTimer > 0 {
        pauseTimer -= delta
        return
      }

      let direction = (target - position).normalized()
      let distance = position.distanceTo(target)

      if Float(distance) < speed * Float(delta) {
        position = target
        movingToEnd.toggle()
        pauseTimer = pauseDuration
      } else {
        let newPos = direction * speed * Float(delta)
        position.x += newPos.x.rounded()
        position.y += newPos.y.rounded()
      }

      body.position = position + shakeOffset
    }
  }
}
