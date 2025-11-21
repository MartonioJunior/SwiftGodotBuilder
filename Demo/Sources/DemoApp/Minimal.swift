import SwiftGodot
import SwiftGodotBuilder

@Godot
final class MinimalGame: Node2D {
  override func _ready() {
    let rootNode = MinimalGameView().toNode()
    addChild(node: rootNode)
  }
}

struct MinimalGameView: GView {
  var body: some GView {
    Node2D$().onReady { _ in
      print("MinimalGameView is ready!")
    }.onProcess { _, _ in
      print("MinimalGameView is processing!")
    }
  }
}
