import Foundation
import SwiftGodot

// MARK: - Camera Configuration

/// Configuration for camera behavior
public struct ActorCameraConfig: Sendable {
  // Drag margins
  public var dragMarginH: Float = 0.2
  public var dragMarginTop: Float = 0.1
  public var dragMarginBottom: Float = 0.3

  // Lookahead
  public var lookahead: Float = 20
  public var lookaheadThreshold: Float = 10
  public var lookaheadSpeed: Float = 3

  // Vertical bias
  public var verticalBiasNormal: Float = -15
  public var verticalBiasCrouch: Float = 30
  public var crouchLookDelay: Double = 0.5

  // Smoothing
  public var smoothingEnabled = false
  public var smoothingSpeed: Float = 5

  public init(
    dragMarginH: Float = 0.2,
    dragMarginTop: Float = 0.1,
    dragMarginBottom: Float = 0.3,
    lookahead: Float = 20,
    lookaheadThreshold: Float = 10,
    lookaheadSpeed: Float = 3,
    verticalBiasNormal: Float = -15,
    verticalBiasCrouch: Float = 30,
    crouchLookDelay: Double = 0.5,
    smoothingEnabled: Bool = false,
    smoothingSpeed: Float = 5
  ) {
    self.dragMarginH = dragMarginH
    self.dragMarginTop = dragMarginTop
    self.dragMarginBottom = dragMarginBottom
    self.lookahead = lookahead
    self.lookaheadThreshold = lookaheadThreshold
    self.lookaheadSpeed = lookaheadSpeed
    self.verticalBiasNormal = verticalBiasNormal
    self.verticalBiasCrouch = verticalBiasCrouch
    self.crouchLookDelay = crouchLookDelay
    self.smoothingEnabled = smoothingEnabled
    self.smoothingSpeed = smoothingSpeed
  }

  public static let `default` = ActorCameraConfig()

  public static let tight = ActorCameraConfig(
    dragMarginH: 0.1,
    dragMarginTop: 0.05,
    dragMarginBottom: 0.1,
    lookahead: 10,
    lookaheadSpeed: 5
  )

  public static let cinematic = ActorCameraConfig(
    dragMarginH: 0.3,
    dragMarginTop: 0.2,
    dragMarginBottom: 0.2,
    lookahead: 30,
    lookaheadSpeed: 2,
    smoothingEnabled: true,
    smoothingSpeed: 3
  )
}

// MARK: - Camera Target

/// What the camera should follow
public enum CameraTarget {
  case actor(ActorState)
  case position(Vector2)
  case node(Node2D)
}

// MARK: - Camera State

/// Observable camera state
@Observable
public class ActorCameraState {
  public var target: CameraTarget
  public var config: ActorCameraConfig

  // Internal tracking
  public var lookaheadOffset: Float = 0
  public var verticalOffset: Float = 0
  public var shakeOffset: Vector2 = .zero
  public var cameraFacing: Facing = .right
  public var movementInDirection: Float = 0
  public var crouchTimer: Double = 0
  public var lastTargetPosition: Vector2 = .zero

  // Pan state
  public var isPanning = false
  public var panStart: Vector2 = .zero
  public var panTarget: Vector2 = .zero
  public var panDuration: Double = 0
  public var panElapsed: Double = 0
  public var panPreviousTarget: CameraTarget?

  public init(target: CameraTarget, config: ActorCameraConfig = .default) {
    self.target = target
    self.config = config
  }

  public var targetPosition: Vector2 {
    switch target {
    case let .actor(actor): actor.position
    case let .position(pos): pos
    case let .node(node): node.globalPosition
    }
  }

  public var targetFacing: Facing {
    switch target {
    case let .actor(actor): actor.facing
    default: cameraFacing
    }
  }

  public var targetVelocity: Vector2 {
    switch target {
    case let .actor(actor): actor.velocity
    default: .zero
    }
  }

  public var isCrouching: Bool {
    switch target {
    case let .actor(actor): actor.isCrouching
    default: false
    }
  }

  public func applyShake(intensity: Float) {
    let angle = Float.random(in: 0 ..< Float.pi * 2)
    let distance = intensity * 10.0
    shakeOffset = [cos(angle) * distance, sin(angle) * distance]
  }

  public func reset() {
    lookaheadOffset = 0
    verticalOffset = 0
    shakeOffset = .zero
    movementInDirection = 0
    crouchTimer = 0
    isPanning = false
    panPreviousTarget = nil
  }

  public func startPan(from: Vector2, to: Vector2, duration: Double) {
    isPanning = true
    panStart = from
    panTarget = to
    panDuration = max(duration, 0.01)
    panElapsed = 0
    panPreviousTarget = target
    target = .position(from)
  }

  public func updatePan(_ delta: Double) -> Bool {
    guard isPanning else { return false }

    panElapsed += delta
    let t = min(panElapsed / panDuration, 1.0)

    // Ease-in-out interpolation
    let eased = t < 0.5
      ? 2 * t * t
      : 1 - pow(-2 * t + 2, 2) / 2

    let currentPos = panStart.lerp(to: panTarget, weight: Float(eased))
    target = .position(currentPos)

    if t >= 1.0 {
      isPanning = false
      return true
    }
    return false
  }
}

