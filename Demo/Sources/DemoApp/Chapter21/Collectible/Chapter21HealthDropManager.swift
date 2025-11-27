import SwiftGodot
import SwiftGodotBuilder

extension Chapter21 {
  struct HealthDropManager: GView {
    let palette = Palette.shared

    var body: some GView {
      Node2D$()
        .onEvent(Event.self) { [palette] node, event in
          if case let .healthDropSpawned(position) = event {
            // Defer to next frame to avoid physics errors
            Engine.onNextFrame {
              let drop = Collectible(position: position, .health(palette))
              node.addChild(node: drop.toNode())
            }
          }
        }
    }
  }
}
