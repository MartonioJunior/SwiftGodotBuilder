import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  struct PauseOverlay: GView {
    let router: ObservableState<GameRouter>

    @State var firstResponder: Button?

    var body: some GView {
      Node2D$ {
        OverlayPanel(panelStyle: Palette.shared.pausePanelStyle) {
          HeaderLabel("PAUSED")

          MenuButton("Resume", color: .cyan, ref: _firstResponder) {
            router.scene = .playing
          }

          MenuButton("Restart", color: .yellow) {
            GameEvent.gameReset.emit()
            Engine.onNextFrame {
              router.scene = .playing
            }
          }

          MenuButton("Settings", color: .purple) {
            router.scene = .settings
          }

          MenuButton("Quit to Menu", color: .gray) {
            router.scene = .levelSelect
          }
        }
      }
      .watch(router, \.scene) { node, scene in
        node.visible = scene == .paused
        if scene == .paused {
          firstResponder?.grabFocus()
        }
      }
    }
  }
}
