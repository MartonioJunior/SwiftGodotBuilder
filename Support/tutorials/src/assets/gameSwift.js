export default `import SwiftGodot
import SwiftGodotBuilder

@Godot
final class Game: Node2D {
  override func _ready() {
    setupInput()
    addChild(node: GameView().toNode())
  }

  func setupInput() {
    Actions {
      Action("move_left") {
        Key(.a)
        Key(.left)
      }

      Action("move_right") {
        Key(.d)
        Key(.right)
      }
    }
    .install()
  }
}`
