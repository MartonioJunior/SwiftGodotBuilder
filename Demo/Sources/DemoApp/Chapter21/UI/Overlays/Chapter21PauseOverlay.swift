import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  struct PauseOverlay: GView {
    let state: ObservableState<GameViewState>

    @State var firstButton: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("PAUSED")

            MenuButton("Resume", color: .cyan, ref: _firstButton) {
              state.wrappedValue.resumeGame()
            }

            MenuButton("Restart", color: .yellow) {
              state.wrappedValue.reset()
              Engine.onNextFrame {
                state.wrappedValue.gameState = .playing
              }
            }

            MenuButton("Settings", color: .purple) {
              state.wrappedValue.gameState = .settings
            }

            MenuButton("Quit to Menu", color: .gray) {
              state.wrappedValue.gameState = .levelSelect
            }

            InfoLabel("[A] Select  [D-Pad] Navigate")
          }
          .theme(["separation": 4])
        }
        .theme("panel", Palette.shared.pausePanelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .visible(state.isPaused)
      .watch(state, \.gameState) { _, gameState in
        if gameState == .paused {
          firstButton?.grabFocus()
        }
      }
    }
  }
}
