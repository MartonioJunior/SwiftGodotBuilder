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
}
