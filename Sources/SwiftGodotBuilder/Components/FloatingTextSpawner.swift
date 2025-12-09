import SwiftGodot

/// Spawns floating text popups that animate upward and fade out.
/// Generic over event type - provide an extractor to pull text, position, and color from events.
public struct FloatingTextSpawner<E: EmittableEvent>: GView {
  let eventType: E.Type
  let extract: (E) -> (text: String, position: Vector2, color: Color)?
  let floatDistance: Float
  let floatDuration: Double
  let randomOffsetX: ClosedRange<Float>
  let randomOffsetY: ClosedRange<Float>

  public init(
    _ eventType: E.Type,
    floatDistance: Float = 20,
    floatDuration: Double = 0.6,
    randomOffsetX: ClosedRange<Float> = -4 ... 4,
    randomOffsetY: ClosedRange<Float> = -2 ... 2,
    extract: @escaping (E) -> (text: String, position: Vector2, color: Color)?
  ) {
    self.eventType = eventType
    self.floatDistance = floatDistance
    self.floatDuration = floatDuration
    self.randomOffsetX = randomOffsetX
    self.randomOffsetY = randomOffsetY
    self.extract = extract
  }

  public var body: some GView {
    Node2D$()
      .onEvent(eventType) { node, event in
        if let data = extract(event) {
          Engine.onNextFrame {
            spawnPopup(parent: node, text: data.text, at: data.position, color: data.color)
          }
        }
      }
  }

  func spawnPopup(parent: Node, text: String, at position: Vector2, color: Color) {
    let randomOffset = Vector2(
      x: Float.random(in: randomOffsetX),
      y: Float.random(in: randomOffsetY)
    )

    let textTheme = Theme([
      "Label": [
        "colors": ["fontColor": color],
      ],
    ])

    let popupNode = Node2D$ {
      Label$()
        .text(text)
        .horizontalAlignment(.center)
        .verticalAlignment(.center)
        .theme(textTheme)
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
