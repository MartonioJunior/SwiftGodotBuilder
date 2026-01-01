import Foundation
import SwiftGodot

// MARK: - SVGSprite builder alias

/// Creates an SVGSprite node with the builder pattern.
///
/// ### Usage:
/// ```swift
/// SVGSprite$()
///   .path("res://bullet.svg")
///   .size(16)
///   .colors([.blue, .white])
/// ```
public typealias SVGSprite$ = GNode<SVGSprite>

// MARK: - SVGSprite builder extensions

public extension GNode where T == SVGSprite {
  /// Sets both stroke color and width.
  func stroke(_ color: Color, width: Float = 1.0) -> Self {
    configure {
      $0.strokeColor = color
      $0.strokeWidth = width
    }
  }

  /// Sets CSS class color overrides for SVGs with styled elements.
  /// Use this for SVGs that define colors via CSS classes in `<style>` blocks.
  ///
  /// Example SVG with classes:
  /// ```xml
  /// <style>.cls-1 { fill: #ffdfb5; } .cls-2 { fill: #f4c38e; }</style>
  /// <path class="cls-1" d="..."/>
  /// ```
  ///
  /// Usage:
  /// ```swift
  /// SVGSprite$()
  ///   .path("icon.svg")
  ///   .classColors(["cls-1": .red, "cls-2": .blue])
  /// ```
  func classColors(_ colors: [String: Color]) -> Self {
    configure { $0.classColors = colors }
  }

  /// Controls whether inner subpaths are treated as holes (cutouts) or separate filled shapes.
  ///
  /// - Parameter enabled: When `true`, inner paths cut out from outer paths (like the hole in "O").
  ///                      When `false`, each subpath renders as a separate filled polygon.
  ///
  /// By default, holes are enabled when no `colors` array is set, and disabled otherwise.
  ///
  /// Usage:
  /// ```swift
  /// // Chess piece with layered details - disable holes to fill all layers
  /// SVGSprite$()
  ///   .path("knight.svg")
  ///   .useHoles(false)
  /// ```
  func useHoles(_ enabled: Bool) -> Self {
    configure { $0.useHoles = enabled }
  }
}
