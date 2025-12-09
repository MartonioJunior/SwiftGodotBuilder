import SwiftGodot
import SwiftGodotBuilder

extension Chapter26 {
  struct WelcomeOverlay: GView {
    let router: ObservableState<GameRouter>

    let palette = Palette.shared

    @State var startButton: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("CHAPTER 25", color: palette.cyan)
            HeaderLabel("SPRITES & DOORWAYS", size: 16, color: palette.gold)

            InfoLabel("• Sprite sheets and animations", color: palette.lightGray)
            InfoLabel("• Doorways for teleportation", color: palette.lightGray)
            InfoLabel("• Breakable blocks", color: palette.lightGray)
            InfoLabel("• Improved attack system", color: palette.lightGray)

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
