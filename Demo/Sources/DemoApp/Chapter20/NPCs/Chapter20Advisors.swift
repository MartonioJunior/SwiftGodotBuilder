import Foundation
import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  // Two advisors who give advice together before the boss fight
  static let Sage = Speaker("Sage")
  static let Knight = Speaker("Knight")

  static func makeAdvisorsDialog(
    state: DialogState,
    gameState _: GameViewState,
    progress _: GameProgress
  ) -> DialogDefinition {
    Dialog(id: "advisors") {
      Branch("main") {
        When({ state.isFirstVisit }) {
          Sage ~ "Ah, a challenger approaches."
          Knight ~ "The beast ahead is no ordinary foe."
          Sage ~ "Indeed. We've seen many fall to its power."
          Knight ~ "But perhaps you have what it takes."

          Choice("Any advice?") {
            Jump("advice")
          }

          Choice("I'm ready.") {
            Knight ~ "Bold! I like that."
            Sage ~ "May fortune favor you."
          }
        }

        When({ !state.isFirstVisit }) {
          Knight ~ "Back for another attempt?"
          Sage ~ "The beast still waits."

          Choice("More tips?") {
            Jump("advice")
          }

          Choice("Let's do this.") {
            Knight ~ "Give 'em hell!"
          }
        }
      }

      Branch("advice") {
        Sage ~ "The beast has three phases."
        Knight ~ "In the first, it charges. Jump over it!"
        Sage ~ "In the second, it leaps. Stay mobile."
        Knight ~ "The final phase is the most dangerous."
        Sage ~ "It will rage. Strike when it pauses."
        Knight ~ "And grab ammo from the platforms above!"

        Choice("Got it.") {
          Sage ~ "Good luck, brave one."
          Knight ~ "Show that beast what you're made of!"
        }
      }
    }
  }
}
