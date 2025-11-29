import SwiftGodot
import SwiftGodotBuilder

extension Chapter22 {
  struct WelcomeOverlay: GView {
    let state: ObservableState<GameViewState>
    let transitionState: ObservableState<TransitionState>

    let palette = Palette.shared

    @State var startButton: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("CHAPTER 22", color: palette.cyan)
            HeaderLabel("TRANSITIONS & TWEENS", size: 16, color: palette.gold)

            Spacer(8)

            InfoLabel("• Fluent tween API", color: palette.lightGray)
            InfoLabel("• UI button animations", color: palette.lightGray)
            InfoLabel("• Screen transitions", color: palette.lightGray)

            Spacer(16)

            AnimatedButton("Start", width: 150, color: .cyan, ref: $startButton) {
              goToLevelSelect()
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
      .onProcess { _, _ in
        guard state.wrappedValue.isWelcome else { return }
        if Action("ui_accept").isJustPressed || Action("attack").isJustPressed {
          goToLevelSelect()
        }
      }
    }

    func goToLevelSelect() {
      transitionState.wrappedValue.wipeTransition(
        duration: 0.8,
        onMidpoint: {
          state.wrappedValue.gameState = .levelSelect
        }
      )
    }
  }
}
