import SwiftGodot

// MARK: - Pulse

/// Applies a continuous pulsing scale animation to wrapped content.
public struct Pulse<Content: GView>: GView {
  let content: Content
  let minScale: Float
  let maxScale: Float
  let duration: Double

  @State var node: Node2D?

  public init(
    minScale: Float = 0.95,
    maxScale: Float = 1.05,
    duration: Double = 1.0,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.minScale = minScale
    self.maxScale = maxScale
    self.duration = duration
  }

  public var body: some GView {
    Node2D$ {
      content
    }
    .ref($node)
    .onReady { node in
      startPulse(node: node)
    }
  }

  func startPulse(node: Node2D) {
    node.tween { seq in
      seq.to(.scale([maxScale, maxScale]), duration: duration / 2)
        .trans(.sine).ease(.inOut)
        .to(.scale([minScale, minScale]), duration: duration / 2)
        .trans(.sine).ease(.inOut)
    }
    .loop()
  }
}

// MARK: - Shake

/// Applies a shake animation to wrapped content when triggered.
public struct Shake<Content: GView>: GView {
  let trigger: State<Bool>
  let content: Content
  let intensity: Float
  let duration: Double
  let shakeCount: Int

  @State var node: Node2D?
  @State var originalPosition: Vector2 = .zero

  public init(
    _ trigger: State<Bool>,
    intensity: Float = 4,
    duration: Double = 0.4,
    shakeCount: Int = 6,
    @GViewBuilder content: () -> Content
  ) {
    self.trigger = trigger
    self.content = content()
    self.intensity = intensity
    self.duration = duration
    self.shakeCount = shakeCount
  }

  public var body: some GView {
    Node2D$ {
      content
    }
    .ref($node)
    .onReady { node in
      originalPosition = node.position
    }
    .watch(trigger) { node, shouldShake in
      if shouldShake {
        performShake(node: node)
      }
    }
  }

  func performShake(node: Node2D) {
    let stepDuration = duration / Double(shakeCount)

    node.tween { seq in
      for i in 0 ..< shakeCount {
        let factor = 1.0 - (Float(i) / Float(shakeCount))
        let offset = Vector2(
          x: Float.random(in: -intensity ... intensity) * factor,
          y: Float.random(in: -intensity ... intensity) * factor
        )
        seq.to(.position(originalPosition + offset), duration: stepDuration)
      }
      seq.to(.position(originalPosition), duration: stepDuration)
    }
    .onFinished {
      trigger.wrappedValue = false
    }
  }
}

// MARK: - FadeIn

/// Fades in wrapped content when it appears.
public struct FadeIn<Content: GView>: GView {
  let content: Content
  let duration: Double
  let delay: Double

  public init(
    duration: Double = 0.3,
    delay: Double = 0,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.duration = duration
    self.delay = delay
  }

  public var body: some GView {
    Node2D$ {
      content
    }
    .modulate(Color(r: 1, g: 1, b: 1, a: 0))
    .onReady { node in
      if delay > 0 {
        node.tween(.alpha(1), duration: duration).delay(delay).ease(.out)
      } else {
        node.tween(.alpha(1), duration: duration).ease(.out)
      }
    }
  }
}

// MARK: - FadeOut

/// Fades out and optionally removes wrapped content when triggered.
public struct FadeOut<Content: GView>: GView {
  let trigger: State<Bool>
  let content: Content
  let duration: Double
  let removeOnComplete: Bool

  @State var node: Node2D?

  public init(
    _ trigger: State<Bool>,
    duration: Double = 0.3,
    removeOnComplete: Bool = true,
    @GViewBuilder content: () -> Content
  ) {
    self.trigger = trigger
    self.content = content()
    self.duration = duration
    self.removeOnComplete = removeOnComplete
  }

  public var body: some GView {
    Node2D$ {
      content
    }
    .ref($node)
    .watch(trigger) { node, shouldFade in
      if shouldFade {
        node.tween(.alpha(0), duration: duration)
          .ease(.out)
          .onFinished {
            if removeOnComplete {
              node.queueFree()
            }
          }
      }
    }
  }
}

// MARK: - SlideIn

/// Slides in wrapped content from a direction when it appears.
public struct SlideIn<Content: GView>: GView {
  public enum Direction {
    case left, right, top, bottom
  }

  let content: Content
  let direction: Direction
  let distance: Float
  let duration: Double
  let delay: Double

  public init(
    from direction: Direction = .left,
    distance: Float = 50,
    duration: Double = 0.3,
    delay: Double = 0,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.direction = direction
    self.distance = distance
    self.duration = duration
    self.delay = delay
  }

  public var body: some GView {
    Node2D$ {
      content
    }
    .modulate(Color(r: 1, g: 1, b: 1, a: 0))
    .onReady { node in
      let startOffset: Vector2
      switch direction {
      case .left: startOffset = [-distance, 0]
      case .right: startOffset = [distance, 0]
      case .top: startOffset = [0, -distance]
      case .bottom: startOffset = [0, distance]
      }

      let originalPos = node.position
      node.position = originalPos + startOffset

      if delay > 0 {
        node.tween(.position(originalPos), duration: duration).delay(delay).ease(.out).trans(.quad)
        node.tween(.alpha(1), duration: duration).delay(delay).ease(.out)
      } else {
        node.tween(.position(originalPos), duration: duration).ease(.out).trans(.quad)
        node.tween(.alpha(1), duration: duration).ease(.out)
      }
    }
  }
}
