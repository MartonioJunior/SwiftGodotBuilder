import Foundation

/// Dialog capability state for actors that can provide dialog when interacted with
public class ActorDialogState {
  // MARK: - Config

  /// The dialog factory closure
  public let dialogFactory: (ActorState, DialogState) -> DialogDefinition?

  // MARK: - State

  /// Number of times this actor has been talked to
  public var visitCount: Int = 0

  // MARK: - Initialization

  public init(dialogFactory: @escaping (ActorState, DialogState) -> DialogDefinition?) {
    self.dialogFactory = dialogFactory
  }

  // MARK: - Methods

  /// Called when interaction occurs - creates dialog if available
  public func tryTriggerDialog(actorState: ActorState, branchId: String? = nil) {
    visitCount += 1
    let dialogState = DialogState(visitCount: visitCount)

    guard let dialog = dialogFactory(actorState, dialogState) else {
      return
    }

    DialogManagerEvent.dialogRequested(
      actorId: actorState.id,
      dialog: dialog,
      branchId: branchId
    ).emit()
  }
}
