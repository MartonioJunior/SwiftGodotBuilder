import SwiftGodot

// MARK: - SafeArea

/// Insets content from screen edges by the specified margins.
public struct SafeArea<Content: GView>: GView {
  let content: Content
  let top: Float
  let right: Float
  let bottom: Float
  let left: Float

  public init(
    top: Float = 0,
    right: Float = 0,
    bottom: Float = 0,
    left: Float = 0,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.top = top
    self.right = right
    self.bottom = bottom
    self.left = left
  }

  public init(
    all: Float,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    top = all
    right = all
    bottom = all
    left = all
  }

  public init(
    horizontal: Float = 0,
    vertical: Float = 0,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    top = vertical
    right = horizontal
    bottom = vertical
    left = horizontal
  }

  public var body: some GView {
    MarginContainer$ {
      content
    }
    .configure { container in
      container.addThemeConstantOverride(name: "margin_top", constant: Int32(top))
      container.addThemeConstantOverride(name: "margin_right", constant: Int32(right))
      container.addThemeConstantOverride(name: "margin_bottom", constant: Int32(bottom))
      container.addThemeConstantOverride(name: "margin_left", constant: Int32(left))
    }
    .anchorsAndOffsets(.fullRect)
  }
}

// MARK: - Delayed

/// Shows wrapped content after a delay.
public struct Delayed<Content: GView>: GView {
  let content: Content
  let seconds: Double
  let fadeIn: Bool
  let fadeDuration: Double

  @State var isVisible = false

  public init(
    seconds: Double,
    fadeIn: Bool = true,
    fadeDuration: Double = 0.2,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.seconds = seconds
    self.fadeIn = fadeIn
    self.fadeDuration = fadeDuration
  }

  public var body: some GView {
    Node2D$ {
      If($isVisible) {
        if fadeIn {
          FadeIn(duration: fadeDuration) {
            content
          }
        } else {
          content
        }
      }
    }
    .onReady { node in
      let timer = node.getTree()?.createTimer(timeSec: seconds)
      timer?.timeout.connect {
        _isVisible.wrappedValue = true
      }
    }
  }
}

// MARK: - AspectRatio

/// Maintains a specific aspect ratio for wrapped content.
public struct AspectRatio<Content: GView>: GView {
  let content: Content
  let ratio: Float
  let stretchMode: AspectRatioContainer.StretchMode

  public init(
    _ ratio: Float,
    stretchMode: AspectRatioContainer.StretchMode = .fit,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.ratio = ratio
    self.stretchMode = stretchMode
  }

  public var body: some GView {
    AspectRatioContainer$ {
      content
    }
    .configure { container in
      container.ratio = Double(ratio)
      container.stretchMode = stretchMode
    }
  }
}

// MARK: - Centered

/// Centers wrapped content in its parent.
public struct Centered<Content: GView>: GView {
  let content: Content

  public init(@GViewBuilder content: () -> Content) {
    self.content = content()
  }

  public var body: some GView {
    CenterContainer$ {
      content
    }
    .anchorsAndOffsets(.fullRect)
  }
}

// MARK: - Scrollable

/// Makes wrapped content scrollable.
public struct Scrollable<Content: GView>: GView {
  let content: Content
  let horizontal: Bool
  let vertical: Bool

  public init(
    horizontal: Bool = false,
    vertical: Bool = true,
    @GViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.horizontal = horizontal
    self.vertical = vertical
  }

  public var body: some GView {
    ScrollContainer$ {
      content
    }
    .horizontalScrollMode(horizontal ? .auto : .disabled)
    .verticalScrollMode(vertical ? .auto : .disabled)
  }
}
