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
  let poolSize: Int

  private let pool = FloatingTextPool()

  public init(
    _ eventType: E.Type,
    floatDistance: Float = 20,
    floatDuration: Double = 0.6,
    randomOffsetX: ClosedRange<Float> = -4 ... 4,
    randomOffsetY: ClosedRange<Float> = -2 ... 2,
    poolSize: Int = 20,
    extract: @escaping (E) -> (text: String, position: Vector2, color: Color)?
  ) {
    self.eventType = eventType
    self.floatDistance = floatDistance
    self.floatDuration = floatDuration
    self.randomOffsetX = randomOffsetX
    self.randomOffsetY = randomOffsetY
    self.poolSize = poolSize
    self.extract = extract
  }

  public var body: some GView {
    Node2D$()
      .onReady { node in
        pool.setup(parent: node, count: poolSize)
      }
      .onEvent(eventType) { [pool, floatDistance, floatDuration, randomOffsetX, randomOffsetY] _, event in
        if let data = extract(event) {
          let randomOffset = Vector2(
            x: Float.random(in: randomOffsetX),
            y: Float.random(in: randomOffsetY)
          )
          pool.spawn(
            text: data.text,
            at: data.position + randomOffset,
            color: data.color,
            floatDistance: floatDistance,
            duration: floatDuration
          )
        }
      }
  }
}

/// Internal pool for floating text nodes
private final class FloatingTextPool {
  private var available: [Node2D] = []
  private weak var parentNode: Node?

  func setup(parent: Node, count: Int) {
    parentNode = parent
    Engine.onNextFrame { [weak self, weak parent] in
      guard let self, let parent else { return }
      for _ in 0 ..< count {
        let node = self.createPopupNode()
        parent.addChild(node: node)
        self.available.append(node)
      }
    }
  }

  private func createPopupNode() -> Node2D {
    let label = Label()
    label.horizontalAlignment = .center
    label.verticalAlignment = .center

    let node = Node2D()
    node.addChild(node: label)
    node.visible = false
    node.position = [-9999, -9999]

    return node
  }

  func spawn(text: String, at position: Vector2, color: Color, floatDistance: Float, duration: Double) {
    guard let parent = parentNode else { return }

    let node: Node2D

    if let pooled = available.popLast() {
      node = pooled
    } else {
      // Pool exhausted - create new (will be pooled when done)
      let newNode = createPopupNode()
      parent.addChild(node: newNode)
      node = newNode
    }

    guard let label = node.getChild(idx: 0) as? Label else { return }

    // Configure
    label.text = text
    label.addThemeColorOverride(name: "font_color", color: color)
    node.position = position
    node.visible = true
    node.modulate = Color(r: 1, g: 1, b: 1, a: 1)

    // Animate
    let endY = position.y - floatDistance
    node.tween(.positionY(endY), duration: duration)
      .ease(.out).trans(.quad)

    node.tween(.alpha(0), duration: 0.3)
      .delay(duration - 0.3)
      .onFinished { [weak self, weak node] in
        guard let node else { return }
        self?.returnToPool(node)
      }
  }

  private func returnToPool(_ node: Node2D) {
    node.visible = false
    node.position = [-9999, -9999]
    available.append(node)
  }
}
