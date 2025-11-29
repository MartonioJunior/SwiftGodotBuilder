import Foundation
import Observation
import SwiftGodot

// MARK: - Transition State

/// Observable state for managing screen transitions
@Observable
public class TransitionState {
  public var isTransitioning = false
  public var progress: Float = 0
  public var rawProgress: Float = 0
  public var transitionType: TransitionType = .fade
  public var duration: Double = 0.5
  public var elapsedTime: Double = 0
  public var onMidpoint: (() -> Void)?
  public var onComplete: (() -> Void)?
  public var midpointFired = false
  public var irisCenter: Vector2 = [0.5, 0.5]

  // Hold at midpoint support
  public var holdDuration: Double = 0
  public var waitForResume = false
  public var holdElapsed: Double = 0
  public var resumeCalled = false
  public var isHolding = false

  public init() {}

  /// Resume the transition after holding at midpoint.
  /// Call this when async work (like level loading) is complete.
  public func resume() {
    resumeCalled = true
  }
}

// MARK: - Transition Helper Functions

public extension TransitionState {
  /// Start a fade transition
  /// - Parameters:
  ///   - duration: Total duration of the transition (not including hold time)
  ///   - holdDuration: Minimum time to hold at midpoint (screen fully covered)
  ///   - waitForResume: If true, wait for `resume()` to be called before continuing
  ///   - onMidpoint: Callback when transition reaches midpoint
  ///   - onComplete: Callback when transition completes
  func fadeTransition(
    duration: Double = 0.5,
    holdDuration: Double = 0,
    waitForResume: Bool = false,
    onMidpoint: (() -> Void)? = nil,
    onComplete: (() -> Void)? = nil
  ) {
    startTransition(type: .fade, duration: duration, holdDuration: holdDuration, waitForResume: waitForResume, onMidpoint: onMidpoint, onComplete: onComplete)
  }

  /// Start a wipe transition
  /// - Parameters:
  ///   - duration: Total duration of the transition (not including hold time)
  ///   - holdDuration: Minimum time to hold at midpoint (screen fully covered)
  ///   - waitForResume: If true, wait for `resume()` to be called before continuing
  ///   - onMidpoint: Callback when transition reaches midpoint
  ///   - onComplete: Callback when transition completes
  func wipeTransition(
    duration: Double = 0.8,
    holdDuration: Double = 0,
    waitForResume: Bool = false,
    onMidpoint: (() -> Void)? = nil,
    onComplete: (() -> Void)? = nil
  ) {
    startTransition(type: .wipe, duration: duration, holdDuration: holdDuration, waitForResume: waitForResume, onMidpoint: onMidpoint, onComplete: onComplete)
  }

  /// Start an iris transition
  /// - Parameters:
  ///   - duration: Total duration of the transition (not including hold time)
  ///   - center: Normalized center point (0-1 range) for the iris effect
  ///   - holdDuration: Minimum time to hold at midpoint (screen fully covered)
  ///   - waitForResume: If true, wait for `resume()` to be called before continuing
  ///   - onMidpoint: Callback when transition reaches midpoint
  ///   - onComplete: Callback when transition completes
  func irisOutTransition(
    duration: Double = 1.5,
    center: Vector2 = [0.5, 0.5],
    holdDuration: Double = 0,
    waitForResume: Bool = false,
    onMidpoint: (() -> Void)? = nil,
    onComplete: (() -> Void)? = nil
  ) {
    irisCenter = center
    startTransition(type: .irisOut, duration: duration, holdDuration: holdDuration, waitForResume: waitForResume, onMidpoint: onMidpoint, onComplete: onComplete)
  }

  private func startTransition(
    type: TransitionType,
    duration: Double,
    holdDuration: Double,
    waitForResume: Bool,
    onMidpoint: (() -> Void)?,
    onComplete: (() -> Void)?
  ) {
    guard !isTransitioning else { return }

    isTransitioning = true
    transitionType = type
    self.duration = duration
    self.holdDuration = holdDuration
    self.waitForResume = waitForResume
    elapsedTime = 0
    holdElapsed = 0
    resumeCalled = false
    isHolding = false
    self.onMidpoint = onMidpoint
    self.onComplete = onComplete
    progress = 0
    rawProgress = 0
    midpointFired = false

    TransitionEvent.started(type: type).emit()
  }
}
