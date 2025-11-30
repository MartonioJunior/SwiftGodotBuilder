import SwiftGodot
import SwiftGodotBuilder

extension Chapter23 {
  struct PauseOverlay: GView {
    let router: ObservableState<GameRouter>

    @State var firstResponder: Button?

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            HeaderLabel("PAUSED")

            MenuButton("Resume", color: .cyan, ref: _firstResponder) {
              router.scene = .playing
            }

            MenuButton("Restart", color: .yellow) {
              Event.gameReset.emit()
              Engine.onNextFrame { [router] in
                router.scene = .playing
              }
            }

            MenuButton("Settings", color: .purple) {
              router.scene = .settings
            }

            MenuButton("Quit to Menu", color: .gray) {
              router.scene = .levelSelect
            }

            InfoLabel("[A] Select  [D-Pad] Navigate")
          }
          .theme(["separation": 4])
        }
        .theme("panel", Palette.shared.pausePanelStyle)
      }
      .anchorsAndOffsets(.fullRect)
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .paused
        if scene == .paused {
          firstResponder?.grabFocus()
        }
      }
    }
  }
}
