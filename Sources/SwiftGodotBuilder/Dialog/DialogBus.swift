import Foundation

/// Events emitted from dialog system - game code subscribes to these.
///
/// ### Example
/// ```swift
/// .onEvent(DialogBusEvent.self) { event in
///   switch event {
///   case .emitted(let name, let data):
///     if name == "giveGold" {
///       player.gold += data?["amount"] as? Int ?? 0
///     }
///   default: break
///   }
/// }
/// ```
public enum DialogBusEvent: EmittableEvent {
  // Built-in lifecycle events
  case dialogStarted(dialogId: String)
  case dialogEnded(dialogId: String)
  case branchStarted(dialogId: String, branchId: String)
  case branchEnded(dialogId: String, branchId: String)
  case lineSpoken(speaker: String, text: String)
  case choiceMade(dialogId: String, branchId: String, choiceText: String)

  // Game events from Emit() in dialog
  case emitted(name: String, data: [String: Any]?)
}
