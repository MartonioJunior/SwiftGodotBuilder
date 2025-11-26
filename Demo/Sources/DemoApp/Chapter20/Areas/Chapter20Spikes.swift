import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  /// Spikes that instantly kill the player on contact
  struct Spikes: GView {
    let position: Vector2
    let width: Float
    let height: Float = 8
    let direction: SpikeDirection

    enum SpikeDirection {
      case up
      case down
      case left
      case right
    }

    let palette = Palette()

    var body: some GView {
      Area2D$ {
        // Visual spikes
        spikeVisual()

        // Collision area (slightly smaller than visual)
        CollisionShape2D$()
          .shape(collisionShape())
          .position(collisionPosition())
      }
      .position(position)
      .collisionLayer(.zeta) // Hazard layer
      .collisionMask(.beta) // Player layer
      .onSignal(\.bodyEntered) { _, body in
        if body is CharacterBody2D {
          // Instant death
          Event.playerHit(damage: 999, position: position).emit()
        }
      }
    }

    func spikeVisual() -> some GView {
      let spikeCount = Int(width / 8)
      let spikeWidth: Float = 8
      let spikeHeight: Float = height

      return Node2D$ {
        for i in 0 ..< spikeCount {
          // Individual spike triangle
          Polygon2D$()
            .polygon(spikeTriangle(width: spikeWidth, height: spikeHeight))
            .color(palette.spikes)
            .position([Float(i) * spikeWidth, 0])
        }
      }
      .rotation(spikeRotation())
      .position(visualOffset())
    }

    func spikeTriangle(width: Float, height: Float) -> PackedVector2Array {
      // Triangle pointing up by default
      PackedVector2Array([
        [0, height], // Bottom left
        [width / 2, 0], // Top center (tip)
        [width, height], // Bottom right
      ])
    }

    func spikeRotation() -> Double {
      switch direction {
      case .up: return 0
      case .down: return .pi
      case .left: return .pi / 2
      case .right: return -.pi / 2
      }
    }

    func visualOffset() -> Vector2 {
      switch direction {
      case .up: return .zero
      case .down: return [width, height]
      case .left: return [height, 0]
      case .right: return [0, width]
      }
    }

    func collisionShape() -> RectangleShape2D {
      switch direction {
      case .up, .down:
        return RectangleShape2D(w: width - 2, h: height - 2)
      case .left, .right:
        return RectangleShape2D(w: height - 2, h: width - 2)
      }
    }

    func collisionPosition() -> Vector2 {
      switch direction {
      case .up:
        return [width / 2, height / 2 + 2]
      case .down:
        return [width / 2, height / 2 - 2]
      case .left:
        return [height / 2 + 2, width / 2]
      case .right:
        return [height / 2 - 2, width / 2]
      }
    }
  }
}
