import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  struct StoryProgress: Codable, Equatable, Sendable {
    var talkedToNPCs: Set<String> = []
    var completedDialogs: Set<String> = []
    var storyFlags: Set<String> = []

    mutating func markTalkedTo(_ npcId: String) {
      talkedToNPCs.insert(npcId)
    }

    mutating func markDialogComplete(_ dialogId: String) {
      completedDialogs.insert(dialogId)
    }

    mutating func setFlag(_ flag: String) {
      storyFlags.insert(flag)
    }

    func hasFlag(_ flag: String) -> Bool {
      storyFlags.contains(flag)
    }
  }

  // Dialog Events
  enum DialogEvent: EmittableEvent {
    case started(npcId: String)
    case lineAdvanced(lineIndex: Int)
    case choiceSelected(choiceIndex: Int)
    case ended(npcId: String)
  }
}
