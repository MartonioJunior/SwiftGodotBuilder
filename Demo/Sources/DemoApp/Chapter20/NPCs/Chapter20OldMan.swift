import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  static let OldMan = Speaker("Old Man")

  static func makeOldManDialog(
    state: DialogState,
    gameState _: GameViewState,
    progress: GameProgress
  ) -> DialogDefinition {
    Dialog(id: "old_man") {
      Branch("main") {
        // Replaying after beating level
        When({ progress.getProgress(for: 1).completed }) {
          When({ state.isFirstVisit }) {
            OldMan ~ "The hero returns! Back for another run?"
            OldMan ~ "Your legend grows with each victory."
          }
          When({ !state.isFirstVisit }) {
            OldMan ~ "Go show them what you're made of!"
          }
        }

        // First playthrough
        When({ !progress.getProgress(for: 1).completed }) {
          // First visit - full intro with quest offer
          When({ state.isFirstVisit }) {
            OldMan ~ "Ah, a traveler! Welcome to Tutorial Valley."
            OldMan ~ "Dangerous times we live in... monsters roam these lands."
            OldMan ~ "But you look capable. Perhaps you can help us?"

            Choice("I'll help!") {
              Jump("quest_accepted")
            }

            Choice("What's in it for me?") {
              OldMan ~ "Hmm, a practical one, eh?"
              OldMan ~ "The villagers will surely reward you with coins!"
              OldMan ~ "And you'll become stronger along the way."

              Choice("Alright, I'll do it.") {
                Jump("quest_accepted")
              }

              Choice("Still not interested.") {
                End
              }
            }

            Choice("Not interested.") {
              End
            }
          }

          // Return visits - just encouragement, quest already known
          When({ !state.isFirstVisit }) {
            OldMan ~ "You're back! How fares your journey?"
            Jump("encouragement")
          }
        }

        Choice("Bye.") {
          End
        }
      }

      Branch("quest_accepted") {
        OldMan ~ "Wonderful! A hero at last!"
        OldMan ~ "The village needs someone to clear the monsters ahead."
        OldMan ~ "Reach the door at the end to prove your worth!"
      }

      Branch("encouragement") {
        OldMan ~ "Keep going, young hero!"
        OldMan ~ "The village believes in you."

        Choice("I'll get it done.") {
          OldMan ~ "That's the spirit!"
        }

        Choice("Any advice?") {
          OldMan ~ "Watch out for the monsters ahead."
          OldMan ~ "And collect coins along the way!"
        }
      }
    }
  }
}
