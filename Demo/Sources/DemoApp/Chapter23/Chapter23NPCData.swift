import SwiftGodot
import SwiftGodotBuilder

// MARK: - NPC Definitions

extension Chapter23.NPCDefinition {
  private static var OldMan: Speaker { Speaker("Old Man") }
  private static var Merchant: Speaker { Speaker("Merchant") }
  private static var Guard: Speaker { Speaker("Guard") }
  private static var Sage: Speaker { Speaker("Sage") }
  private static var Knight: Speaker { Speaker("Knight") }

  static var oldMan: Chapter23.NPCDefinition { Chapter23.NPCDefinition(
    id: "old_man",
    name: "Old Man",
    color: Color(code: "#44AA44"),
    size: [12, 16],
    makeDialog: { dialog, _, progress in
      Dialog(id: "old_man") {
        Branch("main") {
          // Replaying after beating level
          When({ progress.getProgress(for: 1).completed }) {
            When({ dialog.isFirstVisit }) {
              OldMan ~ "The hero returns! Back for another run?"
              OldMan ~ "Your legend grows with each victory."
            }
            When({ !dialog.isFirstVisit }) {
              OldMan ~ "Go show them what you're made of!"
            }
          }

          // First playthrough
          When({ !progress.getProgress(for: 1).completed }) {
            When({ dialog.isFirstVisit }) {
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

            When({ !dialog.isFirstVisit }) {
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
  ) }

  static var merchant: Chapter23.NPCDefinition { Chapter23.NPCDefinition(
    id: "merchant",
    name: "Merchant",
    color: Color(code: "#4488FF"),
    size: [12, 16],
    makeDialog: { dialog, gameState, _ in
      Dialog(id: "merchant") {
        Branch("main") {
          When({ dialog.isFirstVisit }) {
            Merchant ~ "Psst! Hey, you!"
          }

          When({ dialog.visitCount > 1 }) {
            Merchant ~ "Back again, friend!"
          }

          When({ gameState.hasKey }) {
            Merchant ~ "I see you've got the key!"
            Merchant ~ "The door to the next area is just ahead."
          }

          When({ !gameState.hasKey }) {
            When({ dialog.isFirstVisit }) {
              Merchant ~ "Looking for supplies? I've got everything you need."
              Merchant ~ "Well... I would, if the monsters hadn't stolen my wares!"
              Merchant ~ "But I did manage to hide this key..."
            }

            When({ dialog.visitCount > 1 }) {
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
  ) }

  static var `guard`: Chapter23.NPCDefinition { Chapter23.NPCDefinition(
    id: "guard",
    name: "Guard",
    color: Color(code: "#8844FF"),
    size: [12, 16],
    makeDialog: { dialog, _, _ in
      Dialog(id: "guard") {
        Branch("main") {
          When({ dialog.isFirstVisit }) {
            Guard ~ "Halt! The path ahead is dangerous."
            Guard ~ "Spikes, lava, falling platforms... it's a death trap."
            Guard ~ "Are you sure you want to proceed?"
          }

          When({ dialog.visitCount > 1 }) {
            Guard ~ "Back for more, eh?"
            Guard ~ "The hazards haven't gotten any safer."
          }

          Choice("I can handle it.") {
            Guard ~ "Ha! I like your spirit!"
            Guard ~ "Good luck out there, adventurer."
          }

          Choice("Any tips?") {
            When({ dialog.isFirstVisit }) {
              Guard ~ "Smart. Always scout ahead before jumping."
              Guard ~ "Watch for patterns - most hazards have a rhythm."
              Guard ~ "And don't forget to use checkpoints!"
            }
            When({ dialog.visitCount > 1 }) {
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
  ) }

  static var advisors: Chapter23.NPCDefinition { Chapter23.NPCDefinition(
    id: "advisors",
    name: "Sage",
    color: Color(code: "#44AAAA"),
    size: [12, 16],
    makeDialog: { dialog, _, _ in
      Dialog(id: "advisors") {
        Branch("main") {
          When({ dialog.isFirstVisit }) {
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

          When({ !dialog.isFirstVisit }) {
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
    },
    additionalSpeakers: [("Knight", Color(code: "#FF8844"))]
  ) }
}
