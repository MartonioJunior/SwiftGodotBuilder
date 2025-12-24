import Foundation

/// Selection capability state for actors that can be selected.
public class ActorSelectionState {
  /// Whether this actor is currently selected
  public var isSelected = false

  /// Optional group for filtering which actors can be selected together.
  /// Actors with different groups cannot be multi-selected.
  public let selectionGroup: String?

  public init(selectionGroup: String? = nil) {
    self.selectionGroup = selectionGroup
  }
}
