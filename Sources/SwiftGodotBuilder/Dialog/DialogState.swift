import Foundation

/// Per-NPC dialog state passed to dialog factories.
///
/// ### Example
/// ```swift
/// func makeGuardDialog(state: DialogState) -> DialogDefinition {
///   Dialog(id: "guard") {
///     Branch("main") {
///       When({ state.isFirstVisit }) {
///         Guard ~ "Halt! Who goes there?"
///       }
///       When({ state.visitCount > 1 }) {
///         Guard ~ "Back again, traveler."
///       }
///     }
///   }
/// }
/// ```
public struct DialogState: Sendable {
  /// Number of times this NPC has been talked to (1 = first visit).
  public let visitCount: Int

  /// True if this is the first visit to this NPC.
  public var isFirstVisit: Bool { visitCount == 1 }

  public init(visitCount: Int) {
    self.visitCount = visitCount
  }
}
