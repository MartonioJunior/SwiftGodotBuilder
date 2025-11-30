import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  struct WelcomeOverlay: GView {
    let router: ObservableState<GameRouter>

    let palette = Palette.shared

    @State var startButton: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("CHAPTER 23", color: palette.cyan)
            HeaderLabel("CREDITS & SPLASH", size: 16, color: palette.gold)

            Spacer(8)

            InfoLabel("• Splash screen with VFX", color: palette.lightGray)
            InfoLabel("• Death & Game Over screens", color: palette.lightGray)
            InfoLabel("• Scrolling credits with RichTextLabel", color: palette.lightGray)

            Spacer(16)

            HBoxContainer$ {
              AnimatedButton("Start", width: 120, color: .cyan, ref: $startButton) {
                goToLevelSelect()
              }
              AnimatedButton("Credits", width: 120, color: .purple) {
                goToCredits()
              }
            }
            .theme(["separation": 8])
          }
          .theme(["separation": 2])
        }
        .theme("panel", palette.panelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .welcome
        if scene == .welcome {
          startButton?.grabFocus()
        }
      }
      .onProcess { [router] _, _ in
        guard router.scene == .welcome else { return }
        if Action("ui_accept").isJustPressed || Action("attack").isJustPressed {
          goToLevelSelect()
        }
      }
    }

    func goToLevelSelect() {
      router.navigate(to: .levelSelect, transition: .wipe())
    }

    func goToCredits() {
      router.navigate(to: .credits, transition: .fade())
    }
  }
}
