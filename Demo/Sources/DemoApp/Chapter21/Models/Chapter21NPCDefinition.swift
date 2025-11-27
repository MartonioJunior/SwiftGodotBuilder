import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  // MARK: - NPC Definition

  struct NPCDefinition {
    let id: String
    let name: String
    let color: Color
    let size: Vector2
    let makeDialog: (DialogState, GameViewState, GameProgress) -> DialogDefinition?

    // Secondary speakers for multi-NPC dialogs (e.g. advisors)
    var additionalSpeakers: [(name: String, color: Color)] = []
  }

  // MARK: - Speaker Colors

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
