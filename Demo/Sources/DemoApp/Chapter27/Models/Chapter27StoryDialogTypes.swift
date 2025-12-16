import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
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
    case npcInteracted(npcType: NPCType)
    case ended(npcId: String)
  }
}
