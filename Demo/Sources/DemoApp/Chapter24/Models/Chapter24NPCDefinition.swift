import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  /// Types of NPCs for dialog
  enum NPCType: String, LDExported {
    case oldMan = "OldMan"
    case merchant = "Merchant"
    case guardNPC = "Guard"
    case advisors = "Advisors"
  }

  /// Definition for an NPC character
  struct NPCDefinition {
    let id: String
    let name: String
    let color: Color
    let size: Vector2
    let makeDialog: (DialogState, GameViewState, GameProgress) -> DialogDefinition?

    // Secondary speakers for multi-NPC dialogs (e.g. advisors)
    var additionalSpeakers: [(name: String, color: Color)] = []
  }

  static func buildSpeakerColors() -> [String: Color] {
    var colors: [String: Color] = [:]
    for npc in [NPCDefinition.oldMan, .merchant, .guard, .advisors] {
      colors[npc.name] = npc.color
      for speaker in npc.additionalSpeakers {
        colors[speaker.name] = speaker.color
      }
    }
    return colors
  }
}
