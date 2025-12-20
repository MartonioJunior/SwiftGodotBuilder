import Foundation
import SwiftGodot

/// Debug visualization modifiers for `CollisionShape2D` nodes.
public extension GNode where T: CollisionShape2D {
  /// Draws a border around the collision shape for debugging.
  ///
  /// ### Usage:
  /// ```swift
  /// CollisionShape2D$()
  ///   .shape(RectangleShape2D(size: [32, 32]))
  ///   .debugBorder()
  /// ```
  ///
  /// - Parameters:
  ///   - color: Border color (default: red)
  ///   - width: Line width in pixels (default: 1)
  /// - Returns: The modified GNode
  func debugBorder(color: Color = Color.red, width: Float = 1) -> Self {
    var s = self
    s.ops.append { node in
      let line = Line2D()
      line.defaultColor = color
      line.width = Double(width)
      line.closed = true

      // Defer point calculation to next frame so shape is set
      Engine.onNextFrame {
        guard let shape = node.shape else { return }
        let points = Self.borderPoints(for: shape)
        for point in points {
          line.addPoint(position: point)
        }
      }

      node.addChild(node: line)
    }
    return s
  }

  /// Generates border points for different shape types.
  private static func borderPoints(for shape: Shape2D) -> [Vector2] {
    if let rect = shape as? RectangleShape2D {
      return rectanglePoints(size: rect.size)
    } else if let circle = shape as? CircleShape2D {
      return circlePoints(radius: Float(circle.radius))
    } else if let capsule = shape as? CapsuleShape2D {
      return capsulePoints(radius: Float(capsule.radius), height: Float(capsule.height))
    } else if let segment = shape as? SegmentShape2D {
      return [segment.a, segment.b]
    } else if let polygon = shape as? ConvexPolygonShape2D {
      return Array(polygon.points)
    }
    return []
  }

  private static func rectanglePoints(size: Vector2) -> [Vector2] {
    let half = size / 2
    return [
      Vector2(x: -half.x, y: -half.y),
      Vector2(x: half.x, y: -half.y),
      Vector2(x: half.x, y: half.y),
      Vector2(x: -half.x, y: half.y),
      Vector2(x: -half.x, y: -half.y) // Close the shape
    ]
  }

  private static func circlePoints(radius: Float, segments: Int = 32) -> [Vector2] {
    var points: [Vector2] = []
    let angleStep = (Float.pi * 2) / Float(segments)

    for i in 0...segments {
      let angle = angleStep * Float(i)
      points.append(Vector2(
        x: cosf(angle) * radius,
        y: sinf(angle) * radius
      ))
    }
    return points
  }

  private static func capsulePoints(radius: Float, height: Float, segments: Int = 16) -> [Vector2] {
    var points: [Vector2] = []
    let halfHeight = (height / 2) - radius

    // Top semicircle
    for i in 0...segments {
      let angle = Float.pi + (Float.pi * Float(i) / Float(segments))
      points.append(Vector2(
        x: cosf(angle) * radius,
        y: sinf(angle) * radius - halfHeight
      ))
    }

    // Bottom semicircle
    for i in 0...segments {
      let angle = Float.pi * Float(i) / Float(segments)
      points.append(Vector2(
        x: cosf(angle) * radius,
        y: sinf(angle) * radius + halfHeight
      ))
    }

    // Close the shape
    if let first = points.first {
      points.append(first)
    }

    return points
  }
}
