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
///   @ObservableState var transitionState = TransitionState()
///
///   var body: some GView {
///     CanvasLayer$ {
///       // Your game UI here
///     }
///
///     TransitionManager(state: $transitionState, screenSize: [428, 240])
///   }
/// }
///
/// // Trigger transitions:
/// transitionState.fadeTransition(onMidpoint: { loadNextLevel() })
/// transitionState.wipeTransition(duration: 0.8)
/// transitionState.irisOutTransition(center: [0.5, 0.5])
/// ```
public struct TransitionManager: GView {
  let transitionState: ObservableState<TransitionState>
  let screenWidth: Float
  let screenHeight: Float

  /// Create a transition manager
  /// - Parameters:
  ///   - state: Observable state binding for the transition
  ///   - screenSize: The screen dimensions as [width, height]
  public init(state: ObservableState<TransitionState>, screenSize: Vector2) {
    transitionState = state
    screenWidth = screenSize.x
    screenHeight = screenSize.y
  }

  /// Create a transition manager from a scene router
  /// - Parameters:
  ///   - router: The scene router containing the transition state
  ///   - screenSize: The screen dimensions as [width, height]
  public init<R: SceneRouterProtocol>(router: ObservableState<R>, screenSize: Vector2) {
    transitionState = ObservableState(wrappedValue: router.wrappedValue.transitionState)
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
    .onProcess { [transitionState] _, delta in
      let state = transitionState.wrappedValue
      guard state.isTransitioning else { return }

      let halfDuration = state.duration / 2

      // Handle holding at midpoint
      if state.isHolding {
        state.holdElapsed += delta

        let holdComplete = state.holdElapsed >= state.holdDuration
        let resumeComplete = !state.waitForResume || state.resumeCalled

        if holdComplete && resumeComplete {
          // Exit hold, continue with reveal
          state.isHolding = false
          state.elapsedTime = halfDuration
        }
        return
      }

      state.elapsedTime += delta
      state.rawProgress = Float(min(1.0, state.elapsedTime / state.duration))

      if state.elapsedTime < halfDuration {
        // Covering phase
        state.progress = Float(state.elapsedTime / halfDuration)
      } else if !state.midpointFired {
        // Just reached midpoint
        state.midpointFired = true
        state.progress = 1.0
        state.rawProgress = 0.5
        TransitionEvent.midpoint.emit()
        state.onMidpoint?()

        // Check if we need to hold
        if state.holdDuration > 0 || state.waitForResume {
          state.isHolding = true
          state.holdElapsed = 0
        }
      } else if state.elapsedTime < state.duration {
        // Revealing phase
        let remaining = state.elapsedTime - halfDuration
        state.progress = Float(1.0 - (remaining / halfDuration))
      } else {
        // Complete
        state.isTransitioning = false
        state.progress = 0
        state.rawProgress = 0
        state.onComplete?()
        TransitionEvent.completed(type: state.transitionType).emit()
      }
    }
  }
}
