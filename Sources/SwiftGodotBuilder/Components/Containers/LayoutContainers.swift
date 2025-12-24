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

