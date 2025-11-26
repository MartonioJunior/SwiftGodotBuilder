import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  static let Merchant = Speaker("Merchant")

  static func makeMerchantDialog(
    state: DialogState,
    gameState: GameViewState,
    progress: GameProgress
  ) -> DialogDefinition {
    Dialog(id: "merchant") {
      Branch("main") {
        // First visit greeting
        When({ state.isFirstVisit }) {
          Merchant ~ "Psst! Hey, you!"
        }

        // Return visit greeting
        When({ state.visitCount > 1 }) {
          Merchant ~ "Back again, friend!"
        }

        // Already has key - short dialog
        When({ gameState.hasKey }) {
          Merchant ~ "I see you've got the key!"
          Merchant ~ "The door to the next area is just ahead."
        }

        // Doesn't have key - offer it
        When({ !gameState.hasKey }) {
          When({ state.isFirstVisit }) {
            Merchant ~ "Looking for supplies? I've got everything you need."
            Merchant ~ "Well... I would, if the monsters hadn't stolen my wares!"
            Merchant ~ "But I did manage to hide this key..."
          }

          When({ state.visitCount > 1 }) {
            Merchant ~ "Changed your mind about that key?"
          }

          Choice("Can I have the key?") {
            Merchant ~ "Since you're helping clear out the monsters..."
            Merchant ~ "Here, take it. You'll need it to reach the exit."
            Emit("giveKey")
          }

          Choice("What happened here?") {
            Merchant ~ "Flying creatures attacked last night."
            Merchant ~ "Took everything! My potions, my weapons..."
            Merchant ~ "At least they didn't find the key to the door."

            Choice("I'll take that key.") {
              Merchant ~ "Of course! Good luck out there."
              Emit("giveKey")
            }

            Choice("I'll manage without it.") {
              Merchant ~ "Suit yourself..."
              End
            }
          }

          Choice("Not interested.") {
            End
          }
        }
      }
    }
  }
}
