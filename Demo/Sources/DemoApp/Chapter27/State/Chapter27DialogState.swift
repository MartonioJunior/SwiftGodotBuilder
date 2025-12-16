import Foundation
import Observation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Dialog system state - runner, NPC tracking, story progress
  @Observable
  class DialogGameState {
    var dialogRunner: DialogRunner?
    var currentNPCId: String?
    var storyProgress = StoryProgress()
    var npcVisitCounts: [String: Int] = [:]

    // MARK: - Methods

    func beginDialogVisit(npcId: String) -> Int {
      npcVisitCounts[npcId, default: 0] += 1
      return npcVisitCounts[npcId]!
    }

    func prepareDialog(npcId: String, dialog: DialogDefinition, branchId: String? = nil, currentScene: GameState) -> Bool {
      guard currentScene == .playing else { return false }
      currentNPCId = npcId
      dialogRunner = DialogRunner(dialog: dialog)
      dialogRunner?.pendingBranchId = branchId
      return true
    }

    func cleanupDialog() {
      if let npcId = currentNPCId {
        storyProgress.markTalkedTo(npcId)
      }
      if let dialogId = dialogRunner?.dialog.id {
        storyProgress.markDialogComplete(dialogId)
      }
      dialogRunner = nil
      currentNPCId = nil
    }
  }
}
