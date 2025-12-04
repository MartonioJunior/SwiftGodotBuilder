import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct WelcomeOverlay: GView {
    let router: ObservableState<GameRouter>

    let palette = Palette.shared

    @State var startButton: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("CHAPTER 24", color: palette.cyan)
            HeaderLabel("LEVEL DESIGN WITH LDtk", size: 16, color: palette.gold)

            Spacer(8)

            InfoLabel("• Dynamic levels with LDtk", color: palette.lightGray)

            Spacer(16)

            HBoxContainer$ {
              AnimatedButton("Start", width: 70, color: .cyan, ref: $startButton) {
                goToLevelSelect()
              }

              SpacerH()

              AnimatedButton("Credits", width: 70, color: .purple) {
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
      .onProcess { _, _ in
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
