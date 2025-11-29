import Foundation
import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter22 {
  // MARK: - Transition Types

  enum TransitionType: String, CaseIterable {
    case fade
    case wipe
    case irisOut
  }

  // MARK: - Transition Event

  enum TransitionEvent: EmittableEvent {
    case started(type: TransitionType)
    case midpoint
    case completed(type: TransitionType)
  }

  // MARK: - Transition State

  @Observable
  class TransitionState {
    var isTransitioning = false
    var progress: Float = 0
    var rawProgress: Float = 0
    var transitionType: TransitionType = .fade
    var duration: Double = 0.5
    var elapsedTime: Double = 0
    var onMidpoint: (() -> Void)?
    var onComplete: (() -> Void)?
    var midpointFired = false
    var irisCenter: Vector2 = [0.5, 0.5]
  }

  // MARK: - Transition Manager GView

  struct TransitionManager: GView {
    let transitionState: ObservableState<TransitionState>

    let screenWidth: Float = 428
    let screenHeight: Float = 240

    init(state: ObservableState<TransitionState>) {
      self.transitionState = state
    }

    var body: some GView {
      CanvasLayer$ {
        // Fade overlay
        FadeOverlay(transitionState: transitionState)

        // Wipe overlay (Star Wars style)
        WipeOverlay(transitionState: transitionState, screenWidth: screenWidth, screenHeight: screenHeight)

        // Iris/circle overlay
        IrisOverlay(transitionState: transitionState, screenWidth: screenWidth, screenHeight: screenHeight)
      }
      .layer(100)
      .processMode(.always)
      .onProcess { [transitionState] _, delta in
        let state = transitionState.wrappedValue
        guard state.isTransitioning else { return }

        state.elapsedTime += delta
        state.rawProgress = Float(min(1.0, state.elapsedTime / state.duration))

        let halfDuration = state.duration / 2
        if state.elapsedTime < halfDuration {
          state.progress = Float(state.elapsedTime / halfDuration)
        } else if state.elapsedTime < state.duration {
          if !state.midpointFired {
            state.midpointFired = true
            TransitionEvent.midpoint.emit()
            state.onMidpoint?()
          }
          let remaining = state.elapsedTime - halfDuration
          state.progress = Float(1.0 - (remaining / halfDuration))
        } else {
          state.isTransitioning = false
          state.progress = 0
          state.rawProgress = 0
          state.onComplete?()
          TransitionEvent.completed(type: state.transitionType).emit()
        }
      }
    }
  }

  // MARK: - Fade Overlay

  struct FadeOverlay: GView {
    let transitionState: ObservableState<TransitionState>

    var body: some GView {
      ColorRect$()
        .color(Color.black)
        .anchorsAndOffsets(.fullRect)
        .visible(false)
        .watch(transitionState, \.progress) { [transitionState] node, progress in
          let type = transitionState.wrappedValue.transitionType
          guard type == .fade else {
            node.visible = false
            return
          }
          node.visible = progress > 0
          node.modulate = Color(r: 1, g: 1, b: 1, a: progress)
        }
    }
  }

  // MARK: - Wipe Overlay (Star Wars style)

  struct WipeOverlay: GView {
    let transitionState: ObservableState<TransitionState>
    let screenWidth: Float
    let screenHeight: Float

    var body: some GView {
      ColorRect$()
        .color(Color.black)
        .visible(false)
        .watch(transitionState, \.rawProgress) { [transitionState, screenWidth, screenHeight] node, rawProgress in
          let type = transitionState.wrappedValue.transitionType
          guard type == .wipe else {
            node.visible = false
            return
          }

          node.visible = rawProgress > 0 && rawProgress < 1

          if rawProgress <= 0.5 {
            // Covering: rect grows from left edge
            let coverProgress = rawProgress * 2
            node.offsetLeft = 0
            node.offsetRight = Double(screenWidth * coverProgress)
            node.offsetTop = 0
            node.offsetBottom = Double(screenHeight)
          } else {
            // Revealing: left edge moves right
            let revealProgress = (rawProgress - 0.5) * 2
            node.offsetLeft = Double(screenWidth * revealProgress)
            node.offsetRight = Double(screenWidth)
            node.offsetTop = 0
            node.offsetBottom = Double(screenHeight)
          }
        }
    }
  }

  // MARK: - Iris Overlay (Circle wipe)

  struct IrisOverlay: GView {
    let transitionState: ObservableState<TransitionState>
    let screenWidth: Float
    let screenHeight: Float

    var body: some GView {
      Control$()
        .visible(false)
        .watch(transitionState, \.rawProgress) { [transitionState] node, rawProgress in
          let type = transitionState.wrappedValue.transitionType
          let isIris = type == .irisOut
          node.visible = isIris && rawProgress > 0 && rawProgress < 1
          if isIris {
            node.queueRedraw()
          }
        }
        .anchorsAndOffsets(.fullRect)
        .onSignal(\.draw) { [transitionState, screenWidth, screenHeight] node in
          drawIris(control: node, transitionState: transitionState, screenWidth: screenWidth, screenHeight: screenHeight)
        }
    }
  }
}

