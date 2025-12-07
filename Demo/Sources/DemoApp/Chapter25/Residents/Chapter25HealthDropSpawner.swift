import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct HealthDropSpawner: GView {
    var body: some GView {
      Node2D$()
        .onEvent(GameEvent.self) { node, event in
          switch event {
          case let .healthDropSpawned(position):
            // Defer to next frame to avoid physics errors
            Engine.onNextFrame {
              let drop = CollectibleView(position: position, .health)
              node.addChild(node: drop.toNode())
            }
          case .gameReset:
            // Remove all dynamically spawned drops
            for child in node.getChildren() {
              child.queueFree()
            }
          default:
            break
          }
        }
    }
  }
}
