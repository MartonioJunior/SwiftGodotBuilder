import SwiftGodot
import SwiftGodotBuilder

extension Chapter19 {
  struct PauseOverlay: GView {
    let state: ObservableState<GameViewState>

    let palette = Palette()

    @State var firstButton: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            Label$()
              .text("PAUSED")
              .horizontalAlignment(.center)
              .theme(["fontSize": 32, "fontColor": palette.white])

            Button$()
              .text("Resume")
              .minSize([200, 0])
              .focusMode(.all)
              .styleBoxes(palette.cyanButtonStylesWithFocus)
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.resumeGame()
              }
              .onReady { [self] btn in
                firstButton = btn
              }

            Button$()
              .text("Restart")
              .minSize([200, 0])
              .focusMode(.all)
              .styleBoxes(palette.yellowButtonStylesWithFocus)
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.reset()
                Engine.onNextFrame {
                  state.wrappedValue.gameState = .playing
                }
              }

            Button$()
              .text("Settings")
              .minSize([200, 0])
              .focusMode(.all)
              .styleBoxes(palette.purpleButtonStylesWithFocus)
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.gameState = .settings
              }

            Button$()
              .text("Quit to Menu")
              .minSize([200, 0])
              .focusMode(.all)
              .styleBoxes(palette.grayButtonStylesWithFocus)
              .onSignal(\.pressed) { [state] _ in
                state.wrappedValue.gameState = .levelSelect
              }

            Label$()
              .text("[A] Select  [D-Pad] Navigate")
              .horizontalAlignment(.center)
              .theme(["fontColor": palette.darkGray])
          }
          .theme(["separation": 4])
        }
        .theme("panel", palette.pausePanelStyle)
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
