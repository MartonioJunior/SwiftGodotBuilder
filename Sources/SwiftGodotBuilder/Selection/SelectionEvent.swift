import Foundation

/// Events for the selection system.
/// Commands are emitted by SelectionBox, notifications are emitted by Actors after state changes.
public enum SelectionEvent: EmittableEvent {
  // MARK: - Commands (emitted by SelectionBox)

  /// Request to select specific actors. Non-additive clears previous selection.
  case selectRequested(actorIds: Set<Int>, additive: Bool)

  /// Request to deselect specific actors
  case deselectRequested(actorIds: Set<Int>)

  /// Request to clear all selection
  case clearRequested

  /// Request to toggle selection for a specific actor
  case toggleRequested(actorId: Int)

  // MARK: - Notifications (emitted by Actors after state change)

  /// Actor was selected
  case selected(actorId: Int)

  /// Actor was deselected
  case deselected(actorId: Int)
}