// MARK: - Camera Events

public enum ActorCameraEvent: EmittableEvent {
  case shake(intensity: Float)
  case follow(target: CameraTarget)
  case pan(to: Vector2, duration: Double)
  case reset
}

// MARK: - Camera Component

/// Flexible camera that can follow any actor or position
public struct ActorCamera: GView {
  @ObservableState public var cameraState: ActorCameraState
  public let levelWidth: Float
  public let levelHeight: Float

  private var cs: ActorCameraState { cameraState }

  public init(
    target: CameraTarget,
    config: ActorCameraConfig = .default,
    levelWidth: Float,
    levelHeight: Float
  ) {
    _cameraState = ObservableState(wrappedValue: ActorCameraState(
      target: target,
      config: config
    ))
    self.levelWidth = levelWidth
    self.levelHeight = levelHeight
  }

  public var body: some GView {
    Camera2D$()
      .dragHorizontalEnabled(true)
      .dragVerticalEnabled(true)
      .onReady { camera in
        camera.limitLeft = 0
        camera.limitTop = 0
        camera.limitRight = Int32(levelWidth)
        camera.limitBottom = Int32(levelHeight)
        camera.dragLeftMargin = Double(cs.config.dragMarginH)
        camera.dragRightMargin = Double(cs.config.dragMarginH)
        camera.dragTopMargin = Double(cs.config.dragMarginTop)
        camera.dragBottomMargin = Double(cs.config.dragMarginBottom)
        camera.positionSmoothingEnabled = cs.config.smoothingEnabled
        camera.positionSmoothingSpeed = Double(cs.config.smoothingSpeed)
      }
      .onProcess { camera, delta in
        updateCamera(camera, delta)
      }
      .onEvent(ActorCameraEvent.self) { camera, event in
        handleCameraEvent(camera, event)
      }
  }

  // MARK: - Camera Update

  private func updateCamera(_ camera: Camera2D, _ delta: Double) {
    // Handle smooth pan if active
    if cs.isPanning {
      _ = cs.updatePan(delta)
      camera.globalPosition = cs.targetPosition
      return
    }

    // Decay screen shake offset
    if cs.shakeOffset.length() > 0.01 {
      cs.shakeOffset = cs.shakeOffset.lerp(to: .zero, weight: 10.0 * delta)
    } else if cs.shakeOffset != .zero {
      cs.shakeOffset = .zero
    }

    // Track movement in current direction
    let velocity = cs.targetVelocity
    let horizontalMovement = velocity.x * Float(delta)

    if cs.targetFacing == cs.cameraFacing {
      cs.movementInDirection += abs(horizontalMovement)
    } else {
      if abs(horizontalMovement) > 0 {
        cs.movementInDirection += abs(horizontalMovement)
      }
      if cs.movementInDirection >= cs.config.lookaheadThreshold {
        cs.cameraFacing = cs.targetFacing
        cs.movementInDirection = 0
      }
    }

    // Track crouch time for camera look-down
    if cs.isCrouching {
      cs.crouchTimer += delta
    } else {
      cs.crouchTimer = 0
    }

    // Determine target vertical bias based on crouch duration
    let targetVerticalBias = cs.crouchTimer >= cs.config.crouchLookDelay
      ? cs.config.verticalBiasCrouch
      : cs.config.verticalBiasNormal

    // Smoothly interpolate offsets
    cs.verticalOffset += (targetVerticalBias - cs.verticalOffset) * Float(delta) * cs.config.lookaheadSpeed

    let targetLookahead = cs.cameraFacing.sign * cs.config.lookahead
    cs.lookaheadOffset += (targetLookahead - cs.lookaheadOffset) * Float(delta) * cs.config.lookaheadSpeed

    // Clamp offset near level edges
    let viewportSize = camera.getViewportRect().size / camera.zoom
    let halfWidth = viewportSize.x / 2
    let cameraX = camera.globalPosition.x
    let roomOnLeft = cameraX - halfWidth
    let roomOnRight = levelWidth - cameraX - halfWidth
    let clampedLookahead = min(max(cs.lookaheadOffset, -roomOnRight), roomOnLeft)

    camera.offset = [
      round(clampedLookahead + cs.shakeOffset.x),
      round(cs.verticalOffset + cs.shakeOffset.y),
    ]

    // Update camera position to follow target (for non-actor targets)
    switch cs.target {
    case .actor:
      // Actor controls CharacterBody2D position, camera follows via parent
      break
    case let .position(pos):
      camera.globalPosition = pos
    case let .node(node):
      camera.globalPosition = node.globalPosition
    }
  }

  // MARK: - Event Handling

  private func handleCameraEvent(_ camera: Camera2D, _ event: ActorCameraEvent) {
    switch event {
    case let .shake(intensity):
      cs.applyShake(intensity: intensity)
      // Hitstop effect
      Engine.timeScale = 0.0
      Engine.onNextFrame {
        Engine.timeScale = 1.0
      }

    case let .follow(target):
      cs.target = target
      cs.reset()

    case let .pan(to: position, duration: duration):
      cs.startPan(from: camera.globalPosition, to: position, duration: duration)

    case .reset:
      cs.reset()
      camera.offset = .zero
      camera.resetSmoothing()
    }
  }
}
