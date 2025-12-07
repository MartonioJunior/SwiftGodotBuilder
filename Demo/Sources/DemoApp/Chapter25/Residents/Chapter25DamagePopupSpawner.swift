import SwiftGodot
import SwiftGodotBuilder

extension Chapter25 {
  struct DamagePopupSpawner: GView {
    let floatDistance: Float = 20
    let floatDuration: Double = 0.6

    var body: some GView {
      Node2D$()
        .onEvent(GameEvent.self) { node, event in
          if case let .damageDealt(amount, position) = event {
            Engine.onNextFrame {
              spawnPopup(parent: node, amount: amount, at: position)
            }
          }
        }
    }

    func spawnPopup(parent: Node, amount: Int, at position: Vector2) {
      let randomOffset = Vector2(
        x: Float.random(in: -4 ... 4),
        y: Float.random(in: -2 ... 2)
      )

      let damageTheme = Theme([
        "Label": [
          "colors": ["fontColor": Color(code: "#FF6644")]
        ]
      ])

      let popupNode = Node2D$ {
        Label$()
          .text("\(amount)")
          .horizontalAlignment(.center)
          .verticalAlignment(.center)
          .theme(damageTheme)
      }
      .position(position + randomOffset)
      .toNode()

      guard let popup = popupNode as? Node2D else { return }
      parent.addChild(node: popup)

      // Float upward and fade out using tween API
      let endY = popup.position.y - floatDistance
      popup.tween(.positionY(endY), duration: floatDuration)
        .ease(.out).trans(.quad)

      // Fade out near the end
      popup.tween(.alpha(0), duration: 0.3)
        .delay(floatDuration - 0.3)
        .onFinished { popup.queueFree() }
    }
  }
}
