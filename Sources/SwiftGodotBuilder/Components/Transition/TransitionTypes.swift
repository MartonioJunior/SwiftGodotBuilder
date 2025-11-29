import SwiftGodot

// MARK: - Transition Types

/// Types of screen transitions available
public enum TransitionType: String, CaseIterable {
  case fade
  case wipe
  case irisOut
}

// MARK: - Transition Event

/// Events emitted during screen transitions
public enum TransitionEvent: EmittableEvent {
  case started(type: TransitionType)
  case midpoint
  case completed(type: TransitionType)
}
