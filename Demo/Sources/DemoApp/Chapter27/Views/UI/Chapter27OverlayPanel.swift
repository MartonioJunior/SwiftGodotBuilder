import SwiftGodot
import SwiftGodotBuilder

extension Chapter27 {
  /// Reusable panel wrapper for overlay screens
  struct OverlayPanel<Content: GView>: GView {
    let content: Content
    var panelStyle: StyleBoxFlat$
    var separation: Int

    init(
      panelStyle: StyleBoxFlat$? = nil,
      separation: Int = 4,
      @GViewBuilder content: () -> Content
    ) {
      self.content = content()
      self.panelStyle = panelStyle ?? Palette.shared.panelStyle
      self.separation = separation
    }

    var body: some GView {
      CenterContainer$ {
        PanelContainer$ {
          VBoxContainer$ {
            content
          }
          .theme(["separation": separation])
        }
        .theme("panel", panelStyle)
      }
      .anchorsAndOffsets(.fullRect)
    }
  }
}
