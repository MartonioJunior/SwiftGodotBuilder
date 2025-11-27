import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  struct WelcomeOverlay: GView {
    let state: ObservableState<GameViewState>

    let palette = Palette.shared

    @State var startButton: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("CHAPTER 21", color: palette.cyan)
            HeaderLabel("PERFORMANCE", size: 16, color: palette.gold)

            Spacer(8)

            InfoLabel("• Object pooling", color: palette.lightGray)
            InfoLabel("• Code consolidation", color: palette.lightGray)

            Spacer(16)

            MenuButton("Start", width: 150, color: .cyan, ref: $startButton) {
              state.wrappedValue.gameState = .levelSelect
            }
          }
          .theme(["separation": 2])
        }
        .theme("panel", palette.panelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .visible(state.isWelcome)
      .watch(state, \.gameState) { _, gameState in
        if gameState == .welcome {
          startButton?.grabFocus()
        }
      }
      .onProcess { [state] _, _ in
        guard state.wrappedValue.isWelcome else { return }
        if Action("ui_accept").isJustPressed || Action("attack").isJustPressed {
          state.wrappedValue.gameState = .levelSelect
        }
      }
    }
  }
}
