import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  // MARK: - NPC Configuration

  struct NPCConfig: Sendable {
    let id: String
    let name: String
    let color: Color
    let position: Vector2
  }

  static func getNPCConfig(for npcId: String, levelId: Int) -> NPCConfig? {
    let npcs: [NPCConfig]
    switch levelId {
    case 1: npcs = level1NPCs
    case 2: npcs = level2NPCs
    case 3: npcs = level3NPCs
    case 4: npcs = level4NPCs
    default: npcs = []
    }
    return npcs.first { $0.id == npcId }
  }

  /// Factory function to create dialog for an NPC
  static func makeDialog(
    for npcId: String,
    state: DialogState,
    gameState: GameViewState,
    progress: GameProgress
  ) -> DialogDefinition? {
    switch npcId {
    case "old_man": return makeOldManDialog(state: state, gameState: gameState, progress: progress)
    case "merchant": return makeMerchantDialog(state: state, gameState: gameState, progress: progress)
    case "guard": return makeGuardDialog(state: state, gameState: gameState, progress: progress)
    case "advisors": return makeAdvisorsDialog(state: state, gameState: gameState, progress: progress)
    default: return nil
    }
  }

  // MARK: - Level NPC Lists

  static let level1NPCs: [NPCConfig] = [
    NPCConfig(id: "old_man", name: "Old Man", color: Color(code: "#44AA44"), position: [80, 136]),
  ]

  static let level2NPCs: [NPCConfig] = [
    NPCConfig(id: "merchant", name: "Merchant", color: Color(code: "#4488FF"), position: [100, 130]),
  ]

  static let level3NPCs: [NPCConfig] = [
    NPCConfig(id: "guard", name: "Guard", color: Color(code: "#8844FF"), position: [80, 130]),
  ]

  static let level4NPCs: [NPCConfig] = [
    NPCConfig(id: "advisors", name: "Sage", color: Color(code: "#44AAAA"), position: [60, 165]),
  ]

  // MARK: - Speaker Colors

  /// Build speaker colors dict (computed fresh each call - no shared state)
  static func buildSpeakerColors() -> [String: Color] {
    var colors: [String: Color] = [:]
    let allNPCs = level1NPCs + level2NPCs + level3NPCs + level4NPCs
    for npc in allNPCs {
      colors[npc.name] = npc.color
    }
    // Add secondary speakers from multi-NPC dialogs
    colors["Knight"] = Color(code: "#FF8844")
    return colors
  }
}
