import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  static let Guard = Speaker("Guard")

  static func makeGuardDialog(
    state: DialogState,
    gameState: GameViewState,
    progress: GameProgress
  ) -> DialogDefinition {
    Dialog(id: "guard") {
      Branch("main") {
        // First visit
        When({ state.isFirstVisit }) {
          Guard ~ "Halt! The path ahead is dangerous."
          Guard ~ "Spikes, lava, falling platforms... it's a death trap."
          Guard ~ "Are you sure you want to proceed?"
        }

        // Return visits
        When({ state.visitCount > 1 }) {
          Guard ~ "Back for more, eh?"
          Guard ~ "The hazards haven't gotten any safer."
        }

        Choice("I can handle it.") {
          Guard ~ "Ha! I like your spirit!"
          Guard ~ "Good luck out there, adventurer."
        }

        Choice("Any tips?") {
          When({ state.isFirstVisit }) {
            Guard ~ "Smart. Always scout ahead before jumping."
            Guard ~ "Watch for patterns - most hazards have a rhythm."
            Guard ~ "And don't forget to use checkpoints!"
          }
          When({ state.visitCount > 1 }) {
            Guard ~ "You know the drill by now."
            Guard ~ "Stay sharp out there."
          }
        }

        Choice("Maybe later.") {
          End
        }
      }
    }
  }
}
