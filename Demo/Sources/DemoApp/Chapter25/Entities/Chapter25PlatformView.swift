import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  /// Unified platform with composable behavior via LDtk fields
  struct PlatformView: GView {
    // Core properties
    let startPosition: Vector2
    let size: Vector2
    let platformColor: Color

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

    // One-way collision
    let oneWay: Bool

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

    init(entity: LDEntity, level: LDLevel) {
      let gridSize = level.entityLayers.first?.gridSize ?? 8

      startPosition = entity.positionTopLeft
      size = entity.size
      platformColor = entity.field("color")?.asColor() ?? Color(code: "#668844")

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

      // One-way
      oneWay = entity.field("oneWay")?.asBool() ?? false

      position = startPosition
    }

    var computedColor: GState<Color> {
      $triggered.computed(with: $isFalling) { triggered, falling in
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
      AnimatableBody2D$ {
        ColorBox$()
          .size(size)
          .color(falls ? computedColor : GState(wrappedValue: platformColor))

        CollisionShape2D$()
          .shape(RectangleShape2D(size: size))
          .position(size / 2)
          .oneWayCollision(oneWay)
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
        // Handle respawn countdown (invisible state)
        if !isVisible {
          if crumbles { return } // Crumbling platforms don't respawn
          respawnTimer -= delta
          if respawnTimer <= 0 {
            respawn()
          }
          return
        }

        // Handle falling behavior
        if falls {
          // Shaking phase
          if triggered, !isFalling {
            if shakeTimer > 0 {
              shakeTimer -= delta
            } else {
              // Apply shake effect
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

            // Disappear after falling far enough
            if position.y > startPosition.y + 200 {
              // Defer visibility change to avoid modifying physics during physics process
              Engine.onNextFrame {
                isVisible = false
                respawnTimer = respawnDelay
              }
            }
            return // Skip movement logic while falling
          }
        }

        // Handle movement behavior (only if not falling)
        if moves, let target = movingToEnd ? endPoint : startPosition {
          // Pause at endpoints
          if pauseTimer > 0 {
            pauseTimer -= delta
            return
          }

          // Calculate direction and distance
          let direction = (target - position).normalized()
          let distance = position.distanceTo(target)

          // Check if reached target
          if Float(distance) < speed * Float(delta) {
            position = target
            movingToEnd.toggle()
            pauseTimer = pauseDuration
          } else {
            let newPos = direction * speed * Float(delta)
            position.x += newPos.x.rounded()
            position.y += newPos.y.rounded()
          }

          // Update body position for physics sync
          body.position = position + shakeOffset
        }
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
  }
}
