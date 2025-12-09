import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct PlayerCamera: GView {
    let player: ObservableState<PlayerState>
    let levelWidth: Float
    let levelHeight: Float
    let cameraOffset: State<Vector2>

    var ps: PlayerState { player.wrappedValue }
    var config: PlayerConfig.Camera { ps.config.camera }

    // Internal state
    @State var lookaheadOffset: Float = 0
    @State var cameraFacing: Facing = .right
    @State var movementInDirection: Float = 0
    @State var crouchTimer: Double = 0
    @State var verticalOffset: Float = 0

    var body: some GView {
      Camera2D$()
        .positionSmoothingEnabled(false)
        .limitLeft(0)
        .limitTop(0)
        .limitRight(Int32(levelWidth))
        .limitBottom(Int32(levelHeight))
        .dragHorizontalEnabled(true)
        .dragLeftMargin(config.dragMarginH)
        .dragRightMargin(config.dragMarginH)
        .dragVerticalEnabled(true)
        .dragTopMargin(config.dragMarginTop)
        .dragBottomMargin(config.dragMarginBottom)
        .onProcess { camera, delta in
          update(camera, delta)
        }
        .onEvent(GameEvent.self) { camera, event in
          switch event {
          case .gameReset, .doorTeleportComplete:
            reset(camera)
          default:
            break
          }
        }
    }

    func update(_ camera: Camera2D, _ delta: Double) {
      // Track movement in current direction
      let horizontalMovement = ps.velocity.x * Float(delta)

      if ps.facing == cameraFacing {
        movementInDirection += abs(horizontalMovement)
      } else {
        if abs(horizontalMovement) > 0 {
          movementInDirection += abs(horizontalMovement)
        }
        if movementInDirection >= config.lookaheadThreshold {
          cameraFacing = ps.facing
          movementInDirection = 0
        }
      }

      // Track crouch time for camera look-down
      if ps.overlay.contains(.crouching) {
        crouchTimer += delta
      } else {
        crouchTimer = 0
      }

      // Determine target vertical bias based on crouch duration
      let targetVerticalBias = crouchTimer >= config.crouchLookDelay
        ? config.verticalBiasCrouch
        : config.verticalBiasNormal

      // Smoothly interpolate offsets
      verticalOffset += (targetVerticalBias - verticalOffset) * Float(delta) * config.lookaheadSpeed

      let targetLookahead = cameraFacing.sign * config.lookahead
      lookaheadOffset += (targetLookahead - lookaheadOffset) * Float(delta) * config.lookaheadSpeed

      // Clamp offset near level edges (limits constrain camera position, but offset is applied after)
      let viewportSize = camera.getViewportRect().size / camera.zoom
      let halfWidth = viewportSize.x / 2
      let cameraX = camera.globalPosition.x
      let roomOnLeft = cameraX - halfWidth
      let roomOnRight = levelWidth - cameraX - halfWidth
      let clampedLookahead = min(max(lookaheadOffset, -roomOnRight), roomOnLeft)

      // Combine lookahead, vertical bias, and screen shake
      let shake = cameraOffset.wrappedValue
      camera.offset = Vector2(
        x: round(clampedLookahead + shake.x),
        y: round(verticalOffset + shake.y)
      )
    }

    func reset(_ camera: Camera2D) {
      lookaheadOffset = 0
      cameraFacing = .right
      movementInDirection = 0
      crouchTimer = 0
      verticalOffset = config.verticalBiasNormal
      camera.resetSmoothing()
    }
  }
}
