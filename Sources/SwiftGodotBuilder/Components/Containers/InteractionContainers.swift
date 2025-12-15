import SwiftGodot

// MARK: - Clickable

/// Wraps content to make it clickable via an invisible button overlay.
public struct Clickable<Content: GView>: GView {
  let content: Content
  let onPressed: () -> Void

  public init(
    onPressed: @escaping () -> Void,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.onPressed = onPressed
  }

  public var body: some GView {
    Control$ {
      content
      Button$()
        .flat(true)
        .anchorsAndOffsets(.fullRect)
        .focusMode(.none)
        .onSignal(\.pressed) { _ in onPressed() }
    }
  }
}

// MARK: - Hoverable

/// Tracks mouse enter/exit state for wrapped content.
public struct Hoverable<Content: GView>: GView {
  let isHovered: State<Bool>
  let content: Content

  public init(
    _ isHovered: State<Bool>,
    @GViewBuilder content: () -> Content
  ) {
    self.isHovered = isHovered
    self.content = content()
  }

  public var body: some GView {
    Control$ {
      content
    }
    .mouseFilter(.pass)
    .onSignal(\.mouseEntered) { _ in isHovered.wrappedValue = true }
    .onSignal(\.mouseExited) { _ in isHovered.wrappedValue = false }
  }
}

// MARK: - Pressable

/// Adds press-down/release visual feedback to wrapped content.
/// Scales content on press with configurable animation.
public struct Pressable<Content: GView>: GView {
  let content: Content
  let pressScale: Float
  let duration: Double
  let onPressed: () -> Void

  @State var controlNode: Control?
  @State var tween: TweenHandle?

  public init(
    pressScale: Float = 0.95,
    duration: Double = 0.08,
    onPressed: @escaping () -> Void,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.pressScale = pressScale
    self.duration = duration
    self.onPressed = onPressed
  }

  public var body: some GView {
    Control$ {
      content
      Button$()
        .flat(true)
        .anchorsAndOffsets(.fullRect)
        .focusMode(.none)
        .onSignal(\.buttonDown) { _ in
          tween = controlNode?.tween(.scale([pressScale, pressScale]), duration: duration, killing: tween)
            .ease(.out)
        }
        .onSignal(\.buttonUp) { _ in
          tween = controlNode?.tween(.scale([1, 1]), duration: duration, killing: tween)
            .ease(.out)
        }
        .onSignal(\.pressed) { _ in onPressed() }
    }
    .ref($controlNode)
    .onReady { node in
      // Set pivot to center for scaling
      let s = node.getRect().size
      node.pivotOffset = [s.x / 2, s.y / 2]
    }
  }
}
