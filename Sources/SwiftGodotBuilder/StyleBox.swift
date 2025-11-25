import Foundation
import SwiftGodot

// MARK: - StyleBox Builder Protocol

/// Protocol for type-erased StyleBox builders.
public protocol StyleBoxBuilderProtocol {
  func toStyleBox() -> StyleBox
}

// MARK: - Generic StyleBox Builder

/// Generic declarative StyleBox builder using dynamic member lookup.
///
/// Provides a fluent API for configuring StyleBox properties without boilerplate.
@dynamicMemberLookup
public struct StyleBoxBuilder<T: StyleBox>: StyleBoxBuilderProtocol {
  private let styleBox: T

  /// Creates a new StyleBox builder with the given StyleBox instance.
  public init(_ styleBox: T) {
    self.styleBox = styleBox
  }

  /// Dynamic member lookup for setting StyleBox properties.
  ///
  /// Allows calling any writable property on the underlying StyleBox as a method.
  ///
  /// - Parameter keyPath: The keypath to the property to set
  /// - Returns: A closure that takes the value and returns self for chaining
  public subscript<V>(dynamicMember keyPath: ReferenceWritableKeyPath<T, V>) -> (V) -> StyleBoxBuilder<T> {
    return { [styleBox] value in
      styleBox[keyPath: keyPath] = value
      return self
    }
  }

  /// Converts the builder to a StyleBox object.
  ///
  /// - Returns: The configured StyleBox instance
  public func toObject() -> T {
    styleBox
  }

  /// Converts the builder to a StyleBox (type-erased).
  public func toStyleBox() -> StyleBox {
    styleBox
  }
}

// MARK: - Type Aliases for Specific StyleBox Types

/// Builder for StyleBoxFlat.
///
/// ### Example:
/// ```swift
/// StyleBoxFlat$()
///   .bgColor(.black.withAlpha(0.9))
///   .borderColor(.cyan)
///   .borderWidth(2)
///   .cornerRadius(4)
/// ```
public typealias StyleBoxFlat$ = StyleBoxBuilder<StyleBoxFlat>

/// Builder for StyleBoxTexture.
public typealias StyleBoxTexture$ = StyleBoxBuilder<StyleBoxTexture>

/// Builder for StyleBoxLine.
public typealias StyleBoxLine$ = StyleBoxBuilder<StyleBoxLine>

/// Builder for StyleBoxEmpty.
public typealias StyleBoxEmpty$ = StyleBoxBuilder<StyleBoxEmpty>

// MARK: - Convenience Initializers

public extension StyleBoxBuilder where T == StyleBoxFlat {
  /// Creates a new StyleBoxFlat builder with default settings.
  init() {
    self.init(StyleBoxFlat())
  }
}

public extension StyleBoxBuilder where T == StyleBoxTexture {
  /// Creates a new StyleBoxTexture builder with the given texture.
  init(texture: Texture2D) {
    let box = StyleBoxTexture()
    box.texture = texture
    self.init(box)
  }
}

public extension StyleBoxBuilder where T == StyleBoxLine {
  /// Creates a new StyleBoxLine builder with default settings.
  init() {
    self.init(StyleBoxLine())
  }
}

public extension StyleBoxBuilder where T == StyleBoxEmpty {
  /// Creates a new StyleBoxEmpty builder with default settings.
  init() {
    self.init(StyleBoxEmpty())
  }
}

// MARK: - StyleBoxFlat Convenience Methods

public extension StyleBoxBuilder where T == StyleBoxFlat {
  /// Sets all border widths to the same value.
  func borderWidth(_ width: Int32) -> Self {
    styleBox.borderWidthTop = width
    styleBox.borderWidthBottom = width
    styleBox.borderWidthLeft = width
    styleBox.borderWidthRight = width
    return self
  }

  /// Sets all corner radii to the same value.
  func cornerRadius(_ radius: Int32) -> Self {
    styleBox.cornerRadiusTopLeft = radius
    styleBox.cornerRadiusTopRight = radius
    styleBox.cornerRadiusBottomLeft = radius
    styleBox.cornerRadiusBottomRight = radius
    return self
  }

  /// Sets all content margins to the same value.
  func contentMargin(_ margin: Double) -> Self {
    styleBox.contentMarginTop = margin
    styleBox.contentMarginBottom = margin
    styleBox.contentMarginLeft = margin
    styleBox.contentMarginRight = margin
    return self
  }

  /// Sets all expand margins to the same value.
  func expandMargin(_ margin: Double) -> Self {
    styleBox.expandMarginTop = margin
    styleBox.expandMarginBottom = margin
    styleBox.expandMarginLeft = margin
    styleBox.expandMarginRight = margin
    return self
  }
}

// MARK: - GNode Extensions

public extension GNode where T: Control {
  /// Applies multiple StyleBoxes to this control using a dictionary.
  ///
  /// ### Example:
  /// ```swift
  /// Button$()
  ///   .styleBoxes([
  ///     "normal": StyleBoxFlat$().bgColor(.gray),
  ///     "hover": StyleBoxFlat$().bgColor(.lightGray),
  ///     "pressed": StyleBoxFlat$().bgColor(.darkGray)
  ///   ])
  /// ```
  ///
  /// - Parameter dict: Dictionary mapping StyleBox names to builders or StyleBox instances
  func styleBoxes(_ dict: [String: Any]) -> Self {
    var s = self
    s.ops.append { node in
      for (name, value) in dict {
        let styleBox: StyleBox

        if let builder = value as? any StyleBoxBuilderProtocol {
          styleBox = builder.toStyleBox()
        } else if let box = value as? StyleBox {
          styleBox = box
        } else {
          continue
        }

        node.addThemeStyleboxOverride(name: StringName(name), stylebox: styleBox)
      }
    }
    return s
  }
}

// MARK: - Specialized Extensions

public extension GNode where T: PanelContainer {
  /// Applies a panel StyleBox to this PanelContainer.
  ///
  /// Convenience method that automatically uses "panel" as the StyleBox name.
  ///
  /// ### Example:
  /// ```swift
  /// PanelContainer$ {
  ///   // ...
  /// }
  /// .panelStyle(
  ///   StyleBoxFlat$()
  ///     .bgColor(.black.withAlpha(0.9))
  ///     .borderColor(.cyan)
  /// )
  /// ```
  func panelStyle<S: StyleBox>(_ builder: StyleBoxBuilder<S>) -> Self {
    return theme("panel", builder)
  }

  /// Applies a panel StyleBox to this PanelContainer.
  func panelStyle(_ styleBox: StyleBox) -> Self {
    return theme("panel", styleBox)
  }
}

public extension GNode where T: Button {
  /// Applies a normal state StyleBox to this Button.
  func normalStyle<S: StyleBox>(_ builder: StyleBoxBuilder<S>) -> Self {
    return theme("normal", builder)
  }

  /// Applies a hover state StyleBox to this Button.
  func hoverStyle<S: StyleBox>(_ builder: StyleBoxBuilder<S>) -> Self {
    return theme("hover", builder)
  }

  /// Applies a pressed state StyleBox to this Button.
  func pressedStyle<S: StyleBox>(_ builder: StyleBoxBuilder<S>) -> Self {
    return theme("pressed", builder)
  }

  /// Applies a disabled state StyleBox to this Button.
  func disabledStyle<S: StyleBox>(_ builder: StyleBoxBuilder<S>) -> Self {
    return theme("disabled", builder)
  }
}
