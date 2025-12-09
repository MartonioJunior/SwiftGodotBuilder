import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  /// A crusher that moves to endPoint and back, killing the player on contact
  struct CrusherView: GView {
    let startPosition: Vector2
    let endPosition: Vector2
    let width: Float
    let height: Float
    let gridSize: Int
    let crushDirection: Vector2 // Normalized direction to endPoint
    let crushDistance: Float // Distance to endPoint
    let crushSpeed: Float // Speed when crushing
    let retractSpeed: Float // Speed when retracting
    let pauseAtTop: Double // Time to wait at start
    let pauseAtBottom: Double // Time to wait at end
    let damageAmount: Int // Damage to deal to player

    // Sprite (optional)
    let spriteTile: LDTilesetRect?
    let project: LDProject

    @State var position: Vector2 = .zero
    @State var isCrushing = true
    @State var pauseTimer = 0.0

    init(entity: LDEntity, level: LDLevel, project: LDProject) {
      gridSize = level.entityLayers.first?.gridSize ?? 8

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
      position = startPosition
      pauseTimer = pauseAtTop
    }

    var body: some GView {
      let tileCountX = Int(width) / gridSize
      let tileCountY = Int(height) / gridSize

      return AnimatableBody2D$ {
        // Visual - sprites from tileset
        if let tile = spriteTile,
           let tilesetDef = project.defs.tileset(uid: tile.tilesetUid),
           let texture = ResourceLoader.load(path: tilesetDef.resourcePath(relativeTo: project.projectPath ?? "")) as? Texture2D {
          // Handle multi-tile selections
          let sourceTileCountX = tile.w / gridSize
          let sourceTileCountY = tile.h / gridSize
          for y in 0 ..< tileCountY {
            for x in 0 ..< tileCountX {
              let sourceTileX = x % sourceTileCountX
              let sourceTileY = y % sourceTileCountY
              let sourceX = tile.x + (sourceTileX * gridSize)
              let sourceY = tile.y + (sourceTileY * gridSize)
              Sprite2D$()
                .texture(texture)
                .regionEnabled(true)
                .regionRect(Rect2(x: Float(sourceX), y: Float(sourceY), width: Float(gridSize), height: Float(gridSize)))
                .centered(false)
                .position([Float(x * gridSize), Float(y * gridSize)])
            }
          }
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
            GameEvent.playerHit(damage: damageAmount, position: position).emit()
          }
        }
      }
      .position($position)
      .collisionLayer(.terrain)
      .syncToPhysics(true)
      .onPhysicsProcess { body, delta in
        // Handle pause timers
        if pauseTimer > 0 {
          pauseTimer -= delta
          return
        }

        if isCrushing {
          // Move toward endPosition
          let distanceToEnd = Float((endPosition - position).length())
          let moveAmount = crushSpeed * Float(delta)

          if moveAmount >= distanceToEnd {
            position = endPosition
            isCrushing = false
            pauseTimer = pauseAtBottom
          } else {
            position += crushDirection * moveAmount
          }
        } else {
          // Move back toward startPosition
          let distanceToStart = Float((startPosition - position).length())
          let moveAmount = retractSpeed * Float(delta)

          if moveAmount >= distanceToStart {
            position = startPosition
            isCrushing = true
            pauseTimer = pauseAtTop
          } else {
            position -= crushDirection * moveAmount
          }
        }

        body.position = position
      }
      .onEvent(GameEvent.self) { _, event in
        if case .gameReset = event {
          position = startPosition
          isCrushing = true
          pauseTimer = pauseAtTop
        }
      }
    }
  }
}
