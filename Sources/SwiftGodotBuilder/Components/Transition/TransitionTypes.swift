import SwiftGodot

// MARK: - Transition Types

/// Types of screen transitions available
public enum TransitionType: String, CaseIterable {
  case fade
  case wipe
  case irisOut
}

// MARK: - Transition Style

/// A transition with its configuration (type, duration, and options).
///
/// Use this to specify how scene transitions should animate:
/// ```swift
/// router.navigate(to: .levelSelect, transition: .fade())
/// router.navigate(to: .death, transition: .iris(center: playerPos))
/// ```
public enum TransitionStyle {
  /// No transition - instant scene change
  case none
  /// Fade to black and back
  case fade(duration: Double = 0.5)
  /// Horizontal wipe transition
  case wipe(duration: Double = 0.8)
  /// Iris/circle transition that shrinks to a point and expands
  case iris(duration: Double = 1.5, center: Vector2 = [0.5, 0.5])

  /// The underlying transition type, or nil for .none
  public var type: TransitionType? {
    switch self {
    case .none: nil
    case .fade: .fade
    case .wipe: .wipe
    case .iris: .irisOut
    }
  }

  /// The duration of the transition
  public var duration: Double {
    switch self {
    case .none: 0
    case .fade(let d), .wipe(let d), .iris(let d, _): d
    }
  }
}

// MARK: - Transition Event

/// Events emitted during screen transitions
public enum TransitionEvent: EmittableEvent {
  case started(type: TransitionType)
  case midpoint
  case completed(type: TransitionType)
}
