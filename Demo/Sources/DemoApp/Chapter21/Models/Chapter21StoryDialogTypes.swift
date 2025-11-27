import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  struct StoryProgress: Codable, Equatable, Sendable {
    var talkedToNPCs: Set<String> = []
    var completedDialogs: Set<String> = []

    mutating func markTalkedTo(_ npcId: String) {
      talkedToNPCs.insert(npcId)
    }

    mutating func markDialogComplete(_ dialogId: String) {
      completedDialogs.insert(dialogId)
    }
  }

  // Dialog Events
  enum DialogEvent: EmittableEvent {
    case started(npcId: String, makeDialog: (DialogState, GameViewState, GameProgress) -> DialogDefinition?)
    case lineAdvanced(lineIndex: Int)
    case choiceSelected(choiceIndex: Int)
    case ended(npcId: String)
  }
}
