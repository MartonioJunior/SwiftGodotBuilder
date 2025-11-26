import SwiftGodot
import SwiftGodotBuilder

extension Chapter20 {
  struct HealthDropManager: GView {
    var body: some GView {
      Node2D$()
        .onEvent(Event.self) { node, event in
          if case let .healthDropSpawned(position) = event {
            spawnHealthDrop(at: position, parent: node)
          }
        }
    }

    func spawnHealthDrop(at position: Vector2, parent: Node) {
      // Defer to next frame to avoid physics errors
      Engine.onNextFrame {
        let drop = HealthDrop(spawnPosition: position)
        let node = drop.toNode()
        parent.addChild(node: node)
      }
    }
  }
}
