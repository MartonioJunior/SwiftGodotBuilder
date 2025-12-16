import Foundation
import SwiftGodot

// MARK: - Fade Overlay

/// A full-screen fade overlay that transitions opacity based on TransitionState
public struct FadeOverlay: GView {
  let transitionState: ObservableState<TransitionState>

  public init(transitionState: ObservableState<TransitionState>) {
    self.transitionState = transitionState
  }

  public var body: some GView {
    ColorRect$()
      .color(Color.black)
      .anchorsAndOffsets(.fullRect)
      .visible(false)
      .onProcess { node, _ in
        let state = transitionState.wrappedValue
        guard state.transitionType == .fade else {
          node.visible = false
          return
        }

        node.visible = state.progress > 0
        node.modulate = Color(r: 1, g: 1, b: 1, a: state.progress)
      }
  }
}

// MARK: - Wipe Overlay

/// A horizontal wipe overlay that sweeps across the screen
public struct WipeOverlay: GView {
  let transitionState: ObservableState<TransitionState>
  let screenWidth: Float
  let screenHeight: Float

  public init(transitionState: ObservableState<TransitionState>, screenWidth: Float, screenHeight: Float) {
    self.transitionState = transitionState
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
  }

  public var body: some GView {
    ColorRect$()
      .color(Color.black)
      .visible(false)
      .onProcess { node, _ in
        let state = transitionState.wrappedValue
        guard state.transitionType == .wipe else {
          node.visible = false
          return
        }

        let rawProgress = state.rawProgress
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

/// An iris wipe overlay that shrinks to a point and expands back
public struct IrisOverlay: GView {
  let transitionState: ObservableState<TransitionState>
  let screenWidth: Float
  let screenHeight: Float

  public init(transitionState: ObservableState<TransitionState>, screenWidth: Float, screenHeight: Float) {
    self.transitionState = transitionState
    self.screenWidth = screenWidth
    self.screenHeight = screenHeight
  }

  public var body: some GView {
    Control$()
      .visible(false)
      .anchorsAndOffsets(.fullRect)
      .onProcess { node, _ in
        let state = transitionState.wrappedValue
        let isIris = state.transitionType == .irisOut
        let rawProgress = state.rawProgress
        node.visible = isIris && rawProgress > 0 && rawProgress < 1
        if isIris && state.isTransitioning {
          node.queueRedraw()
        }
      }
      .onSignal(\.draw) { node in
        drawIris(control: node, transitionState: transitionState, screenWidth: screenWidth, screenHeight: screenHeight)
      }
  }
}

// MARK: - Iris Drawing Helper

private func drawIris(control: Control, transitionState: ObservableState<TransitionState>, screenWidth: Float, screenHeight: Float) {
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
