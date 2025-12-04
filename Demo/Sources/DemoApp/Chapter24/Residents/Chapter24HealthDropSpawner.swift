import SwiftGodot
import SwiftGodotBuilder

extension Chapter24 {
  struct HealthDropSpawner: GView {
    var body: some GView {
      Node2D$()
        .onEvent(GameEvent.self) { node, event in
          if case let .healthDropSpawned(position) = event {
            // Defer to next frame to avoid physics errors
            Engine.onNextFrame {
              let drop = CollectibleView(position: position, .health)
              node.addChild(node: drop.toNode())
            }
          }
        }
    }
  }
}
