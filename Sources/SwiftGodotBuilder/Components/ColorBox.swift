import SwiftGodot

/// A Godot `Polygon2D` subclass that renders a colored rectangle.
///
/// This is useful for placeholder graphics, debug visualization, or simple colored shapes
/// in the game world (as opposed to UI Controls like ColorRect).
///
/// ### Example
/// ```swift
/// // Using the builder pattern
/// ColorBox$([100, 50])
///   .color(.red)
///   .position([200, 300])
///
/// // Using GNode
/// GNode<ColorBox> {
///   ColorBox([100, 50])
/// }
/// .color(.red)
/// ```
@Godot
public class ColorBox: Polygon2D {
  /// The size of the colored rectangle
  public var size: Vector2 = .init(x: 32, y: 32) {
    didSet {
      updatePolygon()
    }
  }

  /// Convenience init with Vector2 size
  public convenience init(_ size: Vector2) {
    self.init()
    self.size = size
    updatePolygon()
  }

  /// Convenience init with array literal [width, height]
  public convenience init(_ size: [Float]) {
    self.init()
    self.size = Vector2(x: size[0], y: size[1])
    updatePolygon()
  }

  /// Convenience init with width and height
  public convenience init(w: Float, h: Float) {
    self.init()
    size = Vector2(x: w, y: h)
    updatePolygon()
  }

  override public func _ready() {
    updatePolygon()
  }

  private func updatePolygon() {
    let points = PackedVector2Array()
    points.append(Vector2(x: 0, y: 0)) // Top-left
    points.append(Vector2(x: size.x, y: 0)) // Top-right
    points.append(Vector2(x: size.x, y: size.y)) // Bottom-right
    points.append(Vector2(x: 0, y: size.y)) // Bottom-left
    polygon = points
  }
}

// MARK: - Builder Alias

/// Builder-pattern alias for ColorBox
public typealias ColorBox$ = GNode<ColorBox>
