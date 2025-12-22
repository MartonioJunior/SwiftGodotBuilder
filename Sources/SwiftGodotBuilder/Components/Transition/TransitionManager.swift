import SwiftGodot

// MARK: - Transition Manager GView

/// A CanvasLayer-based transition manager that provides screen transition effects.
///
/// This component manages three types of transitions:
/// - **Fade**: Screen fades to black and back
/// - **Wipe**: Horizontal wipe
/// - **Iris**: Circle/iris wipe that shrinks to a point and expands
///
/// ### Example
/// ```swift
/// struct MyGameUI: GView {
///   let transitionState = TransitionState()
///
///   var body: some GView {
///     CanvasLayer$ {
///       // Your game UI here
///     }
///
///     TransitionManager(state: transitionState, screenSize: [428, 240])
///   }
/// }
///
/// // Trigger transitions:
/// transitionState.fadeTransition(onMidpoint: { loadNextLevel() })
/// transitionState.wipeTransition(duration: 0.8)
/// transitionState.irisOutTransition(center: [0.5, 0.5])
/// ```
public struct TransitionManager: GView {
  let transitionState: TransitionState
  let screenWidth: Float
  let screenHeight: Float

  /// Create a transition manager
  /// - Parameters:
  ///   - state: Transition state object
  ///   - screenSize: The screen dimensions as [width, height]
  public init(state: TransitionState, screenSize: Vector2) {
    transitionState = state
    screenWidth = screenSize.x
    screenHeight = screenSize.y
  }

  /// Create a transition manager from a scene router
  /// - Parameters:
  ///   - router: The scene router containing the transition state
  ///   - screenSize: The screen dimensions as [width, height]
  public init<R: SceneRouterProtocol>(router: R, screenSize: Vector2) {
    transitionState = router.transitionState
    screenWidth = screenSize.x
    screenHeight = screenSize.y
  }

  public var body: some GView {
    CanvasLayer$ {
      FadeOverlay(transitionState: transitionState)
      WipeOverlay(transitionState: transitionState, screenWidth: screenWidth, screenHeight: screenHeight)
      IrisOverlay(transitionState: transitionState, screenWidth: screenWidth, screenHeight: screenHeight)
    }
    .layer(100)
    .processMode(.always)
    .onProcess { _, delta in
      guard transitionState.isTransitioning else { return }

      let halfDuration = transitionState.duration / 2

      // Handle holding at midpoint
      if transitionState.isHolding {
        transitionState.holdElapsed += delta

        let holdComplete = transitionState.holdElapsed >= transitionState.holdDuration
        let resumeComplete = !transitionState.waitForResume || transitionState.resumeCalled

        if holdComplete && resumeComplete {
          // Exit hold, continue with reveal
          transitionState.isHolding = false
          transitionState.elapsedTime = halfDuration
        }
        return
      }

      transitionState.elapsedTime += delta
      transitionState.rawProgress = Float(min(1.0, transitionState.elapsedTime / transitionState.duration))

      if transitionState.elapsedTime < halfDuration {
        // Covering phase
        transitionState.progress = Float(transitionState.elapsedTime / halfDuration)
      } else if !transitionState.midpointFired {
        // Just reached midpoint
        transitionState.midpointFired = true
        transitionState.progress = 1.0
        transitionState.rawProgress = 0.5
        TransitionEvent.midpoint.emit()
        transitionState.onMidpoint?()

        // Check if we need to hold
        if transitionState.holdDuration > 0 || transitionState.waitForResume {
          transitionState.isHolding = true
          transitionState.holdElapsed = 0
        }
      } else if transitionState.elapsedTime < transitionState.duration {
        // Revealing phase
        let remaining = transitionState.elapsedTime - halfDuration
        transitionState.progress = Float(1.0 - (remaining / halfDuration))
      } else {
        // Complete
        transitionState.isTransitioning = false
        transitionState.progress = 0
        transitionState.rawProgress = 0
        transitionState.onComplete?()
        TransitionEvent.completed(type: transitionState.transitionType).emit()
      }
    }
  }
}
