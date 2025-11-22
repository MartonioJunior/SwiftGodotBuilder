import SwiftGodot
import SwiftGodotBuilder

struct Chapter13HealthDropManager: GView {
  var body: some GView {
    Node2D$()
      .onEvent(Chapter13Event.self) { node, event in
        if case let .healthDropSpawned(position) = event {
          spawnHealthDrop(at: position, parent: node)
        }
      }
  }

  func spawnHealthDrop(at position: Vector2, parent: Node) {
    // Defer to next frame to avoid physics errors
    Engine.onNextFrame {
      let drop = Chapter13HealthDrop(spawnPosition: position)
      let node = drop.toNode()
      parent.addChild(node: node)
    }
  }
}