// MARK: - Iris Drawing Helper

private func drawIris(control: Control, transitionState: ObservableState<Chapter22.TransitionState>, screenWidth: Float, screenHeight: Float) {
  let state = transitionState.wrappedValue
  let type = state.transitionType
  guard type == .irisOut else { return }

  let size: Vector2 = [screenWidth, screenHeight]
  let center: Vector2 = [size.x * state.irisCenter.x, size.y * state.irisCenter.y]

  // Max radius to cover entire screen from center
  let maxRadius = sqrt(screenWidth * screenWidth + screenHeight * screenHeight)

  let rawProgress = state.rawProgress
  let radius: Float

  // irisOut: circle shrinks to close, then opens back up
  if rawProgress <= 0.5 {
    radius = maxRadius * (1 - rawProgress * 2)
  } else {
    radius = maxRadius * ((rawProgress - 0.5) * 2)
  }

  let black = Color.black

  // Fully black
  if radius <= 0 {
    control.drawRect(Rect2(position: .zero, size: size), color: black)
    return
  }

  // Fully clear
  if radius >= maxRadius {
    return
  }

  // Draw a ring from circle edge to screen edge using segments
  let segments = 64
  let outerRadius = maxRadius * 1.5

  for i in 0 ..< segments {
    let a1 = Float(i) * Float.pi * 2 / Float(segments)
    let a2 = Float(i + 1) * Float.pi * 2 / Float(segments)

    // Inner circle points
    let inner1: Vector2 = [center.x + cos(a1) * radius, center.y + sin(a1) * radius]
    let inner2: Vector2 = [center.x + cos(a2) * radius, center.y + sin(a2) * radius]

    // Outer circle points (way beyond screen)
    let outer1: Vector2 = [center.x + cos(a1) * outerRadius, center.y + sin(a1) * outerRadius]
    let outer2: Vector2 = [center.x + cos(a2) * outerRadius, center.y + sin(a2) * outerRadius]

    // Draw quad as two triangles
    control.drawPolygon(
      points: PackedVector2Array([inner1, inner2, outer2, outer1]),
      colors: PackedColorArray([black, black, black, black])
    )
  }
}

// MARK: - Transition Helper Functions

extension Chapter22.TransitionState {
  func fadeTransition(
    duration: Double = 0.5,
    onMidpoint: (() -> Void)? = nil,
    onComplete: (() -> Void)? = nil
  ) {
    startTransition(type: .fade, duration: duration, onMidpoint: onMidpoint, onComplete: onComplete)
  }

  func wipeTransition(
    duration: Double = 0.8,
    onMidpoint: (() -> Void)? = nil,
    onComplete: (() -> Void)? = nil
  ) {
    startTransition(type: .wipe, duration: duration, onMidpoint: onMidpoint, onComplete: onComplete)
  }

  func irisOutTransition(
    duration: Double = 1.5,
    center: Vector2 = [0.5, 0.5],
    onMidpoint: (() -> Void)? = nil,
    onComplete: (() -> Void)? = nil
  ) {
    irisCenter = center
    startTransition(type: .irisOut, duration: duration, onMidpoint: onMidpoint, onComplete: onComplete)
  }

  private func startTransition(
    type: Chapter22.TransitionType,
    duration: Double,
    onMidpoint: (() -> Void)?,
    onComplete: (() -> Void)?
  ) {
    guard !isTransitioning else { return }

    isTransitioning = true
    transitionType = type
    self.duration = duration
    elapsedTime = 0
    self.onMidpoint = onMidpoint
    self.onComplete = onComplete
    progress = 0
    rawProgress = 0
    midpointFired = false

    Chapter22.TransitionEvent.started(type: type).emit()
  }
}
