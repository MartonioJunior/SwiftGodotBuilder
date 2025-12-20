import SwiftGodot

/// Events for DialogManager integration.
/// Games listen to these to react to dialog lifecycle.
public enum DialogManagerEvent: EmittableEvent {
  /// Emitted when an actor requests dialog to be shown
  case dialogRequested(actorId: Int, dialog: DialogDefinition, branchId: String?)

  /// Emitted when dialog becomes active/inactive (for auto-pause)
  case dialogActive(Bool)

  /// Emitted when dialog completes
  case dialogEnded(actorId: Int, dialogId: String)
}
